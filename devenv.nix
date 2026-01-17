{ pkgs
, config
, lib
, ...
}:
let
  cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
  packageName = cargoToml.package.name;
  packageVersion = cargoToml.package.version;
  packageDescription = cargoToml.package.description or "";
in
{
  # Set root explicitly for flake compatibility
  devenv.root = lib.mkDefault (builtins.toString ./.);

  dotenv.enable = true;
  imports = [
    ./nix/rust.nix
  ];

  # Additional packages for development
  packages = [
    pkgs.git
    pkgs.dbus
    pkgs.pkg-config
  ];

  # Development scripts
  scripts.dev-test.exec = ''
    echo "🧪 Running tests..."
    cargo test --all-features
  '';

  scripts.dev-run.exec = ''
    echo "🚀 Running vogix..."
    cargo run --release
  '';

  scripts.dev-build.exec = ''
    echo "🔨 Building vogix..."
    cargo build --release
  '';

  # Nix development scripts (disable eval cache to avoid stale results)
  scripts.nix-build-dev.exec = ''
    echo "🏗️  Building VM with eval cache disabled (for active development)..."
    nix build .#nixosConfigurations.vogix-test-vm.config.system.build.vm \
      --option eval-cache false
  '';

  scripts.nix-check-dev.exec = ''
    echo "✅ Checking flake with eval cache disabled (for active development)..."
    nix flake check --option eval-cache false
  '';

  # Environment variables
  env = {
    PROJECT_NAME = "vogix";
    CARGO_TARGET_DIR = "./target";
  };

  # Development shell setup
  enterShell = ''
    clear
    ${pkgs.figlet}/bin/figlet "${packageName}"
    echo
    {
      ${pkgs.lib.optionalString (packageDescription != "") ''echo "• ${packageDescription}"''}
      echo -e "• \033[1mv${packageVersion}\033[0m"
      echo -e " \033[0;32m✓\033[0m Development environment ready"
    } | ${pkgs.boxes}/bin/boxes -d stone -a l -i none
    echo
    echo "Available scripts:"
    echo "  Rust Development:"
    echo "    • dev-test      - Run tests"
    echo "    • dev-run       - Run the application"
    echo "    • dev-build     - Build the application"
    echo ""
    echo "  Nix Development (eval cache disabled):"
    echo "    • nix-build-dev - Build VM without eval cache"
    echo "    • nix-check-dev - Check flake without eval cache"
    echo ""
  '';

  # https://devenv.sh/integrations/treefmt/
  treefmt = {
    enable = true;
    config = {
      # Global exclusions
      settings.global.excludes = [
        # Application modules have { lib, appLib } interface contract
        # Not all modules use these params but they're part of the API
        "nix/modules/applications/*.nix"
        # Devenv generated files
        ".devenv.flake.nix"
        ".devenv/"
      ];

      programs = {
        # Nix
        nixpkgs-fmt.enable = true;
        deadnix.enable = true;
        statix.enable = true;

        # Rust
        rustfmt.enable = true;

        # Python
        black.enable = true;

        # Shell
        shellcheck.enable = true;
        shfmt.enable = true;
      };
    };
  };

  # https://devenv.sh/git-hooks/
  git-hooks.settings.rust.cargoManifestPath = "./Cargo.toml";

  git-hooks.hooks = {
    # Use treefmt for all formatting
    treefmt.enable = true;

    # Keep clippy for Rust linting (not just formatting)
    clippy.enable = true;
  };

  # https://devenv.sh/outputs/
  outputs = {
    vogix = config.languages.rust.import ./. {
      # Override to skip Windows-specific dependencies
      crateOverrides = pkgs.defaultCrateOverrides // {
        # Skip all Windows-specific crates
        windows-sys = _attrs: null;
        windows-core = _attrs: null;
        windows-targets = _attrs: null;
        windows_x86_64_gnu = _attrs: null;
        windows_x86_64_msvc = _attrs: null;
        windows_i686_gnu = _attrs: null;
        windows_i686_msvc = _attrs: null;
        windows_aarch64_msvc = _attrs: null;
        windows_aarch64_gnullvm = _attrs: null;
        anstyle-wincon = _attrs: null;
      };
    };
  };

  # https://devenv.sh/tasks/
  tasks = {
    "test:fmt" = {
      exec = "treefmt --fail-on-change";
    };

    "test:clippy" = {
      exec = "cargo clippy --quiet -- -D warnings";
    };

    "test:check" = {
      exec = "cargo check --quiet";
    };

    "test:unit" = {
      exec = "cargo test --quiet";
    };
  };

  # https://devenv.sh/tests/
  # Use mkForce to override devenv's default enterTest which exports bash functions
  # that cause issues with treefmt subprocesses (black, etc.)
  enterTest = lib.mkForce "devenv tasks run test:fmt test:clippy test:check test:unit";

  # See full reference at https://devenv.sh/reference/options/
}
