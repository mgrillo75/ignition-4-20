import re

TYPE_MAP = {
		"br": "jenbacher620",
		"700g": "sel700g",
		"751": "sel751",
		"787": "sel787_3e",
		"2411": "sel2411",
	}

REVERSE_TYPE_MAP = {v: k for k, v in TYPE_MAP.items()}

DEVICE_ID_REGEX = re.compile(r"(?P<provider>\[.*\])?(?P<folder>.*\/)?(?P<site>.*)-(?P<powerblock>pb\d+)-(?P<node>n[12])-(?P<loc>\w+)-(?P<type>\w+)-(?P<seq>\d+)")
NUMBERED_LABEL_REGEX = re.compile(r"^(?P<label>[a-zA-Z]+)(?P<number>\d+)?$")

def type_lookup(input):
	return TYPE_MAP.get(input, None)

def reverse_type_lookup(input):
	return REVERSE_TYPE_MAP.get(input, None)

def build_device_id(node, loc, device_type, device_number):
	site = system.tag.readBlocking(["[default]_Settings/VG-Site/SiteName"], 100)[0].value
	power_block = system.tag.readBlocking(["[default]_Settings/VG-Site/PowerBlock"], 100)[0].value
	return "%s-pb%d-n%d-qp%d-%s-%s-%03d" % (site.lower(), power_block, node, qpac, purpose.lower(), device_type.lower(), device_number)

def parse_device_id(device_id):
	parsed = DEVICE_ID_REGEX.match(device_id)
	if not parsed:
		raise ValueError("Device ID %s is not a valid pattern" % device_id)
	return parsed

def get_device_type(device_id, telemetry_type = False):
	parsed = DEVICE_ID_REGEX.match(device_id)
	if telemetry_type:
		return TYPE_MAP[parsed.group('type')]
	return parsed.group('type')

def get_sel_id(device_id):
	parsed = parse_device_id(device_id)
		
	loc = parsed.group('loc')
	
	# genset related location
	if 'qp' in loc.lower():
		qpac = int(loc.replace('qp', ''))
		unit = int(parsed.group('seq'))
		return "G%d" % (((qpac - 1) * 4) + unit)

	# fcb related location
	if 'fcb' in loc.lower():
		fcb = loc.upper()
		return fcb