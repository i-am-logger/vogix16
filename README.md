# Vogix
[![CI](https://github.com/i-am-logger/vogix/actions/workflows/ci-and-release.yml/badge.svg?branch=master)](https://github.com/i-am-logger/vogix/actions/workflows/ci-and-release.yml)
[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)
[![NixOS](https://img.shields.io/badge/NixOS-5277C3?logo=nixos&logoColor=white)](https://nixos.org)
[![Rust](https://img.shields.io/badge/Rust-2024-orange?logo=rust&logoColor=white)](https://www.rust-lang.org/)

> Runtime theme management for NixOS.

Vogix is a runtime theme management system for NixOS with multi-scheme support. Switch themes without system rebuilds across 4 color schemes on Linux (macOS is untested).

> [!WARNING]  
> right now this runs and working in a vm.
> ```bash
> nix run .#vogix-vm
> ```
> vogix is alpha, it is not battlefield tested though i'm working on integrating it to my system. 

## Philosophy

Vogix supports multiple color scheme philosophies:

- **vogix16**: Semantic design system - colors convey functional meaning (errors, warnings, success) The vogix16 scheme follows a "less is more" approach where functional colors convey information the user needs to know, while monochromatic colors provide structure. See [Vogix16 Design System](docs/vogix16-design-system.md) for detailed guidelines.
- **ansi16**: Terminal standard - traditional ANSI color slot mappings
- **base16**: Minimal palette standard for terminals and UI, widely used for syntax highlighting
- **base24**: Expanded base16 palette with extra accents for richer UI and syntax groups



## Features

- **Multi-Scheme Support**: 4 color schemes (vogix16, ansi16, base16, base24)
  - **vogix16** (default) - Semantic design system focused on functional colors (19 native themes)
  - **ansi16** - Terminal ANSI standard (~450 themes)
  - **base16** - Minimal palette standard, widely used for UI and syntax highlighting (~300 themes)
  - **base24** - Expanded base16 palette with extra accents (~180 themes)
- **Runtime Theme Switching**: Change themes without NixOS rebuilds
- **Multi-Variant Themes**: Themes can have multiple variants (e.g., catppuccin: latte, frappe, macchiato, mocha)
- **Polarity Navigation**: Switch between lighter/darker variants with `vogix -v lighter` / `vogix -v darker`
- **Application-Specific Configs**: Direct integration for [supported applications](https://github.com/i-am-logger/vogix/tree/master/nix/modules/applications)
- **Multiple Reload Methods**: DBus, Unix signals, Sway IPC, filesystem watching
- **Nix-Based Theme Generation**: All theme configurations pre-generated at build time
- **NixOS Integration**: Home Manager module with systemd service
- **Shell Completions**: Support for Bash, Zsh, Fish, and Elvish

## Quick Start

### Installation (NixOS with Flakes)

Add to your `flake.nix`:

```nix
{
  inputs.vogix.url = "github:i-am-logger/vogix";

  outputs = { nixpkgs, home-manager, vogix, ... }: {
    homeConfigurations.youruser = home-manager.lib.homeManagerConfiguration {
      modules = [
        vogix.homeManagerModules.default
        {
          # Enable applications you want to theme
          programs.alacritty.enable = true;
          programs.btop.enable = true;

          # Configure vogix
          programs.vogix = {
            enable = true;
            defaultScheme = "vogix16";
            defaultTheme = "aikido";
            defaultVariant = "dark";
          };
        }
      ];
    };
  };
}
```

### Usage

```bash
# Show current theme state
vogix status

# List all schemes with theme counts
vogix list

# List themes in a specific scheme
vogix list -s base16

# Set scheme, theme, and variant
vogix -s base16 -t catppuccin -v mocha

# Navigate to a darker variant
vogix -v darker

# Navigate to a lighter variant
vogix -v lighter

# Switch to default dark/light variant
vogix -v dark
vogix -v light

# Generate shell completions
vogix completions bash > ~/.local/share/bash-completion/completions/vogix
```

## Testing

Vogix includes automated integration tests:

```bash
# Run all tests
./test.sh

# Or use nix directly
nix flake check
```

See [TESTING.md](TESTING.md) for detailed testing documentation.

## Documentation

- [Architecture](docs/architecture.md) - System architecture and integration
- [CLI Reference](docs/cli.md) - Command-line interface guide
- [Theming Guide](docs/theming.md) - Creating and customizing themes
- [Reload Mechanisms](docs/reload.md) - Application reload methods
- [Vogix16 Design System](docs/vogix16-design-system.md) - Default scheme philosophy and formats

## Defaults

Vogix ships with the vogix16 scheme as the default, using the `aikido` theme in `dark` mode unless configured otherwise.

## Example Themes

Vogix supports themes from multiple sources:

- **vogix16**: Native themes in `themes/vogix16/` (aikido, forest, etc.)
- **ansi16**: Imported from [iTerm2-Color-Schemes](https://github.com/i-am-logger/iTerm2-Color-Schemes)
- **base16/base24**: Imported from [tinted-schemes](https://github.com/i-am-logger/tinted-schemes) (catppuccin, dracula, gruvbox, nord, etc.)

Create custom vogix16 themes by following the format in `themes/vogix16/aikido.nix`.


## Requirements

- NixOS (for full integration) or any Linux distribution (for standalone binary)
- Rust Edition 2024
- DBus (for DBus reload functionality)
- Optional: Sway (for Sway IPC reload)

## License

Creative Commons Attribution-NonCommercial-ShareAlike (CC BY-NC-SA) 4.0 International

See [LICENSE](LICENSE) for details.

## Contributing

- [Contributing Guide](CONTRIBUTING.md) - How to contribute to Vogix
- [Development Guide](DEVELOPMENT.md) - Setting up development environment
- [Testing Guide](TESTING.md) - Automated testing documentation

## Acknowledgments

Vogix is inspired by projects in the theme ecosystem and incorporates scheme data from upstream sources:

- [tinted-theming/schemes](https://github.com/tinted-theming/schemes) - Source for base16/base24 schemes (via [fork](https://github.com/i-am-logger/tinted-schemes))
- [iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes) - Source for ansi16 schemes (via [fork](https://github.com/i-am-logger/iTerm2-Color-Schemes))
- [Base16](https://github.com/chriskempson/base16) - Palette standard that informed scheme conventions
- [Stylix](https://github.com/nix-community/stylix) - NixOS theming inspiration
- [Omarchy](https://github.com/basecamp/omarchy) - Runtime theme switching inspiration
