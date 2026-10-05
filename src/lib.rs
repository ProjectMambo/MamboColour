//! Native access to the `MamboOrche` UI and accent palettes.

use std::sync::OnceLock;
use std::sync::atomic::{AtomicU32, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};

const UI_LIGHT: &str = include_str!("../palettes/mamboorche/ui-light.csv");
const UI_DARK: &str = include_str!("../palettes/mamboorche/ui-dark.csv");
const COLOUR_LIGHT: &str = include_str!("../palettes/mamboorche/colour-light.csv");
const COLOUR_DARK: &str = include_str!("../palettes/mamboorche/colour-dark.csv");
const UI_ROLES: &[&str] = &[
    "bg",
    "bg_surface",
    "border",
    "fg",
    "fg_muted",
    "fg_subtle",
    "brand",
    "brand_hover",
    "brand_active",
    "on_brand",
    "selection",
    "focus",
    "interactive",
    "interactive_hover",
    "success",
    "warning",
    "error",
];

static THEMES: OnceLock<(Theme, Theme)> = OnceLock::new();
static RANDOM_COUNTER: AtomicU32 = AtomicU32::new(0);

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum Scheme {
    Light,
    Dark,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct Colour(&'static str);

impl Colour {
    #[must_use]
    pub const fn hex(self) -> &'static str {
        self.0
    }

    #[must_use]
    pub fn rgb(self) -> [u8; 3] {
        let value = self.0.as_bytes();
        [
            channel(value[1], value[2]),
            channel(value[3], value[4]),
            channel(value[5], value[6]),
        ]
    }
}

#[derive(Debug)]
pub struct Theme {
    ui: UiPalette,
    colour: ColourPalette,
}

impl Theme {
    #[must_use]
    pub const fn ui(&self) -> &UiPalette {
        &self.ui
    }

    #[must_use]
    pub const fn colour(&self) -> &ColourPalette {
        &self.colour
    }
}

#[derive(Debug)]
pub struct UiPalette(Vec<(&'static str, Colour)>);

macro_rules! roles {
    ($($name:ident),+ $(,)?) => {
        impl UiPalette {
            $(
                #[must_use]
                pub fn $name(&self) -> Colour {
                    self.get(stringify!($name))
                }
            )+
        }
    };
}

roles!(
    bg,
    bg_surface,
    border,
    fg,
    fg_muted,
    fg_subtle,
    brand,
    brand_hover,
    brand_active,
    on_brand,
    selection,
    focus,
    interactive,
    interactive_hover,
    success,
    warning,
    error,
);

impl UiPalette {
    fn get(&self, role: &str) -> Colour {
        self.0
            .iter()
            .find_map(|(name, colour)| (*name == role).then_some(*colour))
            .unwrap_or_else(|| panic!("bundled UI palette is missing role {role}"))
    }
}

#[derive(Debug)]
pub struct ColourPalette(Vec<Colour>);

impl ColourPalette {
    /// Chooses a palette colour using process-local entropy.
    #[must_use]
    pub fn random(&self) -> Colour {
        let time = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map_or(0, |duration| {
                let seconds = duration.as_secs().to_le_bytes();
                let folded_seconds =
                    u32::from_le_bytes([seconds[0], seconds[1], seconds[2], seconds[3]])
                        ^ u32::from_le_bytes([seconds[4], seconds[5], seconds[6], seconds[7]]);
                folded_seconds ^ duration.subsec_nanos()
            });
        self.random_seeded(time ^ RANDOM_COUNTER.fetch_add(1, Ordering::Relaxed))
    }

    /// Chooses a palette colour reproducibly across the shared 32-bit Rust/Lua seed domain.
    #[must_use]
    pub fn random_seeded(&self, seed: u32) -> Colour {
        self.0[seeded_index(seed, self.0.len())]
    }

    #[must_use]
    pub fn len(&self) -> usize {
        self.0.len()
    }

    #[must_use]
    pub fn is_empty(&self) -> bool {
        self.0.is_empty()
    }
}

/// Returns the bundled `MamboOrche` theme for one colour scheme.
#[must_use]
pub fn theme(scheme: Scheme) -> &'static Theme {
    let themes = THEMES.get_or_init(load);
    match scheme {
        Scheme::Light => &themes.0,
        Scheme::Dark => &themes.1,
    }
}

fn load() -> (Theme, Theme) {
    load_pair(UI_LIGHT, UI_DARK, COLOUR_LIGHT, COLOUR_DARK)
}

fn load_pair(
    ui_light: &'static str,
    ui_dark: &'static str,
    colour_light: &'static str,
    colour_dark: &'static str,
) -> (Theme, Theme) {
    let ui_light = parse(ui_light);
    let ui_dark = parse(ui_dark);
    assert_eq!(
        keys(&ui_light),
        UI_ROLES,
        "bundled light UI palette roles do not match the public API"
    );
    assert_eq!(
        keys(&ui_dark),
        UI_ROLES,
        "bundled dark UI palette roles do not match the public API"
    );

    let colour_light = parse(colour_light);
    let colour_dark = parse(colour_dark);
    assert_eq!(
        keys(&colour_light),
        keys(&colour_dark),
        "bundled accent palette keys and order do not match"
    );

    (
        Theme {
            ui: UiPalette(ui_light),
            colour: ColourPalette(colours(colour_light)),
        },
        Theme {
            ui: UiPalette(ui_dark),
            colour: ColourPalette(colours(colour_dark)),
        },
    )
}

fn keys(rows: &[(&'static str, Colour)]) -> Vec<&'static str> {
    rows.iter().map(|(key, _)| *key).collect()
}

fn colours(rows: Vec<(&'static str, Colour)>) -> Vec<Colour> {
    rows.into_iter().map(|(_, colour)| colour).collect()
}

fn parse(source: &'static str) -> Vec<(&'static str, Colour)> {
    let mut lines = source
        .lines()
        .map(str::trim)
        .filter(|line| !line.is_empty() && !line.starts_with('#'));
    assert_eq!(lines.next(), Some("key,hex"), "invalid palette header");

    let mut rows = Vec::new();
    for line in lines {
        let (key, hex) = line
            .split_once(',')
            .unwrap_or_else(|| panic!("invalid palette row: {line}"));
        assert!(!hex.contains(','), "invalid palette row: {line}");
        assert!(valid_key(key), "invalid palette key: {key}");
        assert!(valid_hex(hex), "invalid palette colour: {hex}");
        assert!(
            rows.iter().all(|(existing, _)| *existing != key),
            "duplicate palette key: {key}"
        );
        rows.push((key, Colour(hex)));
    }
    assert!(!rows.is_empty(), "palette must not be empty");
    rows
}

fn valid_key(value: &str) -> bool {
    let mut bytes = value.bytes();
    matches!(bytes.next(), Some(b'a'..=b'z'))
        && bytes.all(|byte| byte.is_ascii_lowercase() || byte.is_ascii_digit() || byte == b'_')
}

fn valid_hex(value: &str) -> bool {
    value.len() == 7
        && value.starts_with('#')
        && value[1..]
            .bytes()
            .all(|byte| byte.is_ascii_digit() || (b'a'..=b'f').contains(&byte))
}

fn channel(high: u8, low: u8) -> u8 {
    (nibble(high) << 4) | nibble(low)
}

fn nibble(value: u8) -> u8 {
    match value {
        b'0'..=b'9' => value - b'0',
        b'a'..=b'f' => value - b'a' + 10,
        _ => unreachable!("validated hex contains only lowercase digits"),
    }
}

fn seeded_index(seed: u32, length: usize) -> usize {
    let mixed = seed.wrapping_mul(1_664_525).wrapping_add(1_013_904_223);
    usize::try_from(mixed % u32::try_from(length).expect("palette length fits u32"))
        .expect("palette index fits usize")
}

#[cfg(test)]
mod tests {
    use super::{
        COLOUR_DARK, COLOUR_LIGHT, Colour, Scheme, UI_DARK, UI_LIGHT, UI_ROLES, keys, load_pair,
        parse, theme,
    };

    #[test]
    fn schemes_have_matching_roles_and_colour_order() {
        assert_eq!(keys(&parse(UI_LIGHT)), keys(&parse(UI_DARK)));
        assert_eq!(keys(&parse(UI_LIGHT)), UI_ROLES);
        assert_eq!(keys(&parse(COLOUR_LIGHT)), keys(&parse(COLOUR_DARK)));
    }

    #[test]
    #[should_panic(expected = "bundled accent palette keys and order do not match")]
    fn paired_loader_rejects_mismatched_accent_order() {
        load_pair(
            UI_LIGHT,
            UI_DARK,
            "key,hex\nfirst,#000000\nsecond,#111111",
            "key,hex\nsecond,#111111\nfirst,#000000",
        );
    }

    #[test]
    fn roles_and_seeded_random_are_stable() {
        let dark = theme(Scheme::Dark);
        let light = theme(Scheme::Light);

        assert_eq!(dark.ui().fg().hex(), "#faf7f2");
        assert_eq!(light.ui().fg().rgb(), [28, 17, 17]);
        assert_eq!(dark.colour().len(), 21);
        assert_eq!(dark.colour().random_seeded(42).hex(), "#a2b088");
        assert_eq!(light.colour().random_seeded(42).hex(), "#738763");
        assert_eq!(dark.colour().random_seeded(u32::MAX).hex(), "#bd8f42");
        assert_ne!(
            dark.colour().random_seeded(42).hex(),
            dark.colour().random_seeded(43).hex()
        );
    }

    #[test]
    fn semantic_roles_meet_contrast_targets() {
        for scheme in [Scheme::Light, Scheme::Dark] {
            let ui = theme(scheme).ui();
            for foreground in [ui.fg(), ui.fg_muted(), ui.fg_subtle()] {
                assert_contrast(foreground, ui.bg(), 4.5);
                assert_contrast(foreground, ui.bg_surface(), 4.5);
            }
            for indicator in [
                ui.selection(),
                ui.focus(),
                ui.interactive(),
                ui.interactive_hover(),
                ui.success(),
                ui.warning(),
                ui.error(),
            ] {
                assert_contrast(indicator, ui.bg(), 3.0);
                assert_contrast(indicator, ui.bg_surface(), 3.0);
            }
            for brand in [ui.brand(), ui.brand_hover(), ui.brand_active()] {
                assert_contrast(ui.on_brand(), brand, 4.5);
            }
        }
    }

    #[test]
    fn random_colours_remain_visible_on_their_background() {
        for scheme in [Scheme::Light, Scheme::Dark] {
            let theme = theme(scheme);
            for colour in &theme.colour().0 {
                assert!(
                    contrast(*colour, theme.ui().bg()) >= 3.0,
                    "{} is not visible on {}",
                    colour.hex(),
                    theme.ui().bg().hex()
                );
            }
        }
    }

    fn contrast(first: Colour, second: Colour) -> f64 {
        let (first, second) = (luminance(first), luminance(second));
        (first.max(second) + 0.05) / (first.min(second) + 0.05)
    }

    fn assert_contrast(first: Colour, second: Colour, minimum: f64) {
        assert!(
            contrast(first, second) >= minimum,
            "{} against {} does not meet {minimum}:1 contrast",
            first.hex(),
            second.hex()
        );
    }

    fn luminance(colour: Colour) -> f64 {
        let channels = colour.rgb().map(|channel| {
            let channel = f64::from(channel) / 255.0;
            if channel <= 0.040_45 {
                channel / 12.92
            } else {
                ((channel + 0.055) / 1.055).powf(2.4)
            }
        });
        0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]
    }
}
