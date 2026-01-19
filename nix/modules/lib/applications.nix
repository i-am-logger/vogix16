# Application discovery utilities
#
# Shared logic for discovering and loading application modules
{ lib }:

let
  applicationsDir = ../applications;
  applicationFiles = builtins.readDir applicationsDir;

  nixApplicationFiles = builtins.filter (f: lib.hasSuffix ".nix" f) (
    builtins.attrNames applicationFiles
  );

  # Extract app names from filenames (e.g., "alacritty.nix" -> "alacritty")
  # Exclude lib.nix (shared utilities, not an app)
  availableApps = map (filename: lib.removeSuffix ".nix" filename) (
    builtins.filter (f: f != "lib.nix") nixApplicationFiles
  );

  # Load shared utility functions for app modules
  appLib = import ../applications/lib.nix { inherit lib; };

  # Load all generators dynamically, passing appLib utilities
  loadAppGenerators = lib.listToAttrs (
    map
      (appName: {
        name = appName;
        value = import (applicationsDir + "/${appName}.nix") { inherit lib appLib; };
      })
      availableApps
  );

in
{
  inherit
    availableApps
    appLib
    applicationsDir
    ;
  appGenerators = loadAppGenerators;
}
