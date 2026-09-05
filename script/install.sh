#!/usr/bin/env bash
set -euo pipefail

# Color codes for clean scannable terminal output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Get the absolute path
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COMMAND_SOURCE="$SCRIPT_DIR/mambo_colour.sh"
INSTALL_DIR="${MAMBOCOLOUR_BIN_DIR:-/usr/local/bin}"
COMMAND_TARGET="$INSTALL_DIR/mbcolor"
COMPAT_TARGET="$INSTALL_DIR/mbcolour"

for target in "$COMMAND_TARGET" "$COMPAT_TARGET"; do
    if [[ -e "$target" && ! -L "$target" ]]; then
        echo -e "${RED}[!] Refusing to replace non-symlink command: $target${NC}" >&2
        exit 1
    fi
done

chmod +x "$COMMAND_SOURCE"
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
