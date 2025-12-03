# Template for Vogix16 application theme modules
# Copy this template when creating new application themes
#
# Each module exports an attribute set with:
# - configFile: Where the config should be placed (relative to ~/.config/app/)
# - generate: Function that takes colors and returns theme config
# - reloadMethod: How to reload the app (optional)

{ lib }:

{
  # REQUIRED: Config file path relative to ~/.config/<app>/
  # Examples:
  #   "theme.conf"           -> ~/.config/app/theme.conf
  #   "themes/vogix.theme"   -> ~/.config/app/themes/vogix.theme
  #   "config"               -> ~/.config/app/config
  configFile = "theme.conf";

  # OPTIONAL: Whether to include metadata header in generated config
  # Set to false for binary/strict formats that don't allow comments
  # Default: true
  # includeHeader = false;

  # REQUIRED: Generator function that creates theme config from semantic colors
  # Takes: colors attribute set with semantic color names
  # Returns: string containing the generated config file
  generate = colors: ''
    # Your theme configuration here
    # Use ${colors.background}, ${colors.foreground-text}, etc.

    # Available monochromatic colors:
    # - colors.background
    # - colors.background-surface
    # - colors.background-selection
    # - colors.foreground-comment
    # - colors.foreground-border
    # - colors.foreground-text
    # - colors.foreground-heading
    # - colors.foreground-bright

    # Available functional colors (use ONLY for semantic meaning):
    # - colors.danger      (errors, deletions, critical)
    # - colors.warning     (warnings, cautions, high usage)
    # - colors.notice      (notices, modifications, pending)
    # - colors.success     (success, additions, completed)
    # - colors.active      (active, current, focused, playing)
    # - colors.link        (links, interactive, informational)
    # - colors.highlight   (highlights, focus, important)
    # - colors.special     (special, system, tertiary)
  '';

  # OPTIONAL: Reload method for the application
  # How to trigger the app to reload its theme
  # Options: "touch", "signal", "command"
  # If omitted, no reload action will be performed
  reloadMethod = {
    method = "touch";  # or "signal", "command"

    # If method = "signal":
    # signal = "SIGUSR1";
    # process_name = "appname";

    # If method = "command":
    # command = "app --reload-config";
  };
}
