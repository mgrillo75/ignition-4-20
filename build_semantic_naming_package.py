from pathlib import Path
import json
import re
from collections import defaultdict, Counter

root = Path(r'C:\Users\MiguelGrillo\Documents\cursor\ignition-4-20')
source_instances_path = root / 'object-models-udts-instances' / 'tags-4-20.json'
source_udts_path = root / 'object-models-udts-instances' / 'udts-4-20.json'
source_system_tags_path = root / 'tags-4-20.json'
outdir = root / 'refactor-naming-v1'
outdir.mkdir(parents=True, exist_ok=True)

source_instances = json.loads(source_instances_path.read_text(encoding='utf-8'))
source_udts = json.loads(source_udts_path.read_text(encoding='utf-8'))
source_system_tags = json.loads(source_system_tags_path.read_text(encoding='utf-8'))

UDT_RENAMES = {
    'jenbacher620_1_0_0': 'Device_Generator_JenbacherJ620',
    'sel751a_1_0_0': 'Device_Relay_SEL751A',
    'sel700g_1_0_0': 'Device_Relay_SEL700G',
    'sel735_1_0_0': 'Device_Meter_SEL735',
    'sel751_1_0_0': 'Device_Relay_SEL751',
    'sel787_3e_1_0_0': 'Device_Relay_SEL787_3E',
}


def folder(name, tags=None):
    obj = {'name': name, 'tagType': 'Folder'}
    if tags is not None:
        obj['tags'] = tags
    return obj


def memory_tag(name, value, data_type='String', read_only=True):
    tag = {
        'name': name,
        'tagType': 'AtomicTag',
        'valueSource': 'memory',
        'value': value,
        'defaultValue': value,
        'dataType': data_type,
    }
    if read_only:
        tag['readOnly'] = True
    return tag


def reference_tag(name, source_path, data_type='String', history=False):
    tag = {
        'name': name,
        'tagType': 'AtomicTag',
        'valueSource': 'reference',
        'sourceTagPath': source_path,
        'dataType': data_type,
    }
    if history:
        tag['historyEnabled'] = True
    return tag


def parameter_reference_tag(name, binding, data_type='String', history=False):
    tag = {
        'name': name,
        'tagType': 'AtomicTag',
        'valueSource': 'reference',
        'sourceTagPath': {
            'bindType': 'parameter',
            'binding': binding,
        },
        'dataType': data_type,
    }
    if history:
        tag['historyEnabled'] = True
    return tag


def clone(obj):
    return json.loads(json.dumps(obj))


def rename_adapter_udts(src_root):
    out = {'name': '_types_', 'tagType': 'Folder', 'tags': []}
    for tag in src_root.get('tags', []):
        new_name = UDT_RENAMES.get(tag.get('name'))
        if new_name:
            new_tag = clone(tag)
            new_tag['name'] = new_name
            out['tags'].append(new_tag)
    return out


