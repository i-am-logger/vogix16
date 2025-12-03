{
  description = "Vogix16 - Runtime theme management for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    crate2nix.url = "github:nix-community/crate2nix";
    crate2nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = { self, nixpkgs, home-manager, devenv, ... }@inputs:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      # NixOS module
      nixosModules.default = import ./nix/modules/nixos.nix;

      # Home Manager module
      homeManagerModules.default = import ./nix/modules/home-manager.nix;

      # Packages for each system - from devenv outputs
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "vogix" ];
          };
          # Use mkConfig but only access outputs, not shell
          devenvOutputs = (devenv.lib.mkConfig {
            inherit inputs pkgs;
            modules = [ ./devenv.nix ];
          }).outputs;
        in
        devenvOutputs // {
          default = devenvOutputs.vogix;
        }
      );

      # NixOS VM for testing
      nixosConfigurations.vogix16-test-vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          themesPath = ./themes;
        };
        modules = [
          ./nix/vm/test-vm.nix
          self.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            # Make vogix package available in pkgs
            nixpkgs.overlays = [
              (final: prev: {
                vogix = self.packages.x86_64-linux.vogix;
              })
            ];

            # Allow unfree license for testing
            nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "vogix" ];

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.vogix = import ./nix/vm/home.nix;
            home-manager.sharedModules = [ self.homeManagerModules.default ];
            home-manager.extraSpecialArgs = {
              themesPath = ./themes;
            };
          }
        ];
      };

      # Automated integration tests
      checks = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "vogix" ];
          };
        in
        {
          integration = import ./nix/vm/test.nix {
            inherit pkgs home-manager self;
          };
        }
      );

      # Development shells - using devenv
      # Note: Use 'devenv shell' for development instead of 'nix develop'
      # devShells commented out due to Windows dependencies issue in crate2nix evaluation
      # devShells = forAllSystems (system:
      #   let
      #     pkgs = import nixpkgs {
      #       inherit system;
      #       config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "vogix" ];
      #     };
      #   in
      #   {
      #     default = devenv.lib.mkShell {
      #       inherit inputs pkgs;
      #       modules = [ ./devenv.nix ];
      #     };
      #   }
      # );

      # Apps for easy access
      apps = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          # VM launcher with eval cache disabled to ensure fresh builds during development
          vogix-vm = {
            type = "app";
            program = "${pkgs.writeShellScript "vogix-vm" ''
              echo "Building and launching VM with eval cache disabled..."
              nix build .#nixosConfigurations.vogix16-test-vm.config.system.build.vm \
                --option eval-cache false \
                --no-link \
                --print-out-paths | while read vm_path; do
                "$vm_path/bin/run-vogix16-test-vm"
              done
            ''}";
          };

          # Development helper that disables eval cache to avoid stale results
          # when modifying application modules during active development
          dev-check = {
            type = "app";
            program = "${pkgs.writeShellScript "dev-check" ''
              echo "Running flake checks with eval cache disabled (for development)..."
              nix flake check --option eval-cache false "$@"
            ''}";
          };
        });
    };
}
