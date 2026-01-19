# Template for Vogix application theme modules
# Copy this template when creating new application themes
#
# Each module exports an attribute set with:
# - configFile: Where the config should be placed (relative to ~/.config/app/)
# - format: Config file format (toml, yaml, json, etc.)
# - settingsPath: Path to settings in home-manager config
# - schemes: Generators for each color scheme (vogix16, base16, base24, ansi16)
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

  # REQUIRED: Generators for each color scheme
  # Each generator takes a colors attribute set and returns settings overrides
  # The attribute set gets merged with user's programs.<app>.settings
  schemes = {
    # vogix16: semantic color names
    # Available monochromatic colors:
    # - colors.background, background-surface, background-selection
    # - colors.foreground-comment, foreground-border, foreground-text
    # - colors.foreground-heading, foreground-bright
    #
    # Available functional colors (use ONLY for semantic meaning):
    # - colors.danger      (errors, deletions, critical)
    # - colors.warning     (warnings, cautions, high usage)
    # - colors.notice      (notices, modifications, pending)
    # - colors.success     (success, additions, completed)
    # - colors.active      (active, current, focused, playing)
    # - colors.link        (links, interactive, informational)
    # - colors.highlight   (highlights, focus, important)
    # - colors.special     (special, system, tertiary)
    vogix16 = colors: {
      theme = {
        background = colors.background;
        foreground = colors.foreground-text;
        error = colors.danger;
        warning = colors.warning;
        success = colors.success;
      };
    };

    # Base16: raw base00-base0F colors
    # - base00-base07: monochromatic scale (dark to light)
    # - base08-base0F: accent colors (red, orange, yellow, green, cyan, blue, magenta, brown)
    base16 = colors: {
      theme = {
        background = colors.base00;
        foreground = colors.base05;
        error = colors.base08;
        warning = colors.base0A;
        success = colors.base0B;
      };
    };

    # Base24: base00-base17 with true bright colors
    # - base00-base0F: same as base16
    # - base12: bright red, base13: bright yellow, base14: bright green
    # - base15: bright cyan, base16: bright blue, base17: bright magenta
    base24 = colors: {
      theme = {
        background = colors.base00;
        foreground = colors.base05;
        error = colors.base12; # bright red
        warning = colors.base13; # bright yellow
        success = colors.base14; # bright green
      };
    };

    # ANSI16: direct terminal colors
    # - color00-color07: normal colors (black, red, green, yellow, blue, magenta, cyan, white)
    # - color08-color15: bright colors
    # - background, foreground, cursor_bg, cursor_fg, selection_bg, selection_fg
    ansi16 = colors: {
      theme = {
        background = colors.background;
        foreground = colors.foreground;
        error = colors.color09; # bright red
        warning = colors.color11; # bright yellow
        success = colors.color10; # bright green
      };
    };
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
