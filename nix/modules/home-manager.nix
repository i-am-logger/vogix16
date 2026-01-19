# Home Manager module for Vogix
#
# Accepts scheme sources for theme import:
# - tintedSchemes: base16/base24 from tinted-theming/schemes
# - iterm2Schemes: ansi16 from iTerm2-Color-Schemes
{ tintedSchemes, iterm2Schemes }:

{ config
, lib
, pkgs
, ...
}:

with lib;

let
  cfg = config.programs.vogix;

  # Import the vogix package
  vogix = pkgs.callPackage ../packages/vogix.nix { };

  # Import base16 and base24 themes from tinted-theming/schemes
  base16Import = import ./base16-import.nix {
    inherit lib tintedSchemes;
    scheme = "base16";
  };
  base24Import = import ./base16-import.nix {
    inherit lib tintedSchemes;
    scheme = "base24";
  };

  # Import ansi16 themes from iTerm2-Color-Schemes
  ansi16Import = import ./ansi16-import.nix {
    inherit lib iterm2Schemes;
  };

  # Auto-discover vogix16 theme files from themes directory
  themesDir = ../../themes;

  # Discover vogix16 themes (native Nix format with multi-variant support)
  discoverVogix16Themes =
    let
      schemeDir = themesDir + "/vogix16";
      dirContents = builtins.readDir schemeDir;
      nixFiles = builtins.filter (f: lib.hasSuffix ".nix" f) (builtins.attrNames dirContents);
    in
    lib.listToAttrs (
      map
        (
          filename:
          let
            themeName = builtins.replaceStrings [ ".nix" ] [ "" ] filename;
            theme = import (schemeDir + "/${filename}");
          in
          lib.nameValuePair themeName (theme // { scheme = "vogix16"; })
        )
        nixFiles
    );

  # All vogix16 themes (native format, already multi-variant)
  vogix16Themes = discoverVogix16Themes;

  # All base16 themes (imported from tinted-theming)
  base16Themes = base16Import.themes;

  # All base24 themes (imported from tinted-theming)
  base24Themes = base24Import.themes;

  # All ansi16 themes (imported from iTerm2-Color-Schemes)
  ansi16Themes = ansi16Import.themes;

  # Combined themes: vogix16 > base16 > base24 > ansi16 (precedence order)
  # User themes override all
  allThemes = ansi16Themes // base24Themes // base16Themes // vogix16Themes // cfg.themes;

  # Helper to get theme for each app (with per-app override support)
  getAppTheme = app: if cfg.${app}.theme != null then cfg.${app}.theme else cfg.defaultTheme;

  # Helper to get variant for each app (with per-app override support)
  # Returns the polarity (dark/light), not the variant name
  getAppVariant = app: if cfg.${app}.variant != null then cfg.${app}.variant else cfg.defaultVariant;

  # Helper to get the actual variant name for a theme given a polarity
  # Uses theme.defaults to map polarity -> variant name
  # Falls back to polarity if defaults doesn't exist or doesn't have the polarity
  getVariantName = theme: polarity: theme.defaults.${polarity} or polarity;

  # allThemes contains all loaded themes following the multi-variant format:
  # { name, scheme, variants = { <variantName> = { polarity, colors }; }; defaults = { dark, light }; }

  # Create semantic color mapping from baseXX colors
  # This provides a clean API for application modules (vogix16 semantic names)
  semanticColors = baseColors: {
    # Monochromatic base (base00-07)
    background = baseColors.base00;
    background-surface = baseColors.base01;
    background-selection = baseColors.base02;
    foreground-comment = baseColors.base03;
    foreground-border = baseColors.base04;
    foreground-text = baseColors.base05;
    foreground-heading = baseColors.base06;
    foreground-bright = baseColors.base07;

    # Functional colors (base08-0F)
    danger = baseColors.base08;
    warning = baseColors.base09;
    notice = baseColors.base0A;
    success = baseColors.base0B;
    active = baseColors.base0C;
    link = baseColors.base0D;
    highlight = baseColors.base0E;
    special = baseColors.base0F;
  };

  # Get colors for the selected theme and variant
  # New multi-variant format: theme.variants.<variantName>.colors
  selectedTheme = allThemes.${cfg.defaultTheme};
  # Find the variant name for the requested polarity (dark/light)
  selectedVariantName = selectedTheme.defaults.${cfg.defaultVariant} or cfg.defaultVariant;
  selectedColors = selectedTheme.variants.${selectedVariantName}.colors;

  # Auto-discover all application generators from ./applications/ directory
  applicationsDir = ./applications;
  applicationFiles = builtins.readDir applicationsDir;
  nixApplicationFiles = builtins.filter (f: lib.hasSuffix ".nix" f) (
    builtins.attrNames applicationFiles
  );

  # Load shared utility functions for app modules
  appLib = import ./applications/lib.nix { inherit lib; };

  # Extract app names from filenames (e.g., "alacritty.nix" -> "alacritty")
  # Exclude lib.nix and TEMPLATE.nix from the list of apps
  availableApps = map (filename: builtins.replaceStrings [ ".nix" ] [ "" ] filename) (
    builtins.filter (f: f != "lib.nix" && f != "TEMPLATE.nix") nixApplicationFiles
  );

  # Load all generators dynamically, passing appLib utilities
  appGenerators = lib.listToAttrs (
    map
      (appName: {
        name = appName;
        value = import (applicationsDir + "/${appName}.nix") { inherit lib appLib; };
      })
      availableApps
  );

  # Helper: Check if an app should be themed
  # Only theme apps where:
  #   1. programs.<app>.enable = true (program is actually enabled)
  #   2. vogix.<app>.enable = true (user hasn't disabled theming for this app)
  # Exception: Some apps (like console) don't have programs.<app>, so we just check vogix.<app>.enable
  isAppEnabled =
    appName:
    let
      # Check if programs.<appName>.enable exists and is true
      programEnabled = config.programs.${appName}.enable or null;
      # Check vogix.<appName>.enable (defaults to true)
      vogixEnabled = cfg.${appName}.enable or true;
    in
    # If programs.X doesn't exist (like console), only check vogix.X.enable
      # If programs.X exists, require BOTH programs.X.enable AND vogix.X.enable
    if programEnabled == null then
      vogixEnabled # No programs.<app>, just check vogix.<app>.enable
    else
      programEnabled && vogixEnabled; # Require both

  # Auto-detect enabled applications
  # Final list of apps to theme (apps where the program is enabled AND theming is enabled)
  themedApps = builtins.filter isAppEnabled availableApps;

  # Helper: Generate theme-variant packages using merged settings
  # This is called from config section where we have access to merged config.programs.<app>.settings
  # Returns a function that takes config and returns themeVariantPackages
  mkThemeVariantPackages =
    config:
    mapAttrs
      (
        themeName: theme:
        mapAttrs
          (
            variantName: variantData:
            let
              # Get raw colors and scheme from theme
              rawColors = variantData.colors;
              scheme = theme.scheme or "vogix16";

              # For vogix16 scheme, create semantic color mapping
              # For other schemes, pass raw colors directly
              colors = if scheme == "vogix16" then semanticColors rawColors else rawColors;

              themeVariantName = "${themeName}-${variantName}";

              # Helper to get format generator for an app
              getFormatGen =
                app:
                let
                  appModule = appGenerators.${app} or null;
                  format = if appModule != null then appModule.format or "toml" else "toml";
                in
                if format == "toml" then
                  pkgs.formats.toml { }
                else if format == "yaml" then
                  pkgs.formats.yaml { }
                else if format == "json" then
                  pkgs.formats.json { }
                else if format == "custom-bat" then
                  {
                    # Bat config format: key=value (one per line)
                    generate =
                      name: attrs:
                      pkgs.writeText name (
                        lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k}=${toString v}") attrs)
                      );
                  }
                else if format == "custom-btop" then
                  {
                    # Btop config format: key=value with quotes for strings
                    generate =
                      name: attrs:
                      pkgs.writeText name (
                        lib.concatStringsSep "\n" (
                          lib.mapAttrsToList
                            (
                              k: v:
                              if builtins.isString v then
                                "${k}=\"${v}\""
                              else if builtins.isBool v then
                                "${k}=${if v then "true" else "false"}"
                              else
                                "${k}=${toString v}"
                            )
                            attrs
                        )
                      );
                  }
                else
                  pkgs.formats.toml { }; # default to TOML

              # Helper to get merged settings for an app with theme colors
            in
            pkgs.runCommand "vogix-theme-${themeVariantName}" { } ''
              mkdir -p $out
              ${concatMapStringsSep "\n" (
                app:
                let
                  appModule = appGenerators.${app} or null;
                  # Support both new API (schemes) and old API (generate)
                  # New API: schemes = { vogix16 = ...; base16 = ...; base24 = ...; ansi16 = ...; }
                  # Old API: generate = colors: ... (treated as vogix16)
                  appSchemes = if appModule != null then appModule.schemes or null else null;
                  legacyGenerator = if appModule != null then appModule.generate or null else null;
                  generator =
                    if appSchemes != null && appSchemes ? ${scheme} then
                      appSchemes.${scheme}
                    else if legacyGenerator != null && scheme == "vogix16" then
                      legacyGenerator
                    else
                      null;
                  settingsPath = if appModule != null then appModule.settingsPath or null else null;
                  configFileName = if appModule != null then appModule.configFile or "config" else "config";
                  configDir = dirOf configFileName;
                in
                optionalString (appModule != null && generator != null) (
                  let
                    generatedOutput = generator colors;
                    isHybrid = builtins.isAttrs generatedOutput && generatedOutput ? themeFile;
                    isSettingsBased = settingsPath != null && !isHybrid;
                    themeFileName = if appModule != null then appModule.themeFile or null else null;
                  in
                  # Three cases: hybrid (theme+settings), settings-only, or theme-file-only
                  if isHybrid then
                    # HYBRID app (bat, btop): Generate BOTH theme file AND config file with merged settings
                    let
                      # Generate theme file
                      themeFileDir = dirOf themeFileName;

                      # Get global settings from app module (shared across all schemes)
                      globalSettings = if appModule != null then appModule.settings or { } else { };
                      # Get scheme-specific settings (if any)
                      schemeSettings = generatedOutput.settings or { };

                      # Merge: user settings <- global settings <- scheme settings
                      pathParts = if settingsPath != null then lib.splitString "." settingsPath else [ ];
                      userSettings = lib.attrByPath pathParts { } config;
                      mergedSettings = lib.recursiveUpdate (lib.recursiveUpdate userSettings globalSettings) schemeSettings;

                      # Get format generator for config file
                      formatGen = getFormatGen app;
                      configFile = formatGen.generate "vogix-${app}-config" mergedSettings;
                    in
                    ''
                                                      # Generate theme file
                                                      mkdir -p "$out/${app}/${themeFileDir}"
                                                      cat > "$out/${app}/${themeFileName}" <<'EOF'
                      ${generatedOutput.themeFile}
                      EOF

                                                      # Generate config file with merged settings
                                                      mkdir -p "$out/${app}/${configDir}"
                                                      cp "${configFile}" "$out/${app}/${configFileName}"
                    ''
                  else if isSettingsBased then
                    # SETTINGS-ONLY app (alacritty): merge user settings with theme colors
                    # generatedOutput IS the settings directly (not wrapped in { settings = ...; })
                    let
                      pathParts = if settingsPath != null then lib.splitString "." settingsPath else [ ];
                      userSettings = lib.attrByPath pathParts { } config;
                      mergedSettings = lib.recursiveUpdate userSettings generatedOutput;
                      formatGen = getFormatGen app;
                      configFile = formatGen.generate "vogix-${app}-config" mergedSettings;
                    in
                    ''
                      mkdir -p "$out/${app}/${configDir}"
                      cp "${configFile}" "$out/${app}/${configFileName}"
                    ''
                  else
                    # THEME-FILE-ONLY app (console, ripgrep): direct string output
                    ''
                                                  mkdir -p "$out/${app}/${configDir}"
                                                  cat > "$out/${app}/${configFileName}" <<'EOF'
                      ${generatedOutput}
                      EOF
                    ''
                )
              ) themedApps}
            ''
          )
          # Map over all variants in the theme
          # Each variant has: { polarity, colors }
          theme.variants
      )
      allThemes;
