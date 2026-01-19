use crate::errors::{Result, VogixError};
use crate::scheme::Scheme;
use std::fs;
use std::str::FromStr;

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

/// Discover all available themes from the runtime config.toml
pub fn discover_themes() -> Result<Vec<ThemeInfo>> {
    let runtime_dir = crate::config::Config::runtime_dir()?;
    let manifest_path = runtime_dir.join("config.toml");

    if !manifest_path.exists() {
        return Err(VogixError::ConfigNotFound(manifest_path));
    }

    let content = fs::read_to_string(&manifest_path)
        .map_err(|_| VogixError::ConfigNotFound(manifest_path.clone()))?;

    parse_themes_from_manifest(&content)
}

/// Parse themes from a TOML manifest string
pub fn parse_themes_from_manifest(content: &str) -> Result<Vec<ThemeInfo>> {
    let manifest: toml::Value = content
        .parse()
        .map_err(|e| VogixError::ParseError(format!("Failed to parse config.toml: {}", e)))?;

    let mut themes = Vec::new();

    if let Some(themes_table) = manifest.get("themes").and_then(|v| v.as_table()) {
        for (theme_name, theme_value) in themes_table {
            if let Some(table) = theme_value.as_table() {
                // Skip variant detail entries (they have polarity/bg but no variants array)
                // Only process theme entries (they have a variants array)
                if !table.contains_key("variants") {
                    continue;
                }

                let scheme_str = table
                    .get("scheme")
                    .and_then(|v| v.as_str())
                    .unwrap_or("vogix16");
                let scheme = Scheme::from_str(scheme_str).unwrap_or(Scheme::Vogix16);

                let variant_names: Vec<String> = table
                    .get("variants")
                    .and_then(|v| v.as_array())
                    .map(|arr| {
                        arr.iter()
                            .filter_map(|v| v.as_str().map(String::from))
                            .collect()
                    })
                    .unwrap_or_else(|| vec!["dark".to_string(), "light".to_string()]);

                // Parse variant details (variantName = { polarity, order } inside theme table)
                let mut variants = Vec::new();
                for (idx, var_name) in variant_names.iter().enumerate() {
                    // Look for variant details inside the theme's table
                    let (polarity, order) =
                        if let Some(var_value) = table.get(var_name).and_then(|v| v.as_table()) {
                            let pol = var_value
                                .get("polarity")
                                .and_then(|v| v.as_str())
                                .unwrap_or("dark")
                                .to_string();
                            let ord = var_value
                                .get("order")
                                .and_then(|v| v.as_integer())
                                .unwrap_or(idx as i64) as u32;
                            (pol, ord)
                        } else {
                            // Fallback: infer polarity from variant name, use index as order
                            let pol = if var_name.to_lowercase().contains("light")
                                || var_name.to_lowercase() == "dawn"
                                || var_name.to_lowercase() == "latte"
                            {
                                "light".to_string()
                            } else {
                                "dark".to_string()
                            };
                            (pol, idx as u32)
                        };

                    variants.push(VariantInfo {
                        name: var_name.clone(),
                        polarity,
                        order,
                    });
                }

                themes.push(ThemeInfo {
                    name: theme_name.clone(),
                    scheme,
                    variants,
                });
            }
        }
    }

    themes.sort_by(|a, b| a.name.cmp(&b.name));
    Ok(themes)
}

/// Filter themes by scheme
pub fn filter_by_scheme(themes: &[ThemeInfo], scheme: &Scheme) -> Vec<ThemeInfo> {
    themes
        .iter()
        .filter(|t| &t.scheme == scheme)
        .cloned()
        .collect()
}

/// Get a specific theme by name
pub fn get_theme(themes: &[ThemeInfo], name: &str) -> Option<ThemeInfo> {
    themes.iter().find(|t| t.name == name).cloned()
}

#[cfg(test)]
mod tests {
    use super::*;

    // Helper to find variant by name (test-only)
    fn get_variant<'a>(theme: &'a ThemeInfo, name: &str) -> Option<&'a VariantInfo> {
        theme.variants.iter().find(|v| v.name == name)
    }

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

    #[test]
    fn test_parse_themes_with_variant_details() {
        let manifest = r##"
[themes.aikido]
scheme = "vogix16"
variants = ["night", "day"]
night = { polarity = "dark", order = 1 }
day = { polarity = "light", order = 0 }
"##;
        let themes = parse_themes_from_manifest(manifest).unwrap();
        assert_eq!(themes.len(), 1);

        let aikido = &themes[0];
        assert_eq!(aikido.name, "aikido");
        assert_eq!(aikido.variants.len(), 2);

        let night = get_variant(aikido, "night").unwrap();
        assert_eq!(night.polarity, "dark");
        assert_eq!(night.order, 1);

        let day = get_variant(aikido, "day").unwrap();
        assert_eq!(day.polarity, "light");
        assert_eq!(day.order, 0);
    }

    #[test]
    fn test_filter_by_scheme() {
        let themes = vec![
            ThemeInfo {
                name: "aikido".to_string(),
                scheme: Scheme::Vogix16,
                variants: vec![VariantInfo {
                    name: "dark".to_string(),
                    polarity: "dark".to_string(),
                    order: 0,
                }],
            },
            ThemeInfo {
                name: "gruvbox".to_string(),
                scheme: Scheme::Base16,
                variants: vec![VariantInfo {
                    name: "dark".to_string(),
                    polarity: "dark".to_string(),
                    order: 0,
                }],
            },
        ];

        let base16_themes = filter_by_scheme(&themes, &Scheme::Base16);
        assert_eq!(base16_themes.len(), 1);
        assert_eq!(base16_themes[0].name, "gruvbox");
    }
}
