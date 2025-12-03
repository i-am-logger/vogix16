# Vogix16
[![CI and Release](https://github.com/i-am-logger/vogix16/actions/workflows/ci-and-release.yml/badge.svg?branch=master)](https://github.com/i-am-logger/vogix16/actions/workflows/ci-and-release.yml)
[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)
[![NixOS](https://img.shields.io/badge/NixOS-5277C3?logo=nixos&logoColor=white)](https://nixos.org)
[![Rust](https://img.shields.io/badge/Rust-2024-orange?logo=rust&logoColor=white)](https://www.rust-lang.org/)

> Functional colors for minimalist minds.

A minimalist design system and runtime theme management system for NixOS. Vogix16 combines a 16-color palette with functional semantic meaning, providing dynamic theme switching without requiring system rebuilds.

## Features

- **16-Color Design System**: Monochromatic base (base00-base07) + functional colors (base08-base0F)
- **Runtime Theme Switching**: Change themes without NixOS rebuilds
- **Dark/Light Variants**: Automatic variant switching with maintained semantic meaning
- **Application-Specific Configs**: Direct Vogix16 integration for supported applications
- **Minimal ANSI Support**: Terminal emulators provide minimal ANSI passthrough (not an ANSI color scheme)
- **Multiple Reload Methods**: DBus, Unix signals, Sway IPC, filesystem watching
- **Nix-Based Theme Generation**: All theme configurations pre-generated at build time
- **NixOS Integration**: Home Manager module with systemd service
- **Shell Completions**: Support for Bash, Zsh, Fish, PowerShell, Elvish

## Quick Start

### Installation (NixOS with Flakes)

Add to your `flake.nix`:

```nix
{
  inputs.vogix16.url = "github:i-am-logger/vogix16";

  outputs = { nixpkgs, home-manager, vogix16, ... }: {
    homeConfigurations.youruser = home-manager.lib.homeManagerConfiguration {
      modules = [
        vogix16.homeManagerModules.default
        {
          # Enable applications you want to theme
          programs.alacritty.enable = true;
          programs.btop.enable = true;

          # Configure vogix16
          programs.vogix16 = {
            enable = true;
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
# Check current theme and variant
vogix status

# List available themes
vogix list

# Switch themes
vogix theme forest

# Toggle between dark and light variants
vogix switch

# Generate shell completions
vogix completions bash > ~/.local/share/bash-completion/completions/vogix
```

## Testing

Vogix16 includes comprehensive automated integration tests:

```bash
# Run all tests
./test.sh

# Or use nix directly
nix flake check
```

See [TESTING.md](TESTING.md) for detailed testing documentation.

## Documentation

- [Design System](docs/design-system.md) - Color philosophy and Vogix16 format
- [Architecture](docs/architecture.md) - System architecture and integration
- [CLI Reference](docs/cli.md) - Command-line interface guide
- [Theming Guide](docs/theming.md) - Creating and customizing themes
- [Reload Mechanisms](docs/reload.md) - Application reload methods
- [Contributing Guide](CONTRIBUTING.md) - How to contribute to Vogix16
- [Development Guide](DEVELOPMENT.md) - Setting up development environment
- [Testing Guide](TESTING.md) - Automated testing documentation
- [Implementation](IMPLEMENTATION.md) - Complete implementation details

## Example Themes

Vogix16 includes example themes demonstrating the design system:

- **Aikido** - Grayscale monochromatic (default)
- **Forest** - Green monochromatic

Create custom themes by following the format in `themes/aikido.nix`.

## Philosophy

Vogix16 follows a "less is more" approach:

- Colors used intentionally for functional value only
- Interface surfaces use monochromatic scales
- True distinct colors reserved for functional elements
- Dark and light variants maintain semantic consistency

Functional colors convey information the user needs to know (errors, warnings, resource levels), while monochromatic colors provide structure. See [Design System](docs/design-system.md) for detailed guidelines on semantic color usage.

### Not an ANSI Color Scheme

Vogix16 is a **design system with semantic color meanings**, not an ANSI color scheme:

- Applications should use Vogix16 directly through their own configuration files
- Terminal emulators provide **minimal ANSI mappings** (monochromatic + semantic colors only)
- ANSI passthrough is deliberately minimal to maintain the design philosophy
- Each supported application gets a thoughtfully designed Vogix16 configuration

## Requirements

- NixOS (for full integration) or any Linux distribution (for standalone binary)
- Rust Edition 2024
- DBus (for DBus reload functionality)
- Optional: Sway (for Sway IPC reload)

## License

Creative Commons Attribution-NonCommercial-ShareAlike (CC BY-NC-SA) 4.0 International

See [LICENSE](LICENSE) for details.

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines on:

- Submitting themes
- Adding application support
- Code style and conventions
- Testing requirements
- Pull request process

## Acknowledgments

Vogix16 builds on the shoulders of [Base16](https://github.com/chriskempson/base16), which proved a 16-color palette could unify a system; [Stylix](https://github.com/nix-community/stylix), which made theming native to NixOS; and [Omarchy](https://github.com/basecamp/omarchy), which showed how seamless runtime theme switching could be. Each shaped what Vogix16 became.
