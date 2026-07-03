#!/usr/bin/env bash
# mbcolor - Generate theme config files from Mambo colour CSVs
# Usage: mbcolor <theme> <format> [-o <output_dir>]

# ── Color codes ───────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# ── Help ──────────────────────────────────────────────────────────────────────
usage() {
    echo -e "
${BLUE}Usage:${NC}
  mbcolor <theme> <format> [-o <output_dir>]

${BLUE}Arguments:${NC}
  theme     Theme name — with or without the ${GREEN}mambo${NC} prefix
              e.g. ${GREEN}rose${NC} or ${GREEN}mamborose${NC}
  format    Output format: ${GREEN}hyprland${NC} | ${GREEN}waybar${NC} | ${GREEN}tailwind${NC}

${BLUE}Options:${NC}
  -o <dir>  Output directory (default: theme's own folder)
  -h        Show this help message

${BLUE}Examples:${NC}
  mbcolor rose hyprland
  mbcolor mamborose waybar -o ~/.config/waybar/themes
  mbcolor sky tailwind -o ~/themes/out
"
    exit 0
}

# ── Argument parsing ──────────────────────────────────────────────────────────
[[ $# -lt 2 || "$1" == "-h" || "$1" == "--help" ]] && usage

RAW_THEME=$(echo "$1" | tr '[:upper:]' '[:lower:]')
FORMAT=$(echo "$2" | tr '[:upper:]' '[:lower:]')
shift 2

DEST_DIR=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o) DEST_DIR="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}[!] Unknown option: $1${NC}" >&2; exit 1 ;;
    esac
done

# Strip leading "mambo" prefix so both "rose" and "mamborose" resolve the same
THEME="${RAW_THEME#mambo}"

# ── Validate format ───────────────────────────────────────────────────────────
case "$FORMAT" in
    hyprland|waybar|tailwind) ;;
    *) echo -e "${RED}[!] Invalid format '${FORMAT}'. Choose: hyprland | waybar | tailwind${NC}" >&2; exit 1 ;;
esac

# ── Locate theme directory ────────────────────────────────────────────────────
# Accepts both "mamborose" and "rose" folder names
THEME_DIR=$(find "$SCRIPT_DIR/../colours" -maxdepth 1 -type d \
    \( -iname "mambo${THEME}" -o -iname "${THEME}" \) | head -n 1)

if [[ -z "$THEME_DIR" ]]; then
    echo -e "${RED}[!] Theme '${THEME}' not found in colours/.${NC}" >&2
    exit 1
fi

# ── Locate CSV ────────────────────────────────────────────────────────────────
SOURCE=$(find "$THEME_DIR" -maxdepth 1 -type f \
    \( -iname "mambo${THEME}.csv" -o -iname "${THEME}.csv" \) | head -n 1)

if [[ -z "$SOURCE" ]]; then
    echo -e "${RED}[!] No CSV found in '${THEME_DIR}'.${NC}" >&2
    exit 1
fi

# ── Resolve output path ───────────────────────────────────────────────────────
case "$FORMAT" in
    hyprland) EXT="lua" ;;
    waybar)   EXT="css" ;;
    tailwind) EXT="css" ;;
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
parse_hyprland() {
    local name=$1 hex=$2 alpha=$3
    echo "M.$name = \"rgb($hex)\""
    echo "M.${name}_a = \"rgba($hex$alpha)\""
}

parse_waybar() {
    local name=$1 hex=$2 alpha=$3
    read -r R G B A < <(convert_color "$hex" "$alpha")
    echo "@define-color $name rgba($R,$G,$B,$A);"
}

parse_tailwind() {
    local name=$1 hex=$2 alpha=$3
    echo "  --$name: #$hex;"
}

# ── Tailwind selector: detect light/dark from theme name ─────────────────────
tailwind_selector() {
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
        hyprland)
            [[ "$action" == "open" ]] && echo "local M = {}"
            [[ "$action" == "close" ]] && echo "return M"
            ;;
        tailwind)
            local selector
            case "$THEME" in
                *light) selector='[data-theme="light"]' ;;
                *dark)  selector='[data-theme="dark"]'  ;;
                *)      selector=':root'                ;;
            esac
            [[ "$action" == "open" ]] && echo "$selector {"
            [[ "$action" == "close" ]] && echo "}"
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

[[ "$FORMAT" == "tailwind" ]] && echo -e "  Selector: ${YELLOW}$(tailwind_selector)${NC}"

echo -e "${GREEN}[+] Done! →${NC} ${DEST}"
echo -e "${BLUE}──────────────────────────────────────────${NC}"