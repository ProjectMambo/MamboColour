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

## Start here

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

## Local setup

The scripts target a Linux environment with Bash and standard GNU command-line tools.

```bash
git clone https://github.com/ProjectMambo/MamboColour.git
cd MamboColour
./script/install.sh
```

The installer targets `/usr/local/bin` by default. It creates both command symlinks, refuses to replace a non-symlink at either target, and uses `sudo` only when the destination directory is absent or not writable. Set `MAMBOCOLOUR_BIN_DIR` to use another bin directory; create that directory first to avoid `sudo`:

```bash
mkdir -p "$HOME/.local/bin"
MAMBOCOLOUR_BIN_DIR="$HOME/.local/bin" ./script/install.sh
```

Generate a palette without installing the command:

```bash
./script/mambo_colour.sh mamboorchedark hyprlua --out /tmp/mambo-theme
```

## Repository layout

```text
colours/<palette>/<palette>.csv  source palettes
script/mambo_colour.sh          generator and command-line interface
script/install.sh               command symlink installer
script/test.sh                  CLI and installer regression checks
docs/                           command and project documentation
```

## Development checks

The repository has focused local CLI and installer checks, but no CI or release workflow. Before committing generator changes, run:

```bash
bash -n script/install.sh script/mambo_colour.sh script/test.sh
./script/test.sh
./script/mambo_colour.sh mambooutbackdark css --out /tmp/mambocolour-check
git diff --check
git status --short
```

## Issues and feedback

These palettes are maintained for Project Mambo, so external pull requests are not currently requested. Bug reports and generator suggestions are welcome as repository issues.

## License

Distributed under the MIT License. See **[LICENSE](LICENSE)** for details.
