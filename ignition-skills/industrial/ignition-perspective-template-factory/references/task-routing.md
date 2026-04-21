# Task Routing

## Create Reusable Faceplate

1. Scaffold with `new_faceplate_view.ps1`.
2. If the template is UDT-driven, pass `-UdtType "<Provider/Type>"` so `dropConfig.udts` is generated.
3. Keep required params (`tagPath`, `title`) as input params with `paramDirection: input`.
4. Build sizing skeleton first (Header fixed + Body grow + 3 columns).
5. Add indirect tag bindings that reference `view.params.tagPath`.
6. Validate with `check_template_view.ps1` (use `-RequireTagPathParam` and `-RequireDropConfig` for UDT views).
7. Run a visual sanity pass in Designer to catch any component errors and sizing drift.

## Add Embedded Template Usage

1. Locate host view.
2. Add `ia.display.view` component with `props.path` to template.
3. Map `props.params.tagPath` to a concrete provider path, for example `[udtfpexample]kq_instance_1`.
4. Pass additional params explicitly (`title`, display units, limits).
5. Validate host + template views.

## Add Multi-Instance Host Layout

1. Add repeated `ia.display.view` components pointing to the same reusable faceplate path.
2. Vary only `props.params` values per instance (especially `tagPath`).
3. Keep layout deterministic (explicit `position` in coord views or stable `basis/grow` in flex views).
4. Validate and visually check alignment/spacing after duplication.

## Add Popup Template

1. Create popup view resource.
2. Add launch component action (`type: popup`, `open`/`toggle`).
3. Use stable popup `id` and explicit `viewPath`.
4. Validate both views.

## Wire Page URL and Primary View

1. Edit `page-config/config.json`.
2. Ensure target page route resolves to intended view.
3. Keep shared docks untouched unless requested.
