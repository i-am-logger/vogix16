{ lib }:

# Helper function to generate Linux console palette from semantic colors
# Returns hexadecimal format palette for setvtrgb command
# Format: 16 lines with hex colors (e.g., #000000)
colors:
let
  # Ensure color has # prefix
  ensureHash = color:
    if lib.hasPrefix "#" color
    then color
    else "#${color}";

  # ANSI color mapping: Minimal by default - monochromatic + semantic only
  # Apps needing specific colors should have their own Vogix16 configs
  palette = [
    colors.background          # 0: Black
    colors.danger              # 1: Red (semantic: errors)
    colors.success             # 2: Green (semantic: success)
    colors.warning             # 3: Yellow (semantic: warnings)
    colors.foreground-text     # 4: Blue
    colors.foreground-text     # 5: Magenta
    colors.foreground-text     # 6: Cyan
    colors.foreground-text     # 7: White
    colors.foreground-comment  # 8: Bright Black
    colors.danger              # 9: Bright Red (semantic: errors)
    colors.success             # 10: Bright Green (semantic: success)
    colors.warning             # 11: Bright Yellow (semantic: warnings)
    colors.foreground-heading  # 12: Bright Blue
    colors.foreground-heading  # 13: Bright Magenta
    colors.foreground-heading  # 14: Bright Cyan
    colors.foreground-bright   # 15: Bright White
  ];

  # Ensure all colors have # prefix
  hexColors = map ensureHash palette;
in
# Return hexadecimal format: 16 lines with # prefix
lib.concatStringsSep "\n" hexColors
