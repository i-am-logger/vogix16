use crate::errors::{Result, VogixError};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::PathBuf;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Config {
    pub default_theme: String,
    pub default_variant: String,
    pub apps: HashMap<String, AppMetadata>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AppMetadata {
    pub config_path: String,
    pub reload_method: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub reload_signal: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub process_name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub reload_command: Option<String>,
}

impl Default for Config {
    fn default() -> Self {
        Config {
            default_theme: "aikido".to_string(),
            default_variant: "dark".to_string(),
            apps: HashMap::new(),
        }
    }
}

impl Config {
    /// Load configuration from the runtime config (/run/user/UID/vogix/config.toml)
    pub fn load() -> Result<Self> {
        let manifest_path = Self::manifest_path()?;

        if !manifest_path.exists() {
            // Return default config if manifest doesn't exist
            return Ok(Config::default());
        }

        let contents = fs::read_to_string(&manifest_path)?;
        let manifest: toml::Value = toml::from_str(&contents)
            .map_err(|e| VogixError::ParseError(format!("Failed to parse manifest: {}", e)))?;

        // Extract config from manifest structure
        let default_theme = manifest
            .get("default")
            .and_then(|d| d.get("theme"))
            .and_then(|t| t.as_str())
            .unwrap_or("aikido")
            .to_string();

        let default_variant = manifest
            .get("default")
            .and_then(|d| d.get("variant"))
            .and_then(|v| v.as_str())
            .unwrap_or("dark")
            .to_string();

        // Parse app metadata from [apps] section
        let apps = manifest
            .get("apps")
            .and_then(|a| a.as_table())
            .map(|apps_table| {
                apps_table
                    .iter()
                    .filter_map(|(app_name, app_data)| {
                        let config_path = app_data.get("config_path")?.as_str()?.to_string();
                        let reload_method = app_data.get("reload_method")?.as_str()?.to_string();
                        let reload_signal = app_data
                            .get("reload_signal")
                            .and_then(|v| v.as_str())
                            .map(String::from);
                        let process_name = app_data
                            .get("process_name")
                            .and_then(|v| v.as_str())
                            .map(String::from);
                        let reload_command = app_data
                            .get("reload_command")
                            .and_then(|v| v.as_str())
                            .map(String::from);

                        Some((
                            app_name.clone(),
                            AppMetadata {
                                config_path,
                                reload_method,
                                reload_signal,
                                process_name,
                                reload_command,
                            },
                        ))
                    })
                    .collect()
            })
            .unwrap_or_default();

        Ok(Config {
            default_theme,
            default_variant,
            apps,
        })
    }

    /// Save configuration to the default location
    #[allow(dead_code)]
    pub fn save(&self) -> Result<()> {
        // Config is now read-only from manifest, this is deprecated
        // State is managed separately in /run/user/UID/vogix/state/
        Err(VogixError::InvalidTheme(
            "Config is read-only from manifest. Use state file for runtime changes.".to_string(),
        ))
    }

    /// Get the runtime config path (/run/user/UID/vogix/config.toml)
    fn manifest_path() -> Result<PathBuf> {
        let runtime_dir = Self::runtime_dir()?;
        Ok(runtime_dir.join("config.toml"))
    }

    /// Get the vogix runtime directory (/run/user/UID/vogix/)
    pub fn runtime_dir() -> Result<PathBuf> {
        // Try XDG_RUNTIME_DIR first, fallback to /run/user/UID
        if let Ok(xdg_runtime) = std::env::var("XDG_RUNTIME_DIR") {
            return Ok(PathBuf::from(xdg_runtime).join("vogix"));
        }

        // Fallback: construct /run/user/UID manually
        let uid = unsafe { libc::getuid() };
        Ok(PathBuf::from(format!("/run/user/{}/vogix", uid)))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serial_test::serial;

    #[test]
    fn test_default_config() {
        let config = Config::default();
        assert_eq!(config.default_theme, "aikido");
        assert_eq!(config.default_variant, "dark");
    }

    #[test]
    fn test_parse_valid_manifest() {
        let manifest = r##"
[default]
theme = "nordic"
variant = "light"

[apps.alacritty]
config_path = "/home/user/.config/alacritty/alacritty.toml"
reload_method = "touch"

[apps.btop]
config_path = "/home/user/.config/btop/btop.conf"
reload_method = "signal"
reload_signal = "USR1"
process_name = "btop"
"##;

        let manifest_value: toml::Value = toml::from_str(manifest).unwrap();

        // Extract values like Config::load() does
        let default_theme = manifest_value
            .get("default")
            .and_then(|d| d.get("theme"))
            .and_then(|t| t.as_str())
            .unwrap_or("aikido");

        let default_variant = manifest_value
            .get("default")
            .and_then(|d| d.get("variant"))
            .and_then(|v| v.as_str())
            .unwrap_or("dark");

        assert_eq!(default_theme, "nordic");
        assert_eq!(default_variant, "light");

        let apps_table = manifest_value
            .get("apps")
            .and_then(|a| a.as_table())
            .unwrap();
        assert!(apps_table.contains_key("alacritty"));
        assert!(apps_table.contains_key("btop"));
    }

    #[test]
    fn test_parse_manifest_with_missing_defaults() {
        let manifest = r##"
[apps.alacritty]
config_path = "/home/user/.config/alacritty/alacritty.toml"
reload_method = "touch"
"##;

        let manifest_value: toml::Value = toml::from_str(manifest).unwrap();

        let default_theme = manifest_value
            .get("default")
            .and_then(|d| d.get("theme"))
            .and_then(|t| t.as_str())
            .unwrap_or("aikido");

        let default_variant = manifest_value
            .get("default")
            .and_then(|d| d.get("variant"))
            .and_then(|v| v.as_str())
            .unwrap_or("dark");

        // Should fall back to defaults
        assert_eq!(default_theme, "aikido");
        assert_eq!(default_variant, "dark");
    }

    #[test]
    fn test_parse_invalid_toml() {
        let invalid_manifest = "this is not valid toml {{{";
        let result: std::result::Result<toml::Value, _> = toml::from_str(invalid_manifest);
        assert!(result.is_err());
    }

    #[test]
    #[serial]
    fn test_runtime_dir_with_xdg() {
        // Save current env
        let original = std::env::var("XDG_RUNTIME_DIR").ok();

        // SAFETY: This test is single-threaded and we restore the original value
        unsafe {
            std::env::set_var("XDG_RUNTIME_DIR", "/run/user/1000");
        }
        let result = Config::runtime_dir().unwrap();
        assert_eq!(result, PathBuf::from("/run/user/1000/vogix"));

        // Restore
        unsafe {
            match original {
                Some(val) => std::env::set_var("XDG_RUNTIME_DIR", val),
                None => std::env::remove_var("XDG_RUNTIME_DIR"),
            }
        }
    }
}
