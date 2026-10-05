---
title: API reference
description: Consume MamboOrche through the equivalent Rust and Lua theme APIs.
order: 10
---

::page{layout="docs" width="normal" sidebar=true}

# API reference

MamboColour exposes one model in Rust and Lua. Select a light or dark MamboOrche theme, use stable role methods for interface colours, and ask the colour palette to choose an accent. Consumers do not depend on accent names or generated language-specific files.

## Shared model

```text
theme(light | dark)
├── ui()       stable semantic roles such as fg() and bg()
└── colour()   ordered accent pool with get(), random(), and random_seeded()
```

Every successful lookup returns a `Colour`. Its hexadecimal form includes a leading `#` and uses lowercase digits. RGB conversion returns channels from `0` through `255`.

The two implementations intentionally agree on scheme names, role names, CSV validation, accent order, the inclusive `0..4294967295` seed domain, and seeded selection. Their language-native details differ:

| Operation | Rust | Lua |
|---|---|---|
| Select theme | `theme(Scheme::Light)` or `theme(Scheme::Dark)` | `theme("light")` or `theme("dark")` |
| Read UI palette | `theme.ui()` | `theme:ui()` |
| Read colour palette | `theme.colour()` | `theme:colour()` |
| Hex output | `colour.hex() -> &str` | `colour:hex() -> string` |
| RGB output | `colour.rgb() -> [u8; 3]` | `colour:rgb() -> red, green, blue` |
| Positional colour | `palette.get(index) -> Option<Colour>` | `palette:get(index) -> Colour or nil` |
| Accent count | `palette.len()` | `palette:len()` |
| Empty check | `palette.is_empty()` | Not exposed; validated palettes cannot be empty |

## Rust API

The crate is not published to a registry. Pin a reviewed Git revision in the consumer's `Cargo.toml`:

```toml
[dependencies]
mambocolour = { git = "https://github.com/ProjectMambo/MamboColour.git", rev = "<MAMBOCOLOUR_COMMIT>" }
```

During coordinated local development, the dependency may temporarily use a sibling checkout:

```toml
[dependencies]
mambocolour = { path = "../MamboColour" }
```

Use the crate from application code:

```rust
use mambocolour::{Scheme, theme};

let palette = theme(Scheme::Dark);
let foreground = palette.ui().fg();
let first_accent = palette.colour().get(0).expect("palette is not empty");
let card_accent = palette.colour().random();
let fixture_accent = palette.colour().random_seeded(42);

assert_eq!(foreground.hex(), "#faf7f2");
assert_eq!(foreground.rgb(), [250, 247, 242]);
assert_eq!(first_accent.hex(), "#ff6b57");
assert_eq!(fixture_accent, palette.colour().random_seeded(42));
println!("{}", card_accent.hex());
```

The crate root exposes these public types and functions:

| Item | Contract |
|---|---|
| `Scheme::{Light, Dark}` | Selects one of the two schemes. |
| `theme(Scheme) -> &'static Theme` | On first access, validates and caches both bundled schemes together, then returns the requested process-wide theme. |
| `Theme::ui() -> &UiPalette` | Returns the semantic interface palette. |
| `Theme::colour() -> &ColourPalette` | Returns the accent pool. |
| `Colour::hex() -> &'static str` | Returns `#rrggbb`. |
| `Colour::rgb() -> [u8; 3]` | Returns red, green, and blue byte values. |
| `ColourPalette::get(usize) -> Option<Colour>` | Returns one zero-based accent position, or `None` when it is out of range. |
| `ColourPalette::random()` | Selects an accent using time and a process-local counter. |
| `ColourPalette::random_seeded(u32)` | Selects an accent reproducibly without changing shared random state. |
| `ColourPalette::len()` | Returns the number of accents. |
| `ColourPalette::is_empty()` | Reports whether the pool is empty; bundled data validation guarantees `false`. |

