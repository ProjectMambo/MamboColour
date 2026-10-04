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
└── colour()   ordered accent pool with random() and random_seeded()
```

Every lookup returns a `Colour`. Its hexadecimal form includes a leading `#` and uses lowercase digits. RGB conversion returns channels from `0` through `255`.

The two implementations intentionally agree on scheme names, role names, CSV validation, accent order, and seeded selection. Their language-native details differ:

| Operation | Rust | Lua |
|---|---|---|
| Select theme | `theme(Scheme::Light)` or `theme(Scheme::Dark)` | `theme("light")` or `theme("dark")` |
| Read UI palette | `theme.ui()` | `theme:ui()` |
| Read colour palette | `theme.colour()` | `theme:colour()` |
| Hex output | `colour.hex() -> &str` | `colour:hex() -> string` |
| RGB output | `colour.rgb() -> [u8; 3]` | `colour:rgb() -> red, green, blue` |
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
let card_accent = palette.colour().random();
let fixture_accent = palette.colour().random_seeded(42);

assert_eq!(foreground.hex(), "#faf7f2");
assert_eq!(foreground.rgb(), [250, 247, 242]);
assert_eq!(fixture_accent, palette.colour().random_seeded(42));
println!("{}", card_accent.hex());
```

The crate root exposes these public types and functions:

| Item | Contract |
|---|---|
| `Scheme::{Light, Dark}` | Selects one of the two schemes. |
| `theme(Scheme) -> &'static Theme` | Lazily parses and caches one process-wide theme per scheme. |
| `Theme::ui() -> &UiPalette` | Returns the semantic interface palette. |
| `Theme::colour() -> &ColourPalette` | Returns the accent pool. |
| `Colour::hex() -> &'static str` | Returns `#rrggbb`. |
| `Colour::rgb() -> [u8; 3]` | Returns red, green, and blue byte values. |
| `ColourPalette::random()` | Selects an accent using time and a process-local counter. |
| `ColourPalette::random_seeded(u64)` | Selects an accent reproducibly without changing shared random state. |
| `ColourPalette::len()` | Returns the number of accents. |
| `ColourPalette::is_empty()` | Reports whether the pool is empty; bundled data validation guarantees `false`. |

Rust embeds the CSV files at compile time with `include_str!`. Palette edits therefore take effect after rebuilding the consuming binary; the compiled program performs no palette file I/O.

## Lua API

Keep `lua/mambocolour.lua` and `palettes/mamboorche/` in their repository-relative locations. A vendored checkout or Git submodule preserves that layout. Add the module directory to `package.path`, then require it:

```lua
package.path = "vendor/MamboColour/lua/?.lua;" .. package.path
local mambocolour = require("mambocolour")

local palette = mambocolour.theme("dark")
local foreground = palette:ui():fg()
local card_accent = palette:colour():random()
local fixture_accent = palette:colour():random_seeded(42)

assert(foreground:hex() == "#faf7f2")
local red, green, blue = foreground:rgb()
assert(red == 250 and green == 247 and blue == 242)
assert(fixture_accent:hex() == palette:colour():random_seeded(42):hex())
print(card_accent:hex())
```

The Lua module returns a table with `theme(scheme)`. It accepts only `"light"` and `"dark"`, reads both files for that scheme on first use, and caches the resulting theme for the lifetime of the loaded module. Restart the process or reload the module to observe palette edits.

`random()` uses the Lua runtime's `math.random` state. Applications may manage that state with the runtime's normal facilities. `random_seeded(seed)` accepts a non-negative integer, applies MamboColour's own mapping, and does not consume or modify `math.random` state.

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

- Use `random()` for visual variety such as a card's top rule.
- Use `random_seeded(seed)` when a stable input must receive a stable accent.
- The same seed selects the same position in Rust and Lua when the scheme and palette revision are identical.
- Light and dark files keep matching keys in matching order, so one seed selects corresponding accents across schemes.
- Changing accent order changes seeded results and must be reviewed as a compatibility change.

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
- the two UI files provide the complete role set listed above;
- the two colour files use matching keys in matching order.

Invalid bundled Rust data panics when that scheme is first initialized. Invalid Lua data raises an assertion while loading the scheme. `./script/test.sh` validates both implementations and verifies the cross-scheme role and accent ordering contract.

## Migration from the generator

The `mbcolor` and `mbcolour` aliases, installer, generator, four former palette directories, and generated Hyprland/CSS/Lua formats have been removed. Migrate a consumer by:

1. pinning or vendoring the MamboColour revision it has reviewed;
2. selecting the Rust or Lua API at one consumer-owned adapter boundary;
3. replacing direct UI token access with semantic role methods;
4. replacing decorative accent-name or index access with `random()` or `random_seeded()`; and
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
