# MamboColour

<p align="left">
  <img src="https://img.shields.io/badge/Rust-000000?style=flat-square&logo=rust&logoColor=white" alt="Rust" />
  <img src="https://img.shields.io/badge/Lua-2C2D72?style=flat-square&logo=lua&logoColor=white" alt="Lua" />
  <img src="https://img.shields.io/badge/CSV-7289DA?style=flat-square" alt="CSV" />
</p>
<p align="left">
  <img src="https://img.shields.io/badge/Maintenance-Active-brightgreen?style=flat-square" alt="Maintenance status: active" />
  <img src="https://img.shields.io/github/last-commit/ProjectMambo/MamboColour?style=flat-square&color=7a5fff" alt="Last commit" />
  <img src="https://img.shields.io/github/repo-size/ProjectMambo/MamboColour?style=flat-square&color=yellow" alt="Repository size" />
  <a href="LICENSE"><img src="https://img.shields.io/github/license/ProjectMambo/MamboColour?style=flat-square&color=orange" alt="License" /></a>
</p>

MamboColour is Project Mambo's shared theme boundary. One MamboOrche family provides light and dark UI roles plus accent colours through matching zero-package-dependency Rust and Lua APIs.

## Motivation

Applications should ask for a foreground, surface, status, or varied accent without knowing a palette's descriptive colour names or maintaining generated CSS and Lua copies. MamboColour keeps the reviewed values in four small CSV files and owns the stable access behavior, leaving each consumer responsible only for mapping those results into its framework.

## Status

MamboColour is active and tested on Linux. The Rust crate is versioned as `0.2.0`; it is not published to a registry, and the Lua module is distributed from the same source checkout. There is no global command, generated-output interface, release artifact, or CI workflow.

The previous `mbcolor`/`mbcolour` generator and the separate MamboOrche and MamboOutback theme names have been removed. Consumers should pin a reviewed repository commit while there is no package release and migrate directly to one of the APIs.

## User stories

- As a UI consumer, I can request stable semantic roles such as `fg()` and `bg_surface()` without depending on concrete colour names.
- As a card-list consumer, I can call `random()` for a varied accent such as a card's top line.
- As a test or deterministic builder, I can call `random_seeded(seed)` and receive the same accent position in Rust and Lua.
- As a palette maintainer, I can review four application-neutral CSV files and validate both language interfaces with one gate.

## Getting started

Clone the source and run both API checks:

```bash
git clone https://github.com/ProjectMambo/MamboColour.git
cd MamboColour
./script/test.sh
```

For Rust, pin a reviewed Git commit in the consumer's `Cargo.toml`, then select a scheme and role:

```toml
[dependencies]
mambocolour = { git = "https://github.com/ProjectMambo/MamboColour.git", rev = "<MAMBOCOLOUR_COMMIT>" }
```

```rust
use mambocolour::{Scheme, theme};

let colours = theme(Scheme::Dark);
let foreground = colours.ui().fg().hex();
let card_line = colours.colour().random().hex();
```

For Lua, preserve the checkout's `lua/` and `palettes/` layout, add the module directory to `package.path`, and use the same model:

```lua
package.path = "vendor/MamboColour/lua/?.lua;" .. package.path
local mambocolour = require("mambocolour")

local colours = mambocolour.theme("dark")
local foreground = colours:ui():fg():hex()
local card_line = colours:colour():random():hex()
```

## Dependencies

MamboColour deliberately has no third-party Rust crates, Lua modules, services, or runtime sibling-repository dependencies. The palette data is owned by this repository.

| Dependency | Classification | Purpose | Provider, version pin, or source | Scope | Update path |
|---|---|---|---|---|---|
| Rust toolchain | Tool | Compile the crate and embed its CSV palettes | Rust `1.85` or newer, declared by `rust-version` in `Cargo.toml` | Build/test for Rust consumers and repository checks; built programs need no MamboColour files at runtime | Update `Cargo.toml`, compile on the minimum version, and run `./script/test.sh` |
| Rust standard library | Platform | Provide caching, time-based selection, atomics, and string parsing | Supplied by the selected Rust toolchain | Build/runtime for the Rust API; no external crate or network access | Review with any Rust minimum-version change |
| Lua runtime and standard libraries | Platform | Load CSV text and provide file, debug, string, number, clock, and entropy-fallback facilities | A `lua` executable with standard `debug`, `io`, `math`, `os`, and string libraries; validation currently uses Lua 5.5 | Runtime/test for the Lua API; no external Lua module or package manager | Run `script/test.lua` through `./script/test.sh` when changing the supported runtime |
| Bash and standard Unix utilities | Tool | Orchestrate the combined local validation gate | Linux environment used by `script/test.sh` | Maintainer only; neither library API invokes the shell | Update `script/test.sh` and this declaration together |

