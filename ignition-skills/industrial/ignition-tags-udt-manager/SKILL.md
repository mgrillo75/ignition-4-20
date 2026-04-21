---
name: ignition-tags-udt-manager
description: Create, edit, and validate Ignition tag-provider resources, runtime tag trees, UDT definitions, UDT instances, parameterized tag bindings, inheritance patterns, and nested UDT structures in filesystem-managed gateways.
version: 1.0.0
author: Hermes Agent
tags: [ignition, tags, udt, scada, gateway, json]
platforms: [windows]
---

# Ignition Tags and UDT Manager

Use this skill for gateway tag-provider, tag-definition, and tag-type-definition work in Ignition 8.3 style resource trees.

## What this skill covers

- Provider config updates
- Runtime tags and UDT instance rows
- UDT type definitions and nested members
- Parameter token patterns, inheritance-safe edits, and deterministic multi-instance layouts
- Validation of edited provider resources before returning changes

## Workflow

1. Read `references/project-paths.md` to locate provider roots.
2. Read `references/udt-patterns.md` for parameter, nesting, inheritance, and path rules.
3. Read `references/task-routing.md` to choose the matching procedure.
4. Confirm rollback or export strategy before broad edits.
5. Edit only the requested provider/resource scope.
6. Validate with `references/quality-gates.md` and `scripts/check_tag_resources.ps1`.
7. Remind the user to run Ignition Manager Apply + Restart after direct file edits.

## Bundled references

- `references/project-paths.md`
- `references/udt-patterns.md`
- `references/task-routing.md`
- `references/quality-gates.md`

## Bundled scripts

- `scripts/check_tag_resources.ps1`

## Example command

```powershell
$skill = Join-Path $env:HERMES_HOME 'skills\industrial\ignition-tags-udt-manager\scripts\check_tag_resources.ps1'
powershell -ExecutionPolicy Bypass -File $skill -ProviderPath 'data/config/resources/core/ignition/tag-definition/default' -DefinitionRoots 'data/config/resources/core/ignition/tag-type-definition/default'
```

## Rules

1. Never modify unrelated providers.
2. Preserve existing order and structure unless the task explicitly requests refactoring.
3. Keep `udts.json` payloads as arrays.
4. Use deterministic names and stable `typeId` references.
5. Prefer parent-definition edits for inherited behavior unless the user requested an override-only change.
