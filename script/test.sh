#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
TEST_ROOT="$(mktemp -d /tmp/mambocolour-test.XXXXXX)"

bash -n "$SCRIPT_DIR/install.sh" "$SCRIPT_DIR/mambo_colour.sh" "$0"

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
if NO_COLOR=1 "$TEST_ROOT/bin/mbcolor" --help | grep -q $'\033'; then
    echo "NO_COLOR output should not contain ANSI escapes" >&2
    exit 1
fi
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

mkdir -p "$TEST_ROOT/symlink-conflict"
printf 'other\n' > "$TEST_ROOT/other-command"
ln -s "$TEST_ROOT/other-command" "$TEST_ROOT/symlink-conflict/mbcolor"
if MAMBOCOLOUR_BIN_DIR="$TEST_ROOT/symlink-conflict" "$SCRIPT_DIR/install.sh" >/dev/null 2>&1; then
    echo "installer should refuse a symlink owned by another command" >&2
    exit 1
fi
[[ "$(readlink -f "$TEST_ROOT/symlink-conflict/mbcolor")" == "$TEST_ROOT/other-command" ]]

MAMBOCOLOUR_BIN_DIR="$TEST_ROOT/bin" "$SCRIPT_DIR/install.sh" --uninstall >/dev/null
[[ ! -e "$TEST_ROOT/bin/mbcolor" && ! -L "$TEST_ROOT/bin/mbcolor" ]]
[[ ! -e "$TEST_ROOT/bin/mbcolour" && ! -L "$TEST_ROOT/bin/mbcolour" ]]

mkdir -p "$TEST_ROOT/invalid-project/script" "$TEST_ROOT/invalid-project/colours/mamboinvalid" "$TEST_ROOT/atomic"
cp "$SCRIPT_DIR/mambo_colour.sh" "$TEST_ROOT/invalid-project/script/mambo_colour.sh"
cat > "$TEST_ROOT/invalid-project/colours/mamboinvalid/mamboinvalid.csv" <<'EOF'
valid,112233,ff,base
broken,not-hex,ff,base
EOF
printf 'keep\n' > "$TEST_ROOT/atomic/mamboinvalid.css"
if "$TEST_ROOT/invalid-project/script/mambo_colour.sh" invalid css --out "$TEST_ROOT/atomic" >/dev/null 2>&1; then
    echo "generator should reject an invalid palette row" >&2
    exit 1
fi
[[ "$(cat "$TEST_ROOT/atomic/mamboinvalid.css")" == "keep" ]]

printf 'target\n' > "$TEST_ROOT/symlink-output-target"
ln -s "$TEST_ROOT/symlink-output-target" "$TEST_ROOT/atomic/mamboorchedark.css"
if "$SCRIPT_DIR/mambo_colour.sh" orchedark css --out "$TEST_ROOT/atomic" >/dev/null 2>&1; then
    echo "generator should refuse a symlink output target" >&2
    exit 1
fi
[[ "$(cat "$TEST_ROOT/symlink-output-target")" == "target" ]]

echo "MamboColour CLI checks passed"
