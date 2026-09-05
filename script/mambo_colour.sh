#!/usr/bin/env bash
set -euo pipefail

# mbcolor - Generate theme config files from Mambo colour CSVs
# Usage: mbcolor <theme> <format> [-o|--out <output_dir>]

# ── Color codes ───────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# ── Help ──────────────────────────────────────────────────────────────────────
usage() {
    echo -e "
${BLUE}Usage:${NC}
  mbcolor <theme> <format> [-o|--out <output_dir>]

${BLUE}Arguments:${NC}
  theme     Theme name — with or without the ${GREEN}mambo${NC} prefix
              ${GREEN}orchelight${NC} | ${GREEN}orchedark${NC} | ${GREEN}outbacklight${NC} | ${GREEN}outbackdark${NC}
  format    Output format: ${GREEN}hyprlua${NC} | ${GREEN}hyprlang${NC} | ${GREEN}waybar${NC} | ${GREEN}css${NC}
            Compatibility alias: ${GREEN}tailwind${NC} (same output as css)

${BLUE}Options:${NC}
  -o, --out <dir>  Output directory (default: theme's own folder)
  -h, --help       Show this help message

${BLUE}Examples:${NC}
  mbcolor orchedark hyprlua
  mbcolor mamboorchelight waybar --out ~/.config/waybar
  mbcolour mambooutbackdark css -o ~/themes/out
"
}

# ── Argument parsing ──────────────────────────────────────────────────────────
if [[ $# -eq 0 ]]; then
    usage >&2
    exit 2
fi

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

if [[ $# -lt 2 ]]; then
    echo -e "${RED}[!] Theme and format are required.${NC}" >&2
    usage >&2
    exit 2
fi

RAW_THEME=$(echo "$1" | tr '[:upper:]' '[:lower:]')
FORMAT=$(echo "$2" | tr '[:upper:]' '[:lower:]')
shift 2

DEST_DIR=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--out)
            if [[ $# -lt 2 || -z "${2:-}" || "${2:-}" == -* ]]; then
                echo -e "${RED}[!] $1 requires an output directory.${NC}" >&2
                exit 2
            fi
            DEST_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Unknown option: $1${NC}" >&2
            exit 2
            ;;
    esac
done

# Strip the optional leading "mambo" prefix.
THEME="${RAW_THEME#mambo}"

# ── Validate format ───────────────────────────────────────────────────────────
case "$FORMAT" in
    hyprlua|hyprlang|waybar|css|tailwind) ;;
    *) echo -e "${RED}[!] Invalid format '${FORMAT}'. Choose: hyprlua | hyprlang | waybar | css${NC}" >&2; exit 2 ;;
esac

# ── Locate theme directory ────────────────────────────────────────────────────
# Accept prefixed and unprefixed theme folder names.
THEME_DIR=$(find "$SCRIPT_DIR/../colours" -maxdepth 1 -type d \
    \( -iname "mambo${THEME}" -o -iname "${THEME}" \) -print -quit)

if [[ -z "$THEME_DIR" ]]; then
    echo -e "${RED}[!] Theme '${THEME}' not found in colours/.${NC}" >&2
    exit 1
fi

# ── Locate CSV ────────────────────────────────────────────────────────────────
SOURCE=$(find "$THEME_DIR" -maxdepth 1 -type f \
    \( -iname "mambo${THEME}.csv" -o -iname "${THEME}.csv" \) -print -quit)

if [[ -z "$SOURCE" ]]; then
    echo -e "${RED}[!] No CSV found in '${THEME_DIR}'.${NC}" >&2
    exit 1
fi

# ── Resolve output path ───────────────────────────────────────────────────────
case "$FORMAT" in
    hyprlua)  EXT="lua" ;;
    hyprlang) EXT="conf" ;;
    waybar|css|tailwind) EXT="css" ;;
esac

# Default output: theme's own folder
if [[ -z "$DEST_DIR" ]]; then
    DEST_DIR="$THEME_DIR"
fi

mkdir -p "$DEST_DIR"
DEST="$DEST_DIR/mambo${THEME}.${EXT}"

# ── Print summary ─────────────────────────────────────────────────────────────
echo -e "${BLUE}──────────────────────────────────────────${NC}"
echo -e "  Theme:  ${GREEN}mambo${THEME}${NC}"
echo -e "  Format: ${GREEN}${FORMAT^^}${NC}"
echo -e "  Source: ${YELLOW}${SOURCE}${NC}"
echo -e "  Output: ${YELLOW}${DEST}${NC}"
echo -e "${BLUE}──────────────────────────────────────────${NC}"

# ── Color conversion ──────────────────────────────────────────────────────────
# Usage: convert_color <6-char-hex> <2-char-alpha>
# Outputs: R G B A(float)
convert_color() {
    local hex=$1 alpha=$2
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    local a_num=$((16#$alpha))
    local pct=$(( (a_num * 100) / 255 ))
    local a
    if   [[ $pct -eq 100 ]]; then a="1.0"
    elif [[ $pct -lt 10  ]]; then a="0.0$pct"
    else                          a="0.$pct"
    fi
    echo "$r" "$g" "$b" "$a"
}

# ── Parsers ───────────────────────────────────────────────────────────────────
parse_hyprlua() {
    local name=$1 hex=$2 alpha=$3
    echo "M.$name = \"rgb($hex)\""
    echo "M.${name}_a = \"rgba($hex$alpha)\""
}

parse_hyprlang() {
    local name=$1 hex=$2 alpha=$3
    echo "\$$name = rgb($hex)"
    echo "\$${name}_a = rgba(${hex}${alpha})"
}

parse_waybar() {
    local name=$1 hex=$2 alpha=$3
    read -r R G B A < <(convert_color "$hex" "$alpha")
    echo "@define-color $name rgba($R,$G,$B,$A);"
}

parse_css() {
    local name=$1 hex=$2 alpha=$3
    echo "  --$name: #$hex;"
}

# Compatibility alias retained for existing consumers.
parse_tailwind() {
    parse_css "$@"
}

# ── CSS selector: detect light/dark from theme name ──────────────────────────
css_selector() {
    case "$THEME" in
        *light)     echo '[data-theme="light"]' ;;
        *dark)      echo '[data-theme="dark"]'  ;;
        *)          echo ':root'                ;;
    esac
}

