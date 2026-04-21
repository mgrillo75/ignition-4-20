# Quality Gates

## JSON and Component Integrity

1. JSON parses successfully.
2. Every component has:
   - `version: 0`
   - `meta.name`
   - `position`
3. Root container is present and valid.
4. No "Component Error" placeholders in Designer preview for newly added controls.
5. For UDT templates, `params.tagPath` exists and is configured as input.
6. For UDT templates with drag-drop support, `props.dropConfig.udts` is valid.

## Layout and Sizing

1. Faceplate root has explicit `defaultSize`.
2. Major regions use deterministic sizing:
   - Header fixed basis
   - Body grow=1
   - Left/center/right columns sized by basis/grow intent
3. Avoid large blank zones caused by missing `grow` on primary body containers.

## Reusability

1. Reusable views expose required params.
2. Host views pass params explicitly to embedded/popups.
3. Avoid hardcoded runtime assumptions in template views.
4. For reusable UDT templates, avoid hardcoded provider paths in child bindings.

## Navigation and Popup

1. Popup action includes stable `id` and correct `viewPath`.
2. Page config changes are minimal and route-safe.
3. Popup launch size/behavior matches faceplate intent (large faceplates should not be configured as tiny popups).

## Activation

Run Ignition Manager **Apply + Restart** after direct file edits.
