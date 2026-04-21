# Quality checklist

Use this before saying the diagram conversion is complete.

## Source coverage
- Major buses, feeders, pipes, loops, or signal paths accounted for
- Major equipment items accounted for
- Labels and tag names preserved where legible
- Unknown or unreadable items explicitly flagged

## Topology correctness
- Connections terminate at the correct symbols
- Junctions/tees/splits are represented
- Directional elements are not reversed
- Repeated branches are consistently structured

## Web output quality
- HTML opens without console errors
- SVG scales and zooms cleanly
- Text is readable at normal browser zoom
- No major overlap, clipping, or accidental misalignment
- CSS class names are meaningful and reusable

## Handoff quality
- There is a structured source model or at least documented assumptions
- Repeated symbols are componentized where practical
- Ambiguities are listed for future refinement
