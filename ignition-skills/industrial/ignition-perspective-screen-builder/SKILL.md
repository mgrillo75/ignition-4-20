---
name: ignition-perspective-screen-builder
description: Build and modify Ignition Perspective views, pages, styles, bindings, symbols, charts, alarms, and navigation resources in filesystem-managed projects. Use when tasks involve creating or editing Perspective view.json files or related Perspective resources.
version: 1.0.1
author: Hermes Agent
tags: [ignition, perspective, scada, hmi, json, bindings, views]
platforms: [windows]
---

# Ignition Perspective Screen Builder

Use this skill for Ignition Perspective screen work in filesystem-managed projects.

Confirmed compatible with Ignition 8.3 filesystem-managed projects, including gateway roots like `C:\Users\MiguelGrillo\Documents\ignition8_3` and project roots under `data\projects\<project-name>`.

## What this skill covers

- Create or modify `view.json` resources
- Add or revise bindings, transforms, scripts, symbols, charts, alarms, pages, and docks
- Preserve Perspective component integrity (`version`, `meta.name`, `position`)
- Apply project-safe editing and validation workflow before returning changes

## Workflow

1. Read `references/project-paths.md` to map Ignition resource paths.
2. Confirm the gateway root and Ignition version before editing when the install path may be custom (common for Ignition 8.3). Do not assume `Program Files`; verify the actual root, then resolve the project under `data\projects\<project-name>`.
3. Read `references/task-routing.md` to choose the minimum safe path for the request.
4. If the repository contains project-specific Ignition docs (for example `.cursor/`, `docs/`, or project notes), use them as additional context. Do not block on them if they are absent.
5. Clarify only the missing execution-critical inputs: target view/page/style path, reusable vs one-off intent, source tags, and write-command tags.
6. Edit only the requested Perspective resources.
7. Validate with `references/quality-gates.md` and `scripts/check_view_json.ps1`. Use default parse/meta validation for legacy view trees; add `-Strict` when creating or fully normalizing views/components to enforce `version` and `position` on every component.
8. When you create or edit filesystem-managed Perspective resources, recompute `resource.json.attributes.lastModificationSignature` after updating the resource files and `lastModification` timestamp. Ignition 8.3 does not use a raw file hash; it hashes the resource metadata plus sorted file digests and sorted attributes excluding `lastModificationSignature`. Use the helper script `C:\Users\MiguelGrillo\Documents\github-repos\hermes-agent\ignition_last_mod_sig.py <resource-dir> --write` when it is available on Miguel's machine.
9. If the task updates a live filesystem-managed project and the goal is for the running gateway to pick up the change immediately, prefer the local Ignition Manager workflow when it is available on this machine. First try the local API/UI backend at `http://127.0.0.1:5999/api/workflow/apply-and-restart`; if that UI is not running, invoke `C:\Users\MiguelGrillo\Dropbox\ignition-workspace\scripts\apply_change_and_restart.ps1` directly, because that workflow already performs validation, backup, robust restart, and gateway-ready polling.
10. Before using the manager workflow, verify the actual live gateway service name and HTTP port on this machine instead of trusting stale defaults. Check `C:\Users\MiguelGrillo\Documents\Ignition8_3\data\gateway.xml`, `wrapper.log`, or the live Windows service list. On Miguel's current machine the active Ignition 8.3 runtime is service `Ignition` on HTTP `8088` and SSL `8060`, so defaults like `Ignition83` and `http://localhost:8188` are wrong.
11. The manager finalize script can still report a false timeout on this machine even when the gateway is actually back. After finalize, independently verify `http://localhost:8088/StatusPing` and the Windows service state before concluding restart failed.
12. If the manager workflow is unavailable, fall back to a direct service restart command such as `powershell.exe -NoProfile -Command "Restart-Service -Name Ignition -Force"`, but expect this to fail when Hermes lacks Windows service-control privileges.
13. Read back the touched files and confirm the restart result before calling the task complete.
14. Recommend Ignition Designer or gateway verification for visual/runtime confirmation after file edits.

## Bundled references

- `references/project-paths.md`
- `references/task-routing.md`
- `references/quality-gates.md`

## Bundled scripts

