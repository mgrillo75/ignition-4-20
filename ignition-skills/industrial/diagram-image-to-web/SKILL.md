---
name: diagram-image-to-web
description: Convert medium/low-voltage electrical diagrams, wiring schematics, single-line diagrams, and P&ID images/PDFs into structured HTML/SVG/web front ends. Use when the task starts from a diagram image and ends in a browser-renderable interface or reusable web assets.
version: 1.0.0
author: Hermes Agent
tags: [industrial, electrical, pid, schematic, html, svg, web, ocr, vision]
platforms: [windows, linux]
---

# Diagram Image to Web

Use this skill when a user wants to turn diagram images or PDFs into browser-renderable outputs such as:
- static HTML/SVG recreations
- interactive web front ends
- process mimic screens
- single-line diagram web views
- symbol overlays, hotspots, and data-ready UI shells

## What this skill covers

- Medium-voltage and low-voltage one-lines, three-lines, panel schematics, and wiring diagrams
- P&ID pages and process sheets
- Raster images, screenshots, scans, and PDF pages
- Converting detected structure into HTML/CSS/SVG/Canvas front ends
- Producing reusable symbol/component maps, JSON scene graphs, and web-facing layouts

## Recommended output strategy

Choose the lightest output that satisfies the task:

1. SVG-first for linework-heavy diagrams and scalable fidelity.
2. HTML + inline SVG for clickable or data-bound screens.
3. HTML/CSS cards + SVG connectors for mimic/HMI-style displays.
4. JSON scene graph + renderer when the user wants repeatable generation across many diagrams.

## Repository/tooling notes

Read `references/repo-tooling-map.md` before using the repo at `C:\hermes\sld-agent`.

Short version:
- `CircuitSchematicImageInterpreter`: useful for wire/component/junction extraction in circuit-style diagrams.
- `PidDetector`: useful for P&ID component detection + OCR-oriented extraction from PDFs/images.
- `d3-hwschematic`: useful as a browser visualizer pattern built on D3 + ELK JSON.
- `netlistsvg`: useful for SVG-generation and ELK/netlist-to-diagram rendering patterns.

These repos are starting points, not end-to-end solutions for industrial web HMI conversion. Expect a hybrid workflow: vision/OCR + structured intermediate model + web renderer.

## Default workflow

1. Inspect the source asset.
   - Determine diagram type: SLD, wiring schematic, ladder-ish panel drawing, or P&ID.
   - Determine source quality: clean vector export, screenshot, scan, phone photo, or PDF.
   - Determine target fidelity: exact redraw, operator-friendly mimic, or semantic web component map.

2. Extract structure before styling.
   - Identify symbols/equipment.
   - Identify text labels and tag names.
   - Identify line topology, junctions, flow direction, and grouping.
   - Create an intermediate representation first; do not jump straight to HTML.

3. Build an intermediate model.
   Prefer a machine-readable artifact such as:
   - `diagram.json`
   - `symbols.json`
   - `connections.json`
   - `zones/layers`
   - optional `ocr.csv`

4. Pick the rendering architecture.
   - For exact line diagrams: SVG groups + paths + text.
   - For dashboards/mimics: HTML layout containers plus SVG overlay for pipes/bus/wires.
   - For expandable/navigable diagrams: JSON scene graph rendered by JS.

5. Implement with reusable symbol components.
   - Break repeated items into symbol functions/components.
   - Keep coordinates and labels data-driven where possible.
   - Separate geometry from styling.

6. Verify before claiming success.
   - Compare against the source image.
   - Check labels, counts, connections, orientation, and missing symbols.
   - Open the output in a browser and visually inspect overlap, clipping, and responsiveness.

## Task routing

### Use an exact redraw workflow when
- the user wants the web output to visually match the source diagram closely
- line routing and symbol placement matter
- the source is relatively clean and legible

### Use a semantic reconstruction workflow when
- the user cares more about equipment relationships than pixel-perfect reproduction
- the source is messy, partial, or low quality
- the final destination is an HMI/mimic screen rather than an archival redraw

### Use a hybrid workflow when
- the user wants fidelity for topology but cleaner UI components for equipment
- the diagram will become an interactive front end with states, tooltips, or tag bindings

## Preferred intermediate schema

A good minimum schema contains:
- `metadata`: title, source file, page number, units, diagram type
- `symbols`: id, type, label, bbox, confidence, attributes
- `texts`: id, text, bbox, role
- `connections`: from, to, path or endpoints, confidence
- `regions`: optional functional grouping
- `renderHints`: orientation, layers, style classes

## Quality gates

Before finishing, verify:
- all major equipment in the source exists in the output
- all major text labels/tag names are preserved or intentionally normalized
- all major line/path relationships are represented
- no invented breakers/valves/pumps/sensors appear without evidence
- generated HTML opens cleanly in a browser
- SVG scales without obvious distortion
- repeated symbols are componentized when practical

## Practical repo usage

- Use `CircuitSchematicImageInterpreter` to study circuit segmentation patterns, wire scans, junction recovery, and OCR-assisted component inference.
- Use `PidDetector` when the input is a P&ID PDF/image and you need object-detection-assisted extraction.
- Use `d3-hwschematic` as a reference for browser-side rendering architecture, zoom/pan, hierarchy, and ELK-based layout ideas.
- Use `netlistsvg` as a reference for generating SVG from structured intermediate data.

## Deliverables to prefer

When implementing, aim to leave behind some combination of:
- `index.html`
- `styles.css`
- `app.js` or `renderer.js`
- `diagram.json`
- `assets/symbols/*.svg`
- a comparison note documenting assumptions and unresolved ambiguities

## Clarifications that matter

Ask only for execution-critical choices such as:
- target output type: exact redraw, mimic screen, or data-driven front end
- whether unknown symbols should be placeholders or omitted
- whether responsiveness matters more than exact geometry
- whether the user wants pure static HTML or a framework-based app

## Bundled references

- `references/repo-tooling-map.md`
- `references/reconstruction-patterns.md`
- `references/quality-checklist.md`
- `templates/diagram.json`
- `templates/index.html`
- `templates/styles.css`
- `templates/app.js`

## Example use

When a user sends a schematic image and asks for a web front end:
1. classify diagram type and quality
2. extract a structured model
3. choose exact, semantic, or hybrid reconstruction
4. generate HTML/SVG assets
5. verify visually against the source

## Rules

1. Do not promise pixel-perfect conversion from poor scans; state assumptions in output notes.
2. Do not skip the intermediate structured model for non-trivial diagrams.
3. Prefer SVG for line geometry over absolute-positioned div spaghetti.
4. Preserve labels and equipment IDs whenever legible.
5. For industrial diagrams, prioritize topology correctness over decorative styling.
6. If the source is ambiguous, annotate unknowns rather than inventing certainty.
7. For P&ID and instrumentation-heavy drawings, do not collapse valves, pumps, instrument taps, and tag bubbles into generic rounded boxes unless the user explicitly asks for a simplified mimic view.
8. In second-pass redraws, restore ISA-style symbol fidelity first: vessel shape, valve geometry, pump/compressor symbols, instrument bubbles/taps, and label placement.
