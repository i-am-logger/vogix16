use crate::errors::{Result, VogixError};
use std::fs;
use std::path::PathBuf;

pub struct SymlinkManager;

impl SymlinkManager {
    pub fn new() -> Self {
        SymlinkManager
    }

    /// Update the 'current-theme' symlink to point to the selected theme-variant
    /// Architecture: Nix generates all theme configs in /run/user/UID/vogix16/themes/
    /// App symlinks in ~/.config/app/ point to /run/user/UID/vogix16/themes/current-theme/app/
    /// We just update where 'current-theme' points
    pub fn update_current_symlink(&self, theme: &str, variant: &str) -> Result<()> {
        let runtime_dir = crate::config::Config::runtime_dir()?;
        let themes_dir = runtime_dir.join("themes");

        let current_link = themes_dir.join("current-theme");
        let theme_variant_name = format!("{}-{}", theme, variant);
        let target_path = themes_dir.join(&theme_variant_name);

        // Verify target directory exists (systemd service should have created it)
        if !target_path.exists() {
            return Err(VogixError::ThemeNotFound(format!(
                "Theme-variant directory not found: {}. \
                 This should have been created by the vogix16-setup systemd service.",
                target_path.display()
            )));
        }

        // Remove existing symlink if present
        if current_link.exists() || current_link.is_symlink() {
            if current_link.is_symlink() {
                fs::remove_file(&current_link)?;
            } else {
                return Err(VogixError::SymlinkError(format!(
                    "'current' path exists but is not a symlink: {}",
                    current_link.display()
                )));
            }
        }

        // Create new symlink (relative path within themes/ directory)
        let relative_target = PathBuf::from(&theme_variant_name);
        #[cfg(unix)]
        std::os::unix::fs::symlink(&relative_target, &current_link).map_err(|e| {
            VogixError::SymlinkError(format!("Failed to create 'current-theme' symlink: {}", e))
        })?;

        println!(
            "Updated 'current' symlink: {} -> {}",
            current_link.display(),
            theme_variant_name
        );

        Ok(())
    }
}

impl Default for SymlinkManager {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_symlink_manager_creation() {
        let _manager = SymlinkManager::new();
        // Just verify it can be created
        assert!(true);
    }
}
