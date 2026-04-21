import time

# GLOBAL CONSTANTS
SEL_PROVIDER = "[%s_RTAC_MODBUS]"
DEBUG = False

def current_master():
	master = system.tag.readBlocking(['[default]SEL_Internal_Tags/MasterController'], 300)[0].value
	audit.log_generic("RTAC current master is %s" %(master))
	return master

def build_sel_base_path():
	return SEL_PROVIDER % (current_master())

def dispatch(action_type, device_id, session):
	"""
	Central dispatcher for all operator control actions.

	Args:
	    action_type:    "START", "STOP", "RESET", "OPEN", "CLOSE"
	    device_id:   Equipment lookup key, e.g. "02-05-002-001"
	    session:        Perspective session object (for operator identity)
	"""
	result = {}
	operator = session.props.auth.user.userName
	audit.log_action(device_id, action_type, operator, result.get("success", ""), result.get("message", "Initiated"))

	try:
		result = dispatcher.dispatch_internal(action_type, device_id)
	except Exception, e:
		audit.log_action(device_id, action_type, operator, "FAILED", str(e))
		return {"success": False, "message": str(e)}
	
	audit.log_action(device_id, action_type, operator, result.get("success", "UNKNOWN"), result.get("message", "none"))
	return result

def dispatch_internal(action_type, device_id):
	result = {}

	if action_type == "gen_start":
		result = handleGenStartAction(device_id)
	elif action_type == "gen_stop":
		result = handleGenStopAction(device_id)
	elif action_type == "gen_block":
		result = handleGenBlockAction(device_id)
	elif action_type == "gen_auto":
		result = handleGenAutoAction(device_id)
	elif action_type == "gen_manual":
		result = handleGenManualAction(device_id)
	elif action_type == "gcb_open":
		result = handleGCBOpenAction(device_id)
	elif action_type == "icb_open":
		result = handleICBOpenAction(device_id)
	elif action_type == "icb_close":
		result = handleICBCloseAction(device_id)
	elif action_type == "fcb_open":
		result = handleFCBOpenAction(device_id)
	elif action_type == "fcb_close":
		result = handleFCBCloseAction(device_id)
	elif action_type == "set_gen_priority":
		result = handleSetGenPriorityAction(device_id)
	elif action_type == "set_gen_blackstart":
		result = handleGenSetBlackStartAction(device_id)
	elif action_type == "blackstart":
		result = handleBlackStartAction()
	elif action_type == "party":
		result = handlePartyModeAction()
	elif action_type == "irm":
		result = handleIRMToggleAction()
	elif action_type == "mlm": 
		result = handleMLMToggleAction()
	else:
		raise ValueError("Invalid action %s" % (action_type))
	
	return result
	
	    
def pulseTag(tagPath, pulseLength=1000):
	"""
	Pulses a boolean tag (gateway-safe version using sleep on async thread).
	
	Args:
	    tagPath:     Full tag path, e.g. "[default]MyFolder/MyTag"
	    pulseLength: Pulse duration in milliseconds (default 1000)
	"""
	def doPulse():
		try:
		    system.tag.writeBlocking([tagPath], [True])
		    time.sleep(pulseLength / 1000.0)
		    system.tag.writeBlocking([tagPath], [False])
		except Exception, e:
			audit.log_generic("Pulse failed: %s, error: %s" % (tagPath, str(e)))
	
	system.util.invokeAsynchronous(doPulse)
	    
def handleGenStartAction(device_id):
	
	sel_id = device_registry.get_sel_id(device_id)
	tag_path = "%sGCS/DigitalOutput/GCS_%s_Start_CMD" % (build_sel_base_path(), sel_id)
	pulseTag(tag_path, 1000)
	return {"success": True, "message": "%s start signal sent to SEL tag path %s" % (device_id.upper(), tag_path) }
	
def handleGenStopAction(device_id):
	sel_id = device_registry.get_sel_id(device_id)
	tag_path = "%sGCS/DigitalOutput/GCS_%s_Stop_CMD" % (build_sel_base_path(), sel_id)
	pulseTag(tag_path, 1000)
	# assume success on pulse
	return {"success": True, "message": "%s stop signal sent to SEL tag path %s" % (device_id.upper(), tag_path) }
	
def handleGenBlockAction(device_id):
	sel_id = device_registry.get_sel_id(device_id)
	# below tag path is correct - it is an AGC tag under GCS folder
	tag_path = "%sGCS/AnalogOutput/AGC_%s_GensetOpMode_SET" % (build_sel_base_path(), sel_id)
	system.tag.writeBlocking([tag_path], [2])
	return {"success": True, "message": "%s block signal sent to SEL tag path %s" % (device_id.upper(), tag_path) }
	
