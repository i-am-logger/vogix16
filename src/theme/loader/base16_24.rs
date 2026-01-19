//! base16/base24 theme color loader
//!
//! Loads colors from base16 and base24 YAML files.
//! Both formats use the same structure with a `palette` section.
//!
//! File format:
//! ```yaml
//! system: "base16"  # or "base24"
//! name: "Theme Name"
//! variant: "dark"
//! palette:
//!   base00: "#1e1e2e"
//!   base01: "#181825"
//!   ...
//! ```
//!
//! base16 defines base00-base0F (16 colors)
//! base24 extends this with base10-base17 (24 colors total)

use crate::errors::{Result, VogixError};
use serde::Deserialize;
use std::collections::HashMap;
use std::path::Path;

/// Internal struct for parsing base16/base24 YAML files.
/// Only `palette` is needed; serde ignores other fields in the YAML.
#[derive(Deserialize)]
struct Base16Theme {
    palette: HashMap<String, String>,
}

/// Load colors from a base16 or base24 theme file
///
/// Returns the palette colors as-is (base00-base0F for base16, plus base10-base17 for base24)
pub fn load(content: &str, _path: &Path) -> Result<HashMap<String, String>> {
    let theme: Base16Theme = serde_yaml::from_str(content).map_err(VogixError::YamlParse)?;

    Ok(theme.palette)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_load_base16_colors() {
        let content = r##"system: "base16"
name: "Test Theme"
variant: "dark"
palette:
  base00: "#1e1e2e"
  base01: "#181825"
  base02: "#313244"
  base03: "#45475a"
  base04: "#585b70"
  base05: "#cdd6f4"
  base06: "#f5e0dc"
  base07: "#b4befe"
  base08: "#f38ba8"
  base09: "#fab387"
  base0A: "#f9e2af"
  base0B: "#a6e3a1"
  base0C: "#94e2d5"
  base0D: "#89b4fa"
  base0E: "#cba6f7"
  base0F: "#f2cdcd"
"##;

        let colors = load(content, Path::new("test.yaml")).unwrap();

        assert_eq!(colors.get("base00"), Some(&"#1e1e2e".to_string()));
        assert_eq!(colors.get("base0F"), Some(&"#f2cdcd".to_string()));
        assert_eq!(colors.len(), 16);
    }

    #[test]
    fn test_load_base24_colors() {
        let content = r##"system: "base24"
name: "Test Theme"
variant: "dark"
palette:
  base00: "#1e1e2e"
  base01: "#181825"
  base02: "#313244"
  base03: "#45475a"
  base04: "#585b70"
  base05: "#cdd6f4"
  base06: "#f5e0dc"
  base07: "#b4befe"
  base08: "#f38ba8"
  base09: "#fab387"
  base0A: "#f9e2af"
  base0B: "#a6e3a1"
  base0C: "#94e2d5"
  base0D: "#89b4fa"
  base0E: "#cba6f7"
  base0F: "#f2cdcd"
  base10: "#11111b"
  base11: "#1e1e2e"
  base12: "#f38ba8"
  base13: "#f9e2af"
  base14: "#a6e3a1"
  base15: "#94e2d5"
  base16: "#89b4fa"
  base17: "#cba6f7"
"##;

        let colors = load(content, Path::new("test.yaml")).unwrap();

        // Has all base16 colors
        assert_eq!(colors.get("base00"), Some(&"#1e1e2e".to_string()));
        assert_eq!(colors.get("base0F"), Some(&"#f2cdcd".to_string()));

        // Has extended base24 colors
        assert_eq!(colors.get("base10"), Some(&"#11111b".to_string()));
        assert_eq!(colors.get("base17"), Some(&"#cba6f7".to_string()));
        assert_eq!(colors.len(), 24);
    }

    #[test]
    fn test_load_invalid_yaml() {
        let result = load("not: valid: yaml: {{", Path::new("test.yaml"));
        assert!(result.is_err());
    }

    #[test]
    fn test_load_minimal() {
        // Only required field is palette
        let content = r##"palette:
  base00: "#000000"
"##;

        let colors = load(content, Path::new("test.yaml")).unwrap();
        assert_eq!(colors.get("base00"), Some(&"#000000".to_string()));
    }
}
