# UDT Faceplate Patterns

Use this reference when wiring reusable Perspective views to UDT instance paths.

## Proven Reusable Pattern

- Reusable faceplate view path follows a stable template location such as `Templates/Equipment/Faceplate`
- Required view param: `params.tagPath`
- Host views embed the same faceplate multiple times with different concrete tag paths

## Faceplate Contract

- Define params in `view.json`:
  - `tagPath` (string)
  - additional display config params as needed (`title`, limits, units, thresholds, and so on)
- Define `propConfig` entries:
  - `params.tagPath.paramDirection = "input"`
  - `params.tagPath.persistent = true`
- For drag-and-drop UDT assignment in Designer:
  - set `props.dropConfig.udts` with:
    - `action: "path"`
    - `param: "tagPath"`
    - `type: "<Provider/TypeId>"`

## Binding Conventions

- Use indirect tag bindings from `view.params.tagPath`:
  - references object:
    - `tagPath: "{view.params.tagPath}"`
  - target path examples:
    - `"{tagPath}/Level"`
    - `"{tagPath}/Out1"`
    - `"{tagPath}/DeviceInfo/Serial"`
- Use expression bindings for derived embedded-view param paths:
  - `{view.params.tagPath} + "/Level"`

## Host View Conventions

- Host components use `type: "ia.display.view"`.
- Pass params explicitly per instance:
  - `props.path`: reusable faceplate path
  - `props.params.tagPath`: concrete provider path
- Keep instance layout deterministic with explicit coordinate sizes or stable flex basis/grow settings.
