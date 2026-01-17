{ lib, ... }:

let
  # Helper to generate tmTheme XML for bat
  # Bat uses Sublime Text tmTheme format for syntax highlighting
  mkBatTheme = colors: ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>author</key>
        <string>vogix</string>
        <key>name</key>
        <string>vogix</string>
        <key>colorSpaceName</key>
        <string>sRGB</string>
        <key>settings</key>
        <array>
            <!-- Global editor settings -->
            <dict>
                <key>settings</key>
                <dict>
                    <key>background</key>
                    <string>${colors.bg}</string>
                    <key>foreground</key>
                    <string>${colors.fg}</string>
                    <key>caret</key>
                    <string>${colors.fg_bright}</string>
                    <key>lineHighlight</key>
                    <string>${colors.bg_selection}</string>
                    <key>selection</key>
                    <string>${colors.bg_selection}</string>
                    <key>gutter</key>
                    <string>${colors.bg_surface}</string>
                    <key>gutterForeground</key>
                    <string>${colors.fg_comment}</string>
                </dict>
            </dict>

            <!-- Comments -->
            <dict>
                <key>name</key>
                <string>Comments</string>
                <key>scope</key>
                <string>comment, punctuation.definition.comment</string>
                <key>settings</key>
                <dict>
                    <key>foreground</key>
                    <string>${colors.fg_comment}</string>
                    <key>fontStyle</key>
                    <string>italic</string>
                </dict>
            </dict>

            <!-- All code: minimal differentiation -->
            <dict>
                <key>name</key>
                <string>Code</string>
                <key>scope</key>
                <string>keyword, storage, variable, constant, string, number, entity, support, meta</string>
                <key>settings</key>
                <dict>
                    <key>foreground</key>
                    <string>${colors.fg}</string>
                </dict>
            </dict>

            <!-- Operators and punctuation -->
            <dict>
                <key>name</key>
                <string>Operators</string>
                <key>scope</key>
                <string>keyword.operator, punctuation</string>
                <key>settings</key>
                <dict>
                    <key>foreground</key>
                    <string>${colors.fg_border}</string>
                </dict>
            </dict>

            <!-- Function/class names -->
            <dict>
                <key>name</key>
                <string>Definitions</string>
                <key>scope</key>
                <string>entity.name.function, entity.name.class, entity.name.type</string>
                <key>settings</key>
                <dict>
                    <key>foreground</key>
                    <string>${colors.fg_heading}</string>
                </dict>
            </dict>

            <!-- Git diff: Added lines -->
            <dict>
                <key>name</key>
                <string>Diff Inserted</string>
                <key>scope</key>
                <string>markup.inserted, markup.inserted.diff</string>
                <key>settings</key>
                <dict>
                    <key>foreground</key>
                    <string>${colors.green}</string>
                </dict>
            </dict>

            <!-- Git diff: Removed lines -->
            <dict>
                <key>name</key>
                <string>Diff Deleted</string>
                <key>scope</key>
                <string>markup.deleted, markup.deleted.diff</string>
                <key>settings</key>
                <dict>
                    <key>foreground</key>
                    <string>${colors.red}</string>
                </dict>
            </dict>

            <!-- Git diff: Modified lines -->
            <dict>
                <key>name</key>
                <string>Diff Changed</string>
                <key>scope</key>
                <string>markup.changed, markup.changed.diff</string>
                <key>settings</key>
                <dict>
                    <key>foreground</key>
                    <string>${colors.yellow}</string>
                </dict>
            </dict>

            <!-- Git diff: Header -->
            <dict>
                <key>name</key>
                <string>Diff Header</string>
                <key>scope</key>
                <string>meta.diff.header, meta.diff.range</string>
                <key>settings</key>
                <dict>
                    <key>foreground</key>
                    <string>${colors.cyan}</string>
                    <key>fontStyle</key>
                    <string>bold</string>
                </dict>
            </dict>

            <!-- Errors/invalid -->
            <dict>
                <key>name</key>
                <string>Invalid</string>
                <key>scope</key>
                <string>invalid, invalid.illegal</string>
                <key>settings</key>
                <dict>
                    <key>foreground</key>
                    <string>${colors.red}</string>
                    <key>fontStyle</key>
                    <string>bold</string>
                </dict>
            </dict>
        </array>
    </dict>
    </plist>
  '';
in
{
  # Bat is a HYBRID app: generates theme file + merges config settings
  themeFile = "themes/vogix.tmTheme";
  configFile = "config";
  format = "toml";
  settingsPath = "programs.bat.config";

  # Global settings applied to all schemes
  settings = {
    theme = "vogix";
  };

  schemes = {
    # Vogix16: semantic color names
    vogix16 = colors: {
      themeFile = mkBatTheme {
        bg = colors.background;
        bg_surface = colors.background-surface;
        bg_selection = colors.background-selection;
        fg = colors.foreground-text;
        fg_comment = colors.foreground-comment;
        fg_border = colors.foreground-border;
        fg_heading = colors.foreground-heading;
        fg_bright = colors.foreground-bright;
        red = colors.danger;
        yellow = colors.warning;
        green = colors.success;
        cyan = colors.notice;
      };
    };

    # Base16: raw base00-base0F colors
    base16 = colors: {
      themeFile = mkBatTheme {
        bg = colors.base00;
        bg_surface = colors.base01;
        bg_selection = colors.base02;
        fg = colors.base05;
        fg_comment = colors.base03;
        fg_border = colors.base04;
        fg_heading = colors.base06;
        fg_bright = colors.base07;
        red = colors.base08;
        yellow = colors.base0A;
        green = colors.base0B;
        cyan = colors.base0C;
      };
    };

    # Base24: base00-base17 with true bright colors
    base24 = colors: {
      themeFile = mkBatTheme {
        bg = colors.base00;
        bg_surface = colors.base01;
        bg_selection = colors.base02;
        fg = colors.base05;
        fg_comment = colors.base03;
        fg_border = colors.base04;
        fg_heading = colors.base06;
        fg_bright = colors.base07;
        red = colors.base08;
        yellow = colors.base0A;
        green = colors.base0B;
        cyan = colors.base0C;
      };
    };

    # ANSI16: direct terminal colors
    ansi16 = colors: {
      themeFile = mkBatTheme {
        bg = colors.background;
        bg_surface = colors.color00;
        bg_selection = colors.color08;
        fg = colors.foreground;
        fg_comment = colors.color08;
        fg_border = colors.color07;
        fg_heading = colors.color15;
        fg_bright = colors.color15;
        red = colors.color01;
        yellow = colors.color03;
        green = colors.color02;
        cyan = colors.color06;
      };
    };
  };
}
