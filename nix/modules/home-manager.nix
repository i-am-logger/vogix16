{ config, lib, pkgs, themesPath ? null, ... }:

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
    map (filename:
      let
        name = builtins.replaceStrings [".nix"] [""] filename;
      in lib.nameValuePair name (themesDir + ("/" + filename))
    ) nixThemeFiles
  );

  # Merge auto-discovered themes with user-provided themes (user themes override)
  allThemes = autoDiscoveredThemes // cfg.themes;

  # Helper to get theme for each app (with per-app override support)
  getAppTheme = app:
    if cfg.${app}.theme != null
    then cfg.${app}.theme
    else cfg.defaultTheme;

  # Helper to get variant for each app (with per-app override support)
  getAppVariant = app:
    if cfg.${app}.variant != null
    then cfg.${app}.variant
    else cfg.defaultVariant;

  # Load all theme files
  loadedThemes = mapAttrs (name: path:
    import path
  ) allThemes;

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
  selectedColors = if cfg.defaultVariant == "dark"
    then selectedTheme.dark
    else selectedTheme.light;

  # Auto-discover all application generators from ./applications/ directory
  applicationsDir = ./applications;
  applicationFiles = builtins.readDir applicationsDir;
  nixApplicationFiles = builtins.filter (f: lib.hasSuffix ".nix" f) (builtins.attrNames applicationFiles);

  # Extract app names from filenames (e.g., "alacritty.nix" -> "alacritty")
  availableApps = map (filename: builtins.replaceStrings [".nix"] [""] filename) nixApplicationFiles;

  # Load all generators dynamically
  appGenerators = lib.listToAttrs (
    map (appName: {
      name = appName;
      value = import (applicationsDir + "/${appName}.nix") { inherit lib; };
    }) availableApps
  );

  # Helper: Check if an app should be themed
  # Only theme apps where:
  #   1. programs.<app>.enable = true (program is actually enabled)
  #   2. vogix16.<app>.enable = true (user hasn't disabled theming for this app)
  # Exception: Some apps (like console) don't have programs.<app>, so we just check vogix16.<app>.enable
  isAppEnabled = appName:
    let
      # Check if programs.<appName>.enable exists and is true
      programEnabled = config.programs.${appName}.enable or null;
      # Check vogix16.<appName>.enable (defaults to true)
      vogixEnabled = cfg.${appName}.enable or true;
    in
    # If programs.X doesn't exist (like console), only check vogix16.X.enable
    # If programs.X exists, require BOTH programs.X.enable AND vogix16.X.enable
    if programEnabled == null
    then vogixEnabled  # No programs.<app>, just check vogix16.<app>.enable
    else programEnabled && vogixEnabled;  # Require both

  # Auto-detect enabled applications
  # Only includes apps where the program is enabled AND theming is enabled
  autoDetectedApps = builtins.filter isAppEnabled availableApps;

  # Final list of apps to theme
  themedApps = autoDetectedApps;

  # Generate all theme-variant packages (stored in Nix store, symlinked to /run at activation)
  themeVariantPackages = mapAttrs (themeName: theme:
    mapAttrs (variant: baseColors:
      let
        colors = semanticColors baseColors;
        variantName = "${themeName}-${variant}";
      in
      pkgs.runCommand "vogix16-theme-${variantName}" {} ''
        mkdir -p $out
        ${concatMapStringsSep "\n" (app:
          let
            appModule = appGenerators.${app} or null;
            generator = if appModule != null then appModule.generate or null else null;
            configFileName = if appModule != null then appModule.configFile or "config" else "config";
            includeHeader = if appModule != null then appModule.includeHeader or true else true;
            configDir = dirOf configFileName;
          in
          optionalString (generator != null) (
            if includeHeader then
              # Add metadata header
              ''
                mkdir -p "$out/${app}/${configDir}"
                cat > "$out/${app}/${configFileName}" <<'EOF'
# Vogix16 Theme Configuration
# Theme: ${themeName}
# Variant: ${variant}
# Auto-generated by vogix16 home-manager module

${generator colors}
EOF
              ''
            else
              # No header (e.g., binary formats that require strict format)
              ''
                mkdir -p "$out/${app}/${configDir}"
                cat > "$out/${app}/${configFileName}" <<'EOF'
${generator colors}
EOF
              ''
          )
        ) themedApps}
      ''
    ) { inherit (theme) dark light; }
  ) loadedThemes;

