# Home Manager module for Vogix
#
# Provides:
# - Theme packages in ~/.local/share/vogix/themes/
# - App config symlinks pointing to ~/.local/state/vogix/current-theme/
# - Config file at ~/.local/state/vogix/config.toml
#
# Accepts scheme sources for theme import:
# - tintedSchemes: base16/base24 from tinted-theming/schemes
# - iterm2Schemes: ansi16 from iTerm2-Color-Schemes
# - vogix16Themes: vogix16 from vogix16-themes
{ tintedSchemes
, iterm2Schemes
, vogix16Themes
,
}:

{ config
, lib
, pkgs
, ...
}:

let
  inherit (lib)
    mkIf
    mkMerge
    nameValuePair
    listToAttrs
    flatten
    mapAttrsToList
    concatMapStringsSep
    optionalString
    ;

  cfg = config.programs.vogix;

  # Import theme utilities
  themeUtils = import ./themes.nix {
    inherit
      lib
      tintedSchemes
      iterm2Schemes
      vogix16Themes
      ;
  };

  # Import vogix16-specific utilities
  vogix16Lib = import ../lib/vogix16.nix { inherit lib; };

  # Import color utilities
  colorLib = import ../lib/colors.nix { inherit lib; };
  inherit (colorLib) hexToLuminance;

  # Import options module
  optionsModule = import ./options.nix { inherit lib pkgs; };

  # Import generators
  generators = import ./generators.nix { inherit lib pkgs; };
  inherit (generators) appGenerators availableApps isAppEnabled;

  # Merge all themes with user themes
  allThemes = themeUtils.mergeThemes cfg.themes;

  # Get selected theme colors for the color API
  selectedTheme = allThemes.${cfg.defaultTheme};
  selectedVariantName = selectedTheme.defaults.${cfg.defaultVariant} or cfg.defaultVariant;
  selectedColors = selectedTheme.variants.${selectedVariantName}.colors;

  # Generate theme packages
  themeVariantPackages = generators.mkThemeVariantPackages {
    inherit config cfg allThemes;
  };

  # Apps that will be themed
  themedApps = builtins.filter (isAppEnabled config cfg) availableApps;

  # Default theme-variant for initial current-theme symlink
  defaultThemeVariant = "${cfg.defaultTheme}-${themeUtils.getVariantName selectedTheme cfg.defaultVariant}";

  # Scheme source paths (pointing to /nix/store)
  schemeSources = {
    vogix16 = vogix16Themes;
    base16 = "${tintedSchemes}/base16";
    base24 = "${tintedSchemes}/base24";
    ansi16 = "${iterm2Schemes}/ansi16";
  };

  # Package templates into /nix/store
  templatesDir = builtins.path {
    path = ../../../templates;
    name = "vogix-templates-src";
  };
  templatesPackage = pkgs.runCommand "vogix-templates" { } ''
    mkdir -p $out
    cp -r ${templatesDir}/* $out/
  '';

  # Compute templates hash for cache invalidation
  templatesHash = builtins.hashString "sha256" (
    builtins.readFile (
      pkgs.runCommand "vogix-templates-hash" { } ''
        find ${templatesPackage} -type f -exec sha256sum {} \; | sort | sha256sum | cut -d' ' -f1 > $out
      ''
    )
  );

  # Generate themes section for config.toml
  themesSection = concatMapStringsSep "\n\n"
    (
      themeName:
      let
        theme = allThemes.${themeName};
        scheme = theme.scheme or "vogix16";
        inherit (theme) variants;
        variantNames = builtins.attrNames variants;

        variantLuminance =
          variantName:
          let
            inherit (variants.${variantName}) colors;
            bg = colors.base00 or colors.background or "#000000";
          in
          hexToLuminance bg;

        sortedVariants = builtins.sort (a: b: variantLuminance a > variantLuminance b) variantNames;
        variantOrder = variantName: lib.lists.findFirstIndex (v: v == variantName) 0 sortedVariants;

        variantDetails = lib.concatMapStringsSep "\n"
          (
            variantName:
            let
              variant = variants.${variantName};
              polarity = variant.polarity or "dark";
              order = variantOrder variantName;
            in
            "${variantName} = { polarity = \"${polarity}\", order = ${toString order} }"
          )
          variantNames;
      in
      ''
        [themes."${themeName}"]
        scheme = "${scheme}"
        variants = [${lib.concatMapStringsSep ", " (v: "\"${v}\"") variantNames}]
        ${variantDetails}''
    )
    (builtins.attrNames allThemes);

  # Generate apps section for config.toml with FULL paths
  appsSection = concatMapStringsSep "\n\n"
    (
      app:
      let
        appModule = appGenerators.${app} or null;
        configFileName = if appModule != null then appModule.configFile or "config" else "config";
        themeFileName = if appModule != null then appModule.themeFile or null else null;
        reloadMethod = if appModule != null then appModule.reloadMethod or null else null;
        # Full path to the config file symlink in user's ~/.config
        configPath = "${config.xdg.configHome}/${app}/${configFileName}";
        themeFilePath =
          if themeFileName != null then "${config.xdg.configHome}/${app}/${themeFileName}" else null;
      in
      optionalString (appModule != null && reloadMethod != null) ''
        [apps."${app}"]
        config_path = "${configPath}"
        reload_method = "${reloadMethod.method}"
        ${optionalString (themeFilePath != null) "theme_file_path = \"${themeFilePath}\""}
        ${optionalString (reloadMethod ? signal) "reload_signal = \"${reloadMethod.signal}\""}
        ${optionalString (reloadMethod ? process_name) "process_name = \"${reloadMethod.process_name}\""}
        ${optionalString (reloadMethod ? command) "reload_command = \"\"\"${reloadMethod.command}\"\"\""}''
    )
    themedApps;

  # Generate full config.toml content
  configToml = ''
    # Vogix Theme Configuration
    # Auto-generated by home-manager module

    [default]
    theme = "${cfg.defaultTheme}"
    variant = "${themeUtils.getVariantName selectedTheme cfg.defaultVariant}"

    # Templates for runtime rendering
    [templates]
    path = "${templatesPackage}"
    hash = "${templatesHash}"

    # Theme source directories
    [theme_sources]
    vogix16 = "${schemeSources.vogix16}"
    base16 = "${schemeSources.base16}"
    base24 = "${schemeSources.base24}"
    ansi16 = "${schemeSources.ansi16}"

    ${themesSection}

    # Application reload methods
    ${appsSection}
  '';

in
{
  inherit (optionsModule) options;

  config = mkIf cfg.enable (mkMerge [
    {
      # Install vogix binary
      home.packages = [ cfg.package ];

      # Expose semantic color API for application modules
      programs.vogix.colors = vogix16Lib.semanticColors selectedColors;

      # Create theme symlinks in ~/.local/share/vogix/themes/
      xdg.dataFile = lib.mkMerge [
        # Theme variant symlinks
        (listToAttrs (
          flatten (
            mapAttrsToList
              (
                themeName: variants:
                  mapAttrsToList
                    (
                      variantName: pkg:
                        nameValuePair "vogix/themes/${themeName}-${variantName}" {
                          source = pkg;
                        }
                    )
                    variants
              )
              themeVariantPackages
          )
        ))
      ];

      # Create state directory, config.toml, current-theme symlink, and app config symlinks via activation
      # We use activation instead of xdg.configFile to avoid conflicts with programs.*.enable
      home.activation.vogixSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # Create state directory
        $DRY_RUN_CMD mkdir -p "${config.xdg.stateHome}/vogix"

        # Generate config.toml in state directory
        $DRY_RUN_CMD cat > "${config.xdg.stateHome}/vogix/config.toml" << 'VOGIX_CONFIG_EOF'
        ${configToml}
        VOGIX_CONFIG_EOF
        $VERBOSE_ECHO "Generated config.toml at ${config.xdg.stateHome}/vogix/config.toml"

        # Create initial current-theme symlink if it doesn't exist
        _currentLink="${config.xdg.stateHome}/vogix/current-theme"
        _defaultTarget="${config.xdg.dataHome}/vogix/themes/${defaultThemeVariant}"

        if [ ! -L "$_currentLink" ]; then
          $DRY_RUN_CMD ln -sfT "$_defaultTarget" "$_currentLink"
          $VERBOSE_ECHO "Created initial current-theme symlink: $_currentLink -> $_defaultTarget"
        fi

        # Create app config symlinks
        # These point to ~/.local/state/vogix/current-theme/{app}/{config}
        ${concatMapStringsSep "\n" (
          app:
          let
            appModule = appGenerators.${app} or null;
            configFileName = if appModule != null then appModule.configFile or "config" else "config";
            themeFileName = if appModule != null then appModule.themeFile or null else null;
            configDir = "${config.xdg.configHome}/${app}";
            stateDir = "${config.xdg.stateHome}/vogix/current-theme/${app}";
          in
          ''
            # Setup ${app}
            $DRY_RUN_CMD mkdir -p "${configDir}"

            # Config file symlink
            _configFile="${configDir}/${configFileName}"
            _configTarget="${stateDir}/${configFileName}"
            if [ -L "$_configFile" ] || [ ! -e "$_configFile" ]; then
              $DRY_RUN_CMD ln -sfT "$_configTarget" "$_configFile"
              $VERBOSE_ECHO "Created symlink: $_configFile -> $_configTarget"
            fi
            ${optionalString (themeFileName != null) ''

              # Theme file symlink (may be in a subdirectory like themes/vogix.tmTheme)
              _themeFile="${configDir}/${themeFileName}"
              _themeTarget="${stateDir}/${themeFileName}"
              _themeDir="$(dirname "$_themeFile")"
              $DRY_RUN_CMD mkdir -p "$_themeDir"
              if [ -L "$_themeFile" ] || [ ! -e "$_themeFile" ]; then
                $DRY_RUN_CMD ln -sfT "$_themeTarget" "$_themeFile"
                $VERBOSE_ECHO "Created symlink: $_themeFile -> $_themeTarget"
              fi
            ''}
          ''
        ) themedApps}
      '';
    }

    # Apply theme on login via shell profile (needs TTY access for console colors)
    # Add to bash profile if bash is enabled
    (mkIf (config.programs.bash.enable or false) {
      programs.bash.profileExtra = ''
        # Apply vogix theme on login (restores theme after reboot)
        ${cfg.package}/bin/vogix refresh --quiet 2>/dev/null || true
      '';
    })

    # Add to zsh profile if zsh is enabled
    (mkIf (config.programs.zsh.enable or false) {
      programs.zsh.profileExtra = ''
        # Apply vogix theme on login (restores theme after reboot)
        ${cfg.package}/bin/vogix refresh --quiet 2>/dev/null || true
      '';
    })

    # Add to fish profile if fish is enabled
    (mkIf (config.programs.fish.enable or false) {
      programs.fish.loginShellInit = ''
        # Apply vogix theme on login (restores theme after reboot)
        ${cfg.package}/bin/vogix refresh --quiet 2>/dev/null; or true
      '';
    })

    # Optional daemon service for auto-regeneration
    (mkIf cfg.enableDaemon {
      systemd.user.services.vogix-daemon = {
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
    })
  ]);
}
