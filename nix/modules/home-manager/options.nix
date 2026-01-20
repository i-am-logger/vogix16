# Module options for Vogix Home Manager module
#
# Defines all programs.vogix.* options
{ lib, pkgs }:

let
  inherit (lib)
    mkOption
    mkEnableOption
    types
    literalExpression
    ;

  # Import the vogix package
  vogix = pkgs.callPackage ../../packages/vogix.nix { };

  # Import shared application discovery
  appDiscovery = import ../lib/applications.nix { inherit lib; };
  inherit (appDiscovery) availableApps;

  # Per-app options (dynamically generated)
  appOptions = lib.listToAttrs (
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
            type = types.nullOr types.str;
            default = null;
            description = "Variant to use for ${appName} (overrides defaultVariant)";
          };
        };
      })
      availableApps
  );

in
{
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
      type = types.str;
      default = "night";
      description = "Default variant name (e.g., night, day, dark, light, moon, dawn).";
    };

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
      description = "Enable the vogix daemon for auto-regeneration.";
    };

    colors = mkOption {
      type = types.attrsOf types.str;
      internal = true;
      description = "Semantic color API for the selected theme and variant. Used by application modules.";
    };
  }
  // appOptions;

  # Export for use by other modules
  inherit availableApps vogix;
}
