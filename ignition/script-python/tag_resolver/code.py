# Constants
master_controller_base_path = "default/master-controller"

def resolve(master_controller_id, action_type):
	return "/".join([master_controller_base_path, master_controller_id.lower(), action_type.lower()])