# Isometric Module Component Flow

## Canonical Paths

- Workspace root:
  - `C:\Users\MiguelGrillo\Documents\cursor\ignition-custom-modules`
- Module root:
  - `C:\Users\MiguelGrillo\Documents\cursor\ignition-custom-modules\isometric-perspective-components`
- Repo memory:
  - `C:\Users\MiguelGrillo\Documents\cursor\ignition-custom-modules\ORCHESTRATOR.md`

## Critical Module Files

- Module metadata/build:
  - `isometric-perspective-components/build.gradle.kts`
  - `isometric-perspective-components/settings.gradle.kts`
- Shared constants:
  - `isometric-perspective-components/common/src/main/java/com/miguelgrillo/ignition/isometric/common/IsometricComponents.java`
- Component descriptors:
  - `isometric-perspective-components/common/src/main/java/com/miguelgrillo/ignition/isometric/common/comp/*.java`
- Property schemas:
  - `isometric-perspective-components/common/src/main/resources/*.props.json`
- Gateway registration:
  - `isometric-perspective-components/gateway/src/main/java/com/miguelgrillo/ignition/isometric/gateway/IsometricGatewayHook.java`
- Designer registration:
  - `isometric-perspective-components/designer/src/main/java/com/miguelgrillo/ignition/isometric/designer/IsometricDesignerHook.java`
- Browser runtime + ComponentMeta:
  - `isometric-perspective-components/gateway/src/main/resources/mounted/js/isometric-components.js`
- Mounted SVG assets:
  - `isometric-perspective-components/gateway/src/main/resources/mounted/svg/`
- Source SVG mirror:
  - `isometric-perspective-components/assets/source-svgs/`

## Add-a-Component Checklist

1. Copy source SVG into `assets/source-svgs/` and `mounted/svg/`.
2. Add a schema file for bindable props (`common/src/main/resources`).
3. Add a Java descriptor class (`common/.../comp`) with:
- component ID
- schema reference
- palette entry
- default meta name
4. Register/unregister descriptor in gateway hook.
5. Register/unregister descriptor in designer hook.
6. Add/update browser class and `ComponentMeta` registration in `isometric-components.js`.
7. Ensure default size and props reducer are coherent.
8. Run fresh build and report `.modl` path.

## Asset Classification Rules

- Treat as true SVG when markup is vector/text based (`<path>`, `<rect>`, `<circle>`, `<text>`, etc.).
- Treat as raster-backed wrapper when SVG mostly wraps `<image>` with data URI or external raster links.

## Runtime Binding Policy

- For true SVG assets:
- Expose as many practical explicit bindable props as possible for the asset.
- Include key texts, state values, core colors, and meaningful visual effects.
- Inspect markup for effects (filters, glow paths, stroke highlights, indicator lamps) and expose explicit controls when feasible.
- For glow-capable visuals, expose glow intensity controls via blur/opacity and line or indicator glow controls where those effects exist.
- Keep generic override props available for advanced use.

- For raster-backed wrappers:
- Do not claim full internal recolor/text replacement support.
- Expose feasible bindings such as:
  - overlays (title/value/status text)
  - opacity
  - preserveAspectRatio
  - style/class bindings

## Build and Artifact

- Build command:
  - `.\gradlew.bat build --console=plain --no-daemon`
- Typical artifact:
  - `isometric-perspective-components/build/IsometricPerspectiveComponents.unsigned.modl`
- Also inspect:
  - `isometric-perspective-components/build/buildResult.json`
