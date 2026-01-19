use crate::errors::{Result, VogixError};
use crate::scheme::Scheme;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct State {
    /// Current color scheme (vogix16, base16, base24, ansi16)
    #[serde(default)]
    pub current_scheme: Scheme,
    /// Current theme name
    pub current_theme: String,
    /// Current variant name (e.g., "dark", "light", "dawn", "moon")
    pub current_variant: String,
    /// Timestamp of last theme application
    pub last_applied: Option<String>,
}

impl State {
    /// Load state from the state file
    pub fn load() -> Result<Self> {
        let state_path = Self::state_path()?;

        if !state_path.exists() {
            // Return default state if file doesn't exist
            return Ok(State {
                current_scheme: Scheme::default(),
                current_theme: "aikido".to_string(),
                current_variant: "dark".to_string(),
                last_applied: None,
            });
        }

        let contents = fs::read_to_string(&state_path)?;
        let state: State = toml::from_str(&contents)
            .map_err(|e| VogixError::ParseError(format!("Failed to parse state: {}", e)))?;

        Ok(state)
    }

    /// Save state to the state file
    pub fn save(&self) -> Result<()> {
        let state_path = Self::state_path()?;

        // Create parent directory if it doesn't exist
        if let Some(parent) = state_path.parent() {
            fs::create_dir_all(parent)?;
        }

        let mut state_to_save = self.clone();
        state_to_save.last_applied = Some(chrono::Utc::now().to_rfc3339());

        let contents = toml::to_string_pretty(&state_to_save)
            .map_err(|e| VogixError::ParseError(format!("Failed to serialize state: {}", e)))?;

        fs::write(&state_path, contents)?;
        Ok(())
    }

    /// Get the state file path
    fn state_path() -> Result<PathBuf> {
        let runtime_dir = crate::config::Config::runtime_dir()?;
        Ok(runtime_dir.join("state/current.toml"))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serial_test::serial;
    use tempfile::TempDir;

    #[test]
    fn test_state_creation() {
        let state = State {
            current_scheme: Scheme::Vogix16,
            current_theme: "test".to_string(),
            current_variant: "dark".to_string(),
            last_applied: None,
        };
        assert_eq!(state.current_scheme, Scheme::Vogix16);
        assert_eq!(state.current_theme, "test");
        assert_eq!(state.current_variant, "dark");
    }

    #[test]
    #[serial]
    fn test_state_save_and_load() {
        let temp_dir = TempDir::new().unwrap();
        let temp_path = temp_dir.path().to_path_buf();

        // SAFETY: This test is single-threaded
        unsafe {
            std::env::set_var("XDG_RUNTIME_DIR", &temp_path);
        }

        let state = State {
            current_scheme: Scheme::Base16,
            current_theme: "rose-pine".to_string(),
            current_variant: "moon".to_string(),
            last_applied: None,
        };

        // Save state
        state.save().unwrap();

        // Load state back
        let loaded = State::load().unwrap();

        assert_eq!(loaded.current_scheme, Scheme::Base16);
        assert_eq!(loaded.current_theme, "rose-pine");
        assert_eq!(loaded.current_variant, "moon");
        assert!(loaded.last_applied.is_some()); // save() sets timestamp

        // Cleanup
        unsafe {
            std::env::remove_var("XDG_RUNTIME_DIR");
        }
    }

    #[test]
    #[serial]
    fn test_state_load_missing_returns_default() {
        let temp_dir = TempDir::new().unwrap();
        let temp_path = temp_dir.path().to_path_buf();

        // SAFETY: This test is single-threaded
        unsafe {
            std::env::set_var("XDG_RUNTIME_DIR", &temp_path);
        }

        // Load without saving first - should return default
        let loaded = State::load().unwrap();

        assert_eq!(loaded.current_scheme, Scheme::Vogix16);
        assert_eq!(loaded.current_theme, "aikido");
        assert_eq!(loaded.current_variant, "dark");

        unsafe {
            std::env::remove_var("XDG_RUNTIME_DIR");
        }
    }

    #[test]
    fn test_state_serialization_format() {
        let state = State {
            current_scheme: Scheme::Ansi16,
            current_theme: "dracula".to_string(),
            current_variant: "default".to_string(),
            last_applied: Some("2024-01-01T00:00:00Z".to_string()),
        };

        let serialized = toml::to_string_pretty(&state).unwrap();

        assert!(serialized.contains("current_scheme = \"ansi16\""));
        assert!(serialized.contains("current_theme = \"dracula\""));
        assert!(serialized.contains("current_variant = \"default\""));
    }
}
