#!/usr/bin/env bash

# Color codes for clean scannable terminal output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

source "$(dirname "$(readlink -f "$0")")/utils.sh"

THEME=$(echo "$1" | tr '[:upper:]' '[:lower:]') # Target theme name
FORMAT=$(echo "$2" | tr '[:upper:]' '[:lower:]') # Format case
DEST_DIR=$3 # Destination folder

echo -e "${BLUE}------------------------------------------${NC}"
echo -e " Target: [${GREEN}${THEME^^}${NC}]"
echo -e " Format: [${GREEN}${FORMAT^^}${NC}]"
echo -e "${BLUE}------------------------------------------${NC}"

case "$FORMAT" in
    "hyprland")
        # Setup output files; Exit if setup failed
        setup_theme_files "$THEME" "conf" "$DEST_DIR" || exit 1
        # Parse theme csv
        parse_theme_files "parse_hyprland" "Hyprland"
        ;;
    "waybar")
        setup_theme_files "$THEME" "css" "$DEST_DIR" || exit 1
        parse_theme_files "parse_waybar" "Waybar"
        ;;
    "tailwind")
        setup_theme_files "$THEME" "css" "$DEST_DIR" || exit 1
        parse_theme_files "parse_tailwind" "Tailwind"
        ;;
    *)
        echo -e "${RED}[!] Error: Invalid format choice${NC}" >&2
        exit 1
        ;;
esac

echo -e "\n${BLUE}------------------------------------------${NC}"
echo -e "${GREEN}[+] Theme generated!${NC}"
echo -e "${BLUE}------------------------------------------${NC}"