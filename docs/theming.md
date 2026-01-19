# Theme Format and Structure

Vogix supports multiple color schemes and uses Nix-based theme definitions with application generators to ensure consistency across applications.

## Color Schemes

Vogix supports 4 color schemes, each with its own philosophy:

| Scheme | Philosophy | Source |
|--------|------------|--------|
| **vogix16** | Semantic design system - colors convey functional meaning | Native (`themes/vogix16/*.nix`) |
| **base16** | Syntax highlighting - 16 colors for code categories | [tinted-schemes](https://github.com/i-am-logger/tinted-schemes) |
| **base24** | Extended base16 with 8 additional bright colors | [tinted-schemes](https://github.com/i-am-logger/tinted-schemes) |
| **ansi16** | Terminal standard - traditional ANSI color mappings | [iTerm2-Color-Schemes](https://github.com/i-am-logger/iTerm2-Color-Schemes) |

## Theme Definition Format

### New Multi-Variant Format

Themes now support multiple variants with polarity and automatic ordering:

```nix
# themes/vogix16/catppuccin.nix
{
  name = "catppuccin";
  variants = {
    latte = {
      polarity = "light";
      colors = {
        base00 = "#eff1f5";  # Background
        base01 = "#e6e9ef";
        base02 = "#ccd0da";
        base03 = "#bcc0cc";
        base04 = "#acb0be";
        base05 = "#4c4f69";  # Text
        base06 = "#dc8a78";
        base07 = "#7287fd";
        base08 = "#d20f39";  # Danger
        base09 = "#fe640b";  # Warning
        base0A = "#df8e1d";  # Notice
        base0B = "#40a02b";  # Success
        base0C = "#179299";  # Active
        base0D = "#1e66f5";  # Link
        base0E = "#8839ef";  # Highlight
        base0F = "#dd7878";  # Special
      };
    };
    frappe = {
      polarity = "dark";
      colors = { /* ... */ };
    };
    macchiato = {
      polarity = "dark";
      colors = { /* ... */ };
    };
    mocha = {
      polarity = "dark";
      colors = { /* ... */ };
    };
  };
  defaults = {
    dark = "mocha";
    light = "latte";
  };
}
```

### Theme Structure

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Theme identifier |
| `variants` | Yes | Map of variant name → variant definition |
| `variants.<name>.polarity` | Yes | `"dark"` or `"light"` |
| `variants.<name>.colors` | Yes | Map of base00-base0F (or base00-base17 for base24) |
| `defaults.dark` | No | Default variant for `-v dark` navigation |
| `defaults.light` | No | Default variant for `-v light` navigation |

### Automatic Variant Ordering

Variants are automatically ordered by luminance (lightest to darkest) based on the `base00` (background) color. This enables the `vogix -v darker` and `vogix -v lighter` navigation commands.

For catppuccin, the auto-derived order is: `latte → frappe → macchiato → mocha`

### Single-Variant Themes

Themes with only one variant (like dracula) work correctly:

```nix
{
  name = "dracula";
  variants = {
    dracula = {
      polarity = "dark";
      colors = { /* ... */ };
    };
  };
  # defaults not needed for single-variant themes
}
```

All navigation commands (`-v dark`, `-v light`, `-v darker`, `-v lighter`) resolve to the only available variant.

## Legacy Format (vogix16 only)

For backward compatibility, vogix16 themes can use the simpler two-variant format:

```nix
# themes/vogix16/aikido.nix
{
  dark = {
    base00 = "#181818"; # Background
    base01 = "#282828"; # Surface
    base02 = "#383838"; # Selection
    base03 = "#585858"; # Comments
    base04 = "#B8B8B8"; # Borders
    base05 = "#D8D8D8"; # Text
    base06 = "#E8E8E8"; # Headings
    base07 = "#F8F8F8"; # Bright
    base08 = "#AB4642"; # Danger
    base09 = "#DC9656"; # Warning
    base0A = "#F7CA88"; # Notice
    base0B = "#A1B56C"; # Success
    base0C = "#86C1B9"; # Active
    base0D = "#7CAFC2"; # Link
    base0E = "#BA8BAF"; # Highlight
    base0F = "#A16946"; # Special
  };
  light = {
    base00 = "#F8F8F8"; # Background (lightest)
    # ... reversed monochromatic scale
    base08 = "#AB4642"; # Functional colors stay the same
    # ...
  };
}
```

This is automatically converted to the multi-variant format internally.

## Imported Themes

### base16 and base24

Themes are imported from YAML files in the [tinted-schemes](https://github.com/i-am-logger/tinted-schemes) repository:

```
tinted-schemes/
├── base16/
│   ├── catppuccin/
│   │   ├── latte.yaml
│   │   ├── frappe.yaml
│   │   ├── macchiato.yaml
│   │   └── mocha.yaml
│   ├── dracula/
│   │   └── dracula.yaml
│   └── ...
└── base24/
    └── ...
```

Directory name = theme name, file name = variant name.

### ansi16

Themes are imported from TOML files in the [iTerm2-Color-Schemes](https://github.com/i-am-logger/iTerm2-Color-Schemes) repository.

## Application Generators

Application generators convert theme colors into application-specific configuration files. They support all 4 schemes through pattern matching:

```nix
# nix/modules/applications/alacritty.nix
{ lib, appLib }:
{
  configFile = "alacritty.toml";
  reloadMethod = { method = "touch"; };
  
  schemes = {
    vogix16 = colors: {
      # Semantic color usage
      background = colors.background;
      foreground = colors.foreground-text;
      error = colors.danger;
    };
    
    base16 = colors: {
      # Base16 standard mapping
      background = colors.base00;
      foreground = colors.base05;
      error = colors.base08;
    };
    
    base24 = colors: {
      # Base24 with bright colors
      background = colors.base00;
      foreground = colors.base05;
      bright-red = colors.base12;
    };
    
    ansi16 = colors: {
      # ANSI standard mapping
      background = colors.background;
      foreground = colors.foreground;
      red = colors.red;
    };
  };
}
```

## Theme Processing (Build Time)

Theme processing happens entirely at **Nix build time**, not at runtime:

1. **Discovery**: 
   - Native themes from `themes/vogix16/*.nix`
   - Imported themes from forked repos (base16, base24, ansi16)

2. **Normalization**: All themes converted to multi-variant format

3. **Generation**: For each (scheme, theme, variant, app) combination:
   - Load theme definition
   - Select the appropriate scheme generator
   - Apply generator to produce config file
   - Write to Nix store

4. **Systemd**: On user login, symlink packages to `/run/user/UID/vogix/themes/`

## Directory Structure

```
/nix/store/
├── xxxx-vogix-base16-catppuccin-mocha/
│   ├── alacritty/colors.toml
│   ├── btop/themes/vogix.theme
│   └── console/palette
├── yyyy-vogix-base16-catppuccin-latte/
├── zzzz-vogix-vogix16-aikido-dark/
└── ...

/run/user/1000/vogix/
├── themes/
│   ├── base16-catppuccin-mocha -> /nix/store/xxxx-...
│   ├── base16-catppuccin-latte -> /nix/store/yyyy-...
│   ├── vogix16-aikido-dark -> /nix/store/zzzz-...
│   ├── current-theme -> base16-catppuccin-mocha
│   └── ...
├── manifest.toml
└── state/state.toml

~/.config/
├── alacritty/colors.toml -> /run/user/1000/vogix/themes/current-theme/alacritty/colors.toml
└── ...
```

## Adding New Themes

### Native vogix16 Theme

1. **Create theme file**:
   ```nix
   # themes/vogix16/my-theme.nix
   {
     name = "my-theme";
     variants = {
       dark = {
         polarity = "dark";
         colors = {
           base00 = "#1a1a1a";
           # ... all 16 colors
         };
       };
       light = {
         polarity = "light";
         colors = {
           base00 = "#f5f5f5";
           # ... all 16 colors
         };
       };
     };
     defaults = { dark = "dark"; light = "light"; };
   }
   ```

2. **Rebuild**: Run `home-manager switch`
3. **Verify**: Run `vogix list -s vogix16`
4. **Apply**: Run `vogix -s vogix16 -t my-theme -v dark`

### Contributing to Upstream

For base16/base24 themes, contribute to [tinted-schemes](https://github.com/tinted-theming/schemes).
For ansi16 themes, contribute to [iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes).

## Theme Validation

The system ensures at build time:

1. All required colors are defined (16 for base16/vogix16/ansi16, 24 for base24)
2. Color values are valid hex format (#RRGGBB)
3. Polarity is specified for each variant
4. Generators produce valid configs
