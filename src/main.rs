mod cache;
mod cli;
mod commands;
mod config;
mod errors;
mod reload;
mod scheme;
mod state;
mod symlink;
mod template;
mod theme;

use clap::CommandFactory;
use cli::{CacheCommands, Cli, Commands};
use commands::{
    handle_cache_clean, handle_completions, handle_list, handle_refresh, handle_status,
    handle_theme_change,
};
use errors::Result;
use log::error;

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
            Commands::Cache { command } => {
                return match command {
                    CacheCommands::Clean => handle_cache_clean(),
                };
            }
            Commands::Refresh => {
                return handle_refresh(cli.quiet);
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

// Note: navigate_variant() tests are in src/theme/types.rs (ThemeInfo::navigate)
// since they test the luminance-based navigation logic directly.
// Integration tests in nix/vm/tests/ cover the full CLI behavior.