in
{
  # No module imports needed - we use the generators directly
  # imports = [];

  options.programs.vogix = {
    enable = mkEnableOption "vogix runtime theme management";

    package = mkOption {
      type = types.package;
      default = vogix;
      defaultText = literalExpression "pkgs.vogix";
      description = "The vogix package to use.";
    };

    defaultTheme = mkOption {
      type = types.str;
      default = "aikido";
      description = "Default theme to use.";
    };

    defaultVariant = mkOption {
      type = types.enum [
        "dark"
        "light"
      ];
      default = "dark";
      description = "Default variant (dark or light).";
    };

    # Per-app enable/disable options (dynamically generated from available generators)
    # Creates options like: programs.vogix.alacritty.enable = true;
  }
  // (
    # Dynamically create enable options for each discovered application generator
    let
      applicationsDir = ./applications;
      applicationFiles = builtins.readDir applicationsDir;
      nixApplicationFiles = builtins.filter
        (
          f: lib.hasSuffix ".nix" f && f != "lib.nix" && f != "TEMPLATE.nix"
        )
        (builtins.attrNames applicationFiles);
      availableApps = map
        (
          filename: builtins.replaceStrings [ ".nix" ] [ "" ] filename
        )
        nixApplicationFiles;
    in
    lib.listToAttrs (
      map
        (appName: {
          name = appName;
          value = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Enable vogix theming for ${appName}";
            };

            theme = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Theme to use for ${appName} (overrides defaultTheme)";
            };
            variant = mkOption {
              type = types.nullOr (
                types.enum [
                  "dark"
                  "light"
                ]
              );
              default = null;
              description = "Variant to use for ${appName} (overrides defaultVariant)";
            };
          };
        })
        availableApps
    )
  )
  // {
    # Continue with other non-app-specific options below

    themes = mkOption {
      type = types.attrsOf types.path;
      default = { };
      example = literalExpression ''
        {
          aikido = ./themes/aikido.nix;
          synthwave = ./themes/synthwave.nix;
        }
      '';
      description = "Custom theme definitions.";
    };

    enableDaemon = mkOption {
      type = types.bool;
      default = false;
      description = "Enable the vogix daemon for auto-regeneration (requires XDG_RUNTIME_DIR/home-manager/.config watch path).";
    };

    colors = mkOption {
      type = types.attrs;
      internal = true;
      description = "Semantic color API for the selected theme and variant. Used by application modules.";
    };

  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Install vogix binary
      home.packages = [ cfg.package ];

      # Expose semantic color API for application modules
      programs.vogix.colors = semanticColors selectedColors;
    }

    # Note: We DON'T merge settings here because we need to prevent home-manager
    # from generating config files (since we're generating them in /run instead).
    # Settings merging happens in mk ThemeVariantPackages where we read user's settings
    # and merge with theme colors for each theme-variant.

    (
      let
        # Generate theme packages using merged settings from config
        themeVariantPackages = mkThemeVariantPackages config;
      in
      {

        # No config files in ~/.config/vogix/ - everything is in /run and Nix store
        # The vogix CLI discovers themes by reading /run/user/UID/vogix/themes/
        # and reads/writes state in /run/user/UID/vogix/state/

        # Set up vogix runtime directories using systemd service
        # This runs at user login, after /run/user/UID is created by PAM
        systemd.user.services.vogix-setup = {
          Unit = {
            Description = "Set up vogix theme runtime directories and symlinks";
            After = [ "default.target" ];
          };

          Service = {
            Type = "oneshot";
            RemainAfterExit = true; # Keep service "active" after script exits
            RuntimeDirectory = "vogix/themes"; # Creates /run/user/UID/vogix/themes/

            ExecStart = pkgs.writeShellScript "vogix-setup.sh" ''
                        set -e
                        PATH=${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:$PATH

                        # Determine runtime directory
                        VOGIX_RUNTIME="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}/vogix"
                        THEMES_DIR="$VOGIX_RUNTIME/themes"

                        ${pkgs.coreutils}/bin/echo "Setting up vogix themes in $THEMES_DIR"

                        # Create symlinks for each theme-variant pointing to Nix store packages
                        ${concatMapStringsSep "\n" (
                          themeName:
                          let
                            theme = allThemes.${themeName};
                            variants = builtins.attrNames theme.variants;
                          in
                          concatMapStringsSep "\n" (
                            variant:
                            let
                              variantName = "${themeName}-${variant}";
                              themePackage = themeVariantPackages.${themeName}.${variant};
                            in
                            ''
                              ${pkgs.coreutils}/bin/echo "  Creating symlink: ${variantName} -> ${themePackage}"
                              ${pkgs.coreutils}/bin/ln -sfT "${themePackage}" "$THEMES_DIR/${variantName}"
                            ''
                          ) variants
                        ) (builtins.attrNames themeVariantPackages)}

                        # Create 'current-theme' symlink pointing to default theme-variant
                        # Map polarity (dark/light) to actual variant name using theme.defaults
                        ${
                          let
                            defaultTheme = allThemes.${cfg.defaultTheme};
                            defaultVariantName = getVariantName defaultTheme cfg.defaultVariant;
                          in
                          ''
                            ${pkgs.coreutils}/bin/echo "  Creating current-theme symlink -> ${cfg.defaultTheme}-${defaultVariantName}"
                            ${pkgs.coreutils}/bin/ln -sfT "${cfg.defaultTheme}-${defaultVariantName}" "$THEMES_DIR/current-theme"
                          ''
                        }

                        # Generate config.toml listing all available themes and app metadata
                        ${pkgs.coreutils}/bin/echo "  Generating config.toml"
                        ${pkgs.coreutils}/bin/cat > "$VOGIX_RUNTIME/config.toml" <<'MANIFEST_EOF'
              # Vogix Theme Manifest
              # Auto-generated by home-manager systemd service

              [default]
              theme = "${cfg.defaultTheme}"
              variant = "${getVariantName allThemes.${cfg.defaultTheme} cfg.defaultVariant}"

              [themes]
              ${concatMapStringsSep "\n\n" (
                themeName:
                let
                  theme = allThemes.${themeName};
                  scheme = theme.scheme or "vogix16";
                  inherit (theme) variants;
                  variantNames = builtins.attrNames variants;

                  # Calculate luminance for sorting (sRGB to linear, then ITU-R BT.709)
                  hexToLuminance =
                    hex:
                    let
                      # Remove # prefix and parse RGB
                      h = lib.removePrefix "#" hex;
                      r = (lib.trivial.fromHexString (builtins.substring 0 2 h)) / 255.0;
                      g = (lib.trivial.fromHexString (builtins.substring 2 2 h)) / 255.0;
                      b = (lib.trivial.fromHexString (builtins.substring 4 2 h)) / 255.0;
                      # sRGB to linear (simplified: just use value directly, close enough for ordering)
                    in
                    0.2126 * r + 0.7152 * g + 0.0722 * b;

                  # Get luminance for each variant
                  variantLuminance =
                    variantName:
                    let
                      inherit (variants.${variantName}) colors;
                      bg = colors.base00 or colors.background or "#000000";
                    in
                    hexToLuminance bg;

                  # Sort variants by luminance (lightest first = order 0)
                  sortedVariants = builtins.sort (a: b: variantLuminance a > variantLuminance b) variantNames;

                  # Get order for a variant (0 = lightest)
                  variantOrder = variantName: lib.lists.findFirstIndex (v: v == variantName) 0 sortedVariants;

                  # Generate variant details with polarity and order
                  variantDetails = lib.concatMapStringsSep "\n" (
                    variantName:
                    let
                      variant = variants.${variantName};
                      polarity = variant.polarity or "dark";
                      order = variantOrder variantName;
                    in
                    "${variantName} = { polarity = \"${polarity}\", order = ${toString order} }"
                  ) variantNames;
                in
                ''
                  [themes."${themeName}"]
                  scheme = "${scheme}"
                  variants = [${lib.concatMapStringsSep ", " (v: "\"${v}\"") variantNames}]
                  ${variantDetails}''
              ) (builtins.attrNames themeVariantPackages)}

              # Application configuration and reload methods
              ${concatMapStringsSep "\n\n" (
                app:
                let
                  appModule = appGenerators.${app} or null;
                  configFileName = if appModule != null then appModule.configFile or "config" else "config";
                  themeFileName = if appModule != null then appModule.themeFile or null else null;
                  reloadMethod = if appModule != null then appModule.reloadMethod or null else null;
                  configPath = "${config.xdg.configHome}/${app}/${configFileName}";
                  themeFilePath =
                    if themeFileName != null then "${config.xdg.configHome}/${app}/${themeFileName}" else null;
                  appTheme = getAppTheme app;
                  appPolarity = getAppVariant app;
                  appThemeData = allThemes.${appTheme};
                  appVariantName = getVariantName appThemeData appPolarity;
                in
                ''
                  [apps."${app}"]
                  config_path = "${configPath}"
                  ${optionalString (themeFilePath != null) "theme_file_path = \"${themeFilePath}\""}
                  theme = "${appTheme}"
                  variant = "${appVariantName}"
                  ${optionalString (reloadMethod != null) "reload_method = \"${reloadMethod.method}\""}
                  ${optionalString (
                    reloadMethod != null && reloadMethod ? signal
                  ) "reload_signal = \"${reloadMethod.signal}\""}
                  ${optionalString (
                    reloadMethod != null && reloadMethod ? process_name
                  ) "process_name = \"${reloadMethod.process_name}\""}
                  ${optionalString (
                    reloadMethod != null && reloadMethod ? command
                  ) "reload_command = \"\"\"${reloadMethod.command}\"\"\""}
                ''
              ) themedApps}
              MANIFEST_EOF

                        # Create symlinks in ~/.config/ (file-level symlinks)
                        ${concatMapStringsSep "\n" (
                          app:
                          let
                            appModule = appGenerators.${app} or null;
                            configFileName = if appModule != null then appModule.configFile or "config" else "config";
                            themeFileName = if appModule != null then appModule.themeFile or null else null;
                            # Check if app has explicit theme/variant override
                            hasOverride = cfg.${app}.theme != null || cfg.${app}.variant != null;
                            appTheme = getAppTheme app;
                            appPolarity = getAppVariant app;
                            appThemeData = allThemes.${appTheme};
                            appVariantName = getVariantName appThemeData appPolarity;
                            themeVariant = "${appTheme}-${appVariantName}";
                            # Base path for theme in /run
                            themeBasePath =
                              if hasOverride then
                                "$VOGIX_RUNTIME/themes/${themeVariant}/${app}"
                              else
                                "$VOGIX_RUNTIME/themes/current-theme/${app}";
                          in
                          ''
                            ${pkgs.coreutils}/bin/echo "  Setting up ${app}"

                            # Symlink individual files (config + theme for hybrid apps)

                                  # Create config file symlink
                                  CONFIG_FILE="${config.xdg.configHome}/${app}/${configFileName}"
                                  CONFIG_TARGET="${themeBasePath}/${configFileName}"
                                  CONFIG_DIR=$(${pkgs.coreutils}/bin/dirname "$CONFIG_FILE")

                                  ${pkgs.coreutils}/bin/echo "    Config: $CONFIG_FILE -> $CONFIG_TARGET"

                                  # Create parent directory for config file
                                  ${pkgs.coreutils}/bin/mkdir -p "$CONFIG_DIR"

                                  # Check if target config file exists
                                  if [[ ! -r "$CONFIG_TARGET" ]]; then
                                    ${pkgs.coreutils}/bin/echo "    ERROR: Config target does not exist: $CONFIG_TARGET"
                                    exit 1
                                  fi

                                  # Remove existing file/symlink
                                  if [[ -e "$CONFIG_FILE" ]] || [[ -L "$CONFIG_FILE" ]]; then
                                    ${pkgs.coreutils}/bin/rm -f "$CONFIG_FILE"
                                  fi

                                  # Create config file symlink
                                  if ! ${pkgs.coreutils}/bin/ln -sfT "$CONFIG_TARGET" "$CONFIG_FILE"; then
                                    ${pkgs.coreutils}/bin/echo "    ERROR: Failed to create config symlink!"
                                    exit 1
                                  fi

                                  # Verify config symlink is absolute
                                  ACTUAL_TARGET=$(${pkgs.coreutils}/bin/readlink "$CONFIG_FILE")
                                  if [[ "$ACTUAL_TARGET" != /run/user/* ]]; then
                                    ${pkgs.coreutils}/bin/echo "    ERROR: Config symlink is not absolute! Got: $ACTUAL_TARGET"
                                    exit 1
                                  fi
                                  ${pkgs.coreutils}/bin/echo "    ✓ Verified config symlink: $ACTUAL_TARGET"

                                  ${
                                    # For hybrid apps, also create theme file symlink
                                    optionalString (themeFileName != null) ''
                                      # Create theme file symlink
                                      THEME_FILE="${config.xdg.configHome}/${app}/${themeFileName}"
                                      THEME_TARGET="${themeBasePath}/${themeFileName}"
                                      THEME_DIR=$(${pkgs.coreutils}/bin/dirname "$THEME_FILE")

                                      ${pkgs.coreutils}/bin/echo "    Theme: $THEME_FILE -> $THEME_TARGET"

                                      # Create parent directory for theme file
                                      ${pkgs.coreutils}/bin/mkdir -p "$THEME_DIR"

                                      # Check if target theme file exists
                                      if [[ ! -f "$THEME_TARGET" ]]; then
                                        ${pkgs.coreutils}/bin/echo "    ERROR: Theme target does not exist: $THEME_TARGET"
                                        exit 1
                                      fi

                                      # Remove existing file/symlink
                                      if [[ -e "$THEME_FILE" ]] || [[ -L "$THEME_FILE" ]]; then
                                        ${pkgs.coreutils}/bin/rm -f "$THEME_FILE"
                                      fi

                                      # Create theme file symlink
                                      if ! ${pkgs.coreutils}/bin/ln -sfT "$THEME_TARGET" "$THEME_FILE"; then
                                        ${pkgs.coreutils}/bin/echo "    ERROR: Failed to create theme symlink!"
                                        exit 1
                                      fi

                                      # Verify theme symlink is absolute
                                      ACTUAL_THEME_TARGET=$(${pkgs.coreutils}/bin/readlink "$THEME_FILE")
                                      if [[ "$ACTUAL_THEME_TARGET" != /run/user/* ]]; then
                                        ${pkgs.coreutils}/bin/echo "    ERROR: Theme symlink is not absolute! Got: $ACTUAL_THEME_TARGET"
                                        exit 1
                                      fi
                                      ${pkgs.coreutils}/bin/echo "    ✓ Verified theme symlink: $ACTUAL_THEME_TARGET"
                                    ''
                                  }
                          ''
                        ) themedApps}

                        ${pkgs.coreutils}/bin/echo "Vogix setup complete"
            '';
          };

          Install = {
            WantedBy = [ "default.target" ]; # Run at user login
          };
        };

        # Enable daemon as systemd user service (optional, disabled by default)
        systemd.user.services.vogix-daemon = mkIf cfg.enableDaemon {
          Unit = {
            Description = "Vogix Theme Management Daemon";
            After = [ "graphical-session.target" ];
          };

          Service = {
            Type = "simple";
            ExecStart = "${cfg.package}/bin/vogix daemon";
            Restart = "on-failure";
            RestartSec = 5;
          };

          Install = {
            WantedBy = [ "default.target" ];
          };
        };

        # Don't use xdg.configFile - home-manager doesn't allow symlinks outside $HOME
        # The systemd service creates all symlinks manually
      }
    )
  ]);
}
