logger = system.util.getLogger("operator_actions")

def log_generic(obj):
	logger.info(str(obj))
	
def log_debug(message):
	logger.debug(message)

def log_action(device_id, action_type, operator, result="", message=""):
    """Write an audit record to the operator_action_log table."""
    logger.info("Action %s on device %s performed by operator %s: Result %s - %s" % (action_type, device_id, operator, result, message))
    
    
### FUTURE STATE ###
#    system.db.runNamedQuery(
#        "Operator/InsertActionLog",
#        {
#            "deviceId": device_id,
#            "actionType": action_type,
#            "operator": operator,
#            "result": result,       # "SUCCESS", "FAILED", "CANCELLED"
#            "message": message,
#            "timestamp": system.date.now()
#        }
#    )