def build_semantic_udts():
    udts = []

    udts.append({
        'name': 'Obj_Generator_Genset',
        'tagType': 'UdtType',
        'parameters': {
            'SourcePath': {'dataType': 'String', 'value': '[default]TX3/legacy/genset'},
        },
        'tags': [
            folder('Definition', [
                memory_tag('ObjectType', 'Generator.Genset'),
                memory_tag('NamingStandard', 'SemanticV1'),
            ]),
            folder('Electrical', [
                parameter_reference_tag('RealPower', '{SourcePath}/power', 'Float8', True),
                parameter_reference_tag('ReactivePower', '{SourcePath}/reactivePower', 'Float8', True),
                parameter_reference_tag('Frequency', '{SourcePath}/frequency', 'Float8', True),
                parameter_reference_tag('AverageVoltage', '{SourcePath}/averageVoltage', 'Float8', True),
            ]),
            folder('Control', [
                parameter_reference_tag('AutoManualMode', '{SourcePath}/AutoManual', 'String'),
                parameter_reference_tag('LocalRemoteMode', '{SourcePath}/spare545_LocalRemote', 'String'),
                parameter_reference_tag('PowerSetpoint', '{SourcePath}/setpointPowerControl', 'Float8'),
            ]),
            folder('Status', [
                parameter_reference_tag('BreakerStatus', '{SourcePath}/spare515_BreakerStatus', 'String'),
                parameter_reference_tag('HeartbeatStatus', '{SourcePath}/heartbeat/status', 'String'),
                parameter_reference_tag('HeartbeatCounter', '{SourcePath}/heartbeat/counter', 'Int4'),
                parameter_reference_tag('HeartbeatTimestamp', '{SourcePath}/heartbeat/timestamp', 'String'),
                memory_tag('LegacyDeviceType', 'Device_Generator_JenbacherJ620'),
                memory_tag('LegacyPath', '{SourcePath}', read_only=False),
            ]),
        ]
    })

    udts.append({
        'name': 'Obj_Relay_ProtectionRelay700G',
        'tagType': 'UdtType',
        'parameters': {
            'SourcePath': {'dataType': 'String', 'value': '[default]TX3/legacy/relay700g'},
        },
        'tags': [
            folder('Definition', [
                memory_tag('ObjectType', 'Relay.Protection.700G'),
                memory_tag('NamingStandard', 'SemanticV1'),
            ]),
            folder('Protection', [
                parameter_reference_tag('SyncFrequency', '{SourcePath}/syncFrequency', 'Float8', True),
                parameter_reference_tag('BreakerPosition', '{SourcePath}/bit_52ax', 'String'),
            ]),
            folder('Status', [
                parameter_reference_tag('Address', '{SourcePath}/address', 'String'),
                parameter_reference_tag('HeartbeatStatus', '{SourcePath}/heartbeat/status', 'String'),
                parameter_reference_tag('HeartbeatCounter', '{SourcePath}/heartbeat/counter', 'Int4'),
                parameter_reference_tag('HeartbeatTimestamp', '{SourcePath}/heartbeat/timestamp', 'String'),
                memory_tag('LegacyDeviceType', 'Device_Relay_SEL700G'),
                memory_tag('LegacyPath', '{SourcePath}', read_only=False),
            ]),
        ]
    })

    udts.append({
        'name': 'Obj_Relay_ProtectionRelay751',
        'tagType': 'UdtType',
        'parameters': {
            'SourcePath': {'dataType': 'String', 'value': '[default]TX3/legacy/relay751'},
        },
        'tags': [
            folder('Definition', [
                memory_tag('ObjectType', 'Relay.Protection.751'),
                memory_tag('NamingStandard', 'SemanticV1'),
            ]),
            folder('Protection', [
                parameter_reference_tag('BreakerPosition', '{SourcePath}/bit_52a', 'String'),
            ]),
            folder('Status', [
                parameter_reference_tag('HeartbeatStatus', '{SourcePath}/heartbeat/status', 'String'),
                parameter_reference_tag('HeartbeatCounter', '{SourcePath}/heartbeat/counter', 'Int4'),
                parameter_reference_tag('HeartbeatTimestamp', '{SourcePath}/heartbeat/timestamp', 'String'),
                memory_tag('LegacyDeviceType', 'Device_Relay_SEL751'),
                memory_tag('LegacyPath', '{SourcePath}', read_only=False),
            ]),
        ]
    })

    udts.append({
        'name': 'Obj_Relay_ProtectionRelay787',
        'tagType': 'UdtType',
        'parameters': {
            'SourcePath': {'dataType': 'String', 'value': '[default]TX3/legacy/relay787'},
        },
        'tags': [
            folder('Definition', [
                memory_tag('ObjectType', 'Relay.Protection.787'),
                memory_tag('NamingStandard', 'SemanticV1'),
            ]),
            folder('Protection', [
                parameter_reference_tag('BreakerPosition', '{SourcePath}/bit_52a1', 'String'),
            ]),
            folder('Status', [
                parameter_reference_tag('HeartbeatStatus', '{SourcePath}/heartbeat/status', 'String'),
                parameter_reference_tag('HeartbeatCounter', '{SourcePath}/heartbeat/counter', 'Int4'),
                parameter_reference_tag('HeartbeatTimestamp', '{SourcePath}/heartbeat/timestamp', 'String'),
                memory_tag('LegacyDeviceType', 'Device_Relay_SEL787_3E'),
                memory_tag('LegacyPath', '{SourcePath}', read_only=False),
            ]),
        ]
    })

    udts.append({
        'name': 'Obj_Breaker_GeneratorCircuitBreaker',
        'tagType': 'UdtType',
        'parameters': {
            'SourcePath': {'dataType': 'String', 'value': '[default]TX3/legacy/gcb'},
        },
        'tags': [
            folder('Definition', [
                memory_tag('ObjectType', 'Breaker.GCB'),
                memory_tag('NamingStandard', 'SemanticV1'),
            ]),
            folder('Status', [
                parameter_reference_tag('Position', '{SourcePath}/spare515_BreakerStatus', 'String'),
                parameter_reference_tag('LocalRemoteMode', '{SourcePath}/spare545_LocalRemote', 'String'),
                memory_tag('LegacyPath', '{SourcePath}', read_only=False),
            ])
        ]
    })

    udts.append({
        'name': 'Obj_Breaker_FeederCircuitBreaker',
        'tagType': 'UdtType',
        'parameters': {
            'SourcePath': {'dataType': 'String', 'value': '[default]TX3/legacy/fcb'},
        },
        'tags': [
            folder('Definition', [
                memory_tag('ObjectType', 'Breaker.FCB'),
                memory_tag('NamingStandard', 'SemanticV1'),
            ]),
            folder('Status', [
                parameter_reference_tag('Position', '{SourcePath}/bit_52a', 'String'),
                memory_tag('LegacyPath', '{SourcePath}', read_only=False),
            ])
        ]
    })

    return {'name': '_types_', 'tagType': 'Folder', 'tags': udts}


