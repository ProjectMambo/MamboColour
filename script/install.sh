#!/usr/bin/env bash
set -euo pipefail

# Color codes for clean scannable terminal output
if [[ -n "${NO_COLOR+x}" ]]; then
    GREEN='' RED='' BLUE='' YELLOW='' NC=''
else
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    YELLOW='\033[0;33m'
    NC='\033[0m'
fi

# Get the absolute path
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COMMAND_SOURCE="$SCRIPT_DIR/mambo_colour.sh"
INSTALL_DIR="${MAMBOCOLOUR_BIN_DIR:-/usr/local/bin}"
COMMAND_TARGET="$INSTALL_DIR/mbcolor"
COMPAT_TARGET="$INSTALL_DIR/mbcolour"

usage() {
    cat <<'EOF'
Usage: ./script/install.sh [--uninstall]

Installs or removes the mbcolor and mbcolour command symlinks. Set
MAMBOCOLOUR_BIN_DIR to select a command directory other than /usr/local/bin.
EOF
}

MODE=install
case "${1:-}" in
    "") ;;
    -h|--help) usage; exit 0 ;;
    --uninstall) MODE=uninstall ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
esac
if [[ $# -gt 1 ]]; then
    echo "only one option may be supplied" >&2
    usage >&2
    exit 2
fi

owns_target() {
    [[ -L "$1" && "$(readlink -f -- "$1" 2>/dev/null || true)" == "$COMMAND_SOURCE" ]]
}

for target in "$COMMAND_TARGET" "$COMPAT_TARGET"; do
    if [[ -e "$target" || -L "$target" ]] && ! owns_target "$target"; then
        echo -e "${RED}[!] Refusing command target not owned by MamboColour: $target${NC}" >&2
        exit 1
    fi
done

if [[ "$MODE" == uninstall ]]; then
    if [[ -d "$INSTALL_DIR" && -w "$INSTALL_DIR" ]]; then
        rm -f -- "$COMMAND_TARGET" "$COMPAT_TARGET"
    elif [[ -e "$COMMAND_TARGET" || -L "$COMMAND_TARGET" || -e "$COMPAT_TARGET" || -L "$COMPAT_TARGET" ]]; then
        sudo rm -f -- "$COMMAND_TARGET" "$COMPAT_TARGET"
    fi
    echo -e "${GREEN}[+] Removed MamboColour command symlinks.${NC}"
    exit 0
fi

chmod +x "$COMMAND_SOURCE"
if [[ ! -d "$INSTALL_DIR" && -n "${MAMBOCOLOUR_BIN_DIR+x}" ]]; then
    mkdir -p "$INSTALL_DIR"
fi
if [[ -d "$INSTALL_DIR" && -w "$INSTALL_DIR" ]]; then
    ln -sfn "$COMMAND_SOURCE" "$COMMAND_TARGET"
    ln -sfn "$COMMAND_SOURCE" "$COMPAT_TARGET"
else
    sudo mkdir -p "$INSTALL_DIR"
    sudo ln -sfn "$COMMAND_SOURCE" "$COMMAND_TARGET"
    sudo ln -sfn "$COMMAND_SOURCE" "$COMPAT_TARGET"
fi

echo -e "${BLUE}------------------------------------------${NC}"
echo -e " Tool:    ${GREEN}MamboColour${NC}"
echo -e " Source:  $PROJECT_DIR"
echo -e " Command: $COMMAND_TARGET"

case ":$PATH:" in
    *":$INSTALL_DIR:"*) ;;
    *) echo -e "${YELLOW}[!] Add $INSTALL_DIR to PATH before using mbcolor globally.${NC}" ;;
esac

echo -e "${GREEN}[+] Installation successful!${NC}"
echo -e "${BLUE}------------------------------------------${NC}"
