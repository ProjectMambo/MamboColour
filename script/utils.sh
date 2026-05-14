#!/usr/bin/env bash

# Color codes for clean scannable terminal output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize theme files
# Usage: setup_theme_files <theme_name> <output_file_type> <destination_folder>
setup_theme_files() {
    local theme=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    local output_type=$2
    local dest_dir=$3
    
    # Get theme directory; Exit if given theme is invalid
    local script_dir=$(dirname "$(readlink -f "$BASH_SOURCE")")
    local theme_dir=$(find "$script_dir/../colours" -maxdepth 1 -iname "$theme" -type d | head -n 1)
    if [ -z "$theme_dir" ]; then
        echo -e "${RED}[!] Error: Theme folder for '$theme' not found.${NC}" >&2
        return 1
    fi

    # Get theme csv; Exit if no csv file for given theme
    SOURCE=$(find "$theme_dir" -maxdepth 1 -iname "$theme.csv" -type f | head -n 1)
    if [ -z "$SOURCE" ]; then
        echo -e "${RED}[!] Error: CSV file for '$theme' not found.${NC}" >&2
        return 1
    fi

    # Make destination folder
    mkdir -p "$dest_dir"
    DEST="$dest_dir/$theme.$output_type"

    echo -e "${BLUE}------------------------------------------${NC}"
    echo -e " Theme:  ${GREEN}$theme${NC}"
    echo -e " Source: $SOURCE"
    echo -e " Output: $DEST"
    echo -e "${BLUE}------------------------------------------${NC}"
}

# Parse theme csv to correct format using parser
# Usage: parse_theme_files <parser_function> <header_name>
parse_theme_files() {
    local parser=$1
    local header_name=$2
    
    {
        if [ "$parser" = "parse_tailwind" ]; then
            echo ":root {"
        fi

        grep -v '^#' "$SOURCE" | # Remove comments
        grep '[^[:space:]]' | # Remove empty lines
        while IFS=, read -r name hex alpha cat || # Parse entries to correct format
        [ -n "$name" ]; do # Fallback loop for trailing newlines
            $parser "$name" "$hex" "$alpha"
        done

        if [ "$parser" = "parse_tailwind" ]; then
            echo "}"
        fi
    } > "$DEST"

    echo -e "${BLUE}[*] Target: [${GREEN}${header_name^^}${NC}]"
    echo -e "${GREEN}[+] Generation successful!${NC}"
    echo -e "${BLUE}------------------------------------------${NC}"
}

# Convert hex and alpha to rgba channel values
# Usage: convert_color <6-char-hex> <2-char-alpha>
convert_color() {
    local hex=$1
    local alpha=$2

    # Convert individual channel (0-255)
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    
    # Convert alpha with leading zero
    local a_num=$((16#$alpha))
    local pct=$(( (a_num * 100) / 255 ))
    
    # Calculate percentage (0-100)
    if [ "$pct" -eq 100 ]; then
        local a="1.0"
    elif [ "$pct" -lt 10 ]; then
        local a="0.0$pct"
    else
        local a="0.$pct"
    fi

    echo "$r" "$g" "$b" "$a"
}

# Parsers for different formats
# Usage: parse_xxxx <colour_name> <hex_value> <alpha_value>
parse_hyprland() {
    local name=$1 hex=$2 alpha=$3
    echo "\$$name = rgb($hex)"
    echo "\$${name}_a = rgba($hex$alpha)"
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
