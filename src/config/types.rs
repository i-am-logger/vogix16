//! Configuration types for application metadata and template settings.

use serde::{Deserialize, Serialize};
use std::path::PathBuf;

/// Configuration for template-based rendering
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct TemplatesConfig {
    /// Path to templates directory in /nix/store
    pub path: PathBuf,
    /// Hash of templates for cache invalidation
    pub hash: String,
}

/// Paths to theme source directories for each scheme
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ThemeSourcesConfig {
    pub vogix16: PathBuf,
    pub base16: PathBuf,
    pub base24: PathBuf,
    pub ansi16: PathBuf,
}

/// Metadata for an application that can be themed
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
