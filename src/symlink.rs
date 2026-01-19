use crate::errors::{Result, VogixError};
use std::fs;
use std::path::PathBuf;

pub struct SymlinkManager;

impl SymlinkManager {
    pub fn new() -> Self {
        SymlinkManager
    }

    /// Update the 'current-theme' symlink to point to the selected theme-variant
    /// Architecture: Nix generates all theme configs in /run/user/UID/vogix/themes/
    /// App symlinks in ~/.config/app/ point to /run/user/UID/vogix/themes/current-theme/app/
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
                  This should have been created by the vogix-setup systemd service.",
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
    use serial_test::serial;
    use tempfile::TempDir;

    #[test]
    fn test_symlink_manager_creation() {
        let _manager = SymlinkManager::new();
        let _default = SymlinkManager::default();
    }

    #[test]
    #[serial]
    fn test_update_current_symlink_success() {
        let temp_dir = TempDir::new().unwrap();
        let temp_path = temp_dir.path().to_path_buf();

        // Create theme directory structure
        let themes_dir = temp_path.join("vogix/themes");
        let theme_variant_dir = themes_dir.join("aikido-dark");
        fs::create_dir_all(&theme_variant_dir).unwrap();

        // SAFETY: Single-threaded test
        unsafe {
            std::env::set_var("XDG_RUNTIME_DIR", &temp_path);
        }

        let manager = SymlinkManager::new();
        let result = manager.update_current_symlink("aikido", "dark");

        assert!(result.is_ok());

        // Verify symlink was created
        let current_link = themes_dir.join("current-theme");
        assert!(current_link.is_symlink());

        // Verify symlink points to correct target
        let target = fs::read_link(&current_link).unwrap();
        assert_eq!(target, PathBuf::from("aikido-dark"));

        unsafe {
            std::env::remove_var("XDG_RUNTIME_DIR");
        }
    }

    #[test]
    #[serial]
    fn test_update_current_symlink_theme_not_found() {
        let temp_dir = TempDir::new().unwrap();
        let temp_path = temp_dir.path().to_path_buf();

        // Create themes directory but NOT the theme-variant directory
        let themes_dir = temp_path.join("vogix/themes");
        fs::create_dir_all(&themes_dir).unwrap();

        unsafe {
            std::env::set_var("XDG_RUNTIME_DIR", &temp_path);
        }

        let manager = SymlinkManager::new();
        let result = manager.update_current_symlink("nonexistent", "theme");

        assert!(result.is_err());
        let err_msg = result.unwrap_err().to_string();
        assert!(err_msg.contains("not found"));

        unsafe {
            std::env::remove_var("XDG_RUNTIME_DIR");
        }
    }

    #[test]
    #[serial]
    fn test_update_current_symlink_replaces_existing() {
        let temp_dir = TempDir::new().unwrap();
        let temp_path = temp_dir.path().to_path_buf();

        // Create two theme directories
        let themes_dir = temp_path.join("vogix/themes");
        fs::create_dir_all(themes_dir.join("aikido-dark")).unwrap();
        fs::create_dir_all(themes_dir.join("aikido-light")).unwrap();

        unsafe {
            std::env::set_var("XDG_RUNTIME_DIR", &temp_path);
        }

        let manager = SymlinkManager::new();

        // Create first symlink
        manager.update_current_symlink("aikido", "dark").unwrap();
        let target1 = fs::read_link(themes_dir.join("current-theme")).unwrap();
        assert_eq!(target1, PathBuf::from("aikido-dark"));

        // Update to different variant
        manager.update_current_symlink("aikido", "light").unwrap();
        let target2 = fs::read_link(themes_dir.join("current-theme")).unwrap();
        assert_eq!(target2, PathBuf::from("aikido-light"));

        unsafe {
            std::env::remove_var("XDG_RUNTIME_DIR");
        }
    }
}
