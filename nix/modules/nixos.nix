{ config
, lib
, pkgs
, options
, ...
}:

with lib;

let
  cfg = config.vogix;

  # Helper: Convert theme colors (base16 format) to console.colors array
  # Takes a theme colors attrset and returns a list of 16 hex colors (without #)
  mkConsoleColors =
    themeColors:
    map (c: builtins.replaceStrings [ "#" ] [ "" ] c) [
      themeColors.base00 # black (ANSI 0)
      themeColors.base08 # red (ANSI 1)
      themeColors.base0B # green (ANSI 2)
      themeColors.base0A # yellow (ANSI 3)
      themeColors.base0D # blue (ANSI 4)
      themeColors.base0E # magenta (ANSI 5)
      themeColors.base0C # cyan (ANSI 6)
      themeColors.base05 # white (ANSI 7)
      themeColors.base03 # bright black (ANSI 8)
      themeColors.base08 # bright red (ANSI 9)
      themeColors.base0B # bright green (ANSI 10)
      themeColors.base0A # bright yellow (ANSI 11)
      themeColors.base0D # bright blue (ANSI 12)
      themeColors.base0E # bright magenta (ANSI 13)
      themeColors.base0C # bright cyan (ANSI 14)
      themeColors.base07 # bright white (ANSI 15)
    ];
in
{
  options.vogix = {
    enable = mkEnableOption "vogix console colors integration";

    autoFromHomeManager = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Automatically configure console.colors from home-manager vogix configuration.
        When enabled and no explicit theme/variant is set, will use the theme from the
        first home-manager user with programs.vogix.enable = true.
      '';
    };

    theme = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to theme file for console colors (overrides auto-detection)";
      example = literalExpression "./themes/aikido.nix";
    };

    variant = mkOption {
      type = types.nullOr (
        types.enum [
          "dark"
          "light"
        ]
      );
      default = null;
      description = "Theme variant (dark or light) for console colors (overrides auto-detection)";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Make vogix CLI available system-wide
      environment.systemPackages = [ pkgs.vogix ];

      # Add security wrappers for console theme switching
      # This allows users to run these commands without sudo
      security.wrappers = {
        chvt = {
          owner = "root";
          group = "root";
          capabilities = "cap_sys_tty_config+ep";
          source = "${pkgs.kbd}/bin/chvt";
        };
        setvtrgb = {
          owner = "root";
          group = "root";
          capabilities = "cap_sys_tty_config+ep";
          source = "${pkgs.kbd}/bin/setvtrgb";
        };
      };
    }

    # Auto-detect theme from home-manager if enabled
    (mkIf (cfg.autoFromHomeManager && cfg.theme == null && cfg.variant == null) {
      console.colors =
        let
          # Try to find the first user with vogix enabled
          homeManagerUsers =
            if options ? home-manager then
              attrNames
                (
                  filterAttrs (_name: userCfg: userCfg.programs.vogix.enable or false) (
                    config.home-manager.users or { }
                  )
                )
            else
              [ ];

          firstVogixUser = if homeManagerUsers != [ ] then builtins.head homeManagerUsers else null;

          # Get theme configuration from home-manager user
          hmVogixCfg =
            if firstVogixUser != null then config.home-manager.users.${firstVogixUser}.programs.vogix else null;

          # Get themes directory (vogix16 native themes)
          themesDir = ../../themes/vogix16;

          # Get theme name and variant (polarity)
          selectedThemeName = if hmVogixCfg != null then hmVogixCfg.defaultTheme else null;
          selectedPolarity = if hmVogixCfg != null then hmVogixCfg.defaultVariant else null;

          # Resolve theme path
          selectedThemePath =
            if selectedThemeName != null then themesDir + "/${selectedThemeName}.nix" else null;

          # Load theme (new multi-variant format)
          loadedTheme =
            if selectedThemePath != null && selectedPolarity != null then import selectedThemePath else null;

          # Get actual variant name from defaults mapping
          selectedVariantName =
            if loadedTheme != null then loadedTheme.defaults.${selectedPolarity} or selectedPolarity else null;

          # Get colors based on variant (new format: variants.<name>.colors)
          themeColors =
            if loadedTheme != null && selectedVariantName != null then
              loadedTheme.variants.${selectedVariantName}.colors or null
            else
              null;

        in
        mkIf (themeColors != null) (mkConsoleColors themeColors);
    })

    # Explicit theme/variant configuration
    (mkIf (cfg.theme != null && cfg.variant != null) {
      console.colors =
        let
          # Load explicit theme (new multi-variant format)
          loadedTheme = import cfg.theme;
          # Get variant name from defaults mapping
          variantName = loadedTheme.defaults.${cfg.variant} or cfg.variant;
          themeColors = loadedTheme.variants.${variantName}.colors;
        in
        mkConsoleColors themeColors;
    })
  ]);
}
