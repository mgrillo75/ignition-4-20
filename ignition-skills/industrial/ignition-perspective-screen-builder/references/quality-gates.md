# Quality Gates

Run this checklist before returning Ignition Perspective changes.

## JSON Integrity

1. Keep valid JSON only; no trailing commas.
2. For new or normalized components, keep `version: 0` on every component. In practice, strict validation also expects the root component to include `version: 0`; add it when creating or heavily normalizing a view.
3. Keep `meta.name` present and semantic on every component.
4. For new or normalized components, keep `position` present on every component. In practice, strict validation also expects the root component to include a `position` object (an empty object is acceptable for the root when using a coordinate container).
5. Preserve existing object and array structure when modifying existing views.

## Binding and Transform Rules

1. Use the simplest binding type that fits the requirement (tag, indirect tag, property, expression, query, history).
2. Prefer map, format, or expression transforms before script transforms.
3. Avoid `runScript()` inside expressions when built-in expression functions exist.

## Project-Safe Defaults

1. Prefer simulation-aware bindings only when the project already uses them or the user requests them.
2. Use null-safe numeric handling such as `coalesce(..., 0)` when bad quality or nulls are expected.
3. Prefer built-in Perspective components before inventing custom component structures.

## Validation Scope

Validate files created or modified in the current task. Do not run strict validation across untouched legacy view trees unless requested.

## Live Project Finalize Gate

For live filesystem-managed project edits that must be visible immediately:

1. Prefer the local Ignition Manager finalize workflow when available:
   - `POST http://127.0.0.1:5999/api/workflow/apply-and-restart`
   - `C:\Users\MiguelGrillo\Dropbox\ignition-workspace\scripts\apply_change_and_restart.ps1`
2. Verify the actual runtime service name and gateway port before invoking that workflow. On Miguel's current machine the live service is `Ignition` and the gateway HTTP port is `8088`.
3. Confirm the finalize step reported success, including gateway-ready polling.
4. Read back the edited `view.json` and related `resource.json` before returning success.
5. If forced to fall back to raw Windows service commands, report privilege failures explicitly rather than assuming the restart happened.

## Fast Validation Command

```powershell
$skill = Join-Path $env:HERMES_HOME 'skills\industrial\ignition-perspective-screen-builder\scripts\check_view_json.ps1'
powershell -ExecutionPolicy Bypass -File $skill -Path 'com.inductiveautomation.perspective/views/Screens/LoadBank/Overview/view.json'
```