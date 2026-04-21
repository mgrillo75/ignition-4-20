# Gateway Timer Script — RTAC Failover Controller
# Fires every 1000 ms, dedicated scope: Gateway

# --- Tunables ---
HEARTBEAT_STALE_MS      = 5000   # heartbeat must advance within this window
FAILOVER_DEBOUNCE_SEC   = 3      # sustained bad health before flipping
RECOVERY_HOLD_SEC       = 30     # how long the other side must be healthy before we flip back

# --- Persistent state across timer fires (stored on the script itself) ---
state = system.util.getGlobals().setdefault("rtac_failover_state", {
    "a_bad_since": None,
    "b_bad_since": None,
    "a_good_since": None,
    "b_good_since": None,
    "last_heartbeat_a": None,
    "last_heartbeat_b": None,
    "last_heartbeat_a_time": None,
    "last_heartbeat_b_time": None,
})

now = system.date.now()

def assess_rtac(label, conn_name):
    """Return True if the RTAC is healthy right now."""
    # 1. Is the Modbus connection itself up? The driver exposes diagnostic tags.
    #    Adjust the path if your connection diagnostics live elsewhere.
    conn_status_path = "[System]Gateway/OPC/%s/Connected" % conn_name
    try:
        connected = system.tag.readBlocking([conn_status_path])[0].value
    except:
        connected = False
    if not connected:
        return False

    # 2. Heartbeat register should be incrementing. Path assumes each RTAC exposes
    #    a heartbeat register reachable through a fixed UDT at the known namespace.
    hb_path = "ns=1;s=[%s]heartbeat/counter" % conn_name
    # Read via OPC directly rather than through the parameterized UDT so we're
    # probing the physical connection, not whatever is currently active.
    try:
        hb_qv = system.opc.readValues("Ignition OPC UA Server", [hb_path])[0]
        hb_val = hb_qv.value if hb_qv.quality.isGood() else None
    except:
        hb_val = None

    last_key  = "last_heartbeat_%s" % label.lower()
    time_key  = "last_heartbeat_%s_time" % label.lower()

    if hb_val is None:
        return False

    prev_val  = state.get(last_key)
    prev_time = state.get(time_key)

    if prev_val is None or hb_val != prev_val:
        state[last_key]  = hb_val
        state[time_key]  = now
        return True

    # Value hasn't changed — is it stale?
    age_ms = system.date.millisBetween(prev_time, now)
    return age_ms < HEARTBEAT_STALE_MS


a_healthy = assess_rtac("A", "GCSA_RTAC_MODBUS")
b_healthy = assess_rtac("B", "GCSB_RTAC_MODBUS")

system.tag.writeBlocking(
    ["[default]GCS_RTAC_Control/A_Healthy",
     "[default]GCS_RTAC_Control/B_Healthy"],
    [a_healthy, b_healthy]
)

# --- Track how long each side has been in its current state ---
def stamp(key_good, key_bad, is_healthy):
    if is_healthy:
        if state[key_good] is None:
            state[key_good] = now
        state[key_bad] = None
    else:
        if state[key_bad] is None:
            state[key_bad] = now
        state[key_good] = None

stamp("a_good_since", "a_bad_since", a_healthy)
stamp("b_good_since", "b_bad_since", b_healthy)

def seconds_in_state(key):
    t = state.get(key)
    return None if t is None else system.date.secondsBetween(t, now)

# --- Decide active ---
forced  = system.tag.readBlocking(["[default]GCS_RTAC_Control/ForcedRTAC"])[0].value
current = system.tag.readBlocking(["[default]GCS_RTAC_Control/ActiveRTAC"])[0].value
new_active = current  # default: no change

if forced in ("A", "B"):
    # Manual override — respect it regardless of health.
    new_active = forced
else:
    # AUTO mode
    if current == "A":
        a_bad = seconds_in_state("a_bad_since")
        b_ok  = seconds_in_state("b_good_since")
        if a_bad is not None and a_bad >= FAILOVER_DEBOUNCE_SEC and b_healthy:
            new_active = "B"
    elif current == "B":
        b_bad = seconds_in_state("b_bad_since")
        a_ok  = seconds_in_state("a_good_since")
        # Only fail back to A after a longer hold period — avoids ping-ponging.
        if b_bad is not None and b_bad >= FAILOVER_DEBOUNCE_SEC and a_healthy:
            if a_ok is not None and a_ok >= RECOVERY_HOLD_SEC:
                new_active = "A"
            elif not b_healthy:
                # B is bad and hasn't recovered — take A if it's healthy at all
                new_active = "A"
    else:
        # Uninitialized — pick a healthy one, preferring A
        if a_healthy:
            new_active = "A"
        elif b_healthy:
            new_active = "B"

if new_active != current:
    logger = system.util.getLogger("RTAC_Failover")
    logger.warn("RTAC failover: %s -> %s (A_healthy=%s, B_healthy=%s, forced=%s)"
                % (current, new_active, a_healthy, b_healthy, forced))
    fc = system.tag.readBlocking(["[default]GCS_RTAC_Control/FailoverCount"])[0].value or 0
    system.tag.writeBlocking(
        ["[default]GCS_RTAC_Control/ActiveRTAC",
         "[default]GCS_RTAC_Control/LastFailoverTime",
         "[default]GCS_RTAC_Control/FailoverCount"],
        [new_active, now, fc + 1]
    )