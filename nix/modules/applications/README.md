# Application Configuration Modules

This directory contains Vogix theme configuration generators for various applications.

## Multi-Scheme Support

Application generators support all 4 color schemes through the `schemes` pattern:

```nix
# nix/modules/applications/alacritty.nix
{ lib, appLib }:
{
  configFile = "alacritty.toml";
  reloadMethod = { method = "touch"; };
  
  schemes = {
    vogix16 = colors: {
      # Semantic color usage (vogix16 philosophy)
      background = colors.background;
      foreground = colors.foreground-text;
      error = colors.danger;
      success = colors.success;
    };
    
    base16 = colors: {
      # Base16 standard mapping
      background = colors.base00;
      foreground = colors.base05;
      red = colors.base08;
      green = colors.base0B;
    };
    
    base24 = colors: {
      # Base24 with additional bright colors
      background = colors.base00;
      foreground = colors.base05;
      bright-red = colors.base12;
      bright-green = colors.base14;
    };
    
    ansi16 = colors: {
      # ANSI standard slot mapping
      background = colors.background;
      foreground = colors.foreground;
      red = colors.red;
      green = colors.green;
    };
  };
}
```

## Configuration Strategy

Vogix's minimalist philosophy ("functional colors for minimalist minds") applies to the **vogix16 scheme**. Other schemes follow their own conventions.

### vogix16 Scheme: Minimal ANSI by Default

For terminal emulators (alacritty, console), ANSI color slots are mapped minimally:
- **Monochromatic base** for most slots (blue, magenta, cyan → foreground colors)
- **Semantic colors only** for red/green/yellow (danger/success/warning)

This creates a minimal terminal by default.

### base16/base24/ansi16 Schemes: Standard Mappings

These schemes follow their respective standards, providing full color support as defined by their specifications.

### Application-Specific Configurations

**Examples**: btop, ls/eza, git, ripgrep, bat, vim, neovim, tmux, etc.

Each application gets scheme-aware configuration with appropriate color mappings:

- **vogix16**: Semantic colors for functional indicators only
- **base16/base24**: Standard syntax highlighting mappings
- **ansi16**: Traditional ANSI terminal colors

## Key Principle

**Scheme-appropriate coloring**: Each scheme generator respects the philosophy of that scheme. The vogix16 scheme is minimal by design; base16/base24/ansi16 provide full color support per their standards.

## Adding New Application Modules

When adding a new application:

1. **Create the generator file** in `nix/modules/applications/`
2. **Implement all 4 schemes** in the `schemes` attribute
3. **Follow each scheme's philosophy**:
   - vogix16: Only use functional colors for semantic meaning
   - base16/base24: Map to syntax highlighting categories
   - ansi16: Map to ANSI color slots
4. **Test with multiple schemes** to ensure correct output

### Generator Template

```nix
{ lib, appLib }:
{
  configFile = "path/to/config";
  reloadMethod = { method = "touch"; };  # or "signal", "command", "none"
  
  schemes = {
    vogix16 = colors: ''
      # Config using semantic names: colors.danger, colors.success, etc.
    '';
    
    base16 = colors: ''
      # Config using base16 names: colors.base00, colors.base08, etc.
    '';
    
    base24 = colors: ''
      # Config using base24 names: colors.base00-base17
    '';
    
    ansi16 = colors: ''
      # Config using ANSI names: colors.red, colors.green, etc.
    '';
  };
}
```

### Determining Semantic vs. Monochromatic (vogix16 scheme)

Ask: "Does this color convey information the user needs to know?"

**YES - Use functional colors:**
- Error states, warnings, success indicators
- Resource utilization levels (CPU at 90% vs 10%)
- Temperature/status gradients (cool → warm → hot)
- Active/selected/focused items
- Added/removed/modified content (git diffs, file changes)
- Important notifications or alerts

**NO - Use monochromatic:**
- UI borders, dividers, structural elements
- File type differentiation (unless indicating errors)
- Syntax highlighting for aesthetics
- Category labels without status meaning
- Navigation elements
- Decorative accents

**Real Examples:**

✓ btop CPU gradient: low (comment) → moderate (warning) → high (danger)
  - Semantic: User needs to know resource utilization levels

✓ git diff: added (success) / removed (danger) / modified (warning)
  - Semantic: Indicates type of change

✗ btop box borders: all use foreground-border
  - Not semantic: Just organizational structure

✗ File listing colors by type: use monochromatic
  - Not semantic: Type differentiation is informational, not status
