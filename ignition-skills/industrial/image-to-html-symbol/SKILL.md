---
name: image-to-html-symbol
description: Convert a reference image or existing symbol HTML into geometry-faithful HTML/SVG symbol output, especially when matching an existing exemplar style, preserving branched single-line topology, or exporting transparent SVG without changing geometry.
version: 2.0.0
author: Hermes Agent
tags: [industrial, symbol, schematic, single-line, html, svg, geometry, reconstruction]
platforms: [windows, linux]
---

# Image to HTML Symbol

Use this skill when a task is narrower than full diagram reconstruction and the goal is to build or convert a compact symbol, panel, or branched schematic fragment while preserving exact geometry.

Typical triggers:
- turn a reference image into a self-contained HTML/SVG electrical symbol
- match the style of a nearby exemplar without changing source topology
- rebuild a branched single-line fragment faithfully
- convert an existing HTML symbol into transparent-background SVG
- preserve exact geometry, stroke treatment, spacing, and framing

## Scope

This skill is for symbol-level or panel-level reconstruction, not full end-to-end semantic diagram extraction. When the task is a broader diagram-to-web conversion with intermediate models, use `diagram-image-to-web` instead.

Use this skill when geometry fidelity is the primary requirement.

## Core principles

1. Treat the source asset as the authority for geometry and topology.
2. Treat the exemplar as the authority for style tokens, color system, typography, panel chrome, and UI language.
3. If the source is an existing HTML symbol file, read it first and preserve its rendered geometry, stroke sizes, spacing, and framing instead of redrawing it from scratch.
4. Preserve the source silhouette unless the user explicitly asks for balancing, centering, or restyling.
5. Keep the result self-contained with inline CSS and, when precision matters, inline SVG.
6. Prefer one SVG for contiguous symbol runs that must stay aligned under zoom instead of stacking separate divs or line elements.

## Default workflow

1. Identify the source asset before drawing anything.
   - reference image
   - existing HTML symbol file
   - or both
   - plus the style exemplar, if any

2. Decide whether the job is:
   - image -> HTML/SVG symbol recreation
   - HTML -> SVG conversion
   - style-match reconstruction against an exemplar

3. Build a geometry map before coding.
   Capture at minimum:
   - trunk path
   - takeoff origin
   - takeoff height
   - symbol centers
   - node inventory
   - node heights
   - dashed versus solid segments
   - terminal positions
   - relative x/y offsets
   - generator connection target when present

4. For branched diagrams, write a tiny anchor table before coding.
   Include at minimum:
   - trunk entry
   - branch takeoff
   - each breaker box
   - each node/terminal
   - generator connection target

5. Implement the output.
   - Use inline SVG when zoom-stable electrical runs matter.
   - Keep styles local and easy to edit.
   - Preserve source spacing, line placement, stroke widths, framing, and scale.

6. Re-render and compare against the reference until topology, proportions, and stroke treatment match.

## HTML-to-SVG workflow

For HTML-to-SVG work, treat it as two steps:
1. create an SVG that matches the original HTML presentation
2. create the final SVG by preserving identical geometry and styling while removing only the background or panel fill/chrome the user wants omitted

Rules for HTML-to-SVG conversion:
- prefer native SVG over `foreignObject` wrappers unless the user explicitly asks for a wrapper export
- default to transparent background unless the user asks otherwise
- keep the same viewBox, line placement, glow, stroke widths, and overall scale
- remove only background-bearing shapes, not symbol geometry

## Output rules

- Keep the HTML dependency-free unless the exemplar already uses a library and parity requires it.
- Do not invent new UI chrome that is not present in the reference image.
- Do not guess unreadable labels. Preserve structure and call out ambiguity instead.
- Keep classes and styles small, local, and easy to edit.
- Preserve the requested look and feel without changing source geometry unless the user asks for that change.
- Do not "improve" a single-line diagram by rebalancing, enlarging, or regularizing it when the reference already defines the layout.
- Do not snap a branched schematic onto a cleaner card grid, symmetric column layout, or centered composition if the source is offset.
- Do not move a branch takeoff to the nearest box center; anchor it to the same trunk segment as the source.
- Do not merge or mirror lower nodes into paired columns if the source has distinct node heights or a dashed middle drop.
- Do not retarget a generator connection to a visually convenient column; trace it to the exact source node or column.

## Geometry checks

Before considering the work complete, verify:
- the main trunk follows the source path and only stays on-axis when the source does
- branch takeoffs leave the trunk at the same height and from the same trunk segment as the reference
- every node/terminal in the source is counted and recreated with the same count and height tiers
- lower node count, lower node heights, and lower column spacing match the source exactly
- dashed and solid columns remain in the same columns as the source and do not get swapped, merged, or mirrored
- the generator connection lands on the same lower node or column as the source, not the nearest neat endpoint
- label boxes stay at source size and are not normalized into a new card grid
- terminal circles, dashed drops, and generator symbols keep the source spacing and scale

For vertically mirrored symbols, also verify:
- intended mirrored runs are symmetric at the raw-coordinate level when the source is symmetric
- mirrored attachment relationships match too: stem-to-circle, stem-to-coil, and stem-to-body gaps/touches must mirror, not just segment lengths

## Verification checklist

Compare the final render against both the reference image and the exemplar.

Check these before claiming success:
- trunk path matches the source
- branch takeoff heights match the source
- branch takeoff origin matches the source trunk segment
- mirrored segment lengths match where the source is symmetric
- mirrored attachment/gap relationships also match
- lower node count and column order match the source
- node inventory and node height tiers match the source
- dashed versus solid columns match the source
- generator connection target matches the source
- stroke consistency matches the exemplar
- for HTML-to-SVG exports, the final SVG matches the source HTML framing and geometry
- for HTML-to-SVG exports, the final SVG keeps the same structure and symbol geometry as the original HTML symbol
- for HTML-to-SVG exports, the final SVG has a transparent background unless requested otherwise

## Repo patterns

Treat the repo's symbol files as the local style guide.
- `v7` represents the older Tailwind-based variant.
- `v8` represents the cleaner self-contained HTML/CSS direction.

For zoom-stable electrical runs, prefer inline SVG and a shared coordinate system over stacked boxes and div lines. If the user asks for `v7` look and feel, preserve that styling, but do not let it override the source geometry.

## Bundled references

- `references/repo-patterns.md`

## Rules

1. Source geometry wins over nicer-looking layout.
2. Exemplar style wins over arbitrary restyling.
3. For branched diagrams, anchor topology before styling.
4. Prefer native SVG for exact symbol geometry.
5. Call out ambiguity instead of hallucinating unreadable labels or hidden structure.
6. Use this skill for symbol-focused reconstruction; use `diagram-image-to-web` for broader diagram-to-web workflows.
