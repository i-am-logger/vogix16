use crate::scheme::Scheme;
use clap::{Parser, Subcommand, ValueEnum};

#[derive(Parser)]
#[command(name = env!("CARGO_PKG_NAME"))]
#[command(author = env!("CARGO_PKG_AUTHORS"))]
#[command(version = env!("CARGO_PKG_VERSION"))]
#[command(about = env!("CARGO_PKG_DESCRIPTION"), long_about = None)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Option<Commands>,

    /// Set the color scheme (vogix16, base16, base24, ansi16)
    #[arg(short = 's', long, global = true)]
    pub scheme: Option<Scheme>,

    /// Set the theme name
    #[arg(short = 't', long, global = true)]
    pub theme: Option<String>,

    /// Set the variant (e.g., dark, light, dawn, moon)
    /// Use "darker" or "lighter" to navigate within the current theme
    #[arg(short = 'v', long, global = true)]
    pub variant: Option<String>,

    /// Suppress non-error output
    #[arg(short = 'q', long, global = true)]
    pub quiet: bool,
}

#[derive(Subcommand)]
pub enum Commands {
    /// List all available themes
    #[command(alias = "ls")]
    List {
        /// Filter by scheme (vogix16, base16, base24, ansi16)
        #[arg(short = 's', long)]
        scheme: Option<Scheme>,

        /// Show variants for each theme
        #[arg(long)]
        variants: bool,
    },

    /// Show current theme and variant status
    Status,

    /// Generate shell completions
    Completions {
        /// Shell to generate completions for
        shell: CompletionShell,
    },

    /// Manage the template cache
    Cache {
        #[command(subcommand)]
        command: CacheCommands,
    },

    /// Refresh current theme (reapply without changes)
    Refresh,
}

#[derive(Subcommand)]
pub enum CacheCommands {
    /// Remove stale cache entries from old template versions
    Clean,
}

#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord, ValueEnum)]
pub enum CompletionShell {
    /// Bash shell
    Bash,
    /// Zsh shell
    Zsh,
    /// Fish shell
    Fish,
    /// PowerShell
    Pwsh,
    /// Elvish shell
    Elvish,
}

impl Cli {
    pub fn parse_args() -> Self {
        Self::parse()
    }

    /// Check if any theme change flags were provided
    pub fn has_theme_changes(&self) -> bool {
        self.scheme.is_some() || self.theme.is_some() || self.variant.is_some()
    }

    /// Check if variant is a navigation command (darker/lighter)
    pub fn is_variant_navigation(&self) -> bool {
        if let Some(ref v) = self.variant {
            matches!(v.to_lowercase().as_str(), "darker" | "lighter")
        } else {
            false
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn cli_with_flags(scheme: Option<Scheme>, theme: Option<&str>, variant: Option<&str>) -> Cli {
        Cli {
            command: None,
            scheme,
            theme: theme.map(String::from),
            variant: variant.map(String::from),
            quiet: false,
        }
    }

    #[test]
    fn test_has_theme_changes_none() {
        let cli = cli_with_flags(None, None, None);
        assert!(!cli.has_theme_changes());
    }

    #[test]
    fn test_has_theme_changes_scheme_only() {
        let cli = cli_with_flags(Some(Scheme::Base16), None, None);
        assert!(cli.has_theme_changes());
    }

    #[test]
    fn test_has_theme_changes_theme_only() {
        let cli = cli_with_flags(None, Some("gruvbox"), None);
        assert!(cli.has_theme_changes());
    }

    #[test]
    fn test_has_theme_changes_variant_only() {
        let cli = cli_with_flags(None, None, Some("dark"));
        assert!(cli.has_theme_changes());
    }

    #[test]
    fn test_has_theme_changes_all_flags() {
        let cli = cli_with_flags(Some(Scheme::Base16), Some("gruvbox"), Some("dark"));
        assert!(cli.has_theme_changes());
    }

    #[test]
    fn test_is_variant_navigation_darker() {
        let cli = cli_with_flags(None, None, Some("darker"));
        assert!(cli.is_variant_navigation());
    }

    #[test]
    fn test_is_variant_navigation_lighter() {
        let cli = cli_with_flags(None, None, Some("lighter"));
        assert!(cli.is_variant_navigation());
    }

    #[test]
    fn test_is_variant_navigation_case_insensitive() {
        let cli = cli_with_flags(None, None, Some("DARKER"));
        assert!(cli.is_variant_navigation());

        let cli = cli_with_flags(None, None, Some("Lighter"));
        assert!(cli.is_variant_navigation());
    }

    #[test]
    fn test_is_variant_navigation_normal_variant() {
        let cli = cli_with_flags(None, None, Some("dark"));
        assert!(!cli.is_variant_navigation());

        let cli = cli_with_flags(None, None, Some("light"));
        assert!(!cli.is_variant_navigation());

        let cli = cli_with_flags(None, None, Some("moon"));
        assert!(!cli.is_variant_navigation());
    }

    #[test]
    fn test_is_variant_navigation_none() {
        let cli = cli_with_flags(None, None, None);
        assert!(!cli.is_variant_navigation());
    }
}
