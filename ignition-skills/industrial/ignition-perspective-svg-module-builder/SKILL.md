---
name: ignition-perspective-svg-module-builder
description: Update the Ignition `isometric-perspective-components` module with one or more SVG assets, expose runtime-bindable Perspective props, run a fresh Gradle build, and report the resulting `.modl` path for gateway installation. Use when requests involve adding/editing module-backed custom Perspective SVG components (not normal Perspective view JSON editing).
---

# Ignition Perspective SVG Module Builder

## Overview

Use this skill to implement module-backed custom SVG Perspective components in:
`C:\Users\MiguelGrillo\Documents\cursor\ignition-custom-modules\isometric-perspective-components`

Use this skill instead of `ignition-perspective-screen-builder` when the request changes module code/build artifacts.

## Workflow

1. Read repo memory first.
- Try to read `C:\Users\MiguelGrillo\Documents\cursor\ignition-custom-modules\ORCHESTRATOR.md` before planning edits.
- If that file is missing, continue with `references/module-component-flow.md` and inspect the live repo structure directly instead of failing.
- Use `references/module-component-flow.md` for the exact file map and add-component checklist.

2. Intake SVG source assets.
- Confirm one or more SVG source file paths.
- Copy source files into:
  - `isometric-perspective-components/assets/source-svgs/`
  - `isometric-perspective-components/gateway/src/main/resources/mounted/svg/`

3. Classify each asset type.
- Treat as true SVG when the file contains shape/text markup (`<path>`, `<rect>`, `<text>`, etc.).
- Treat as raster-backed wrapper when SVG primarily embeds an image (`<image ... href="data:image/...">` or external image href).
- State realistic capabilities for each type before coding.

4. Implement component registration end-to-end.
- Add/update schema in `common/src/main/resources/`.
- Add a Java descriptor class in `common/src/main/java/.../comp/`.
- Register/unregister descriptor in:
  - `gateway/src/main/java/.../IsometricGatewayHook.java`
  - `designer/src/main/java/.../IsometricDesignerHook.java`
- Add client component class + meta registration in:
  - `gateway/src/main/resources/mounted/js/isometric-components.js`

5. Expose runtime-bindable props aggressively and deliberately.
- Expose as many practical bindable props as the asset supports, not just minimal text/color fields.
- Inspect the SVG for meaningful effect controls and expose explicit props for them when feasible.
- For glow-capable assets, expose glow controls such as intensity via blur/opacity and line/indicator glow tuning when those effects exist in the markup.
- Prefer explicit bindable props for user-facing text, state values, colors, and effect controls.
- Keep/merge generic override props (`colorOverrides`, `textOverrides`, global fill/stroke, opacity) as an advanced fallback.
- For raster-backed wrappers, avoid claiming full recolor support; expose feasible bindings (for example overlays, opacity, aspect ratio, style) and state limits explicitly.

6. Build and report install artifact.
- Run the helper script:
  - `scripts/build_isometric_modl.ps1`
- Or run directly in module root:
  - `.\gradlew.bat build --console=plain --no-daemon`
- Report the latest `.modl` absolute path and last-write timestamp.

7. Verify and communicate limits.
- Confirm build success.
- Call out manual validation expectations (Designer palette + runtime bindings).
- Explicitly list limitations for raster-backed assets.

## Orchestration Pattern

- Use orchestration-first execution when the task is substantial:
  - Delegate implementation to worker agents with owned files and explicit no-touch scope.
  - Review worker output and run local build verification before final response.
- Keep worker prompts explicit about the three registration layers and build verification.

## References

- Read `references/module-component-flow.md` for:
  - Critical file locations
  - Add-a-component checklist
  - Raster-wrapper handling policy

## Scripts

- Use `scripts/build_isometric_modl.ps1` to run a fresh module build and print:
  - `MODL_PATH`
  - `MODL_LAST_WRITE_UTC`
  - `MODL_SIZE_BYTES`
