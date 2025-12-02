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

  # Standard Linux console color mapping (ANSI order)
  palette = [
    colors.background          # 0: Black
    colors.danger              # 1: Red
    colors.success             # 2: Green
    colors.notice              # 3: Yellow
    colors.link                # 4: Blue
    colors.highlight           # 5: Magenta
    colors.active              # 6: Cyan
    colors.foreground-text     # 7: White
    colors.foreground-comment  # 8: Bright Black
    colors.danger              # 9: Bright Red
    colors.success             # 10: Bright Green
    colors.notice              # 11: Bright Yellow
    colors.link                # 12: Bright Blue
    colors.highlight           # 13: Bright Magenta
    colors.active              # 14: Bright Cyan
    colors.foreground-bright   # 15: Bright White
  ];

  # Ensure all colors have # prefix
  hexColors = map ensureHash palette;
in
# Return hexadecimal format: 16 lines with # prefix
lib.concatStringsSep "\n" hexColors
