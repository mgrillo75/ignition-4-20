# Template Patterns

Use these defaults unless the user asks otherwise.

## Faceplate View Pattern

- Root container: `ia.container.flex`
- Root props: `direction: column`
- Params:
  - `tagPath` (string, input)
  - `title` (string, input)
- UDT drop support (when applicable):
  - `props.dropConfig.udts[0].action = "path"`
  - `props.dropConfig.udts[0].param = "tagPath"`
  - `props.dropConfig.udts[0].type = "<Provider/TypeId>"`
- Layout skeleton:
  - `Header` (fixed basis, `shrink: 0`)
  - `Body` (`grow: 1`) with three columns:
    - left visual/critical column (`basis` fixed)
    - center process metrics column (`grow: 1`)
    - right controls/alarms column (`basis` fixed)
- Typical children:
  - Title label bound to `view.params.title`
  - Value component with indirect tag binding derived from `view.params.tagPath`
  - Command button (optional) for writeback actions
- Sizing:
  - Set `props.defaultSize` close to target popup/page size before adding components.
  - Prefer explicit `basis` on major cards and `grow` on filler regions.

## UDT Binding Pattern

- Base reference:
  - tag binding config `mode: "indirect"`
  - references object with one key, for example `base: "{view.params.tagPath}"`
- Derived member paths:
  - `"{base}/Level"`
  - `"{base}/Out1"`
- For embedded indicators, pass derived paths through expression bindings:
  - `"{view.params.tagPath} + \"/Level\""`

## Embedded Template Pattern

- Host component type: `ia.display.view`
- Required props:
  - `path`: template view path
  - `params`: object mapping host context to template params
- For repeated instances, duplicate the component and only change param values.

## Popup Pattern

- Popup view has compact default size and clear close control.
- Launcher button uses popup action config:
  - `id`: stable and unique in view scope
  - `type`: `open` or `toggle`
  - `viewPath`: explicit popup view path
  - `showCloseIcon`: true
  - `draggable`: true when operator repositioning is useful
- For large control faceplates, set view `defaultSize` to full working canvas and keep one `Body` container with `grow: 1` to avoid blank regions.

## Reuse Rules

1. Keep template internals generic; pass context through params.
2. Avoid hardcoded project tag paths in template roots.
3. Keep names semantic (`meta.name`) for maintainability.
4. Prefer stable built-in controls for first pass (for example simple button rows) before introducing more complex controls that may vary by gateway version.
