#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

bash -n "$0"
cargo test --manifest-path "$PROJECT_DIR/Cargo.toml"

TEST_DIR="$(mktemp -d /tmp/mambocolour-test.XXXXXX)"
if [[ "$TEST_DIR" != /tmp/mambocolour-test.* || ! -d "$TEST_DIR" ]]; then
    echo "refusing unsafe test directory: $TEST_DIR" >&2
    exit 1
fi

cleanup() {
    if [[ "$TEST_DIR" == /tmp/mambocolour-test.* && -d "$TEST_DIR" ]]; then
        rm -rf -- "$TEST_DIR"
    fi
}
trap cleanup EXIT

copy_fixture() {
    local fixture="$1"
    mkdir -p "$fixture/lua" "$fixture/palettes"
    cp "$PROJECT_DIR/lua/mambocolour.lua" "$fixture/lua/"
    cp -R "$PROJECT_DIR/palettes/mamboorche" "$fixture/palettes/"
}

swap_first_rows() {
    local path="$1"
    awk 'NR == 2 { first = $0; next } NR == 3 { print; print first; next } { print }' \
        "$path" > "$path.reordered"
    mv "$path.reordered" "$path"
}

expect_load_error() {
    local runtime="$1"
    local fixture="$2"
    local message="$3"
    "$runtime" "$SCRIPT_DIR/test.lua" "$fixture" expect-load-error "$message"
}

test_lua_runtime() {
    local runtime="$1"
    local runtime_dir="$TEST_DIR/$(basename "$runtime")"

    "$runtime" "$SCRIPT_DIR/test.lua" "$PROJECT_DIR"

    local fixture="$runtime_dir/detached"
    copy_fixture "$fixture"
    "$runtime" "$SCRIPT_DIR/test.lua" "$fixture" detach-palettes

    fixture="$runtime_dir/missing-ui-role"
    copy_fixture "$fixture"
    sed -i '/^warning,/d' "$fixture/palettes/mamboorche/ui-light.csv"
    expect_load_error "$runtime" "$fixture" "light UI palette keys do not match"

    fixture="$runtime_dir/extra-ui-role"
    copy_fixture "$fixture"
    printf 'extra,#000000\n' >> "$fixture/palettes/mamboorche/ui-light.csv"
    expect_load_error "$runtime" "$fixture" "light UI palette keys do not match"

    fixture="$runtime_dir/reordered-ui-roles"
    copy_fixture "$fixture"
    swap_first_rows "$fixture/palettes/mamboorche/ui-light.csv"
    expect_load_error "$runtime" "$fixture" "light UI palette keys or order do not match"

    fixture="$runtime_dir/mismatched-accent-count"
    copy_fixture "$fixture"
    sed -i '$d' "$fixture/palettes/mamboorche/colour-dark.csv"
    expect_load_error "$runtime" "$fixture" "accent palettes keys do not match"

    fixture="$runtime_dir/reordered-accents"
    copy_fixture "$fixture"
    swap_first_rows "$fixture/palettes/mamboorche/colour-dark.csv"
    expect_load_error "$runtime" "$fixture" "accent palettes keys or order do not match"
}

test_lua_runtime lua
if command -v luajit >/dev/null; then
    test_lua_runtime luajit
fi

echo "MamboColour API checks passed"
