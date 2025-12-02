# Theme Format and Structure

Vogix16 uses Nix-based theme definitions and application generators to ensure consistency across applications while maintaining flexibility.

## Theme Definition Format

A theme is a Nix file defining both dark and light variants:

```nix
# themes/aikido.nix
{
  dark = {
    # Base colors (monochromatic scale) - darkest to lightest
    base00 = "#181818"; # Background
    base01 = "#282828"; # Surface
    base02 = "#383838"; # Selection
    base03 = "#585858"; # Comments
    base04 = "#B8B8B8"; # Borders
    base05 = "#D8D8D8"; # Text
    base06 = "#E8E8E8"; # Headings
    base07 = "#F8F8F8"; # Bright

    # Functional colors (semantic purpose)
    base08 = "#AB4642"; # Danger (errors, destructive actions)
    base09 = "#DC9656"; # Warning (caution, important notifications)
    base0A = "#F7CA88"; # Notice (status, announcements)
    base0B = "#A1B56C"; # Success (completed, positive)
    base0C = "#86C1B9"; # Active (current selection, focused)
    base0D = "#7CAFC2"; # Link (interactive, informational)
    base0E = "#BA8BAF"; # Highlight (focus indicators)
    base0F = "#A16946"; # Special (system, specialized)
  };

  light = {
    # Light variant reverses base colors - lightest to darkest
    base00 = "#F8F8F8"; # Background (lightest)
    base01 = "#E8E8E8";
    base02 = "#D8D8D8";
    base03 = "#B8B8B8";
    base04 = "#585858";
    base05 = "#383838";
    base06 = "#282828";
    base07 = "#181818"; # Bright (darkest)

    # Functional colors maintain same semantic purpose
    base08 = "#AB4642"; # Danger
    base09 = "#DC9656"; # Warning
    base0A = "#F7CA88"; # Notice
    base0B = "#A1B56C"; # Success
    base0C = "#86C1B9"; # Active
    base0D = "#7CAFC2"; # Link
    base0E = "#BA8BAF"; # Highlight
    base0F = "#A16946"; # Special
  };
}
```

## Application Generators

Application generators are Nix functions that convert theme colors into application-specific configuration files. They're located in `nix/modules/applications/`.

### Example: Alacritty Generator

```nix
# nix/modules/applications/alacritty.nix
{ lib }: colors: ''
[colors.primary]
background = "${colors.background}"
foreground = "${colors.foreground-text}"

[colors.cursor]
text = "${colors.background}"
cursor = "${colors.foreground-text}"

[colors.normal]
black = "${colors.background}"
red = "${colors.danger}"
green = "${colors.success}"
yellow = "${colors.notice}"
blue = "${colors.link}"
magenta = "${colors.highlight}"
cyan = "${colors.active}"
white = "${colors.foreground-text}"

[colors.bright]
black = "${colors.foreground-comment}"
red = "${colors.danger}"
green = "${colors.success}"
yellow = "${colors.notice}"
blue = "${colors.link}"
magenta = "${colors.highlight}"
cyan = "${colors.active}"
white = "${colors.foreground-bright}"
''
```

**Key Points:**
- Generators are pure Nix functions: `colors -> string`
- Input `colors` has semantic names (background, danger, success, etc.)
- Output is the complete config file content
- No templating engine - just Nix string interpolation

## Theme Processing (Build Time)

Theme processing happens entirely at **Nix build time**, not at runtime:

1. **Discovery**: home-manager module discovers all themes in `themes/*.nix`
2. **Semantic Mapping**: Converts baseXX colors to semantic names:
   ```nix
   semanticColors = baseColors: {
     background = baseColors.base00;
     danger = baseColors.base08;
     success = baseColors.base0B;
     # ... etc
   };
   ```
3. **Generation**: For each (theme, variant, app) combination:
   - Load theme definition: `themes/aikido.nix`
   - Extract variant colors: `theme.dark` or `theme.light`
   - Convert to semantic colors
   - Apply generator: `alacrittyGenerator colors`
   - Write to Nix store: `/nix/store/xxxx-vogix16-theme-aikido-dark/alacritty/colors.toml`
4. **Package**: Create derivation containing all generated configs
5. **Systemd**: On user login, symlink packages from `/nix/store` to `/run/user/UID/vogix16/themes/`

**Critical**: The vogix CLI never generates configs - it only manages the `current-theme` symlink.

## Directory Structure

```
/nix/store/
    ├── xxxx-vogix16-theme-aikido-dark/      # Immutable generated configs
    │   ├── alacritty/colors.toml
    │   ├── btop/themes/vogix.theme
    │   └── console/palette
    ├── yyyy-vogix16-theme-aikido-light/
    ├── zzzz-vogix16-theme-forest-dark/
    └── ...

/run/user/1000/vogix16/
    ├── themes/                              # Symlinks created by systemd service
    │   ├── aikido-dark -> /nix/store/xxxx-vogix16-theme-aikido-dark
    │   ├── aikido-light -> /nix/store/yyyy-vogix16-theme-aikido-light
    │   ├── forest-dark -> /nix/store/zzzz-vogix16-theme-forest-dark
    │   ├── current-theme -> aikido-dark     # Updated by vogix CLI
    │   └── ...
    ├── manifest.toml
    └── state/state.toml

~/.config/                                   # App configs point to current-theme
    ├── alacritty/colors.toml -> /run/user/1000/vogix16/themes/current-theme/alacritty/colors.toml
    └── ...
```

## Adding New Themes

To add a custom theme:

1. **Create theme file** in your flake or locally:
   ```nix
   # themes/my-theme.nix
   {
     dark = {
       base00 = "#1a1a1a";
       # ... define all 16 colors
     };
     light = {
       base00 = "#f5f5f5";
       # ... define all 16 colors
     };
   }
   ```

2. **Add to home-manager config**:
   ```nix
   programs.vogix16 = {
     enable = true;
     themes.my-theme = ./themes/my-theme.nix;  # Register custom theme
     defaultTheme = "my-theme";
   };
   ```

3. **Rebuild**: Run `home-manager switch` to generate configs
4. **Verify**: Run `vogix list` to see your theme
5. **Apply**: Run `vogix theme my-theme`

## Adding New Application Generators

To add support for a new application:

1. **Create generator** in your module:
   ```nix
   # In your home-manager config or custom module
   programs.vogix16.myapp-generator = { lib }: colors: ''
     # Generate app config using semantic color names
     background-color: ${colors.background}
     text-color: ${colors.foreground-text}
     error-color: ${colors.danger}
   '';
   ```

2. **Enable the app**:
   ```nix
   programs.myapp.enable = true;  # Vogix16 auto-detects and themes it
   ```

See existing generators in `nix/modules/applications/` for examples.

## Theme Validation

The system ensures at build time:

1. All 16 colors (base00-base0F) are defined
2. Color values are valid hex format (#RRGGBB)
3. Both dark and light variants exist
4. Generators produce valid configs

