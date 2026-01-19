mod cli;
mod config;
mod errors;
mod generator;
mod reload;
mod scheme;
mod state;
mod symlink;
mod theme;

use clap::CommandFactory;
use clap_complete::{generate, shells};
use cli::{Cli, Commands, CompletionShell};
use config::Config;
use errors::Result;
use generator::ThemeGenerator;
use log::{debug, error, info, warn};
use reload::ReloadDispatcher;
use scheme::Scheme;
use state::State;
use std::io;
use symlink::SymlinkManager;

fn main() {
    // Initialize logger with minimal format (no timestamps)
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info"))
        .format_timestamp(None)
        .format_target(false)
        .init();

    if let Err(e) = run() {
        error!("{}", e);
        std::process::exit(1);
    }
}

fn run() -> Result<()> {
    let cli = Cli::parse_args();

    // Handle subcommands first
    if let Some(ref command) = cli.command {
        match command {
            Commands::List { scheme, variants } => {
                return handle_list(scheme.as_ref(), *variants);
            }
            Commands::Status => {
                return handle_status();
            }
            Commands::Completions { shell } => {
                return handle_completions(*shell);
            }
            Commands::Apply => {
                return handle_apply();
            }
        }
    }

    // Handle theme change flags (-s, -t, -v)
    if cli.has_theme_changes() {
        return handle_theme_change(&cli);
    }

    // No command and no flags - show help
    Cli::command().print_help()?;
    println!();
    Ok(())
}

/// Handle theme/variant/scheme changes via flags
fn handle_theme_change(cli: &Cli) -> Result<()> {
    let mut state = State::load()?;
    let config = Config::load()?;

    let old_scheme = state.current_scheme;
    let old_theme = state.current_theme.clone();
    let old_variant = state.current_variant.clone();

    // Update scheme if provided
    if let Some(scheme) = cli.scheme {
        state.current_scheme = scheme;
    }

    // Track if theme changed (we'll need to resolve variant for new theme)
    let theme_changed = cli.theme.is_some() && cli.theme.as_ref() != Some(&state.current_theme);

    // Update theme if provided
    if let Some(ref theme) = cli.theme {
        state.current_theme = theme.clone();
    }

    // Update variant if provided, OR resolve default variant if theme changed
    if let Some(ref variant) = cli.variant {
        if cli.is_variant_navigation() {
            state.current_variant = navigate_variant(&state, variant)?;
        } else {
            // Resolve variant: could be an exact variant name OR a polarity request (dark/light)
            state.current_variant =
                resolve_variant(&state.current_theme, variant, &state.current_variant)?;
        }
    } else if theme_changed {
        // Theme changed but no variant specified - find appropriate variant for current polarity
        let themes = theme::discover_themes()?;
        if let Some(new_theme) = theme::get_theme(&themes, &state.current_theme) {
            // Get the polarity of the old variant to maintain dark/light preference
            let current_polarity = theme::get_theme(&themes, &old_theme)
                .and_then(|t| {
                    t.variants
                        .iter()
                        .find(|v| v.name == old_variant)
                        .map(|v| v.polarity.clone())
                })
                .unwrap_or_else(|| "dark".to_string());

            // Find the default variant for this polarity in the new theme
            if let Some(default_var) = new_theme.default_variant_for_polarity(&current_polarity) {
                state.current_variant = default_var.name.clone();
            }
        }
    }

    // Check if anything changed
    if state.current_scheme == old_scheme
        && state.current_theme == old_theme
        && state.current_variant == old_variant
    {
        info!("No changes to apply");
        return Ok(());
    }

    // Log changes
    if state.current_scheme != old_scheme {
        info!("scheme: {} → {}", old_scheme, state.current_scheme);
    }
    if state.current_theme != old_theme {
        info!("theme: {} → {}", old_theme, state.current_theme);
    }
    if state.current_variant != old_variant {
        info!("variant: {} → {}", old_variant, state.current_variant);
    }

    // Verify theme-variant exists
    let generator = ThemeGenerator::new();
    generator.verify_theme_variant_exists(&state.current_theme, &state.current_variant)?;
    debug!("Verified theme-variant exists");

    // Update the 'current' symlink
    let symlink_manager = SymlinkManager::new();
    symlink_manager.update_current_symlink(&state.current_theme, &state.current_variant)?;
    debug!("Updated current symlink");

    // Save state
    state.save()?;
    debug!("Saved state");

    // Reload applications
    let reload_dispatcher = ReloadDispatcher::new();
    let reload_result = reload_dispatcher.reload_apps(&config);

    // Log appropriate message based on reload results
    let theme_variant = format!("{}-{}", state.current_theme, state.current_variant);
    if reload_result.has_failures() {
        warn!(
            "Applied: {} ({}/{} reloaded, {} failed)",
            theme_variant,
            reload_result.success_count,
            reload_result.total_count,
            reload_result.failed_apps.len()
        );
    } else {
        info!("Applied: {}", theme_variant);
    }
    Ok(())
}

