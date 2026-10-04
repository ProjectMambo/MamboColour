#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

bash -n "$0"
cargo test --manifest-path "$PROJECT_DIR/Cargo.toml"
lua "$SCRIPT_DIR/test.lua" "$PROJECT_DIR"

echo "MamboColour API checks passed"
