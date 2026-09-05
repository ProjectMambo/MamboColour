---
description: Shared colour palettes and cross-application format generation for Project Mambo.
title: MamboColour
order: 10
---

::page{layout="project" width="normal" sidebar=true}

# MamboColour

MamboColour is the shared palette source for Project Mambo. Four CSV palettes provide a compact semantic UI set and a larger accent set in matching light and dark variants.

::button{label="Source code" href="https://github.com/ProjectMambo/MamboColour" variant="secondary" external=true}

## What it provides

- MamboOrche light and dark palettes for core interface roles.
- MamboOutback light and dark palettes for broader accent ranges.
- The `mbcolor` and `mbcolour` command aliases.
- Hyprland Lua, Hyprland, Waybar, and CSS-variable output.

The palette source stays application-neutral. Consumers generate the format they need instead of maintaining separate hand-edited copies.

## Documentation

::children{view="list" sort="order" direction="asc" show=["title","description"]}

## Current status

The generator and all four palettes are in active use. Generation is deterministic for a given CSV, but the repository does not yet have automated tests, CI, or a release pipeline.
