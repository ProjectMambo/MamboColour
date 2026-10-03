# MamboColour

<p align="left">
  <img src="https://img.shields.io/badge/CSV-7289DA?style=flat-square" alt="CSV" />
  <img src="https://img.shields.io/badge/Shell_Script-121011?style=flat-square&logo=gnu-bash&logoColor=white" alt="Shell Script" />
</p>
<p align="left">
  <img src="https://img.shields.io/badge/Maintenance-Active-brightgreen?style=flat-square" alt="Maintenance status: active" />
  <img src="https://img.shields.io/github/last-commit/ProjectMambo/MamboColour?style=flat-square&color=7a5fff" alt="Last commit" />
  <img src="https://img.shields.io/github/repo-size/ProjectMambo/MamboColour?style=flat-square&color=yellow" alt="Repository size" />
  <a href="LICENSE"><img src="https://img.shields.io/github/license/ProjectMambo/MamboColour?style=flat-square&color=orange" alt="License" /></a>
</p>

MamboColour is Project Mambo's shared colour source. It stores light and dark palettes as readable CSV files and converts them into formats consumed by Hyprland, Hyprland Lua, Waybar, and CSS applications.

## Motivation

Project Mambo applications need one reviewed colour vocabulary without maintaining separate hand-edited copies for every target format. MamboColour keeps the palette source application-neutral and makes each consumer's generated boundary reproducible.

## Status

MamboColour is active on Linux. Four palettes and the `mbcolor`/`mbcolour` command are used by MamboDot and MamboSite. There is no package release or CI workflow yet; the repository's focused shell gate is authoritative.

Temporary versioning exception:

- **Requirement:** version installed commands and generated-asset contracts.
- **Current behavior:** the command is installed from a Git checkout and has no SemVer release.
- **Reason:** it is currently a Project Mambo maintainer tool, not a distributed package.
- **Risk:** an arbitrary newer checkout may not match a consumer's reviewed generated files.
- **Mitigation:** consumers record the provider commit and test the exact formats and tokens they consume; the current checked-in snapshots identify commit `66f0c26d6d6462c54c023a4842e49dc6fa0b3c1c`.
- **Review:** remove this exception before the first external release or any incompatible command, token, filename, or output change.

## User stories

- As a theme maintainer, I can edit one readable palette and regenerate every supported target.
- As a MamboDot maintainer, I can generate Hyprland, Lua, and Waybar files with stable names and tokens.
- As a MamboSite maintainer, I can generate predictable CSS custom properties for the reviewed default theme.
- As a cautious user, I can install or remove only MamboColour-owned command links and never write through a symlink output target.

## Getting started

The scripts require Linux, Bash, and standard GNU command-line tools. A user-owned installation needs no elevated privileges:

```bash
git clone https://github.com/ProjectMambo/MamboColour.git
cd MamboColour
mkdir -p "$HOME/.local/bin"
MAMBOCOLOUR_BIN_DIR="$HOME/.local/bin" ./script/install.sh
mbcolor mamboorchedark hyprlua --out /tmp/mambo-theme
```

## Documentation

| Goal | Document or command |
|---|---|
| Read the canonical Wiki documentation | [projectmambo.org/mambocolour/](https://projectmambo.org/mambocolour/) |
| Install the `mbcolor` command | [Local setup](#local-setup) |
| Generate a theme | [Command reference](docs/Commands.md) |
| Inspect the source palettes | [`colours/`](colours/) |

## Current palettes

| Family | Variants | Purpose |
|---|---|---|
| MamboOrche | `mamboorchelight`, `mamboorchedark` | Compact semantic UI palette for backgrounds, text, interaction, and status |
| MamboOutback | `mambooutbacklight`, `mambooutbackdark` | Expanded accent spectrum for cards, data, illustrations, and themes |

Each palette is a CSV file with `name,hex,alpha,category` records. Comment and blank lines are ignored by the generator.

## Outputs

`mbcolor` accepts palette names with or without the leading `mambo` prefix and writes one generated file:

| Format | Extension | Output form |
|---|---|---|
| `hyprlua` | `.lua` | Lua module with `rgb(...)` and `rgba(...)` strings |
| `hyprlang` | `.conf` | Hyprland variables |
| `waybar` | `.css` | GTK `@define-color` declarations |
| `css` | `.css` | CSS custom properties under a light, dark, or root selector |
| `tailwind` | `.css` | Compatibility alias that produces the same bytes as `css` |

Without `--out`, output is written beside the source CSV and will appear as a working-tree change. Use an explicit output directory for generated application files. `-o` remains the short alias.

The generator validates every source row, writes a temporary sibling, and atomically replaces the regular destination only after generation succeeds. It refuses symlink and non-file targets. Set `NO_COLOR` to suppress ANSI styling.

## Local setup

The scripts target a Linux environment with Bash and standard GNU command-line tools.

```bash
git clone https://github.com/ProjectMambo/MamboColour.git
cd MamboColour
./script/install.sh
```

The installer targets `/usr/local/bin` by default. It creates both command symlinks, refuses any target not already owned by this checkout, and uses `sudo` only when the default system directory is absent or not writable. Set `MAMBOCOLOUR_BIN_DIR` to use another bin directory; the installer creates that explicit directory without `sudo` when permissions allow:

```bash
mkdir -p "$HOME/.local/bin"
MAMBOCOLOUR_BIN_DIR="$HOME/.local/bin" ./script/install.sh
```

Generate a palette without installing the command:

```bash
./script/mambo_colour.sh mamboorchedark hyprlua --out /tmp/mambo-theme
```

Remove only the links owned by the same checkout:

```bash
MAMBOCOLOUR_BIN_DIR="$HOME/.local/bin" ./script/install.sh --uninstall
```

Installation and removal refuse ordinary files, broken links, and links to another command. Usage errors return `2`; missing sources, invalid palette data, and unsafe targets return another non-zero status; successful generation and help return `0`.

## Project structure

```text
colours/<palette>/<palette>.csv  source palettes
script/mambo_colour.sh          generator and command-line interface
script/install.sh               owned-link installer and uninstaller
script/test.sh                  authoritative shell and behavior gate
docs/                           command and project documentation
```

## Validation

The repository has focused local CLI and installer checks, but no CI or release workflow. Run:

```bash
./script/test.sh
../MamboDocs/script/check-repository.sh --strict .
git diff --check
```

The shell test covers syntax, both installed names, install/uninstall ownership, `NO_COLOR`, every theme and format, compatibility output, invalid source data, usage errors, and atomic target protection.

## Development

Treat theme names, token names, command arguments, output filenames, and generated grammar as public interfaces. Coordinate incompatible changes with MamboDot and MamboSite before removal; regenerate and validate both consumers when their reviewed snapshots change.

Author documentation in `notes/Docs/Projects/MamboColour/`, update page metadata, then run `node Scripts/sync_docs.js --sync MamboColour MamboWiki` from `notes/`. Review the root README and complete `docs/` replacement before committing.

These palettes are maintained for Project Mambo, so external pull requests are not currently requested. Bug reports and generator suggestions are welcome as repository issues.

## License

Distributed under the MIT License. See **[LICENSE](LICENSE)** for details.