- `scripts/new_view_skeleton.ps1`
- `scripts/check_view_json.ps1`

## Example commands

```powershell
$skill = Join-Path $env:HERMES_HOME 'skills\industrial\ignition-perspective-screen-builder\scripts\new_view_skeleton.ps1'
powershell -ExecutionPolicy Bypass -File $skill -ViewPath 'Screens/AreaA/Overview' -Container flex
```

```powershell
$skill = Join-Path $env:HERMES_HOME 'skills\industrial\ignition-perspective-screen-builder\scripts\check_view_json.ps1'
powershell -ExecutionPolicy Bypass -File $skill -Path 'com.inductiveautomation.perspective/views/Screens/AreaA/Overview/view.json'
```

## Rules

1. Prefer built-in Perspective components before inventing custom structures.
2. Keep `version: 0`, semantic `meta.name`, and a `position` object on every component.
3. Preserve surrounding structure when modifying existing views.
4. Before any write, create a timestamped or task-labeled backup of each `view.json` you touch so edits can be reverted quickly.
5. For live filesystem-managed projects, finish by restarting the Ignition service when immediate gateway pickup is required and permissions allow. Default command on Windows: `powershell.exe -NoProfile -Command "Restart-Service -Name Ignition -Force"`.
6. Keep bindings as simple as possible before escalating to script transforms.
7. Validate only files touched in the current task unless the user asks for a broader sweep.
8. When a request implies broad coverage across an entire Ignition tag subtree (for example “everything under SEL”), inventory the tag-definition JSON first and derive the exact address/tag surface before editing the Perspective view or simulator device. Save the inventory to a temporary JSON/Markdown report so the scope is auditable.
9. Do not render thousands of live controls into one giant Perspective view by default. If broad coverage exceeds a few hundred controls, prefer a lighter architecture such as per-group subviews, filtered sections, paging, or selector-driven detail views. A single generated `view.json` with thousands of controls can become multi-megabyte and materially degrade Designer/session usability.
10. For very large simulator or audit screens, prefer a lightweight landing page plus split per-group or per-area views/routes. The landing page should not be text-only: include a compact set of high-value quick controls at the top (for example the main start/stop bits, key status bits, and a few primary numeric setpoints) so operators can immediately simulate common cases without navigating away.
11. When you add or change Perspective routes, treat `page-config/config.json` and `page-config/resource.json` as touched resources too: back them up, update them, and refresh their `lastModificationSignature` just like any edited view resource.
12. When the manager restart workflow falsely reports a timeout, independently verify success with the Windows service state and `http://localhost:8088/StatusPing` before concluding the change failed.
13. On Windows-backed Ignition projects, avoid Perspective resource folder names that match reserved device names such as `AUX`. A generated view folder named `AUX` caused Ignition Designer startup failure with `NameInvalidException`. Use a filesystem-safe resource name like `AUX_Group` and keep the public page route/title as `/Simulator/AUX` if needed.
14. If you temporarily generate a full-surface audit/control page to prove coverage, present it as an initial pass and recommend a second pass to refactor into a performant structure.
15. For operator-facing simulator screens in complex power or utility projects, organize the main overview by operational assets (for example generators, source couplers, breaker banks, bus health) rather than raw tag folders or long tag lists. Use the tag inventory to identify the high-value fields per asset (status, breaker state, power, frequency, runtime, reserve, setpoint, writable setpoint tags) and keep the detailed per-folder routes for engineering depth.
16. When a user references sample/demo Perspective component paths that do not exist literally in the local filesystem, search the local sample project for equivalent component demo views (for example Multi State Button, Gauge, Progress, or symbol widgets) and use those patterns instead of blocking on the exact path string.
ators, source couplers, breaker banks, bus health) rather than raw tag folders or long tag lists. Use the tag inventory to identify the high-value fields per asset (status, breaker state, power, frequency, runtime, reserve, setpoint, writable setpoint tags) and keep the detailed per-folder routes for engineering depth.
16. When a user references sample/demo Perspective component paths that do not exist literally in the local filesystem, search the local sample project for equivalent component demo views (for example Multi State Button, Gauge, Progress, or symbol widgets) and use those patterns instead of blocking on the exact path string.
