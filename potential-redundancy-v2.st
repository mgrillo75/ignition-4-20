# Gateway Timer Script — RTAC Failover Controller
# Fires every 1000 ms, Gateway scope
#
# Authoritative source: [default]SEL_Internal_Tags/MasterController
#   Values: "GCSA" or "GCSB"
# Output: [default]GCS_RTAC_Control/ActiveRTAC ("A" or "B")
# The UDT parameter ActiveRTAC reads this and routes all member OPC paths
# to [GCS{ActiveRTAC}_RTAC_MODBUS].

# --- Tunables ---
DEBOUNCE_SEC = 2  # how long a new value must persist before we commit to it

# --- Persistent state across timer fires ---
state = system.util.getGlobals().setdefault("rtac_failover_state", {
    "pending_value": None,     # value we've seen but not yet committed
    "pending_since": None,     # when we first saw it
})

now = system.date.now()
logger = system.util.getLogger("RTAC_Failover")

# --- Read inputs ---
reads = system.tag.readBlocking([
    "[default]SEL_Internal_Tags/MasterController",
    "[default]GCS_RTAC_Control/ForcedRTAC",
    "[default]GCS_RTAC_Control/ActiveRTAC",
    "[System]Gateway/OPC/GCSA_RTAC_MODBUS/Connected",
    "[System]Gateway/OPC/GCSB_RTAC_MODBUS/Connected",
])

master_qv   = reads[0]
forced      = reads[1].value
current     = reads[2].value
a_connected = bool(reads[3].value)
b_connected = bool(reads[4].value)

# Publish raw health for operator visibility
system.tag.writeBlocking(
    ["[default]GCS_RTAC_Control/A_Healthy",
     "[default]GCS_RTAC_Control/B_Healthy"],
    [a_connected, b_connected]
)

# --- Translate MasterController value to our A/B convention ---
def translate(val):
    if val == "GCSA":
        return "A"
    if val == "GCSB":
        return "B"
    return None  # unknown / null / garbage

master_valid   = master_qv.quality.isGood() and master_qv.value is not None
authoritative  = translate(master_qv.value) if master_valid else None

# --- Decide the target ---
# Priority: manual override > authoritative RTAC value > fallback to last-known-good connection
if forced in ("A", "B"):
    target = forced
    reason = "forced"
elif authoritative is not None:
    target = authoritative
    reason = "authoritative"
elif a_connected and not b_connected:
    target = "A"
    reason = "fallback: only A reachable"
elif b_connected and not a_connected:
    target = "B"
    reason = "fallback: only B reachable"
else:
    # Authoritative source unreadable AND we can't distinguish by connection.
    # Hold whatever we had. Don't change anything.
    target = current
    reason = "hold: no reliable signal"

# --- Debounce: don't commit a change until it's stable ---
commit = False

if target == current:
    # Nothing to do; clear any pending change
    state["pending_value"] = None
    state["pending_since"] = None
elif reason == "forced":
    # Manual overrides take effect immediately
    commit = True
else:
    if state["pending_value"] != target:
        # First time we've seen this new target — start the clock
        state["pending_value"] = target
        state["pending_since"] = now
    else:
        # Same target as last tick — has it been stable long enough?
        age = system.date.secondsBetween(state["pending_since"], now)
        if age >= DEBOUNCE_SEC:
            commit = True

# --- Commit the switch ---
if commit and target != current:
    logger.warn(
        "RTAC failover: %s -> %s (reason=%s, master=%s, A_conn=%s, B_conn=%s)"
        % (current, target, reason, master_qv.value, a_connected, b_connected)
    )
    fc = system.tag.readBlocking(["[default]GCS_RTAC_Control/FailoverCount"])[0].value or 0
    system.tag.writeBlocking(
        ["[default]GCS_RTAC_Control/ActiveRTAC",
         "[default]GCS_RTAC_Control/LastFailoverTime",
         "[default]GCS_RTAC_Control/FailoverCount"],
        [target, now, fc + 1]
    )
    state["pending_value"] = None
    state["pending_since"] = None