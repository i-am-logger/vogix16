_:

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

  # Generators for each color scheme
  schemes = {
    # Vogix16: semantic color names
    vogix16 = colors: {
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

        normal = {
          black = colors.background;
          red = colors.danger;
          green = colors.success;
          yellow = colors.warning;
          blue = colors.link;
          magenta = colors.highlight;
          cyan = colors.active;
          white = colors.foreground-text;
        };

        bright = {
          black = colors.foreground-comment;
          red = colors.danger;
          green = colors.success;
          yellow = colors.warning;
          blue = colors.link;
          magenta = colors.highlight;
          cyan = colors.active;
          white = colors.foreground-bright;
        };
      };
    };

    # Base16: raw base00-base0F colors
    base16 = colors: {
      colors = {
        primary = {
          background = colors.base00;
          foreground = colors.base05;
          bright_foreground = colors.base07;
        };

        selection = {
          text = colors.base05;
          background = colors.base02;
        };

        cursor = {
          text = colors.base00;
          cursor = colors.base05;
        };

        vi_mode_cursor = {
          text = colors.base00;
          cursor = colors.base0E;
        };

        normal = {
          black = colors.base00;
          red = colors.base08;
          green = colors.base0B;
          yellow = colors.base0A;
          blue = colors.base0D;
          magenta = colors.base0E;
          cyan = colors.base0C;
          white = colors.base05;
        };

        bright = {
          black = colors.base03;
          red = colors.base08;
          green = colors.base0B;
          yellow = colors.base0A;
          blue = colors.base0D;
          magenta = colors.base0E;
          cyan = colors.base0C;
          white = colors.base07;
        };
      };
    };

    # Base24: base00-base17 with true bright colors
    base24 = colors: {
      colors = {
        primary = {
          background = colors.base00;
          foreground = colors.base05;
          bright_foreground = colors.base07;
        };

        selection = {
          text = colors.base05;
          background = colors.base02;
        };

        cursor = {
          text = colors.base00;
          cursor = colors.base05;
        };

        vi_mode_cursor = {
          text = colors.base00;
          cursor = colors.base0E;
        };

        normal = {
          black = colors.base00;
          red = colors.base08;
          green = colors.base0B;
          yellow = colors.base0A;
          blue = colors.base0D;
          magenta = colors.base0E;
          cyan = colors.base0C;
          white = colors.base05;
        };

        bright = {
          black = colors.base03;
          red = colors.base12; # base24 bright red
          green = colors.base14; # base24 bright green
          yellow = colors.base13; # base24 bright yellow
          blue = colors.base16; # base24 bright blue
          magenta = colors.base17; # base24 bright magenta
          cyan = colors.base15; # base24 bright cyan
          white = colors.base07;
        };
      };
    };

    # ANSI16: direct terminal colors
    ansi16 = colors: {
      colors = {
        primary = {
          inherit (colors) background foreground;
        };

        selection = {
          text = colors.selection_fg;
          background = colors.selection_bg;
        };

        cursor = {
          text = colors.cursor_fg;
          cursor = colors.cursor_bg;
        };

        vi_mode_cursor = {
          text = colors.cursor_fg;
          cursor = colors.cursor_bg;
        };

        normal = {
          black = colors.color00;
          red = colors.color01;
          green = colors.color02;
          yellow = colors.color03;
          blue = colors.color04;
          magenta = colors.color05;
          cyan = colors.color06;
          white = colors.color07;
        };

        bright = {
          black = colors.color08;
          red = colors.color09;
          green = colors.color10;
          yellow = colors.color11;
          blue = colors.color12;
          magenta = colors.color13;
          cyan = colors.color14;
          white = colors.color15;
        };
      };
    };
  };
}