Rust consumers depend only on the compiled crate's public types; its four CSV files are embedded at compile time. Lua consumers need `lua/mambocolour.lua` and the repository-relative `palettes/mamboorche/` directory while the module loads. The module eagerly reads, validates, and caches all four files, so later working-directory changes or palette-file removal do not affect that loaded module instance.

## API

Both languages expose a theme with two parts:

```text
theme(light | dark)
├── ui()       role methods: fg(), bg(), brand(), success(), ...
└── colour()   random(), random_seeded(seed), len()
```

`Colour` values expose `hex()` and `rgb()`. UI role methods are the compatibility boundary; their concrete values may change with a palette revision. Accent keys are not exposed, so a descriptive key can change without forcing consumers to change. Accent order is significant because `random_seeded()` maps the same seed to the same position across Rust and Lua.

`random()` is for visual variation and is not cryptographically secure. Lua reads `/dev/urandom` when available and otherwise uses a module-local standard-library fallback without reading or modifying `math.random`; Rust uses process-local entropy. `random_seeded()` is for repeatable assignment and tests, accepts the shared `0..4294967295` seed domain, and does not alter shared PRNG state. See the [API reference](docs/API.md) for every role, language-specific signatures, file validation, and `0.1` migration guidance.

## Palettes

MamboOrche is one theme family with UI and general-colour layers in light and dark schemes:

| File | Consumer behavior |
|---|---|
| `palettes/mamboorche/ui-light.csv` | Light semantic UI roles |
| `palettes/mamboorche/ui-dark.csv` | Dark semantic UI roles |
| `palettes/mamboorche/colour-light.csv` | Light ordered accent pool |
| `palettes/mamboorche/colour-dark.csv` | Dark ordered accent pool |

Every file uses the `key,hex` schema. Both implementations require each UI file to contain the exact public role sequence and require the light and dark accent files to contain matching keys in matching order. UI keys are stable API roles. Colour keys are maintainer-readable identities; API consumers select their values through `random()` or `random_seeded()` rather than by name.

## Documentation

| Goal | Document or location |
|---|---|
| Read the canonical Wiki documentation | [projectmambo.org/mambocolour/](https://projectmambo.org/mambocolour/) |
| Integrate Rust or Lua | [API reference](docs/API.md) |
| Inspect authoritative data | [`palettes/mamboorche/`](palettes/mamboorche/) |
| Check package metadata and Rust minimum version | [`Cargo.toml`](Cargo.toml) |

## Project structure

```text
Cargo.toml                  Rust package metadata and minimum toolchain
src/lib.rs                  zero-third-party-crate Rust API
lua/mambocolour.lua         zero-third-party-module Lua API
palettes/mamboorche/        four authoritative UI/accent CSV files
script/test.lua             Lua API contract checks
script/test.sh              combined Rust and Lua validation gate
docs/                       synchronized detailed documentation
```

## Validation

The repository has focused local Rust and Lua checks but no CI or release workflow. Run these commands in order:

```bash
./script/test.sh
../MamboDocs/script/check-repository.sh --strict .
git diff --check
```

The first command runs Rust unit tests and Lua contract tests. It checks exact ordered UI roles, paired accent keys and order, stable role lookup, hexadecimal and RGB output, the shared 32-bit seeded-selection domain, unseeded Lua selection, and malformed-palette rejection.

## Development

Treat scheme names, UI role methods, colour return forms, seeded selection, CSV paths and schema, and accent ordering as public interfaces. A change to an accent's descriptive key does not affect random-only consumers, but changing the order changes seeded assignments. Keep the two UI files role-compatible and the two colour files key-and-order compatible.

MamboColour owns palette parsing and selection behavior, while consumers own CSS properties, Hyprland values, widget styles, and other framework mappings. Do not restore application-specific generators to this provider boundary.

Author documentation in `notes/Docs/Projects/MamboColour/`, update page metadata, then run `node Scripts/sync_docs.js --sync MamboColour MamboWiki` from `notes/`. Review the root README and complete `docs/` replacement before committing.

These palettes are maintained for Project Mambo, so external pull requests are not currently requested. Bug reports and API suggestions are welcome as repository issues.

## License

Distributed under the MIT License. See **[LICENSE](LICENSE)** for details.
