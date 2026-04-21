# Repo tooling map: C:\hermes\sld-agent

This repo collection is useful as a toolkit survey, not as a single turnkey pipeline.

## 1) CircuitSchematicImageInterpreter
Purpose:
- Segment circuit images into components, wires, and junctions
- OCR-assisted component identification
- Build graph-like understanding of schematic topology

Best use inside this skill:
- Medium/low-voltage schematics with clear linework
- Studying extraction stages: wire scan, object detection, junction detection
- Producing intermediate symbol/connection JSON before rendering

Cautions:
- Oriented toward circuit analysis rather than industrial HMI/front-end generation
- Best for clean diagrams; noisy plant scans may still require manual correction

## 2) PidDetector
Purpose:
- Detect P&ID symbols from PDFs/images using a YOLO-style detector
- OCR text and export extracted results

Best use inside this skill:
- P&ID sheets and PDF page processing
- Building a symbol inventory with approximate bounding boxes and labels
- Feeding a process-diagram reconstruction pipeline

Cautions:
- Appears to depend on trained weights and OCR/runtime setup
- Detection coverage depends on model quality and class training
- Better for extraction than final web rendering

## 3) d3-hwschematic
Purpose:
- Render structured schematic/hardware graphs in the browser
- D3 + ELK based interactive visualization

Best use inside this skill:
- Reference implementation for browser-side rendering architecture
- Zoom/pan, hierarchy, graph layout, edge routing patterns
- Rendering from structured JSON when exact source coordinates are not required

Cautions:
- Domain is hardware schematic visualization, not directly industrial one-lines/P&IDs
- Input format is ELK JSON; conversion from extracted diagram model is still required

## 4) netlistsvg
Purpose:
- Render SVG schematics from structured netlist-like JSON
- Useful examples of symbol composition and SVG generation

Best use inside this skill:
- Reference for converting structured diagram data into SVG output
- Thinking in symbol libraries + connections rather than raw image overlays

Cautions:
- More digital/netlist-centric than plant/electrical field drawings
- Not a direct image-to-web converter

## Suggested hybrid pipeline

For electrical diagrams:
1. Use vision/OCR or circuit extraction to identify symbols, text, and connections.
2. Normalize into `diagram.json`.
3. Render with SVG-first output, optionally borrowing graph/layout ideas from d3-hwschematic or netlistsvg.

For P&IDs:
1. Use detector + OCR to inventory equipment/instruments/labels.
2. Normalize into process objects, lines, and text layers.
3. Rebuild as HTML + SVG mimic or as a structured interactive process canvas.
