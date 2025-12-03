{ lib, appLib }:

{
  # Config file path relative to ~/.config/console/
  # Binary palette file for setvtrgb
  configFile = "palette";

  # Don't include metadata header (setvtrgb expects exactly 16 hex lines)
  includeHeader = false;

  # Reload method: use setvtrgb command to load palette and switch VTs
  reloadMethod = {
    method = "command";
    # Use setvtrgb to load palette, then switch VTs to force refresh
    # Note: Requires security.wrappers from vogix16 NixOS module for non-root access
    # Only runs on actual VT consoles (not in PTY/SSH sessions)
    command = "if [ -c /dev/console ] && fgconsole >/dev/null 2>&1; then setvtrgb \${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/vogix16/themes/current-theme/console/palette && { CURRENT_VT=$(fgconsole); NEXT_VT=$((CURRENT_VT % 6 + 1)); [ \"\$NEXT_VT\" = \"\$CURRENT_VT\" ] && NEXT_VT=1; chvt $NEXT_VT && sleep 0.05 && chvt $CURRENT_VT; }; fi";
  };

  # Generator function to create Linux console palette from semantic colors
  # Returns hexadecimal format palette for setvtrgb command
  # Format: 16 lines with hex colors (e.g., #000000)
  generate = colors:
    let
      # ANSI color mapping: Minimal by default - monochromatic + semantic only
      # Apps needing specific colors should have their own Vogix16 configs
      palette = [
        colors.background # 0: Black
        colors.danger # 1: Red (semantic: errors)
        colors.success # 2: Green (semantic: success)
        colors.warning # 3: Yellow (semantic: warnings)
        colors.foreground-text # 4: Blue
        colors.foreground-text # 5: Magenta
        colors.foreground-text # 6: Cyan
        colors.foreground-text # 7: White
        colors.foreground-comment # 8: Bright Black
        colors.danger # 9: Bright Red (semantic: errors)
        colors.success # 10: Bright Green (semantic: success)
        colors.warning # 11: Bright Yellow (semantic: warnings)
        colors.foreground-heading # 12: Bright Blue
        colors.foreground-heading # 13: Bright Magenta
        colors.foreground-heading # 14: Bright Cyan
        colors.foreground-bright # 15: Bright White
      ];
    in
    # Return hexadecimal format: 16 lines with # prefix
      # Theme colors already have # prefix, just join them
    lib.concatStringsSep "\n" palette;
}
