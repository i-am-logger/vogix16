{ config, lib, pkgs, options, themesPath ? null, ... }:

with lib;

let
  cfg = config.vogix16;
in
{
  options.vogix16 = {
    enable = mkEnableOption "vogix16 console colors integration";

    autoFromHomeManager = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Automatically configure console.colors from home-manager vogix16 configuration.
        When enabled and no explicit theme/variant is set, will use the theme from the
        first home-manager user with programs.vogix16.enable = true.
      '';
    };

    theme = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to theme file for console colors (overrides auto-detection)";
      example = literalExpression "./themes/aikido.nix";
    };

    variant = mkOption {
      type = types.nullOr (types.enum [ "dark" "light" ]);
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
          # Try to find the first user with vogix16 enabled
          homeManagerUsers = if options ? home-manager then
            attrNames (filterAttrs (name: userCfg:
              userCfg.programs.vogix16.enable or false
            ) (config.home-manager.users or {}))
          else [];

          firstVogixUser = if homeManagerUsers != [] then builtins.head homeManagerUsers else null;

          # Get theme configuration from home-manager user
          hmVogixCfg = if firstVogixUser != null
            then config.home-manager.users.${firstVogixUser}.programs.vogix16
            else null;

          # Get themes directory
          themesDir = if themesPath != null then themesPath else ../../themes;

          # Get theme name and variant
          selectedThemeName = if hmVogixCfg != null then hmVogixCfg.defaultTheme else null;
          selectedVariant = if hmVogixCfg != null then hmVogixCfg.defaultVariant else null;

          # Resolve theme path
          selectedThemePath = if selectedThemeName != null
            then themesDir + "/${selectedThemeName}.nix"
            else null;

          # Load theme
          loadedTheme = if selectedThemePath != null && selectedVariant != null
            then import selectedThemePath
            else null;

          # Get colors based on variant
          themeColors = if loadedTheme != null
            then (if selectedVariant == "dark" then loadedTheme.dark else loadedTheme.light)
            else null;

        in mkIf (themeColors != null) (
          map (c: builtins.replaceStrings ["#"] [""] c) [
            themeColors.base00  # black (ANSI 0)
            themeColors.base08  # red (ANSI 1)
            themeColors.base0B  # green (ANSI 2)
            themeColors.base0A  # yellow (ANSI 3)
            themeColors.base0D  # blue (ANSI 4)
            themeColors.base0E  # magenta (ANSI 5)
            themeColors.base0C  # cyan (ANSI 6)
            themeColors.base05  # white (ANSI 7)
            themeColors.base03  # bright black (ANSI 8)
            themeColors.base08  # bright red (ANSI 9)
            themeColors.base0B  # bright green (ANSI 10)
            themeColors.base0A  # bright yellow (ANSI 11)
            themeColors.base0D  # bright blue (ANSI 12)
            themeColors.base0E  # bright magenta (ANSI 13)
            themeColors.base0C  # bright cyan (ANSI 14)
            themeColors.base07  # bright white (ANSI 15)
          ]
        );
    })

    # Explicit theme/variant configuration
    (mkIf (cfg.theme != null && cfg.variant != null) {
      console.colors =
        let
          # Load explicit theme
          loadedTheme = import cfg.theme;
          themeColors = if cfg.variant == "dark" then loadedTheme.dark else loadedTheme.light;
        in
          map (c: builtins.replaceStrings ["#"] [""] c) [
            themeColors.base00  # black (ANSI 0)
            themeColors.base08  # red (ANSI 1)
            themeColors.base0B  # green (ANSI 2)
            themeColors.base0A  # yellow (ANSI 3)
            themeColors.base0D  # blue (ANSI 4)
            themeColors.base0E  # magenta (ANSI 5)
            themeColors.base0C  # cyan (ANSI 6)
            themeColors.base05  # white (ANSI 7)
            themeColors.base03  # bright black (ANSI 8)
            themeColors.base08  # bright red (ANSI 9)
            themeColors.base0B  # bright green (ANSI 10)
            themeColors.base0A  # bright yellow (ANSI 11)
            themeColors.base0D  # bright blue (ANSI 12)
            themeColors.base0E  # bright magenta (ANSI 13)
            themeColors.base0C  # bright cyan (ANSI 14)
            themeColors.base07  # bright white (ANSI 15)
          ];
    })
  ]);
}
