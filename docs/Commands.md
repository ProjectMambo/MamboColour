---
title: MamboColour command reference
description: Generate application colour files from the MamboColour CSV palettes.
order: 10
---

::page{layout="docs" width="normal" sidebar=true}

# MamboColour command reference

`mbcolor` converts one source palette into one application-specific file. `mbcolour` is an equivalent installed alias.

## Syntax

```bash
mbcolor <theme> <format> [-o|--out <output-directory>]
```

Theme and format names are case-insensitive. Run `mbcolor --help` for the same interface summary in the terminal.

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
| `css` | `mambo<theme>.css` | CSS custom properties; the palette name selects light, dark, or root scope |
| `tailwind` | `mambo<theme>.css` | Compatibility alias with byte-identical `css` output |

## Output location

Pass `--out` to choose a destination directory. The directory is created when needed. `-o` is the short alias.

If `--out` is omitted, the generated file is written into the source palette directory. That is useful while developing the generator but normally dirties the repository.

The command validates the complete source before replacing output. It renders to a temporary file in the destination directory, then atomically replaces a regular destination. A symlink, directory, device, or other non-regular target is rejected so the command cannot write through an unexpected path. A failed validation leaves an existing destination unchanged.

## Examples

```bash
# Hyprland Lua module
mbcolor mamboorchedark hyprlua --out ~/.config/hypr/themes

# Waybar GTK colours; the prefix is optional
mbcolor orchelight waybar --out ~/.config/waybar

# CSS variables for a web project
mbcolour mambooutbackdark css --out ./styles/generated
```

Existing consumers may continue to pass `tailwind`; it produces exactly the same file as `css`.

Set `NO_COLOR` to any value when logs must not contain ANSI styling:

```bash
NO_COLOR=1 mbcolor orchedark css --out ./styles/generated
```

## Install and remove

Install into a user-owned command directory:

```bash
mkdir -p "$HOME/.local/bin"
MAMBOCOLOUR_BIN_DIR="$HOME/.local/bin" ./script/install.sh
```

Remove the same links:

```bash
MAMBOCOLOUR_BIN_DIR="$HOME/.local/bin" ./script/install.sh --uninstall
```

Both operations inspect `mbcolor` and `mbcolour` before mutation. They proceed only when each existing target is a link to this checkout. Removal leaves the source palettes and generated consumer files unchanged.

## Exit status

| Status | Meaning |
|---:|---|
| `0` | Help, installation, removal, or generation succeeded |
| `2` | Command-line usage is invalid |
| other non-zero | A source, target, palette row, tool, or filesystem operation failed |

## Source CSV contract

Each non-comment row has four comma-separated fields:

```text
name,hex,alpha,category
```

- `name` becomes the target variable name.
- `hex` is a six-digit colour without `#`.
- `alpha` is a two-digit hexadecimal alpha value.
- `category` documents the semantic group and is not emitted.

Names must be lowercase identifiers containing letters, digits, and underscores; colours require six hexadecimal digits; alpha requires two hexadecimal digits; and category must be present. A fifth CSV field or malformed value fails the complete generation before the destination is replaced.

## Verification

```bash
./script/test.sh
../MamboDocs/script/check-repository.sh --strict .
```

The regression script covers shell syntax, both installed command names, owned-link installation and removal, every theme and accepted format name, `css`/`tailwind` equivalence, `NO_COLOR`, usage errors, invalid CSV, and safe output and installer collisions. It is not currently run by CI.
