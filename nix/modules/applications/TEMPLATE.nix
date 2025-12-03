# Template for Vogix16 application theme modules
# Copy this template when creating new application themes
#
# Each module exports an attribute set with:
# - configFile: Where the config should be placed (relative to ~/.config/app/)
# - format: Config file format (toml, yaml, json, etc.)
# - settingsPath: Path to settings in home-manager config
# - generate: Function that takes colors and returns settings overrides
# - reloadMethod: How to reload the app (optional)
#
# Parameters:
# - lib: nixpkgs lib functions
# - appLib: Shared utility functions from lib.nix (hexToRgb, stripHash, etc.)

{ lib, appLib }:

{
  # REQUIRED: Config file path relative to ~/.config/<app>/
  # This is where home-manager would normally generate the config
  # Examples:
  #   "config.toml"          -> ~/.config/app/config.toml
  #   "themes/vogix.theme"   -> ~/.config/app/themes/vogix.theme
  #   "config"               -> ~/.config/app/config
  configFile = "config.toml";

  # REQUIRED: Format used by home-manager for this app's settings
  # Determines which generator to use (tomlFormat, yamlFormat, etc.)
  # Options: "toml", "yaml", "json", "ini", "custom"
  format = "toml";

  # REQUIRED: Settings path in home-manager config
  # This is where your color overrides will be merged with user settings
  # Examples:
  #   "programs.alacritty.settings"
  #   "programs.btop.settings"
  #   "programs.app.extraConfig"
  settingsPath = "programs.app.settings";

  # REQUIRED: Generator function that returns settings overrides
  # Takes: colors attribute set with semantic color names
  # Returns: attribute set that will be MERGED with user's settings
  #
  # IMPORTANT: This returns an attribute set, NOT a string!
  # The attribute set gets merged with user's programs.<app>.settings
  generate = colors: {
    # Your theme configuration here as Nix attribute set
    # This will be merged with user's existing settings
    colors = {
      background = colors.background;
      foreground = colors.foreground-text;
    };

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
  };

  # OPTIONAL: Reload method for the application
  # How to trigger the app to reload its theme
  # Options: "touch", "signal", "command"
  # If omitted, no reload action will be performed
  reloadMethod = {
    method = "touch"; # or "signal", "command"

    # If method = "signal":
    # signal = "SIGUSR1";
    # process_name = "appname";

    # If method = "command":
    # command = "app --reload-config";
  };
}