# parse legacy instances into semantic structure
legacy_instances = []

def walk(node, path=''):
    if isinstance(node, dict):
        for c in node.get('tags', []) or []:
            child = f"{path}/{c.get('name', '')}" if path else c.get('name', '')
            if c.get('tagType') == 'UdtInstance' and c.get('typeId'):
                legacy_instances.append({'path': child, 'node': c})
            walk(c, child)
walk(source_instances)

qpac_map = defaultdict(lambda: {'gens': [], '700g': [], '787': []})
feeder_map = defaultdict(lambda: {'751': []})
rename_rows = []

for inst in legacy_instances:
    name = inst['node']['name']
    path = inst['path']
    if m := re.match(r'TX3/tx3-pb(\d+)-n(\d+)-qp(\d+)-br-(\d+)$', path):
        pb, node, qpac, idx = m.groups()
        new_path = f'TX3/PowerBlock_{int(pb)}/Node_{int(node)}/QPAC_{int(qpac)}/PowerGen/Gen_{int(idx)}'
        qpac_map[(int(pb), int(node), int(qpac))]['gens'].append((int(idx), path, new_path))
        rename_rows.append((path, new_path, 'Generator adapter instance', 'PowerGen/Gen_n semantic object'))
    elif m := re.match(r'TX3/tx3-pb(\d+)-n(\d+)-qp(\d+)-sel700g-(\d+)$', path):
        pb, node, qpac, idx = m.groups()
        new_path = f'TX3/PowerBlock_{int(pb)}/Node_{int(node)}/QPAC_{int(qpac)}/IEDs/700G_{int(idx)}'
        qpac_map[(int(pb), int(node), int(qpac))]['700g'].append((int(idx), path, new_path))
        rename_rows.append((path, new_path, 'SEL700G relay instance', 'IEDs/700G_n semantic object'))
    elif m := re.match(r'TX3/tx3-pb(\d+)-n(\d+)-qp(\d+)-787-(\d+)$', path):
        pb, node, qpac, idx = m.groups()
        new_path = f'TX3/PowerBlock_{int(pb)}/Node_{int(node)}/QPAC_{int(qpac)}/IEDs/787_{int(idx)}'
        qpac_map[(int(pb), int(node), int(qpac))]['787'].append((int(idx), path, new_path))
        rename_rows.append((path, new_path, 'SEL787 relay instance', 'IEDs/787_n semantic object'))
    elif m := re.match(r'TX3/tx3-pb(\d+)-n(\d+)-fcb(\d+)-751-(\d+)$', path):
        pb, node, fcb, idx = m.groups()
        new_path = f'TX3/PowerBlock_{int(pb)}/Node_{int(node)}/Feeders/FCB_{int(fcb)}/IEDs/751_{int(idx)}'
        feeder_map[(int(pb), int(node), int(fcb))]['751'].append((int(idx), path, new_path))
        rename_rows.append((path, new_path, 'SEL751 feeder relay instance', 'Feeders/FCB_n/IEDs/751_n semantic object'))

# system folder mirrors
system_mapping = {
    'GCS_RTAC_Control': ('Systems', 'GCS', 'RTACControl'),
    'SEL_Internal_Tags': ('Infrastructure', 'SEL', 'InternalTags'),
    '_Controls_': ('Infrastructure', 'Controls'),
    '_Settings': ('Settings',),
}