/// Navigate to a darker or lighter variant based on luminance ordering
fn navigate_variant(state: &State, direction: &str) -> Result<String> {
    // Load themes and find the current one
    let themes = theme::discover_themes()?;
    let current_theme = theme::get_theme(&themes, &state.current_theme).ok_or_else(|| {
        errors::VogixError::InvalidTheme(format!("Theme '{}' not found", state.current_theme))
    })?;

    // Use the theme's luminance-based navigation
    current_theme.navigate(&state.current_variant, direction)
}

/// Resolve a variant name: could be an exact variant name OR a polarity request (dark/light)
/// For polarity requests, finds the default variant for that polarity in the theme.
/// For single-variant themes, always returns the only variant (ignores polarity request).
fn resolve_variant(theme_name: &str, requested: &str, _current_variant: &str) -> Result<String> {
    let themes = theme::discover_themes()?;
    let theme_info = theme::get_theme(&themes, theme_name).ok_or_else(|| {
        errors::VogixError::InvalidTheme(format!("Theme '{}' not found", theme_name))
    })?;

    let requested_lower = requested.to_lowercase();

    // First, check if requested is an exact variant name match (case-insensitive)
    for variant in &theme_info.variants {
        if variant.name.to_lowercase() == requested_lower {
            return Ok(variant.name.clone());
        }
    }

    // For single-variant themes, always use the only variant regardless of polarity request
    if theme_info.variants.len() == 1 {
        return Ok(theme_info.variants[0].name.clone());
    }

    // If not an exact match, check if it's a polarity request (dark/light)
    if requested_lower == "dark" || requested_lower == "light" {
        // Find the default variant for this polarity
        if let Some(variant) = theme_info.default_variant_for_polarity(&requested_lower) {
            // Verify the variant actually has the requested polarity
            if variant.polarity == requested_lower {
                return Ok(variant.name.clone());
            }
        }

        // No variant with the requested polarity exists
        let available_polarities: Vec<_> = theme_info
            .variants
            .iter()
            .map(|v| format!("{} ({})", v.name, v.polarity))
            .collect();
        return Err(errors::VogixError::InvalidTheme(format!(
            "Theme '{}' has no '{}' variant. Available: {}",
            theme_name,
            requested,
            available_polarities.join(", ")
        )));
    }

    // Not an exact match and not a polarity - invalid variant
    let available: Vec<_> = theme_info
        .variants
        .iter()
        .map(|v| v.name.as_str())
        .collect();
    Err(errors::VogixError::InvalidTheme(format!(
        "Variant '{}' not found in theme '{}'. Available variants: {}",
        requested,
        theme_name,
        available.join(", ")
    )))
}

