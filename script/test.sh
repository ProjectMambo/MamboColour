#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
TEST_ROOT="$(mktemp -d /tmp/mambocolour-test.XXXXXX)"

cleanup() {
    if [[ -d "$TEST_ROOT" && "$TEST_ROOT" == /tmp/mambocolour-test.* ]]; then
        rm -rf -- "$TEST_ROOT"
    fi
}
trap cleanup EXIT

mkdir -p "$TEST_ROOT/bin"
MAMBOCOLOUR_BIN_DIR="$TEST_ROOT/bin" "$SCRIPT_DIR/install.sh" >/dev/null

[[ -L "$TEST_ROOT/bin/mbcolor" ]]
[[ -L "$TEST_ROOT/bin/mbcolour" ]]
[[ "$(readlink -f "$TEST_ROOT/bin/mbcolor")" == "$SCRIPT_DIR/mambo_colour.sh" ]]
[[ "$(readlink -f "$TEST_ROOT/bin/mbcolour")" == "$SCRIPT_DIR/mambo_colour.sh" ]]

"$TEST_ROOT/bin/mbcolor" --help | grep -q 'hyprlua'
if "$TEST_ROOT/bin/mbcolor" >/dev/null 2>&1; then
    echo "mbcolor without arguments should fail" >&2
    exit 1
fi
if "$TEST_ROOT/bin/mbcolor" mamboorchedark invalid >/dev/null 2>&1; then
    echo "mbcolor should reject an invalid format" >&2
    exit 1
fi
if "$TEST_ROOT/bin/mbcolor" mamboorchedark hyprlua --out >/dev/null 2>&1; then
    echo "mbcolor should reject --out without a directory" >&2
    exit 1
fi
if "$TEST_ROOT/bin/mbcolor" mamboorchedark hyprlua --out --help >/dev/null 2>&1; then
    echo "mbcolor should reject an option used as the --out directory" >&2
    exit 1
fi

for theme in mamboorchelight mamboorchedark mambooutbacklight mambooutbackdark; do
    for format in hyprlua hyprlang waybar css tailwind; do
        output_dir="$TEST_ROOT/output/$format"
        "$TEST_ROOT/bin/mbcolor" "$theme" "$format" --out "$output_dir" >/dev/null
        case "$format" in
            hyprlua) extension=lua ;;
            hyprlang) extension=conf ;;
            *) extension=css ;;
        esac
        [[ -s "$output_dir/$theme.$extension" ]]
    done
done

for theme in mamboorchelight mamboorchedark mambooutbacklight mambooutbackdark; do
    cmp "$TEST_ROOT/output/css/$theme.css" "$TEST_ROOT/output/tailwind/$theme.css"
done

"$TEST_ROOT/bin/mbcolour" ORCHEDARK HYPRLUA -o "$TEST_ROOT/compat" >/dev/null
[[ -s "$TEST_ROOT/compat/mamboorchedark.lua" ]]

mkdir -p "$TEST_ROOT/conflict"
printf 'keep\n' > "$TEST_ROOT/conflict/mbcolor"
if MAMBOCOLOUR_BIN_DIR="$TEST_ROOT/conflict" "$SCRIPT_DIR/install.sh" >/dev/null 2>&1; then
    echo "installer should refuse a non-symlink command target" >&2
    exit 1
fi
[[ "$(cat "$TEST_ROOT/conflict/mbcolor")" == "keep" ]]

echo "MamboColour CLI checks passed"
