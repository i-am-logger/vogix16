//! Theme color loading from different scheme formats
//!
//! Each scheme has its own loader module:
//! - vogix16: TOML files with `polarity` and `[colors]` section + semantic mappings
//! - base16_24: YAML files with `palette` section (handles both base16 and base24)
//! - ansi16: TOML files in Alacritty format with nested color sections

mod ansi16;
mod base16_24;
#[cfg(test)]
mod tests;
mod vogix16;

use crate::errors::{Result, VogixError};
use crate::scheme::Scheme;
use std::collections::HashMap;
use std::fs;
use std::path::Path;

/// Load colors from a theme file based on the scheme type
///
/// Returns a HashMap of color names to hex values (e.g., "base00" -> "#1e1e2e")
pub fn load_theme_colors<P: AsRef<Path>>(
    path: P,
    scheme: Scheme,
) -> Result<HashMap<String, String>> {
    let path = path.as_ref();
    let content =
        fs::read_to_string(path).map_err(|_| VogixError::ConfigNotFound(path.to_path_buf()))?;

    match scheme {
        Scheme::Vogix16 => vogix16::load(&content, path),
        Scheme::Base16 | Scheme::Base24 => base16_24::load(&content, path),
        Scheme::Ansi16 => ansi16::load(&content, path),
    }
}
