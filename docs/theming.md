# Theme Format and Structure

Vogix16 uses a structured theme format to ensure consistency across applications while maintaining flexibility.

## Theme Definition

A theme defines a color palette with base and functional colors:

```nix
{
  name = "aikido";
  description = "A minimal, calm theme inspired by martial arts philosophy";
  author = "Vogix Team";
  
  # Base colors (monochromatic scale)
  colors = {
    base00 = "#181818"; # Background
    base01 = "#282828"; # Lighter background
    base02 = "#383838"; # Selection background
    base03 = "#585858"; # Comments, invisibles
    base04 = "#B8B8B8"; # Dark foreground
    base05 = "#D8D8D8"; # Default foreground
    base06 = "#E8E8E8"; # Light foreground
    base07 = "#F8F8F8"; # Light background
    
    # Functional colors
    base08 = "#AB4642"; # Error/Danger
    base09 = "#DC9656"; # Warning/Caution
    base0A = "#F7CA88"; # Notice/Attention
    base0B = "#A1B56C"; # Success/Confirmed
    base0C = "#86C1B9"; # Active/Current
    base0D = "#7CAFC2"; # Information/Interactive
    base0E = "#BA8BAF"; # Focus/Highlight
    base0F = "#A16946"; # Special States
  };
  
  # Light variant reverses some colors
  light = {
    base00 = "#F8F8F8"; # Light variant background
    base01 = "#E8E8E8";
    # ... other reversed colors
  };
}
```

## Application Templates

For each supported application, there's a template that defines how the theme colors should be applied:

```nix
{
  name = "alacritty";
  template = ''
    # Colors configuration for Alacritty
    colors:
      primary:
        background: '{{base00}}'
        foreground: '{{base05}}'
      cursor:
        text: '{{base00}}'
        cursor: '{{base05}}'
      normal:
        black: '{{base00}}'
        red: '{{base08}}'
        green: '{{base0B}}'
        yellow: '{{base0A}}'
        blue: '{{base0D}}'
        magenta: '{{base0E}}'
        cyan: '{{base0C}}'
        white: '{{base05}}'
      bright:
        black: '{{base03}}'
        red: '{{base08}}'
        green: '{{base0B}}'
        yellow: '{{base0A}}'
        blue: '{{base0D}}'
        magenta: '{{base0E}}'
        cyan: '{{base0C}}'
        white: '{{base07}}'
  '';
}
```

## Theme Processing

When a theme is applied:

1. The base configuration is read from `/run/user/1000/home-manager/.config/`
2. The theme definition is applied to application templates
3. The resulting themed configuration is written to `/run/user/1000/vogix16/themes/`

## Directory Structure

```
/nix/store/.../.themes/
    ├── aikido.nix
    ├── synthwave.nix
    └── ...

~/.config/vogix16/themes/  # Optional user themes
    ├── mytheme.nix
    └── ...

/run/user/1000/vogix16/themes/
    ├── aikido-dark/
    │   ├── alacritty/
    │   ├── btop/
    │   └── ...
    ├── aikido-light/
    │   ├── alacritty/
    │   ├── btop/
    │   └── ...
    └── ...
```

## Adding New Themes

Users can create custom themes by:

1. Creating a new theme definition file in `~/.config/vogix16/themes/`
2. Following the theme format specification
3. Using `vogix list` to verify the theme is detected
4. Applying with `vogix theme mytheme`

## Theme Compatibility

The system ensures:

1. All required colors are defined
2. Color values are valid
3. Light variants have appropriate contrast
4. Application templates can be properly rendered

