# Reconstruction patterns

## Pattern A: Exact redraw
Use when source fidelity matters.

Artifacts:
- calibrated background/image dimensions
- SVG paths for wires, buses, pipes
- SVG groups for repeated symbols
- text labels placed from OCR or manual correction

Good for:
- single-line diagrams
- wiring schematics
- archival browser copies

## Pattern B: Semantic mimic
Use when operations/UI value matters more than exact drafting fidelity.

Artifacts:
- equipment cards/components
- SVG connectors and pipes
- classes for running/alarm/open/closed/energized states
- layout optimized for readability

Good for:
- operator front ends
- process screens
- responsive web views

## Pattern C: Hybrid redraw + components
Use when topology should resemble the source, but devices should be rendered with reusable web components.

Artifacts:
- source-informed coordinates for topology
- component library for valves, pumps, breakers, motors, CT/PT, transformers, instruments
- data-bound labels and CSS states

Good for:
- interactive electrical one-lines
- P&ID modernization
- screen families sharing symbol libraries

## Suggested implementation sequence

1. Build `diagram.json`.
2. Render lowest-risk static version first.
3. Verify geometry and labels.
4. Add interactivity only after topology is correct.
5. Split reusable symbols into functions/components.
