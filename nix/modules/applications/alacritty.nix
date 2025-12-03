{ lib }:

{
  # Config file path relative to ~/.config/alacritty/
  configFile = "colors.toml";

  # Reload method: touch the config symlink to trigger Alacritty's file watcher
  reloadMethod = {
    method = "touch";
  };

  # Generator function to create alacritty colors config from semantic colors
  # Returns TOML content
  generate = colors: ''
  [colors.primary]
  background = "${colors.background}"
  foreground = "${colors.foreground-text}"
  bright_foreground = "${colors.foreground-bright}"

  [colors.selection]
  text = "${colors.foreground-text}"
  background = "${colors.background-selection}"

  [colors.cursor]
  text = "${colors.background}"
  cursor = "${colors.active}"

  [colors.vi_mode_cursor]
  text = "${colors.background}"
  cursor = "${colors.highlight}"

  # ANSI colors: Minimal by default - monochromatic + semantic only
  # Apps needing specific colors should have their own Vogix16 configs
  [colors.normal]
  black = "${colors.background}"
  red = "${colors.danger}"
  green = "${colors.success}"
  yellow = "${colors.warning}"
  blue = "${colors.foreground-text}"
  magenta = "${colors.foreground-text}"
  cyan = "${colors.foreground-text}"
  white = "${colors.foreground-text}"

  [colors.bright]
  black = "${colors.foreground-comment}"
  red = "${colors.danger}"
  green = "${colors.success}"
  yellow = "${colors.warning}"
  blue = "${colors.foreground-heading}"
  magenta = "${colors.foreground-heading}"
  cyan = "${colors.foreground-heading}"
  white = "${colors.foreground-bright}"
  '';
}