def mirror_folder_as_references(src_folder, src_prefix):
    tags = []
    for item in src_folder.get('tags', []) or []:
        if item.get('tagType') == 'Folder':
            tags.append({'name': item['name'], 'tagType': 'Folder', 'tags': mirror_folder_as_references(item, f"{src_prefix}/{item['name']}")})
        elif item.get('tagType') == 'AtomicTag':
            data_type = item.get('dataType', 'String')
            tags.append(reference_tag(item['name'], f"[default]{src_prefix}/{item['name']}", data_type, item.get('historyEnabled', False)))
    return tags

provider_root = {'name': '', 'tagType': 'Provider', 'tags': []}

tx3_folder = folder('TX3', [])
provider_root['tags'].append(tx3_folder)

# mirrored settings/systems/infrastructure
for child in source_system_tags.get('tags', []):
    if child.get('name') in system_mapping:
        parts = system_mapping[child['name']]
        current = tx3_folder
        for part in parts:
            existing = next((t for t in current['tags'] if t.get('name') == part and t.get('tagType') == 'Folder'), None)
            if not existing:
                existing = folder(part, [])
                current['tags'].append(existing)
            current = existing
        current['tags'].extend(mirror_folder_as_references(child, f"/{child['name']}"))

# power block hierarchy
pb_folders = {}
for (pb, node, qpac), _ in list(qpac_map.items()):
    pb_folder = pb_folders.setdefault(pb, folder(f'PowerBlock_{pb}', []))
    node_folder = next((t for t in pb_folder['tags'] if t['name'] == f'Node_{node}'), None)
    if not node_folder:
        node_folder = folder(f'Node_{node}', [])
        pb_folder['tags'].append(node_folder)
    q_folder = folder(f'QPAC_{qpac}', [])
    q_data = qpac_map[(pb, node, qpac)]

    if q_data['gens']:
        pg = folder('PowerGen', [])
        br = folder('Breakers', [])
        for idx, legacy_path, _new_path in sorted(q_data['gens']):
            src = f'[default]{legacy_path}'
            pg['tags'].append({
                'name': f'Gen_{idx}',
                'tagType': 'UdtInstance',
                'typeId': 'Obj_Generator_Genset',
                'parameters': {'SourcePath': {'dataType': 'String', 'value': src}}
            })
            br['tags'].append({
                'name': f'GCB_{idx}',
                'tagType': 'UdtInstance',
                'typeId': 'Obj_Breaker_GeneratorCircuitBreaker',
                'parameters': {'SourcePath': {'dataType': 'String', 'value': src}}
            })
        q_folder['tags'].append(pg)
        q_folder['tags'].append(br)

    if q_data['700g'] or q_data['787']:
        ieds = folder('IEDs', [])
        for idx, legacy_path, _new_path in sorted(q_data['700g']):
            ieds['tags'].append({
                'name': f'700G_{idx}',
                'tagType': 'UdtInstance',
                'typeId': 'Obj_Relay_ProtectionRelay700G',
                'parameters': {'SourcePath': {'dataType': 'String', 'value': f'[default]{legacy_path}'}}
            })
        for idx, legacy_path, _new_path in sorted(q_data['787']):
            ieds['tags'].append({
                'name': f'787_{idx}',
                'tagType': 'UdtInstance',
                'typeId': 'Obj_Relay_ProtectionRelay787',
                'parameters': {'SourcePath': {'dataType': 'String', 'value': f'[default]{legacy_path}'}}
            })
        q_folder['tags'].append(ieds)

    node_folder['tags'].append(q_folder)

# feeders
for (pb, node, fcb), data in feeder_map.items():
    pb_folder = pb_folders.setdefault(pb, folder(f'PowerBlock_{pb}', []))
    node_folder = next((t for t in pb_folder['tags'] if t['name'] == f'Node_{node}'), None)
    if not node_folder:
        node_folder = folder(f'Node_{node}', [])
        pb_folder['tags'].append(node_folder)
    feeders = next((t for t in node_folder['tags'] if t['name'] == 'Feeders'), None)
    if not feeders:
        feeders = folder('Feeders', [])
        node_folder['tags'].append(feeders)
    f_folder = folder(f'FCB_{fcb}', [])
    ieds = folder('IEDs', [])
    breakers = folder('Breakers', [])
    for idx, legacy_path, _new_path in sorted(data['751']):
        src = f'[default]{legacy_path}'
        ieds['tags'].append({
            'name': f'751_{idx}',
            'tagType': 'UdtInstance',
            'typeId': 'Obj_Relay_ProtectionRelay751',
            'parameters': {'SourcePath': {'dataType': 'String', 'value': src}}
        })
        breakers['tags'].append({
            'name': f'FCB_{fcb}',
            'tagType': 'UdtInstance',
            'typeId': 'Obj_Breaker_FeederCircuitBreaker',
            'parameters': {'SourcePath': {'dataType': 'String', 'value': src}}
        })
    f_folder['tags'].append(ieds)
    f_folder['tags'].append(breakers)
    feeders['tags'].append(f_folder)

