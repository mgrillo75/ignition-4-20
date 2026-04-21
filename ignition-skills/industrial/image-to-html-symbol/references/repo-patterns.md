# Repo Patterns

This repo is a small symbol workspace built from standalone HTML files and SVG exports.

## Style Baseline

- `symbols/html/modern-genset-panel-v8.html` is the clean self-contained HTML/CSS direction.
- `symbols/html/modern-genset-panel-v7.html` is the older Tailwind-based variant.
- `symbols/svgs/modern-genset-panel-v7.svg` shows an export wrapper pattern, but `foreignObject` rendering is fragile.

## Practical Rules

- Prefer inline CSS and self-contained markup.
- Prefer inline SVG for zoom-stable electrical runs and contiguous symbol geometry.
- Keep the panel readable, compact, and aligned to the exemplar style.
- Verify by rendering and comparing against the reference image, especially around thin lines, circles, and small labels.
