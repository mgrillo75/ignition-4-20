---
name: ignition-perspective-script-audit
description: Scan filesystem-managed Ignition Perspective projects for bindings that use script transforms, summarize reuse patterns, and produce initial audit reports.
version: 1.0.0
author: Hermes Agent
tags: [ignition, perspective, audit, bindings, script-transforms, json]
platforms: [windows]
---

# Ignition Perspective Script Audit

Use this skill when a user wants an initial inventory of Perspective bindings that contain script transforms, especially in filesystem-managed Ignition projects on Windows.

This is for high-level discovery and triage, not for editing/fixing the scripts themselves.

## When to use

- "Find all bindings with scripts in this Ignition project"
- "Audit Perspective script transforms"
- "Give me an initial list of where script bindings are used"
- "Which views/components use expression bindings with script transforms?"

## Scope this skill covers

Primary target:
- Perspective `view.json` files with property bindings containing `binding.transforms[].type == "script"`

Useful adjacent signal:
- event/action script nodes where a JSON object has `type == "script"` and a `script` body

Not covered automatically unless you extend the scan:
- gateway event scripts
- session event scripts outside scanned view JSON
- project library scripts
- Vision resources
- named queries
- non-Perspective project scripting

## Proven workflow

1. Resolve the live project root first. On Miguel's machine this is typically under:
   `C:\Users\MiguelGrillo\Documents\Ignition8_3\data\projects\<project-name>`
2. Target:
   `com.inductiveautomation.perspective`
3. Recursively scan `view.json` files.
4. Parse each JSON file and walk the entire object tree.
5. For each dict node:
   - if it contains `binding.transforms` and any transform has `type == "script"`, record it as a binding-script hit.
   - if it contains `type == "script"` with a `script` field, record it separately as an event/action-script hit.
6. For each hit, capture:
   - full file path
   - relative view path
   - JSON path to the property
   - binding type (`expr`, `expr-struct`, `property`, etc.)
   - script transform index
   - compact code preview
   - stable code hash for deduplication
7. Summarize results by:
   - total views scanned
   - total binding script-transform instances
   - total views containing script-transform instances
   - unique script body count
   - top reused script hashes
   - top views by instance count
8. Emit both:
   - machine-readable JSON
   - human-readable Markdown report

## Reference implementation

A reusable Python scanner was created at:
`C:\Users\MiguelGrillo\.hermes\scripts\scan_ignition_script_bindings.py`

Example run:

```powershell
python C:\Users\MiguelGrillo\.hermes\scripts\scan_ignition_script_bindings.py "C:\Users\MiguelGrillo\Documents\Ignition8_3\data\projects\data-center-hmi" --output-json "C:\Users\MiguelGrillo\.hermes\tmp\data-center-hmi-script-bindings.json" --output-md "C:\Users\MiguelGrillo\.hermes\tmp\data-center-hmi-script-bindings.md"
```

## Output expectations

The Markdown report should include:
- counts summary
- views with script-binding instances
- per-view hit counts
- JSON property paths for each hit
- top script bodies by reuse

The JSON report should include:
- summary counts
- top code hashes
- all binding hits with code previews
- event-script hits captured separately

## Important lessons learned

- Simple text grep is too noisy; parse JSON and walk the structure instead.
- The most reliable discriminator for the target request is:
  `binding.transforms[].type == "script"`
- Keep event/action scripts separate from binding script transforms; users often mean only the latter.
- Deduplicate by normalized code hash, not just exact file location.
- A high-level first pass is most useful when it includes both:
  - where scripts live
  - how often the same script body is reused
- In large Perspective projects, a small number of script bodies may dominate the instance count; ranking by hash is valuable for cleanup planning.

## Good follow-up analyses

After the initial scan, optionally produce:
1. Deduplicated script body inventory
2. Top views by script-binding density
3. Categorization by intent, e.g.:
   - styling/state-color scripts
   - text conversion scripts
   - permission/visibility scripts
   - data/table-building scripts
4. "Best first cleanup targets" shortlist based on:
   - high reuse
   - suspicious logic
   - broken or fragile string matching

## Validation

Before reporting results:
- confirm the project root exists
- confirm `com.inductiveautomation.perspective` exists
- confirm JSON parsing succeeded for the scanned views
- explicitly state scan scope so the user knows this is an initial pass, not a full all-scripts project audit
