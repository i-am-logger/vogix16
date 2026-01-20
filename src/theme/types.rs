//! Theme and variant type definitions.

use crate::errors::{Result, VogixError};
use crate::scheme::Scheme;

/// Variant information with polarity and order (0 = lightest)
#[derive(Debug, Clone)]
pub struct VariantInfo {
    pub name: String,
    pub polarity: String,
    pub order: u32,
}

/// Theme information from the config manifest
#[derive(Debug, Clone)]
pub struct ThemeInfo {
    pub name: String,
    pub scheme: Scheme,
    pub variants: Vec<VariantInfo>,
}

impl ThemeInfo {
    /// Get variants sorted by order (lightest first, order 0)
    pub fn variants_by_order(&self) -> Vec<&VariantInfo> {
        let mut sorted: Vec<_> = self.variants.iter().collect();
        sorted.sort_by_key(|v| v.order);
        sorted
    }

    /// Get the default variant for a given polarity (dark/light)
    /// Returns the first variant with matching polarity, or the first variant if none match
    pub fn default_variant_for_polarity(&self, polarity: &str) -> Option<&VariantInfo> {
        self.variants
            .iter()
            .find(|v| v.polarity == polarity)
            .or_else(|| self.variants.first())
    }

    /// Navigate to darker or lighter variant
    /// Returns the new variant name, or error if at boundary
    pub fn navigate(&self, current: &str, direction: &str) -> Result<String> {
        let sorted = self.variants_by_order();

        // Find current position
        let current_idx = sorted
            .iter()
            .position(|v| v.name.to_lowercase() == current.to_lowercase())
            .ok_or_else(|| {
                VogixError::InvalidTheme(format!("Variant '{}' not found in theme", current))
            })?;

        match direction.to_lowercase().as_str() {
            "darker" => {
                if current_idx >= sorted.len() - 1 {
                    Err(VogixError::InvalidTheme(
                        "Already at darkest variant".to_string(),
                    ))
                } else {
                    Ok(sorted[current_idx + 1].name.clone())
                }
            }
            "lighter" => {
                if current_idx == 0 {
                    Err(VogixError::InvalidTheme(
                        "Already at lightest variant".to_string(),
                    ))
                } else {
                    Ok(sorted[current_idx - 1].name.clone())
                }
            }
            _ => Err(VogixError::InvalidTheme(format!(
                "Unknown direction: {}. Use 'darker' or 'lighter'",
                direction
            ))),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_variant_info_creation() {
        let variant = VariantInfo {
            name: "dark".to_string(),
            polarity: "dark".to_string(),
            order: 1,
        };
        assert_eq!(variant.name, "dark");
        assert_eq!(variant.order, 1);
    }

    #[test]
    fn test_theme_navigate_darker() {
        let theme = ThemeInfo {
            name: "test".to_string(),
            scheme: Scheme::Vogix16,
            variants: vec![
                VariantInfo {
                    name: "light".to_string(),
                    polarity: "light".to_string(),
                    order: 0, // lightest
                },
                VariantInfo {
                    name: "dark".to_string(),
                    polarity: "dark".to_string(),
                    order: 1, // darkest
                },
            ],
        };

        let result = theme.navigate("light", "darker").unwrap();
        assert_eq!(result, "dark");
    }

    #[test]
    fn test_theme_navigate_lighter() {
        let theme = ThemeInfo {
            name: "test".to_string(),
            scheme: Scheme::Vogix16,
            variants: vec![
                VariantInfo {
                    name: "light".to_string(),
                    polarity: "light".to_string(),
                    order: 0,
                },
                VariantInfo {
                    name: "dark".to_string(),
                    polarity: "dark".to_string(),
                    order: 1,
                },
            ],
        };

        let result = theme.navigate("dark", "lighter").unwrap();
        assert_eq!(result, "light");
    }

    #[test]
    fn test_theme_navigate_at_boundary() {
        let theme = ThemeInfo {
            name: "test".to_string(),
            scheme: Scheme::Vogix16,
            variants: vec![
                VariantInfo {
                    name: "light".to_string(),
                    polarity: "light".to_string(),
                    order: 0,
                },
                VariantInfo {
                    name: "dark".to_string(),
                    polarity: "dark".to_string(),
                    order: 1,
                },
            ],
        };

        // Already at darkest
        assert!(theme.navigate("dark", "darker").is_err());

        // Already at lightest
        assert!(theme.navigate("light", "lighter").is_err());
    }

    #[test]
    fn test_theme_navigate_multi_variant() {
        // Rose-pine style: dawn (lightest, order=0), moon (order=1), base (darkest, order=2)
        let theme = ThemeInfo {
            name: "rose-pine".to_string(),
            scheme: Scheme::Base16,
            variants: vec![
                VariantInfo {
                    name: "dawn".to_string(),
                    polarity: "light".to_string(),
                    order: 0,
                },
                VariantInfo {
                    name: "moon".to_string(),
                    polarity: "dark".to_string(),
                    order: 1,
                },
                VariantInfo {
                    name: "base".to_string(),
                    polarity: "dark".to_string(),
                    order: 2,
                },
            ],
        };

        // Navigate from dawn (lightest) -> moon -> base (darkest)
        let result1 = theme.navigate("dawn", "darker").unwrap();
        assert_eq!(result1, "moon");

        let result2 = theme.navigate("moon", "darker").unwrap();
        assert_eq!(result2, "base");

        // Can't go darker than base
        assert!(theme.navigate("base", "darker").is_err());

        // Navigate back: base -> moon -> dawn
        let result3 = theme.navigate("base", "lighter").unwrap();
        assert_eq!(result3, "moon");

        let result4 = theme.navigate("moon", "lighter").unwrap();
        assert_eq!(result4, "dawn");

        // Can't go lighter than dawn
        assert!(theme.navigate("dawn", "lighter").is_err());
    }

    #[test]
    fn test_variants_by_order() {
        let theme = ThemeInfo {
            name: "test".to_string(),
            scheme: Scheme::Base16,
            variants: vec![
                VariantInfo {
                    name: "base".to_string(),
                    polarity: "dark".to_string(),
                    order: 2, // darkest
                },
                VariantInfo {
                    name: "dawn".to_string(),
                    polarity: "light".to_string(),
                    order: 0, // lightest
                },
                VariantInfo {
                    name: "moon".to_string(),
                    polarity: "dark".to_string(),
                    order: 1,
                },
            ],
        };

        let sorted = theme.variants_by_order();
        // Should be sorted by order: dawn (0) first, base (2) last
        assert_eq!(sorted[0].name, "dawn");
        assert_eq!(sorted[1].name, "moon");
        assert_eq!(sorted[2].name, "base");
    }
}
