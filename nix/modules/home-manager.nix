{ config
, lib
, pkgs
, themesPath ? null
, ...
}:

with lib;

let
  cfg = config.programs.vogix16;

  # Import the vogix package
  vogix16 = pkgs.callPackage ../packages/vogix.nix { };

  # Auto-discover all theme files from themes directory
  # Use provided themesPath or fall back to relative path
  themesDir = if themesPath != null then themesPath else ../../themes;
  themeFiles = builtins.readDir themesDir;
  nixThemeFiles = builtins.filter (f: lib.hasSuffix ".nix" f) (builtins.attrNames themeFiles);
  autoDiscoveredThemes = lib.listToAttrs (
    map
      (
        filename:
        let
          name = builtins.replaceStrings [ ".nix" ] [ "" ] filename;
        in
        lib.nameValuePair name (themesDir + ("/" + filename))
      )
      nixThemeFiles
  );

  # Merge auto-discovered themes with user-provided themes (user themes override)
  allThemes = autoDiscoveredThemes // cfg.themes;

  # Helper to get theme for each app (with per-app override support)
  getAppTheme = app: if cfg.${app}.theme != null then cfg.${app}.theme else cfg.defaultTheme;

  # Helper to get variant for each app (with per-app override support)
  getAppVariant = app: if cfg.${app}.variant != null then cfg.${app}.variant else cfg.defaultVariant;

  # Load all theme files
  loadedThemes = mapAttrs (name: path: import path) allThemes;

  # Create semantic color mapping from baseXX colors
  # This provides a clean API for application modules
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
  selectedTheme = loadedThemes.${cfg.defaultTheme};
  selectedColors = if cfg.defaultVariant == "dark" then selectedTheme.dark else selectedTheme.light;

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
  #   2. vogix16.<app>.enable = true (user hasn't disabled theming for this app)
  # Exception: Some apps (like console) don't have programs.<app>, so we just check vogix16.<app>.enable
  isAppEnabled =
    appName:
    let
      # Check if programs.<appName>.enable exists and is true
      programEnabled = config.programs.${appName}.enable or null;
      # Check vogix16.<appName>.enable (defaults to true)
      vogixEnabled = cfg.${appName}.enable or true;
    in
    # If programs.X doesn't exist (like console), only check vogix16.X.enable
      # If programs.X exists, require BOTH programs.X.enable AND vogix16.X.enable
    if programEnabled == null then
      vogixEnabled # No programs.<app>, just check vogix16.<app>.enable
    else
      programEnabled && vogixEnabled; # Require both

  # Auto-detect enabled applications
  # Only includes apps where the program is enabled AND theming is enabled
  autoDetectedApps = builtins.filter isAppEnabled availableApps;

  # Final list of apps to theme
  themedApps = autoDetectedApps;

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
            variant: baseColors:
            let
              colors = semanticColors baseColors;
              variantName = "${themeName}-${variant}";

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
              getMergedSettings =
                app:
                let
                  appModule = appGenerators.${app} or null;
                  generator = if appModule != null then appModule.generate or null else null;
                  settingsPath = if appModule != null then appModule.settingsPath or null else null;
                  pathParts = if settingsPath != null then lib.splitString "." settingsPath else [ ];
                  # Get user's settings from config (already merged by home-manager)
                  userSettings = lib.attrByPath pathParts { } config;
                  # Merge with this theme's colors
                  themeColorOverrides = if generator != null then generator colors else { };
                in
                lib.recursiveUpdate userSettings themeColorOverrides;
            in
            pkgs.runCommand "vogix16-theme-${variantName}" { } ''
              mkdir -p $out
              ${concatMapStringsSep "\n" (
                app:
                let
                  appModule = appGenerators.${app} or null;
                  generator = if appModule != null then appModule.generate or null else null;
                  settingsPath = if appModule != null then appModule.settingsPath or null else null;
                  configFileName = if appModule != null then appModule.configFile or "config" else "config";
                  configDir = dirOf configFileName;
                in
                optionalString (appModule != null) (
                  let
                    generatedOutput = if generator != null then generator colors else null;
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

                      # Merge settings with user's settings
                      pathParts = if settingsPath != null then lib.splitString "." settingsPath else [ ];
                      userSettings = lib.attrByPath pathParts { } config;
                      mergedSettings = lib.recursiveUpdate userSettings generatedOutput.settings;

                      # Get format generator for config file
                      formatGen = getFormatGen app;
                      configFile = formatGen.generate "vogix16-${app}-config" mergedSettings;
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
                      configFile = formatGen.generate "vogix16-${app}-config" mergedSettings;
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
          { inherit (theme) dark light; }
      )
      loadedThemes;

in
{
  # No module imports needed - we use the generators directly
  # imports = [];

  options.programs.vogix16 = {
    enable = mkEnableOption "vogix16 runtime theme management";

    package = mkOption {
      type = types.package;
      default = vogix16;
      defaultText = literalExpression "pkgs.vogix16";
      description = "The vogix16 package to use.";
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
    # Creates options like: programs.vogix16.alacritty.enable = true;
  }
  // (
    # Dynamically create enable options for each discovered application generator
    let
      applicationsDir = ./applications;
      applicationFiles = builtins.readDir applicationsDir;
      nixApplicationFiles = builtins.filter (f: lib.hasSuffix ".nix" f) (
        builtins.attrNames applicationFiles
      );
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
              description = "Enable vogix16 theming for ${appName}";
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
      description = "Enable the vogix16 daemon for auto-regeneration (requires XDG_RUNTIME_DIR/home-manager/.config watch path).";
    };

    colors = mkOption {
      type = types.attrs;
      internal = true;
      description = "Semantic color API for the selected theme and variant. Used by application modules.";
    };

  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Install vogix16 binary
      home.packages = [ cfg.package ];

      # Expose semantic color API for application modules
      programs.vogix16.colors = semanticColors selectedColors;
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

        # No config files in ~/.config/vogix16/ - everything is in /run and Nix store
        # The vogix16 CLI discovers themes by reading /run/user/UID/vogix16/themes/
        # and reads/writes state in /run/user/UID/vogix16/state/

        # Set up vogix16 runtime directories using systemd service
        # This runs at user login, after /run/user/UID is created by PAM
        systemd.user.services.vogix16-setup = {
          Unit = {
            Description = "Set up vogix16 theme runtime directories and symlinks";
            After = [ "default.target" ];
          };

          Service = {
            Type = "oneshot";
            RemainAfterExit = true; # Keep service "active" after script exits
            RuntimeDirectory = "vogix16/themes"; # Creates /run/user/UID/vogix16/themes/

            ExecStart = pkgs.writeShellScript "vogix16-setup.sh" ''
                        set -e
                        PATH=${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:$PATH

                        # Determine runtime directory
                        VOGIX_RUNTIME="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}/vogix16"
                        THEMES_DIR="$VOGIX_RUNTIME/themes"

                        ${pkgs.coreutils}/bin/echo "Setting up vogix16 themes in $THEMES_DIR"

                        # Create symlinks for each theme-variant pointing to Nix store packages
                        ${concatMapStringsSep "\n" (
                          themeName:
                          concatMapStringsSep "\n"
                            (
                              variant:
                              let
                                variantName = "${themeName}-${variant}";
                                themePackage = themeVariantPackages.${themeName}.${variant};
                              in
                              ''
                                ${pkgs.coreutils}/bin/echo "  Creating symlink: ${variantName} -> ${themePackage}"
                                ${pkgs.coreutils}/bin/ln -sfT "${themePackage}" "$THEMES_DIR/${variantName}"
                              ''
                            )
                            [
                              "dark"
                              "light"
                            ]
                        ) (builtins.attrNames themeVariantPackages)}

                        # Create 'current-theme' symlink pointing to default theme-variant
                        ${pkgs.coreutils}/bin/echo "  Creating current-theme symlink -> ${cfg.defaultTheme}-${cfg.defaultVariant}"
                        ${pkgs.coreutils}/bin/ln -sfT "${cfg.defaultTheme}-${cfg.defaultVariant}" "$THEMES_DIR/current-theme"

                        # Generate config.toml listing all available themes and app metadata
                        ${pkgs.coreutils}/bin/echo "  Generating config.toml"
                        ${pkgs.coreutils}/bin/cat > "$VOGIX_RUNTIME/config.toml" <<'MANIFEST_EOF'
              # Vogix16 Theme Manifest
              # Auto-generated by home-manager systemd service

              [default]
              theme = "${cfg.defaultTheme}"
              variant = "${cfg.defaultVariant}"

              [themes]
              ${concatMapStringsSep "\n" (themeName: "${themeName} = [\"dark\", \"light\"]") (
                builtins.attrNames themeVariantPackages
              )}

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
                  appVariant = getAppVariant app;
                in
                ''
                  [apps."${app}"]
                  config_path = "${configPath}"
                  ${optionalString (themeFilePath != null) "theme_file_path = \"${themeFilePath}\""}
                  theme = "${appTheme}"
                  variant = "${appVariant}"
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
                            appVariant = getAppVariant app;
                            themeVariant = "${appTheme}-${appVariant}";
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
                                  if [[ ! -f "$CONFIG_TARGET" ]]; then
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

                        ${pkgs.coreutils}/bin/echo "Vogix16 setup complete"
            '';
          };

          Install = {
            WantedBy = [ "default.target" ]; # Run at user login
          };
        };

        # Enable daemon as systemd user service (optional, disabled by default)
        systemd.user.services.vogix16-daemon = mkIf cfg.enableDaemon {
          Unit = {
            Description = "Vogix16 Theme Management Daemon";
            After = [ "graphical-session.target" ];
          };

          Service = {
            Type = "simple";
            ExecStart = "${cfg.package}/bin/vogix16 daemon";
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
