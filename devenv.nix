{
  pkgs,
  config,
  ...
}:
let
  cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
  packageName = cargoToml.package.name;
  packageVersion = cargoToml.package.version;
  packageDescription = cargoToml.package.description or "";
in
{
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
    echo "🚀 Running vogix16..."
    cargo run --release
  '';

  scripts.dev-build.exec = ''
    echo "🔨 Building vogix16..."
    cargo build --release
  '';

  # Nix development scripts (disable eval cache to avoid stale results)
  scripts.nix-build-dev.exec = ''
    echo "🏗️  Building VM with eval cache disabled (for active development)..."
    nix build .#nixosConfigurations.vogix16-test-vm.config.system.build.vm \
      --option eval-cache false
  '';

  scripts.nix-check-dev.exec = ''
    echo "✅ Checking flake with eval cache disabled (for active development)..."
    nix flake check --option eval-cache false
  '';

  # Environment variables
  env = {
    PROJECT_NAME = "vogix16";
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

  # https://devenv.sh/languages/
  languages.rust = {
    enable = true;
    channel = "stable";

    components = [
      "rustc"
      "cargo"
      "clippy"
      "rustfmt"
      "rust-analyzer"
    ];
  };

  # https://devenv.sh/git-hooks/
  git-hooks.settings.rust.cargoManifestPath = "./Cargo.toml";

  git-hooks.hooks = {
    rustfmt.enable = true;
    clippy.enable = true;
  };

  # https://devenv.sh/tasks/
  tasks = {
    "test:fmt" = {
      exec = "cargo fmt --check";
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
  enterTest = "devenv tasks run test:fmt test:clippy test:check test:unit";

  # See full reference at https://devenv.sh/reference/options/
}
