# Vogix16 Architecture

## 1. Overview

Vogix16 is a minimalist design system focused on functional color usage in NixOS. This document provides a high-level overview of the architecture that enables dynamic theme switching at runtime.

The system is designed to allow users to switch between themes (color palettes) and variants (dark/light) without requiring a rebuild, making the theming experience seamless.

## 2. Key Components

- **Theme Definitions**: Theme files defining color palettes in the Vogix16 format
- **Theme Generator**: Processes base configs with theme colors to create application-specific configs
- **Theme Storage**: In-memory storage of theme variations in the runtime directory
- **Vogix CLI**: Command-line interface for interacting with the theme system
- **Reload Mechanism**: System for notifying applications of theme changes

For detailed implementation of specific components, see the specialized documentation:
- [CLI Tool Documentation](cli.md)
- [Reload Mechanism](reload.md)
- [Theme Format and Structure](theming.md)

## 3. Directory Structure

```
/run/user/1000/home-manager/.config/  # home-manager base configs
    ├── app1/
    ├── app2/
    └── ...

/run/user/1000/vogix16/themes/       # themed configurations
    ├── theme1-dark/
    │   ├── app1/
    │   └── app2/
    ├── theme1-light/
    │   ├── app1/
    │   └── app2/
    └── ...

~/.config/                           # actual config locations
    ├── app1 -> /run/user/1000/vogix16/themes/current-theme/app1
    ├── app2 -> /run/user/1000/vogix16/themes/current-theme/app2
    └── ... (non-themed apps managed normally by home-manager)
```

## 4. Home-Manager Integration

Home-manager continues to manage non-themed applications normally in `~/.config/`. For themed applications:

1. Base configurations are generated in `/run/user/1000/home-manager/.config/`
2. The Vogix16 system processes these to create themed variants
3. Symlinks in `~/.config/` point to the current theme's configuration

```nix
# Example home-manager configuration
{
  vogix16 = {
    enable = true;
    defaultTheme = "aikido";
    variant = "dark";
    themedApps = [ "alacritty" "btop" "waybar" ];
  };
}
```

## 5. Theme Switching Mechanism

When a user switches themes or variants:

1. The vogix CLI tool updates symlinks to point to the new theme or variant
2. Applications are notified to reload their configurations
3. The change takes effect immediately without requiring a rebuild

## 6. Implementation Requirements

1. Systemd user service to initialize the directory structure
2. Theme generator to process base configs with theme definitions
3. Vogix CLI tool for user interaction
4. Library of theme definitions
5. Application-specific reload configurations