in {
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
      type = types.enum [ "dark" "light" ];
      default = "dark";
      description = "Default variant (dark or light).";
    };

    # Per-app enable/disable options (dynamically generated from available generators)
    # Creates options like: programs.vogix16.alacritty.enable = true;
  } // (
    # Dynamically create enable options for each discovered application generator
    let
      applicationsDir = ./applications;
      applicationFiles = builtins.readDir applicationsDir;
      nixApplicationFiles = builtins.filter (f: lib.hasSuffix ".nix" f) (builtins.attrNames applicationFiles);
      availableApps = map (filename: builtins.replaceStrings [".nix"] [""] filename) nixApplicationFiles;
    in
    lib.listToAttrs (
      map (appName: {
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
            type = types.nullOr (types.enum [ "dark" "light" ]);
            default = null;
            description = "Variant to use for ${appName} (overrides defaultVariant)";
          };
        };
      }) availableApps
    )
  ) // {
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
        RemainAfterExit = true;  # Keep service "active" after script exits
        RuntimeDirectory = "vogix16/themes";  # Creates /run/user/UID/vogix16/themes/

        ExecStart = pkgs.writeShellScript "vogix16-setup.sh" ''
          set -e
          PATH=${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:$PATH

          # Determine runtime directory
          VOGIX_RUNTIME="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}/vogix16"
          THEMES_DIR="$VOGIX_RUNTIME/themes"

          ${pkgs.coreutils}/bin/echo "Setting up vogix16 themes in $THEMES_DIR"

          # Create symlinks for each theme-variant pointing to Nix store packages
          ${concatMapStringsSep "\n" (themeName:
            concatMapStringsSep "\n" (variant:
              let
                variantName = "${themeName}-${variant}";
                themePackage = themeVariantPackages.${themeName}.${variant};
              in
              ''
                ${pkgs.coreutils}/bin/echo "  Creating symlink: ${variantName} -> ${themePackage}"
                ${pkgs.coreutils}/bin/ln -sfT "${themePackage}" "$THEMES_DIR/${variantName}"
              ''
            ) ["dark" "light"]
          ) (builtins.attrNames themeVariantPackages)}

          # Create 'current-theme' symlink pointing to default theme-variant
          ${pkgs.coreutils}/bin/echo "  Creating current-theme symlink -> ${cfg.defaultTheme}-${cfg.defaultVariant}"
          ${pkgs.coreutils}/bin/ln -sfT "${cfg.defaultTheme}-${cfg.defaultVariant}" "$THEMES_DIR/current-theme"

          # Generate manifest.toml listing all available themes and app metadata
          ${pkgs.coreutils}/bin/echo "  Generating manifest.toml"
          ${pkgs.coreutils}/bin/cat > "$VOGIX_RUNTIME/manifest.toml" <<'MANIFEST_EOF'
# Vogix16 Theme Manifest
# Auto-generated by home-manager systemd service

[default]
theme = "${cfg.defaultTheme}"
variant = "${cfg.defaultVariant}"

[themes]
${concatMapStringsSep "\n" (themeName:
  "${themeName} = [\"dark\", \"light\"]"
) (builtins.attrNames themeVariantPackages)}

# Application configuration and reload methods
${concatMapStringsSep "\n\n" (app:
  let
    appModule = appGenerators.${app} or null;
    configFileName = if appModule != null then appModule.configFile or "config" else "config";
    reloadMethod = if appModule != null then appModule.reloadMethod or null else null;
    configPath = "${config.xdg.configHome}/${app}/${configFileName}";
    appTheme = getAppTheme app;
    appVariant = getAppVariant app;
  in
  ''
[apps."${app}"]
config_path = "${configPath}"
theme = "${appTheme}"
variant = "${appVariant}"
${optionalString (reloadMethod != null) "reload_method = \"${reloadMethod.method}\""}
${optionalString (reloadMethod != null && reloadMethod ? signal) "reload_signal = \"${reloadMethod.signal}\""}
${optionalString (reloadMethod != null && reloadMethod ? process_name) "process_name = \"${reloadMethod.process_name}\""}
${optionalString (reloadMethod != null && reloadMethod ? command) "reload_command = \"\"\"${reloadMethod.command}\"\"\""}
  ''
) themedApps}
MANIFEST_EOF

          # Create app config symlinks in ~/.config/ pointing to runtime theme configs
          ${concatMapStringsSep "\n" (app:
            let
              appModule = appGenerators.${app} or null;
              configFileName = if appModule != null then appModule.configFile or "config" else "config";
              appConfigDir = "${config.xdg.configHome}/${app}";
              # Check if app has explicit theme/variant override
              hasOverride = cfg.${app}.theme != null || cfg.${app}.variant != null;
              appTheme = getAppTheme app;
              appVariant = getAppVariant app;
              themeVariant = "${appTheme}-${appVariant}";
              # CRITICAL: Use absolute path, not relative! Must point to /run/user/UID/vogix16/
              # If app has override, point directly to theme-variant; otherwise use current-theme for runtime switching
              targetPath = if hasOverride
                then "$VOGIX_RUNTIME/themes/${themeVariant}/${app}/${configFileName}"
                else "$VOGIX_RUNTIME/themes/current-theme/${app}/${configFileName}";
            in
            ''
              ${pkgs.coreutils}/bin/echo "  Setting up ${app} config symlink"

              # Create parent directory
              ${pkgs.coreutils}/bin/mkdir -p "${appConfigDir}/$(${pkgs.coreutils}/bin/dirname ${configFileName})" || {
                ${pkgs.coreutils}/bin/echo "    ERROR: Failed to create directory ${appConfigDir}/$(${pkgs.coreutils}/bin/dirname ${configFileName})"
                exit 1
              }

              # Debug: Print what we're linking
              ${pkgs.coreutils}/bin/echo "    Target: ${targetPath}"
              ${pkgs.coreutils}/bin/echo "    Link: ${appConfigDir}/${configFileName}"

              # Check if target exists
              if [[ ! -e "${targetPath}" ]]; then
                ${pkgs.coreutils}/bin/echo "    ERROR: Target does not exist: ${targetPath}"
                exit 1
              fi

              # Create ABSOLUTE symlink (force overwrite with -f)
              if ! ${pkgs.coreutils}/bin/ln -sfT "${targetPath}" "${appConfigDir}/${configFileName}"; then
                ${pkgs.coreutils}/bin/echo "    ERROR: Failed to create symlink!"
                exit 1
              fi

              # Verify symlink was actually created
              if [[ ! -L "${appConfigDir}/${configFileName}" ]]; then
                ${pkgs.coreutils}/bin/echo "    ERROR: Symlink was not created at ${appConfigDir}/${configFileName}!"
                exit 1
              fi

              # Verify symlink is absolute (not relative)
              ACTUAL_TARGET=$(${pkgs.coreutils}/bin/readlink "${appConfigDir}/${configFileName}")
              if [[ "$ACTUAL_TARGET" != /run/user/* ]]; then
                ${pkgs.coreutils}/bin/echo "    ERROR: Symlink is not absolute! Got: $ACTUAL_TARGET"
                ${pkgs.coreutils}/bin/echo "    Expected: /run/user/*/vogix16/themes/..."
                exit 1
              fi
              ${pkgs.coreutils}/bin/echo "    ✓ Verified absolute symlink: $ACTUAL_TARGET"
            ''
          ) themedApps}

          ${pkgs.coreutils}/bin/echo "Vogix16 setup complete"
        '';
      };

      Install = {
        WantedBy = [ "default.target" ];  # Run at user login
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
    }
  ]);
}
