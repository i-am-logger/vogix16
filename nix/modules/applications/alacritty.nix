{ lib, appLib }:

{
  # Config file path relative to ~/.config/alacritty/
  configFile = "alacritty.toml";

  # Reload method: touch the config symlink to trigger Alacritty's file watcher
  reloadMethod = {
    method = "touch";
  };

  # Format used by home-manager for this app's settings
  format = "toml";

  # Settings path in home-manager config
  settingsPath = "programs.alacritty.settings";

  # Generator function that returns programs.alacritty.settings overrides
  # Returns attribute set that will be merged with user's settings
  generate = colors: {
    colors = {
      primary = {
        inherit (colors) background;
        foreground = colors.foreground-text;
        bright_foreground = colors.foreground-bright;
      };

      selection = {
        text = colors.foreground-text;
        background = colors.background-selection;
      };

      cursor = {
        text = colors.background;
        cursor = colors.active;
      };

      vi_mode_cursor = {
        text = colors.background;
        cursor = colors.highlight;
      };

      # ANSI colors: Minimal by default - monochromatic + semantic only
      # Apps needing specific colors should have their own Vogix16 configs
      normal = {
        black = colors.background;
        red = colors.danger;
        green = colors.success;
        yellow = colors.warning;
        blue = colors.foreground-text;
        magenta = colors.foreground-text;
        cyan = colors.foreground-text;
        white = colors.foreground-text;
      };

      bright = {
        black = colors.foreground-comment;
        red = colors.danger;
        green = colors.success;
        yellow = colors.warning;
        blue = colors.foreground-heading;
        magenta = colors.foreground-heading;
        cyan = colors.foreground-heading;
        white = colors.foreground-bright;
      };
    };
  };
}
