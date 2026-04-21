# RTAC Failover — audit logging via Gateway Tag Change Script.
#
# Ignition 8.3: configure this under
#   Project  ->  Gateway Events  ->  Tag Change  ->  [New Tag Change Script]
#
# Configure the script as follows:
#   Name:        RTAC_Failover_Audit
#   Tag paths:   [default]GCS_RTAC_Control/ActiveRTAC
#   Event type:  Value changed
#   Script body: everything below (PASTE starting at the `if initialChange:` line)
#
# The event provides: tagPath, previousValue, currentValue, initialChange, missedEvents.

if initialChange:
    # Fired once per gateway start; don't record it as a real transition.
    pass
else:
    prev = previousValue.value if previousValue is not None else None
    curr = currentValue.value if currentValue is not None else None

    if prev != curr:
        reads = system.tag.readBlocking([
            "[default]GCS_RTAC_Control/ForcedRTAC",
            "[default]SEL_Internal_Tags/MasterController",
            "[default]GCS_RTAC_Control/A_Healthy",
            "[default]GCS_RTAC_Control/B_Healthy",
            "[default]GCS_RTAC_Control/FailoverCount",
        ])
        forced    = reads[0].value
        master    = reads[1].value
        a_healthy = bool(reads[2].value)
        b_healthy = bool(reads[3].value)
        count     = reads[4].value or 0

        if forced in ("A", "B"):
            reason = "forced=%s" % forced
        else:
            reason = "master=%s (A_healthy=%s, B_healthy=%s)" % (master, a_healthy, b_healthy)

        now = system.date.now()

        system.tag.writeBlocking(
            [
                "[default]GCS_RTAC_Control/LastFailoverTime",
                "[default]GCS_RTAC_Control/LastFailoverReason",
                "[default]GCS_RTAC_Control/FailoverCount",
            ],
            [now, reason, count + 1]
        )

        system.util.getLogger("RTAC_Failover").warn(
            "RTAC failover: %s -> %s (%s)" % (prev, curr, reason)
        )
