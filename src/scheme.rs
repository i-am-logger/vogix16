use clap::ValueEnum;
use serde::{Deserialize, Serialize};
use std::fmt;
use std::str::FromStr;

/// Color scheme types supported by Vogix
///
/// Each scheme defines a different color palette structure:
/// - Ansi16: 16 standard ANSI terminal colors + foreground/background/cursor
/// - Base16: 16 colors (base00-base0F) following the base16 specification
/// - Base24: 24 colors (base00-base17) extending base16 with additional UI colors
/// - Vogix16: 16 semantic colors with functional naming (danger, success, etc.)
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, ValueEnum)]
#[serde(rename_all = "lowercase")]
pub enum Scheme {
    /// ANSI 16-color terminal scheme
    Ansi16,
    /// Base16 scheme (16 colors: base00-base0F)
    Base16,
    /// Base24 scheme (24 colors: base00-base17)
    Base24,
    /// Vogix16 native scheme with semantic color names
    #[default]
    Vogix16,
}

impl fmt::Display for Scheme {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Scheme::Vogix16 => write!(f, "vogix16"),
            Scheme::Base16 => write!(f, "base16"),
            Scheme::Base24 => write!(f, "base24"),
            Scheme::Ansi16 => write!(f, "ansi16"),
        }
    }
}

impl FromStr for Scheme {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "vogix16" => Ok(Scheme::Vogix16),
            "base16" => Ok(Scheme::Base16),
            "base24" => Ok(Scheme::Base24),
            "ansi16" => Ok(Scheme::Ansi16),
            _ => Err(format!(
                "Unknown scheme: {}. Valid schemes: vogix16, base16, base24, ansi16",
                s
            )),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // Helper to get all schemes (test-only, alphabetical order)
    fn all_schemes() -> &'static [Scheme] {
        &[
            Scheme::Ansi16,
            Scheme::Base16,
            Scheme::Base24,
            Scheme::Vogix16,
        ]
    }

    #[test]
    fn test_scheme_display() {
        assert_eq!(Scheme::Vogix16.to_string(), "vogix16");
        assert_eq!(Scheme::Base16.to_string(), "base16");
        assert_eq!(Scheme::Base24.to_string(), "base24");
        assert_eq!(Scheme::Ansi16.to_string(), "ansi16");
    }

    #[test]
    fn test_scheme_from_str() {
        assert_eq!("vogix16".parse::<Scheme>().unwrap(), Scheme::Vogix16);
        assert_eq!("BASE16".parse::<Scheme>().unwrap(), Scheme::Base16);
        assert_eq!("Base24".parse::<Scheme>().unwrap(), Scheme::Base24);
        assert_eq!("ANSI16".parse::<Scheme>().unwrap(), Scheme::Ansi16);
        assert!("invalid".parse::<Scheme>().is_err());
    }

    #[test]
    fn test_scheme_all() {
        let schemes = all_schemes();
        assert_eq!(schemes.len(), 4);
        assert!(schemes.contains(&Scheme::Vogix16));
        assert!(schemes.contains(&Scheme::Base16));
        assert!(schemes.contains(&Scheme::Base24));
        assert!(schemes.contains(&Scheme::Ansi16));
    }

    #[test]
    fn test_scheme_default() {
        assert_eq!(Scheme::default(), Scheme::Vogix16);
    }
}
