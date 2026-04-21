# Task Routing

Choose the smallest safe path that satisfies the request.

## Create or Revise Runtime Tag(s)

1. Identify provider root under `tag-definition/<provider>/...`.
2. Add or update the target `udts.json`.
3. Validate with `check_tag_resources.ps1`.

## Revise Existing Runtime Tag(s)

1. Locate exact `udts.json` containing the tag.
2. Modify only requested properties (path, data type, alarms, history, etc.).
3. Validate and preserve neighboring tag objects.

## Create or Revise UDT Type Definition

1. Identify destination tree under `tag-type-definition/<provider>/...`.
2. Add or update the `tagType: "UdtType"` row in `udts.json`.
3. For parameterized members, use `{ParamName}` tokens and keep parameter keys stable.
4. For nested UDT members (`tagType: "UdtInstance"`), keep `typeId` valid and pass parent parameters explicitly.
5. Validate and check `typeId`/member consistency.

## Create or Revise UDT Instances

1. Identify destination tree under `tag-definition/<provider>/...`.
2. Add or update `tagType: "UdtInstance"` rows in `udts.json`.
3. Keep deterministic naming for multi-instance patterns (for example `kq_instance_1`, `kq_instance_2`).
4. If parameters are required, set explicit `parameters.<name>.value` overrides.
5. Validate type resolution against `tag-type-definition/<provider>`.

## Handle Inheritance and Nesting Changes

1. If request targets inherited behavior, update parent UDT definition unless override-only change is requested.
2. In child UDT definitions, change only overridden member properties and do not add brand-new members.
3. For nested UDTs, map parent parameters into child parameters (pass-through) before adding instance rows.
4. Revalidate all affected `udts.json` files after edits.

## Provider Policy Changes

1. Edit only `tag-provider/<provider>/config.json`.
2. Do not mix provider changes with tag payload edits unless requested.

## Completion

After file edits, run the Ignition Manager **Apply + Restart** workflow so changes are active.
