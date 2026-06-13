#!/usr/bin/env bash

# Color codes for clean scannable terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the absolute path
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Make script executable
chmod +x "$SCRIPT_DIR/mambo_colour.sh"

# Make a symlink for the main command
sudo rm -rf /usr/local/bin/mbcolor
sudo rm -rf /usr/local/bin/mbcolour
sudo ln -sf "$SCRIPT_DIR/mambo_colour.sh" /usr/local/bin/mbcolor
sudo ln -sf "$SCRIPT_DIR/mambo_colour.sh" /usr/local/bin/mbcolour

echo -e "${BLUE}------------------------------------------${NC}"
echo -e " Tool:   ${GREEN}MamboColour${NC}"
echo -e " Source: $PROJECT_DIR"
echo -e "${GREEN}[+] Installation successful!${NC}"
echo -e "${BLUE}------------------------------------------${NC}"