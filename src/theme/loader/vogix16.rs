//! vogix16 theme color loader
//!
//! Loads colors from vogix16 TOML files and generates semantic color mappings.
//!
//! File format:
//! ```toml
//! polarity = "dark"
//! [colors]
//! base00 = "#262626"
//! base01 = "#333333"
//! ...
//! ```

use crate::errors::{Result, VogixError};
use serde::Deserialize;
use std::collections::HashMap;
use std::path::Path;

/// Internal struct for parsing vogix16 TOML files.
/// Only `colors` is needed; serde ignores other fields in the TOML.
#[derive(Deserialize)]
struct Vogix16Theme {
    colors: HashMap<String, String>,
}

/// Semantic color mapping from base16 colors to named colors
const SEMANTIC_MAPPINGS: &[(&str, &str)] = &[
    // Monochromatic scale
    ("base00", "background"),
    ("base01", "background_surface"),
    ("base02", "background_selection"),
    ("base03", "foreground_comment"),
    ("base04", "foreground_border"),
    ("base05", "foreground_text"),
    ("base06", "foreground_heading"),
    ("base07", "foreground_bright"),
    // Functional colors
    ("base08", "success"),
    ("base09", "warning"),
    ("base0A", "notice"),
    ("base0B", "danger"),
    ("base0C", "active"),
    ("base0D", "link"),
    ("base0E", "highlight"),
    ("base0F", "special"),
];

/// Load colors from a vogix16 theme file
///
/// Returns base colors plus semantic mappings (e.g., "background", "foreground_text")
pub fn load(content: &str, _path: &Path) -> Result<HashMap<String, String>> {
    let theme: Vogix16Theme = toml::from_str(content).map_err(VogixError::TomlParse)?;

    // Start with base colors
    let mut colors = theme.colors.clone();

    // Add semantic color mappings
    for (base_color, semantic_name) in SEMANTIC_MAPPINGS {
        if let Some(v) = theme.colors.get(*base_color) {
            colors.insert(semantic_name.to_string(), v.clone());
        }
    }

    Ok(colors)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_load_vogix16_colors() {
        let content = r##"polarity = "dark"

[colors]
base00 = "#262626"
base01 = "#333333"
base02 = "#3b3028"
base03 = "#54433a"
base04 = "#6c5d53"
base05 = "#a29990"
base06 = "#cbc3bc"
base07 = "#f6f5f0"
base08 = "#4d5645"
base09 = "#835538"
base0A = "#bfa46f"
base0B = "#d7503c"
base0C = "#8694a8"
base0D = "#658fbd"
base0E = "#896ea4"
base0F = "#7a5c42"
"##;

        let colors = load(content, Path::new("test.toml")).unwrap();

        // Check base colors exist
        assert_eq!(colors.get("base00"), Some(&"#262626".to_string()));
        assert_eq!(colors.get("base0F"), Some(&"#7a5c42".to_string()));

        // Check semantic mappings
        assert_eq!(colors.get("background"), Some(&"#262626".to_string()));
        assert_eq!(colors.get("foreground_text"), Some(&"#a29990".to_string()));
        assert_eq!(colors.get("danger"), Some(&"#d7503c".to_string()));
    }

    #[test]
    fn test_load_invalid_toml() {
        let result = load("not valid toml {{", Path::new("test.toml"));
        assert!(result.is_err());
    }

    #[test]
    fn test_semantic_mappings_count() {
        // Ensure we have all 16 semantic mappings
        assert_eq!(SEMANTIC_MAPPINGS.len(), 16);
    }
}
