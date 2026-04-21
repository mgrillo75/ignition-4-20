# Tag/UDT Project Paths (Ignition 8.3)

Use these filesystem locations for gateway tag resources.

## Provider Config

- `data/config/resources/core/ignition/tag-provider/<provider>/config.json`
- `data/config/resources/core/ignition/tag-provider/<provider>/resource.json`

## Runtime Tag Tree and UDT Instances

- Root: `data/config/resources/core/ignition/tag-definition/<provider>/`
- Folder metadata: `**/unary-resource.json`
- Payloads: `**/udts.json`
- Contents include folders, atomic tags, and `tagType: "UdtInstance"` rows.

## UDT Type Definitions

- Root: `data/config/resources/core/ignition/tag-type-definition/<provider>/`
- Folder metadata: `**/unary-resource.json`
- Type payloads: `**/udts.json`
- Contents include `tagType: "UdtType"` rows and nested members.

## Typical Layout Example

- `<Ignition data dir>/data/config/resources/core/ignition/tag-provider/default/config.json`
- `<Ignition data dir>/data/config/resources/core/ignition/tag-definition/default/`
- `<Ignition data dir>/data/config/resources/core/ignition/tag-type-definition/default/`

## Notes

- `udts.json` files are JSON arrays; preserve ordering unless the task asks to reorder.
- Tag resources are gateway-level resources, not stored inside project folders.
- If you edit `tag-definition/<provider>`, validate against the sibling `tag-type-definition/<provider>` so `typeId` references remain valid.
