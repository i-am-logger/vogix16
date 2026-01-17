# Theme importer for directory-based tinted-schemes fork
#
# Imports base16 and base24 themes from i-am-logger/tinted-schemes
# which uses a directory-based structure:
#   base16/<theme-name>/<variant>.yaml
#   base24/<theme-name>/<variant>.yaml
#
# Each directory becomes a multi-variant theme with all variants merged.
#
{ lib
, tintedSchemes
, scheme
,
}:

let
  # Read theme directories from the scheme directory
  # Structure: ${tintedSchemes}/base16/<theme-dir>/*.yaml
  schemeDir = "${tintedSchemes}/${scheme}";
  themeDirs = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir schemeDir)
  );

  # Simple YAML parser for base16/base24 theme files
  # Based on nix-colors implementation
  fromYAML =
    yaml:
    let
      inherit (builtins) elemAt filter match;

      # Helper functions
      mapListToAttrs = f: l: lib.listToAttrs (map f l);
      nameValuePair = name: value: { inherit name value; };

      # Check if line has content (not just whitespace)
      usefulLine = line: match "[ \t]*" line == null;

      # Parse a string value (handles quoted and unquoted, strips quotes and inline comments)
      # Input examples:
      #   '"#303446" # base'  -> '#303446'
      #   '#303446 # comment' -> '#303446'
      #   '"value"'           -> 'value'
      parseString =
        token:
        let
          # First, strip inline YAML comments (anything after unquoted ' #')
          # For quoted values like '"#303446" # base', we need to find the closing quote first

          # For quoted strings: extract content between quotes, ignore anything after
          # Match: "value" followed by optional comment
          quotedMatch = match ''^"([^"]*)".*$'' token;

          # For unquoted strings: take everything before ' #' comment
          # But be careful: color values start with # which is NOT a comment
          unquotedValue =
            let
              # Split on ' #' (space followed by hash) to separate value from comment
              parts = lib.splitString " #" token;
            in
            builtins.head parts;

          stripped = if quotedMatch != null then elemAt quotedMatch 0 else lib.trim unquotedValue;
        in
        stripped;

      # Parse a single "key: value" line
      attrLine =
        line:
        let
          m = match "[ ]*([^ :]+): *(.*)" line;
        in
        if m == null then null else nameValuePair (elemAt m 0) (parseString (elemAt m 1));

      lines = lib.splitString "\n" yaml;
      lines' = filter usefulLine lines;
      parsed = filter (x: x != null) (map attrLine lines');
    in
    mapListToAttrs (x: x) parsed;

  # Parse a single YAML variant file
  parseVariantFile =
    themeDir: filename:
    let
      content = builtins.readFile "${schemeDir}/${themeDir}/${filename}";
      parsed = fromYAML content;
      variantName = lib.removeSuffix ".yaml" filename;
      polarity = parsed.variant or "dark";
      author = parsed.author or "Unknown";

      # Extract palette colors (base00-base0F for base16, base00-base17 for base24)
      paletteKeys = builtins.filter (k: builtins.match "base[0-9A-Fa-f]+" k != null) (
        builtins.attrNames parsed
      );
      colors = lib.listToAttrs (map (k: lib.nameValuePair k parsed.${k}) paletteKeys);
    in
    {
      inherit
        variantName
        polarity
        author
        colors
        ;
      name = parsed.name or themeDir;
    };

  # Import a single theme directory with all its variants
  importThemeDir =
    themeDir:
    let
      themePath = "${schemeDir}/${themeDir}";
      yamlFiles = builtins.filter (f: lib.hasSuffix ".yaml" f) (
        builtins.attrNames (builtins.readDir themePath)
      );

      # Parse all variant files
      parsedVariants = map (parseVariantFile themeDir) yamlFiles;

      # Get theme name and author from first variant (they should be consistent)
      firstVariant = builtins.head parsedVariants;
      themeName = firstVariant.name;
      inherit (firstVariant) author;

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
      # Find a variant for each polarity
      darkVariant = lib.findFirst (v: v.polarity == "dark") null parsedVariants;
      lightVariant = lib.findFirst (v: v.polarity == "light") null parsedVariants;

      defaults =
        (lib.optionalAttrs (darkVariant != null) { dark = darkVariant.variantName; })
        // (lib.optionalAttrs (lightVariant != null) { light = lightVariant.variantName; });
    in
    {
      inherit
        themeName
        author
        variants
        defaults
        ;
      slug = themeDir;
    };

  # Import all theme directories
  allThemes = map importThemeDir themeDirs;

  # Convert to final multi-variant format
  toMultiVariantTheme = theme: {
    name = theme.themeName;
    inherit scheme;
    inherit (theme) author variants defaults;
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