Rust embeds the CSV files at compile time with `include_str!`. The first `theme()` call parses all four bundled CSVs, verifies the exact ordered UI roles and paired accent keys and order, and caches both themes together. Palette edits therefore take effect after rebuilding the consuming binary; the compiled program performs no palette file I/O.

## Lua API

Keep `lua/mambocolour.lua` and `palettes/mamboorche/` in their repository-relative locations. A vendored checkout or Git submodule preserves that layout. Add the module directory to `package.path`, then require it:

```lua
package.path = "vendor/MamboColour/lua/?.lua;" .. package.path
local mambocolour = require("mambocolour")

local palette = mambocolour.theme("dark")
local foreground = palette:ui():fg()
local first_accent = palette:colour():get(0)
local card_accent = palette:colour():random()
local fixture_accent = palette:colour():random_seeded(42)

assert(foreground:hex() == "#faf7f2")
assert(first_accent:hex() == "#ff6b57")
local red, green, blue = foreground:rgb()
assert(red == 250 and green == 247 and blue == 242)
assert(fixture_accent:hex() == palette:colour():random_seeded(42):hex())
print(card_accent:hex())
```

The Lua module eagerly reads and validates all four CSV files as `require("mambocolour")` loads, then returns a table with `theme(scheme)`. It accepts only `"light"` and `"dark"` and caches both resulting themes for the lifetime of the loaded module. Later working-directory changes or palette-file moves and removals are safe for that loaded instance; restart the process or reload the module from a complete layout to observe palette edits.

`get(index)` requires a non-negative integer, uses a zero-based index like Rust, and returns `nil` at or beyond `len()`. `random()` reads four bytes from `/dev/urandom` when that device is available. Otherwise it combines module-local counter, clock, time, and table-identity inputs using only the Lua standard library. It never reads, seeds, or modifies the application's `math.random` state. `random_seeded(seed)` accepts an integer from `0` through `4294967295`, applies MamboColour's own mapping, and likewise leaves `math.random` untouched.

## UI roles

The UI palette exposes the same methods in Rust and Lua. These role names are the stable boundary; concrete hexadecimal values may evolve while a consumer continues to ask for the same purpose.

| Method | Intended use |
|---|---|
| `bg()` | Main application or page background |
| `bg_surface()` | Raised panel, card, or secondary surface |
| `border()` | Dividers and component outlines |
| `fg()` | Primary foreground text and icons |
| `fg_muted()` | Secondary foreground content |
| `fg_subtle()` | Lowest-emphasis readable foreground content |
| `brand()` | Primary branded action or accent |
| `brand_hover()` | Hovered branded action |
| `brand_active()` | Pressed or active branded action |
| `on_brand()` | Foreground content placed on `brand()` |
| `selection()` | Selected-item or selection highlight |
| `focus()` | Keyboard or input focus indicator |
| `interactive()` | Neutral interactive control |
| `interactive_hover()` | Hovered neutral interactive control |
| `success()` | Successful or positive state |
| `warning()` | Warning or caution state |
| `error()` | Error or destructive state |

Applications own the mapping from these roles into framework-specific CSS, Hyprland, terminal, or widget properties. MamboColour deliberately does not generate those files.

## Accent selection

`colour()` returns the 21-value accent palette for the selected scheme. It does not expose lookup by accent key, so consumers stay independent from descriptive accent-name changes.

- Use `get(index)` with `len()` to read one direct colour or enumerate the whole ordered palette. Indexes are zero-based in both languages, and the same index selects paired light and dark values.
- Use `random()` for visual variety such as a card's top rule.
- Use `random_seeded(seed)` when a stable input must receive a stable accent.
- Pass an integer from `0` through `4294967295`; Rust expresses the shared domain as `u32`, while Lua validates the same bounds at runtime.
- The same seed selects the same position in Rust and Lua when the scheme and palette revision are identical.
- Light and dark files keep matching keys in matching order, so one seed selects corresponding accents across schemes.
- Changing accent order changes direct positions and seeded results and must be reviewed as a compatibility change.

