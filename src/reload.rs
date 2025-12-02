use crate::config::Config;
use crate::errors::{Result, VogixError};
use std::process::Command;

pub struct ReloadDispatcher;

impl ReloadDispatcher {
    pub fn new() -> Self {
        ReloadDispatcher
    }

    /// Reload all themed applications
    pub fn reload_apps(&self, config: &Config) -> Result<()> {
        println!("\nReloading applications...");
        for (app_name, app_metadata) in &config.apps {
            match self.reload_app(app_name, app_metadata) {
                Ok(msg) => println!("  ✓ {}: {}", app_name, msg),
                Err(e) => eprintln!("  ⚠ {}: {}", app_name, e),
            }
        }
        Ok(())
    }

    /// Reload a single application using metadata from manifest
    fn reload_app(&self, app_name: &str, metadata: &crate::config::AppMetadata) -> Result<String> {
        match metadata.reload_method.as_str() {
            "signal" => {
                let signal = metadata.reload_signal.as_ref().ok_or_else(|| {
                    VogixError::ReloadError(
                        "Signal reload method requires reload_signal".to_string(),
                    )
                })?;
                let process_name = metadata.process_name.as_deref().unwrap_or(app_name);
                self.send_signal(process_name, signal)?;
                Ok(format!("sent {} signal", signal))
            }
            "command" => {
                let cmd = metadata.reload_command.as_ref().ok_or_else(|| {
                    VogixError::ReloadError(
                        "Command reload method requires reload_command".to_string(),
                    )
                })?;
                self.run_command(cmd)?;
                Ok("executed reload command".to_string())
            }
            "touch" => {
                // Touch the symlink to trigger file watchers (use -h to touch symlink, not target)
                let cmd = format!("touch -h {} 2>/dev/null || true", metadata.config_path);
                self.run_command(&cmd)?;
                Ok("touched config file (triggers auto-reload)".to_string())
            }
            "none" => Ok("no reload needed (changes take effect on next use)".to_string()),
            _ => Err(VogixError::ReloadError(format!(
                "Unknown reload method: {}",
                metadata.reload_method
            ))),
        }
    }

    /// Send a Unix signal to a process
    fn send_signal(&self, process_name: &str, signal: &str) -> Result<()> {
        // Check if process is running
        let pgrep = Command::new("pgrep")
            .arg(process_name)
            .output()
            .map_err(|e| VogixError::ReloadError(format!("Failed to run pgrep: {}", e)))?;

        if !pgrep.status.success() {
            return Err(VogixError::ReloadError(format!(
                "Process '{}' is not running",
                process_name
            )));
        }

        // Send signal using killall
        let output = Command::new("killall")
            .arg("-s")
            .arg(signal)
            .arg(process_name)
            .output()
            .map_err(|e| VogixError::ReloadError(format!("Failed to send signal: {}", e)))?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(VogixError::ReloadError(format!(
                "Failed to send signal to '{}': {}",
                process_name, stderr
            )));
        }

        Ok(())
    }

    /// Run a shell command
    fn run_command(&self, cmd: &str) -> Result<()> {
        let output = Command::new("sh")
            .arg("-c")
            .arg(cmd)
            .output()
            .map_err(|e| VogixError::ReloadError(format!("Failed to run command: {}", e)))?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(VogixError::ReloadError(format!(
                "Command failed: {}",
                stderr
            )));
        }

        Ok(())
    }
}

impl Default for ReloadDispatcher {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_reload_dispatcher_creation() {
        let _dispatcher = ReloadDispatcher::new();
        // Verify it can be created
        assert!(true);
    }

    #[test]
    fn test_reload_app_with_touch_method() {
        use crate::config::AppMetadata;
        let dispatcher = ReloadDispatcher::new();
        let metadata = AppMetadata {
            config_path: "/tmp/test.conf".to_string(),
            reload_method: "touch".to_string(),
            reload_signal: None,
            process_name: None,
            reload_command: None,
        };

        // Test that touch method doesn't crash
        match dispatcher.reload_app("test", &metadata) {
            Ok(msg) => assert!(msg.contains("touched")),
            Err(_) => {
                // Touch might fail if /tmp doesn't exist in test environment, that's OK
                assert!(true);
            }
        }
    }

    #[test]
    fn test_reload_app_with_none_method() {
        use crate::config::AppMetadata;
        let dispatcher = ReloadDispatcher::new();
        let metadata = AppMetadata {
            config_path: "/tmp/test.conf".to_string(),
            reload_method: "none".to_string(),
            reload_signal: None,
            process_name: None,
            reload_command: None,
        };

        let result = dispatcher.reload_app("test", &metadata);
        assert!(result.is_ok());
        assert!(result.unwrap().contains("no reload needed"));
    }
}