# ── Wrapper Logic ─────────────────────────────────────────────────────────────
# Usage: wrap_output <format> <action: open/close>
wrap_output() {
    local fmt=$1 action=$2
    case "$fmt" in
        hyprlua)
            if [[ "$action" == "open" ]]; then
                echo "local M = {}"
            elif [[ "$action" == "close" ]]; then
                echo "return M"
            fi
            ;;
        hyprlang)
            if [[ "$action" == "open" ]]; then
                echo "# Auto-generated theme colors"
            fi
            ;;
        css|tailwind)
            local selector
            case "$THEME" in
                *light) selector='[data-theme="light"]' ;;
                *dark)  selector='[data-theme="dark"]'  ;;
                *)      selector=':root'                ;;
            esac
            if [[ "$action" == "open" ]]; then
                echo "$selector {"
            elif [[ "$action" == "close" ]]; then
                echo "}"
            fi
            ;;
        waybar)
            :
            ;;
    esac
}

# ── Generate output ───────────────────────────────────────────────────────────
{
    wrap_output "$FORMAT" "open"

    grep -v '^#' "$SOURCE" |        # strip comments
    grep '[^[:space:]]' |           # strip blank lines
    while IFS=, read -r name hex alpha cat || [[ -n "$name" ]]; do
        "parse_${FORMAT}" "$name" "$hex" "$alpha"
    done

    wrap_output "$FORMAT" "close"
} > "$DEST"

if [[ "$FORMAT" == "css" || "$FORMAT" == "tailwind" ]]; then
    echo -e "  Selector: ${YELLOW}$(css_selector)${NC}"
fi

echo -e "${GREEN}[+] Done! →${NC} ${DEST}"
echo -e "${BLUE}──────────────────────────────────────────${NC}"
