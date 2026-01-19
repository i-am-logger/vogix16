//! Cache management command handlers.

use crate::cache::ThemeCache;
use crate::config::Config;
use crate::errors::Result;

/// Handle the `cache clean` command - remove stale cache entries
pub fn handle_cache_clean() -> Result<()> {
    let config = Config::load()?;

    // Check if template caching is configured
    if config.templates.is_none() {
        println!("Template caching is not configured.");
        println!("Add a [templates] section to your config to enable caching.");
        return Ok(());
    }

    let cache = ThemeCache::from_config(&config)?;
    let removed = cache.clean_stale()?;

    if removed == 0 {
        println!("Cache is clean, no stale entries found.");
    } else {
        println!("Removed {} stale cache entries.", removed);
    }

    Ok(())
}
