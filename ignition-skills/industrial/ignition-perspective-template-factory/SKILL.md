---
name: ignition-perspective-template-factory
description: Build reusable Ignition Perspective faceplates, template views, popup views, embedded-view layouts, and UDT-aware tagPath-driven screens with safe parameter contracts and drag-drop UDT support.
version: 1.0.0
author: Hermes Agent
tags: [ignition, perspective, templates, faceplates, udt, popup]
platforms: [windows]
---

# Ignition Perspective Template Factory

Use this skill for reusable Perspective views and faceplates, especially when a screen should be parameterized around a UDT instance path.

## What this skill covers

- Reusable faceplate/template view creation
- `params.tagPath` and other input parameter contracts
- `props.dropConfig.udts` setup for Designer drag-drop UDT workflows
- Embedded view wiring, popup launch actions, and page-route hookup
- Validation of reusable view JSON before return

## Workflow

1. Read `references/template-patterns.md`.
2. Read `references/udt-faceplate-patterns.md` when the view is driven by a UDT instance path.
3. Read `references/task-routing.md` for the request type.
4. Decide whether the target is a reusable template/faceplate, embedded usage, popup view, or page wiring task.
5. Build or update the view resources.
6. Validate with `references/quality-gates.md` and `scripts/check_template_view.ps1`.
7. Recommend a visual sanity pass in Ignition Designer plus Apply + Restart after direct file edits.

## Bundled references

- `references/template-patterns.md`
- `references/udt-faceplate-patterns.md`
- `references/task-routing.md`
- `references/quality-gates.md`

## Bundled scripts

- `scripts/new_faceplate_view.ps1`
- `scripts/check_template_view.ps1`

## Example commands

```powershell
$skill = Join-Path $env:HERMES_HOME 'skills\industrial\ignition-perspective-template-factory\scripts\new_faceplate_view.ps1'
powershell -ExecutionPolicy Bypass -File $skill -ProjectViewsRoot 'com.inductiveautomation.perspective/views' -ViewPath 'Templates/PumpFaceplate' -UdtType 'Provider/Pump'
```

```powershell
$skill = Join-Path $env:HERMES_HOME 'skills\industrial\ignition-perspective-template-factory\scripts\check_template_view.ps1'
powershell -ExecutionPolicy Bypass -File $skill -Path 'com.inductiveautomation.perspective/views/Templates/PumpFaceplate/view.json' -RequireTagPathParam -RequireDropConfig
```

## Rules

1. Reusable views expose required params explicitly.
2. Avoid hardcoded runtime instance paths in reusable templates.
3. Keep host/template wiring explicit and deterministic.
4. Validate both the reusable view and any edited host/page resources.
5. Use stable popup ids and explicit view paths.
6. If the user wants a reusable simulator/operator card that must both reflect live Ignition tags and issue real commands, prefer a native Perspective template over a Web Dev/iframe-hosted React card. A Web Dev card may render visually, but its buttons are only local unless you separately build an API/tag-write bridge. For live simulator work, a Perspective template is usually the correct first implementation.
7. For reusable simulator cards, expose at least `params.gensetNumber` and `params.tagProvider` (or equivalent device-identifying params), then build dynamic tag expressions like `[default]SEL/GCS/.../GCS_G{N}_Start_CMD` from those params instead of hardcoding G1 paths.
8. For command buttons that drive simulator booleans, use explicit gateway-scope event scripts with `system.tag.writeBlocking`. For momentary commands (Start/Stop/Breaker Open/Breaker Close), pulse the command true then false asynchronously using `system.util.invokeAsynchronous` plus a short sleep. For toggle-style enables (AGC/VCS), read current value and write the inverse.
