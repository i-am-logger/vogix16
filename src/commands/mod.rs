//! Command handlers for vogix CLI.
//!
//! This module provides handlers for each CLI command:
//! - `list` - Show available themes and schemes
//! - `status` - Display current theme state
//! - `refresh` - Reapply current theme without changes
//! - `cache` - Manage template cache
//! - `completions` - Generate shell completions
//! - `theme_change` - Handle -t, -v, -s flags

mod cache;
mod completions;
mod list;
mod refresh;
mod status;
mod theme_change;

pub use cache::handle_cache_clean;
pub use completions::handle_completions;
pub use list::handle_list;
pub use refresh::handle_refresh;
pub use status::handle_status;
pub use theme_change::handle_theme_change;
