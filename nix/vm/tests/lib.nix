# Shared test utilities and VM configuration
#
# This module provides common setup for all integration tests:
# - VM configuration (nodes.machine)
# - Theme data (allThemes, themesJSON)
# - Common Python test helpers
#
{ pkgs
, home-manager
, self
,
}:

let
  # Import the test-vm configuration
  testVMConfig = import ../test-vm.nix;

  # Load vogix16 themes for validation (new multi-scheme structure)
  vogix16Dir = ../../../themes/vogix16;
  themeFiles = builtins.readDir vogix16Dir;

  # Convert multi-variant format to test-compatible format
  allThemes = builtins.listToAttrs (
    builtins.map
      (
        filename:
        let
          name = builtins.replaceStrings [ ".nix" ] [ "" ] filename;
          theme = import (vogix16Dir + "/${filename}");
          variantColors = builtins.mapAttrs (_variantName: variantData: variantData.colors) theme.variants;
        in
        {
          inherit name;
          value = variantColors;
        }
      )
      (builtins.filter (f: builtins.match ".*\\.nix$" f != null) (builtins.attrNames themeFiles))
  );

  themesJSON = builtins.toJSON allThemes;

  # Common VM node configuration
  machineConfig = {
    imports = [
      testVMConfig
      self.nixosModules.default
      home-manager.nixosModules.home-manager
    ];

    nixpkgs.overlays = [
      (_final: _prev: {
        inherit (self.packages.x86_64-linux) vogix;
      })
    ];

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.vogix = import ../home.nix;
    home-manager.sharedModules = [ self.homeManagerModules.default ];
  };

  # Common Python preamble for all test scripts
  testPreamble = ''
    import time
    import json
    import shlex
    import re

    # Ensure imports are used (prevents lint warnings in tests that don't need them)
    _ = (shlex.quote, re.search)

    # Load all theme colors from Nix
    all_themes = json.loads(r"""${themesJSON}""")
    aikido_colors = all_themes['aikido']

    # Start the machine
    machine.start()
    machine.wait_for_unit("multi-user.target")

    # Wait for user session to be ready
    time.sleep(2)

    # Get UID for runtime paths
    uid = machine.succeed("su - vogix -c 'id -u'").strip()
    vogix_runtime = f"/run/user/{uid}/vogix"
  '';

  # Helper to create a test with common setup
  mkTest =
    name: testScript:
    pkgs.testers.nixosTest {
      name = "vogix-${name}";
      nodes.machine = _: machineConfig;
      testScript = testPreamble + testScript;
    };

in
{
  inherit
    allThemes
    themesJSON
    machineConfig
    testPreamble
    mkTest
    ;
}
