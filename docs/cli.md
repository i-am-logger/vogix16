# Vogix CLI Tool

The Vogix CLI is the primary user interface for managing themes in the Vogix16 system.

## Commands

### Core Theme Management

```bash
# Switch between dark and light variants of the current theme
vogix switch dark
vogix switch light

# Switch to a different theme (maintaining dark/light preference)
vogix theme aikido
vogix theme synthwave

# List available themes
vogix list

# Show current theme and variant
vogix status
```

### Configuration

The CLI tool is configured via a configuration file at `~/.config/vogix16/config.toml`:

```toml
default_theme = "aikido"
default_variant = "dark"
themed_apps = ["alacritty", "btop", "waybar"]
```

## System Integration

The CLI tool handles several background tasks:

1. **XDG Directory Monitoring**: Watches for changes in the XDG configuration directory
2. **Symlink Management**: Creates and updates symlinks to themed configuration directories
3. **State Persistence**: Saves the current theme and variant state
4. **Theme Generation**: Combines theme definitions with base configs to create themed versions
5. **Application Reloading**: Notifies applications to reload their configurations

## Implementation Details

The vogix CLI is implemented in Rust and provides:

- Fast, efficient theme switching
- Command completion for shells
- Error handling for missing themes or applications
- Support for custom theme directories
- Validation of theme definitions

For details on how applications are reloaded, see [Reload Mechanism](reload.md).

