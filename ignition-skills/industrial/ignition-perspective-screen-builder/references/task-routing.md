# Task Routing

Choose the smallest safe path that satisfies the request.

## Create New View

1. Confirm target view path.
2. Use `scripts/new_view_skeleton.ps1` when a clean starter view is faster than hand-authoring.
3. Choose the simplest root container that fits the requirement.
4. Add components incrementally and validate the resulting `view.json`.

## Modify Existing View

1. Locate the exact `view.json`.
2. Preserve existing layout and component structure unless refactoring is explicitly requested.
3. Change only the requested components, bindings, scripts, or styling.
4. Validate only the touched view files.
5. When editing a live filesystem-managed project and the user expects the running gateway to reflect the change immediately, prefer the local Ignition Manager finalize workflow if available:
   - API: `POST http://127.0.0.1:5999/api/workflow/apply-and-restart`
   - Script: `C:\Users\MiguelGrillo\Dropbox\ignition-workspace\scripts\apply_change_and_restart.ps1`
6. Before using that finalize workflow, verify the actual service name and gateway HTTP port from `gateway.xml`, `wrapper.log`, or the live Windows service list. On Miguel's current machine the live service is `Ignition` on `http://localhost:8088`, not `Ignition83` / `8188`.
7. Only fall back to raw `Restart-Service` or `sc` service commands when the manager workflow is unavailable, and report privilege failures clearly.
8. Read back the edited files and confirm the restart result before reporting success.

## Add or Change Binding

1. Identify the target property and source path.
2. Prefer property, tag, indirect tag, expression, query, or history bindings before scripts.
3. Keep parameter and transform logic minimal and readable.
4. Recheck null handling and quality behavior after edits.

## Add Toggle, Selector, or Command Control

1. Confirm the readback path and write target.
2. Use built-in controls first.
3. Keep action logic explicit and avoid hidden side effects.
4. Validate any button state, enablement, and feedback bindings.

## Add Scripts or Event Handlers

1. Verify the task cannot be solved with built-in bindings or transforms.
2. Keep script scope narrow and tied to the specific component or view.
3. Preserve existing event structure.
4. Flag any gateway/designer verification the user should perform.

## Add Symbols, Charts, Alarms, Navigation, or Style Classes

1. Edit only the relevant Perspective resource file(s).
2. Prefer stable built-in Perspective components and configuration structures.
3. Keep naming semantic and route-safe.
4. Validate changed views plus any directly edited page/style resources.

## Escalation Rule

If the task spans multiple Perspective domains at once, explicitly verify assumptions before broad edits.