def handleGenAutoAction(device_id):
	sel_id = device_registry.get_sel_id(device_id)
	# below tag path is correct - it is an AGC tag under GCS folder
	tag_path = "%sGCS/AnalogOutput/AGC_%s_GensetOpMode_SET" % (build_sel_base_path(), sel_id)
	system.tag.writeBlocking([tag_path], [1])
	return {"success": True, "message": "%s auto signal sent to SEL tag path %s" % (device_id.upper(), tag_path) }
	
def handleGenManualAction(device_id):
	sel_id = device_registry.get_sel_id(device_id)
	# below tag path is correct - it is an AGC tag under GCS folder
	tag_path = "%sGCS/AnalogOutput/AGC_%s_GensetOpMode_SET" % (build_sel_base_path(), sel_id)
	system.tag.writeBlocking([tag_path], [0])
	return {"success": True, "message": "%s manual signal sent to SEL tag path %s" % (device_id.upper(), tag_path) }
	
def handleGCBOpenAction(device_id):
	sel_id = device_registry.get_sel_id(device_id)
	tag_path = "%sGCS/DigitalOutput/GCS_%s_BrkOpen_CMD" % (build_sel_base_path(), sel_id)
	pulseTag(tag_path, 1000)
	return {"success": True, "message": "%s open signal sent to SEL tag path %s" % (device_id.upper(), tag_path) }

def handleICBOpenAction(device_id):
	sel_id = device_registry.get_sel_id(device_id)
	tag_path = "%sICB/DigitalOutput/ICB_%s_Open_CMD" % (build_sel_base_path(), sel_id)
	pulseTag(tag_path, 1000)
	return {"success": True, "message": "%s open signal sent to SEL tag path %s" % (device_id.upper(), tag_path) }

def handleICBCloseAction(device_id):
	sel_id = device_registry.get_sel_id(device_id)
	tag_path = "%sICB/DigitalOutput/ICB_%s_Close_CMD" % (build_sel_base_path(), sel_id)
	pulseTag(tag_path, 1000)
	return {"success": True, "message": "%s close signal sent to SEL tag path %s" % (device_id.upper(), tag_path) }
	
def handleFCBOpenAction(device_id):
	sel_id = device_registry.get_sel_id(device_id)
	tag_path = "%sICB/DigitalOutput/LOAD_%s_Open_CMD" % (build_sel_base_path(), sel_id)
	pulseTag(tag_path, 1000)
	return {"success": True, "message": "%s open signal sent to SEL tag path %s" % (device_id.upper(), tag_path) }

def handleFCBCloseAction(device_id):
	sel_id = device_registry.get_sel_id(device_id)
	tag_path = "%sICB/DigitalOutput/LOAD_%s_Close_CMD" % (build_sel_base_path(), sel_id)
	pulseTag(tag_path, 1000)
	return {"success": True, "message": "%s close signal sent to SEL tag path %s" % (device_id.upper(), tag_path) }

def handlePartyModeAction():
	audit.log_generic("HERE")
	tag_path = "%sGMS/DigitalOutput/GMS_PartyModeEnable_CMD" % (build_sel_base_path())
	pulseTag(tag_path, 1000)
	return {"success": True, "message": "%s close signal sent to SEL tag path %s" % (device_id.upper(), tag_path) }
	
def handleIRMToggleAction():
	# get current value
	current_value = system.tag.readBlocking("%sGMS/DigitalInput/GMS_IRMControlEnabled_STAT" % (build_sel_base_path()), 300)[0].value
	tag_path = "%sGMS/DigitalOutput/GMS_IRMEnable_CMD" % (build_sel_base_path())
	system.tag.writeBlocking([tag_path], [not current_value])
	return {"success": True, "message": "IRM toggle signal sent to SEL tag path %s" % (tag_path) }
	
def handleMLMToggleAction():
	# get current value
	current_value = system.tag.readBlocking("%sGMS/DigitalInput/GMS_MLMControlEnabled_STAT" % (build_sel_base_path()), 300)[0].value
	tag_path = "%sGMS/DigitalOutput/GMS_MLMEnable_CMD" % (build_sel_base_path())
	system.tag.writeBlocking([tag_path], [not current_value])
	return {"success": True, "message": "MLM toggle signal sent to SEL tag path %s" % (tag_path) }
	
def handleSetGenPriorityAction(device_id):
	pass
	
def handleSetBlackStartAction(device_id):
	pass
	
def handleBlackStartAction():
	pass