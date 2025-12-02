use crate::errors::{Result, VogixError};
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct State {
    pub current_theme: String,
    pub current_variant: String,
    pub last_applied: Option<String>,
}

impl State {
    /// Load state from the state file
    pub fn load() -> Result<Self> {
        let state_path = Self::state_path()?;

        if !state_path.exists() {
            // Return default state if file doesn't exist
            return Ok(State {
                current_theme: "aikido".to_string(),
                current_variant: "dark".to_string(),
                last_applied: None,
            });
        }

        let contents = fs::read_to_string(&state_path)?;
        let state: State = toml::from_str(&contents)
            .map_err(|e| VogixError::InvalidTheme(format!("Failed to parse state: {}", e)))?;

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
            .map_err(|e| VogixError::InvalidTheme(format!("Failed to serialize state: {}", e)))?;

        fs::write(&state_path, contents)?;
        Ok(())
    }

    /// Get the state file path
    fn state_path() -> Result<PathBuf> {
        // Try XDG_RUNTIME_DIR first, fallback to ~/.local/state
        if let Ok(runtime_dir) = std::env::var("XDG_RUNTIME_DIR") {
            let path = PathBuf::from(runtime_dir).join("vogix16/state/current.toml");
            return Ok(path);
        }

        let home = dirs::home_dir()
            .ok_or_else(|| VogixError::ConfigNotFound(PathBuf::from("HOME not set")))?;
        Ok(home.join(".local/state/vogix16/current.toml"))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_state_creation() {
        let state = State {
            current_theme: "test".to_string(),
            current_variant: "dark".to_string(),
            last_applied: None,
        };
        assert_eq!(state.current_theme, "test");
        assert_eq!(state.current_variant, "dark");
    }
}