fn handle_list(filter_scheme: Option<&Scheme>, show_variants: bool) -> Result<()> {
    let all_themes = theme::discover_themes()?;

    if all_themes.is_empty() {
        info!("No themes found");
        info!("Add themes to your NixOS/home-manager configuration");
        return Ok(());
    }

    // Filter by scheme if provided
    let themes = if let Some(scheme) = filter_scheme {
        theme::filter_by_scheme(&all_themes, scheme)
    } else {
        all_themes.clone()
    };

    // Show available schemes if no filter
    if filter_scheme.is_none() {
        // Count themes per scheme
        let vogix16_count = theme::filter_by_scheme(&all_themes, &Scheme::Vogix16).len();
        let base16_count = theme::filter_by_scheme(&all_themes, &Scheme::Base16).len();
        let base24_count = theme::filter_by_scheme(&all_themes, &Scheme::Base24).len();
        let ansi16_count = theme::filter_by_scheme(&all_themes, &Scheme::Ansi16).len();

        println!("Schemes:");
        println!("  vogix16 ({} themes)", vogix16_count);
        println!("  base16  ({} themes)", base16_count);
        println!("  base24  ({} themes)", base24_count);
        println!("  ansi16  ({} themes)", ansi16_count);
        println!();
        println!("Use 'vogix list -s <scheme>' to list themes for a specific scheme");
        println!();
    }

    if themes.is_empty() {
        info!("No themes found for scheme: {}", filter_scheme.unwrap());
        return Ok(());
    }

    println!(
        "Themes{}:",
        filter_scheme
            .map(|s| format!(" ({})", s))
            .unwrap_or_default()
    );

    for t in &themes {
        if show_variants {
            // Show variants with polarity info: name(polarity)
            let variant_info: Vec<String> = t
                .variants_by_order()
                .iter()
                .map(|v| format!("{}({})", v.name, v.polarity))
                .collect();
            println!("  {} [{}]", t.name, variant_info.join(", "));
        } else {
            println!("  {}", t.name);
        }
    }

    println!();
    println!("Total: {}", themes.len());

    Ok(())
}

fn handle_status() -> Result<()> {
    let state = State::load()?;
    state.save()?;

    println!("scheme:  {}", state.current_scheme);
    println!("theme:   {}", state.current_theme);
    println!("variant: {}", state.current_variant);

    if let Some(ref last_applied) = state.last_applied {
        println!("applied: {}", last_applied);
    }

    Ok(())
}

fn handle_apply() -> Result<()> {
    let state = State::load()?;
    let config = Config::load()?;

    let generator = ThemeGenerator::new();
    generator.verify_theme_variant_exists(&state.current_theme, &state.current_variant)?;

    let symlink_manager = SymlinkManager::new();
    symlink_manager.update_current_symlink(&state.current_theme, &state.current_variant)?;

    let reload_dispatcher = ReloadDispatcher::new();
    let reload_result = reload_dispatcher.reload_apps(&config);

    if reload_result.has_failures() {
        warn!(
            "Applied current state ({}/{} reloaded, {} failed)",
            reload_result.success_count,
            reload_result.total_count,
            reload_result.failed_apps.len()
        );
    } else {
        debug!("Applied current state");
    }
    Ok(())
}

fn handle_completions(shell: CompletionShell) -> Result<()> {
    let mut cmd = Cli::command();
    let bin_name = "vogix";

    match shell {
        CompletionShell::Bash => generate(shells::Bash, &mut cmd, bin_name, &mut io::stdout()),
        CompletionShell::Zsh => generate(shells::Zsh, &mut cmd, bin_name, &mut io::stdout()),
        CompletionShell::Fish => generate(shells::Fish, &mut cmd, bin_name, &mut io::stdout()),
        CompletionShell::Pwsh => {
            generate(shells::PowerShell, &mut cmd, bin_name, &mut io::stdout())
        }
        CompletionShell::Elvish => generate(shells::Elvish, &mut cmd, bin_name, &mut io::stdout()),
    }

    Ok(())
}

// Note: navigate_variant() tests are in src/theme.rs (ThemeInfo::navigate)
// since they test the luminance-based navigation logic directly.
// Integration tests in nix/vm/test.nix cover the full CLI behavior.
