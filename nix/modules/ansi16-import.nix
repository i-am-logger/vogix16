# ANSI 16-color theme importer for directory-based iTerm2-Color-Schemes fork
#
# Imports ansi16 themes from i-am-logger/iTerm2-Color-Schemes
# which uses a directory-based structure:
#   ansi16/<theme-name>/<variant>.toml
#
# Each directory becomes a multi-variant theme with all variants merged.
#
# Source: https://github.com/i-am-logger/iTerm2-Color-Schemes
#
{ lib
, iterm2Schemes
,
}:

let
  # Read theme directories from the ansi16 directory
  schemesDir = "${iterm2Schemes}/ansi16";
  themeDirs = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir schemesDir)
  );

  # Detect polarity from background color using luminance
  detectPolarity =
    bgColor:
    let
      hex = lib.removePrefix "#" (lib.toLower bgColor);
      redHex = builtins.substring 0 2 hex;
      hexToInt =
        h:
        let
          chars = lib.stringToCharacters h;
          hexDigit =
            c:
            let
              idx = lib.lists.findFirstIndex (x: x == c) null [
                "0"
                "1"
                "2"
                "3"
                "4"
                "5"
                "6"
                "7"
                "8"
                "9"
                "a"
                "b"
                "c"
                "d"
                "e"
                "f"
              ];
            in
            if idx != null then idx else 0;
        in
        (hexDigit (builtins.elemAt chars 0)) * 16 + (hexDigit (builtins.elemAt chars 1));
      red = hexToInt redHex;
    in
    if red < 128 then "dark" else "light";

  # Parse a single TOML variant file
  parseVariantFile =
    themeDir: filename:
    let
      content = builtins.readFile "${schemesDir}/${themeDir}/${filename}";
      parsed = builtins.fromTOML content;
      variantName = lib.removeSuffix ".toml" filename;

      # Extract colors from alacritty format
      colors = parsed.colors or { };
      normal = colors.normal or { };
      bright = colors.bright or { };
      primary = colors.primary or { };
      cursor = colors.cursor or { };
      selection = colors.selection or { };

      # Map to ANSI 16 color format
      ansiColors = {
        # Normal colors (0-7)
        color00 = normal.black or "#000000";
        color01 = normal.red or "#ff0000";
        color02 = normal.green or "#00ff00";
        color03 = normal.yellow or "#ffff00";
        color04 = normal.blue or "#0000ff";
        color05 = normal.magenta or "#ff00ff";
        color06 = normal.cyan or "#00ffff";
        color07 = normal.white or "#ffffff";

        # Bright colors (8-15)
        color08 = bright.black or "#808080";
        color09 = bright.red or "#ff0000";
        color10 = bright.green or "#00ff00";
        color11 = bright.yellow or "#ffff00";
        color12 = bright.blue or "#0000ff";
        color13 = bright.magenta or "#ff00ff";
        color14 = bright.cyan or "#00ffff";
        color15 = bright.white or "#ffffff";

        # Additional colors
        background = primary.background or "#000000";
        foreground = primary.foreground or "#ffffff";
        cursor_bg = cursor.cursor or cursor.background or "#ffffff";
        cursor_fg = cursor.text or cursor.foreground or "#000000";
        selection_bg = selection.background or "#444444";
        selection_fg = selection.text or selection.foreground or "#ffffff";
      };

      polarity = detectPolarity ansiColors.background;
    in
    {
      inherit variantName polarity;
      colors = ansiColors;
    };

  # Import a single theme directory with all its variants
  importThemeDir =
    themeDir:
    let
      themePath = "${schemesDir}/${themeDir}";
      tomlFiles = builtins.filter (f: lib.hasSuffix ".toml" f) (
        builtins.attrNames (builtins.readDir themePath)
      );

      # Parse all variant files
      parsedVariants = map (parseVariantFile themeDir) tomlFiles;

      # Build variants attribute set
      variants = lib.listToAttrs (
        map
          (
            v:
            lib.nameValuePair v.variantName {
              inherit (v) polarity colors;
            }
          )
          parsedVariants
      );

      # Build defaults mapping (polarity -> variant name)
      darkVariant = lib.findFirst (v: v.polarity == "dark") null parsedVariants;
      lightVariant = lib.findFirst (v: v.polarity == "light") null parsedVariants;

      defaults =
        (lib.optionalAttrs (darkVariant != null) { dark = darkVariant.variantName; })
        // (lib.optionalAttrs (lightVariant != null) { light = lightVariant.variantName; });
    in
    {
      slug = themeDir;
      name = themeDir; # Use directory name as display name
      inherit variants defaults;
    };

  # Import all theme directories
  allThemes = map importThemeDir themeDirs;

  # Convert to final multi-variant format
  toMultiVariantTheme = theme: {
    inherit (theme) name variants defaults;
    scheme = "ansi16";
    author = "iTerm2-Color-Schemes";
  };

  # Create the final attribute set: { slug = theme; ... }
  importedThemes = lib.listToAttrs (
    map (theme: lib.nameValuePair theme.slug (toMultiVariantTheme theme)) allThemes
  );

in
{
  # Expose the imported themes
  themes = importedThemes;

  # Expose individual themes for debugging
  inherit allThemes;

  # Helper to get theme count
  count = builtins.length allThemes;
}