for pb in sorted(pb_folders):
    tx3_folder['tags'].append(pb_folders[pb])

# create docs
rename_matrix_md = ['# 4-20 Rename Matrix', '', '| Legacy path | Proposed semantic path | Legacy role | New role |', '|---|---|---|---|']
for old, new, old_role, new_role in sorted(rename_rows):
    rename_matrix_md.append(f'| `{old}` | `{new}` | {old_role} | {new_role} |')

udt_standard_md = '''# 4-20 UDT Type Naming Standard

Prefix rules:
- `Device_` = vendor/device-specific UDTs that preserve raw source field names
- `Base_` = reusable semantic primitives
- `Obj_` = semantic domain objects used by views and higher-level logic

Active UDT names in semantic package:
- Device_Generator_JenbacherJ620
- Device_Relay_SEL700G
- Device_Relay_SEL751
- Device_Relay_SEL751A
- Device_Meter_SEL735
- Device_Relay_SEL787_3E
- Obj_Generator_Genset
- Obj_Relay_ProtectionRelay700G
- Obj_Relay_ProtectionRelay751
- Obj_Relay_ProtectionRelay787
- Obj_Breaker_GeneratorCircuitBreaker
- Obj_Breaker_FeederCircuitBreaker

Object/member naming rules:
- Preserve canonical acronyms in uppercase: TX3, QPAC, IED, GCB, ICB, FCB, FEP, GCS, GMS, AGC, VCS
- Use PascalCase semantic member names: `RealPower`, `ReactivePower`, `AutoManualMode`, `BreakerStatus`
- Keep raw vendor naming only inside device UDTs
'''

pilot_slice_md = '''# Pilot Slice Naming Cleanup Applied

Pilot slice aligned to the recommended naming model:
- Genset semantic path: `TX3/PowerBlock_1/Node_1/QPAC_1/PowerGen/Gen_1`
- Relay semantic path: `TX3/PowerBlock_1/Node_1/QPAC_2/IEDs/700G_2`

Notes:
- The runtime Perspective cards currently point at these semantic object paths only when those tags exist in the gateway.
- The generated semantic tag package in `refactor-naming-v1/tags-semantic-v1.json` is the import-ready buildout for these paths and the rest of the currently exported TX3 equipment.
- Existing live cards were left operational; no additional card edits were required for the naming-only package output.
'''

readme = f'''# Semantic Naming Refactor Package v1

Generated outputs:
- `udts-semantic-v1.json` — import-ready semantic and adapter UDT definitions
- `tags-semantic-v1.json` — import-ready semantic tag hierarchy built from current exported 4-20 instances
- `2026-04-21-4-20-rename-matrix.md`
- `2026-04-21-4-20-udt-type-standard.md`
- `2026-04-21-4-20-pilot-slice-naming-cleanup.md`

Summary:
- Renamed adapter UDTs: {len(UDT_RENAMES)}
- Semantic UDTs added: 6
- Legacy instances mapped: {len(rename_rows)}
- QPAC groups generated: {len(qpac_map)}
- Feeder groups generated: {len(feeder_map)}
'''

(outdir / 'udts-semantic-v1.json').write_text(json.dumps({'name': '_types_', 'tagType': 'Folder', 'tags': rename_adapter_udts(source_udts)['tags'] + build_semantic_udts()['tags']}, indent=2) + '\n', encoding='utf-8')
(outdir / 'tags-semantic-v1.json').write_text(json.dumps(provider_root, indent=2) + '\n', encoding='utf-8')
(outdir / '2026-04-21-4-20-rename-matrix.md').write_text('\n'.join(rename_matrix_md) + '\n', encoding='utf-8')
(outdir / '2026-04-21-4-20-udt-type-standard.md').write_text(udt_standard_md, encoding='utf-8')
(outdir / '2026-04-21-4-20-pilot-slice-naming-cleanup.md').write_text(pilot_slice_md, encoding='utf-8')
(outdir / 'README.md').write_text(readme, encoding='utf-8')

print('wrote package to', outdir)
print('rename rows', len(rename_rows))
print('qpacs', len(qpac_map), 'feeders', len(feeder_map))
print('types', Counter(node['typeId'] for inst in legacy_instances for node in [inst['node']]))
