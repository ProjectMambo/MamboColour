---
title: MamboColour Command Reference
description: Generate application colour files from the MamboColour CSV palettes.
order: 10
---

::page{layout="docs" width="normal" sidebar=true}

# MamboColour Command Reference

`mbcolor` converts one source palette into one application-specific file. `mbcolour` is an equivalent installed alias.

## Syntax

```bash
mbcolor <theme> <format> [-o <output-directory>]
```

Theme and format names are case-insensitive. The tables below reflect the active implementation; the built-in `--help` text still contains historical theme and format examples.

## Themes

| Theme | Tokens | Description |
|---|---:|---|
| `mamboorchelight` | 13 | Light semantic interface palette |
| `mamboorchedark` | 13 | Dark semantic interface palette |
| `mambooutbacklight` | 51 | Light expanded accent palette |
| `mambooutbackdark` | 51 | Dark expanded accent palette |

The `mambo` prefix is optional, so `orchedark` and `mamboorchedark` resolve to the same palette.

## Formats

| Format | File | Description |
|---|---|---|
| `hyprlua` | `mambo<theme>.lua` | Lua module with normal and alpha colour values |
| `hyprlang` | `mambo<theme>.conf` | Hyprland `$name` and `$name_a` variables |
| `waybar` | `mambo<theme>.css` | GTK CSS `@define-color` declarations |
| `tailwind` | `mambo<theme>.css` | CSS custom properties; the palette name selects light, dark, or root scope |

## Output location

Pass `-o` to choose a destination directory. The directory is created when needed.

If `-o` is omitted, the generated file is written into the source palette directory. That is useful while developing the generator but normally dirties the repository.

## Examples

```bash
# Hyprland Lua module
mbcolor mamboorchedark hyprlua -o ~/.config/hypr/themes

# Waybar GTK colours; the prefix is optional
mbcolor orchelight waybar -o ~/.config/waybar

# CSS variables for a web project
mbcolour mambooutbackdark tailwind -o ./styles/generated
```

## Source CSV contract

Each non-comment row has four comma-separated fields:

```text
name,hex,alpha,category
```

- `name` becomes the target variable name.
- `hex` is a six-digit colour without `#`.
- `alpha` is a two-digit hexadecimal alpha value.
- `category` documents the semantic group and is not emitted.

The current parser assumes valid source rows. Validate new palette records by generating every supported format before committing them.
