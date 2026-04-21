# RTAC Failover — audit-logging tag change script.
#
# Bind this script to the Value Changed event of
#   [default]GCS_RTAC_Control/ActiveRTAC
# in Designer (Tag Editor -> Events -> Value Changed, or Gateway Tag Change
# Scripts if you prefer a project-scope binding).
#
# The failover DECISION is made in the expression chain
#   [default]SEL_Internal_Tags/MasterController
#     -> [default]SEL_Internal_Tags/ActiveProvider
#     -> [default]GCS_RTAC_Control/ActiveRTAC
# All this script does is keep an audit trail when ActiveRTAC flips.
#
# currentValue and previousValue are QualifiedValue objects (event parameters).

def valueChanged(tag, tagPath, previousValue, currentValue, initialChange, missedEvents):
    # Ignore startup initialization — only record real transitions at runtime.
    if initialChange:
        return

    prev = previousValue.value if previousValue is not None else None
    curr = currentValue.value if currentValue is not None else None

    if prev == curr:
        return

    # Figure out WHY we flipped so the audit trail is useful.
    reads = system.tag.readBlocking([
        "[default]GCS_RTAC_Control/ForcedRTAC",
        "[default]SEL_Internal_Tags/MasterController",
        "[default]GCS_RTAC_Control/A_Healthy",
        "[default]GCS_RTAC_Control/B_Healthy",
        "[default]GCS_RTAC_Control/FailoverCount",
    ])
    forced       = reads[0].value
    master       = reads[1].value
    a_healthy    = bool(reads[2].value)
    b_healthy    = bool(reads[3].value)
    count        = reads[4].value or 0

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

    logger = system.util.getLogger("RTAC_Failover")
    logger.warn("RTAC failover: %s -> %s (%s)" % (prev, curr, reason))