Neither random method is suitable for cryptography, secrets, security decisions, or statistically rigorous sampling.

## Palette files

MamboOrche is one family with two layers and two schemes:

| File | Purpose |
|---|---|
| `palettes/mamboorche/ui-light.csv` | Semantic UI roles for the light scheme |
| `palettes/mamboorche/ui-dark.csv` | Semantic UI roles for the dark scheme |
| `palettes/mamboorche/colour-light.csv` | Ordered accent pool for the light scheme |
| `palettes/mamboorche/colour-dark.csv` | Ordered accent pool for the dark scheme |

Each file is UTF-8 text. Its first non-blank, non-comment line must be exactly:

```csv
key,hex
```

Every later data row has exactly two comma-separated fields:

```csv
descriptive_key,#a1b2c3
```

The schema contract is:

- blank lines and lines whose first non-whitespace character is `#` are ignored;
- `key` starts with `a` through `z`, followed only by lowercase letters, digits, or `_`;
- `hex` is exactly `#` followed by six lowercase hexadecimal digits;
- fields do not contain surrounding whitespace or additional commas;
- keys are unique within one file;
- every file contains at least one data row;
- each UI file provides exactly the role set listed above in that documented order;
- the two colour files use matching keys in matching order.

Invalid bundled Rust data panics when either scheme is first requested because both themes initialize together. Invalid Lua data raises an assertion while the module loads because all four files initialize together. `./script/test.sh` validates both implementations and verifies the exact UI-role and paired accent-order contracts.

## Migrating from `0.2`

MamboColour `0.3.0` adds zero-based `get(index)` to both APIs. Existing `0.2` consumers continue to compile and behave unchanged after repinning. Use `get()` only when a consumer needs a direct position or complete ordered enumeration; continue using UI roles for semantic interface states and the random methods for one-off decorative selection.

## Migrating from `0.1`

MamboColour `0.2.0` narrows the explicit seeded-selection contract to the shared 32-bit domain. Integer literals and Rust values already typed as `u32` continue to work unchanged.

- Rust callers that passed a `u64` must either reject values above `u32::MAX` or deliberately reduce the old value modulo `2^32` before conversion. Modulo reduction preserves `0.1`'s seeded position because that release applied the same reduction internally.
- Lua callers must now pass an integer from `0` through `4294967295`. If a `0.1` caller intentionally used a larger exactly represented value, reduce it with `seed % 4294967296` before calling the API to preserve its prior position.
- Lua applications no longer control MamboColour's unseeded selection through `math.randomseed()`. Use `random_seeded()` when application-controlled repeatability is required.
- Lua now reports malformed data when the module loads rather than waiting until a scheme is first requested. Keep all four CSV files beside the module for loading even when an application uses only one scheme.

## Migration from the generator

The `mbcolor` and `mbcolour` aliases, installer, generator, four former palette directories, and generated Hyprland/CSS/Lua formats have been removed. Migrate a consumer by:

1. pinning or vendoring the MamboColour revision it has reviewed;
2. selecting the Rust or Lua API at one consumer-owned adapter boundary;
3. replacing direct UI token access with semantic role methods;
4. replacing decorative accent-name access with zero-based `get()`, `random()`, or `random_seeded()` according to whether the consumer needs enumeration, fresh variety, or repeatability; and
5. deleting generator invocations and generated snapshots that no remaining interface consumes.

MamboColour no longer installs a global command and creates no generated files. Removing it means deleting the consumer's dependency or vendored checkout after that consumer stops importing the API.

## Verification

From a MamboColour checkout, run:

```bash
./script/test.sh
../MamboDocs/script/check-repository.sh --strict .
git diff --check
```

The focused gate runs Rust unit tests and the Lua contract test. It requires the Rust toolchain and a `lua` executable and is not currently run by CI.
