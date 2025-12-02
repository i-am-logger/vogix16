{
  pkgs,
  ...
}:

{

  languages.rust = {
    enable = true;
    # https://devenv.sh/reference/options/#languagesrustchannel
    channel = "stable";

    components = [
      "rustc"
      "cargo"
      "clippy"
      "rustfmt"
      "rust-analyzer"
    ];

    targets = [
      "x86_64-pc-windows-gnu"
    ];
  };

  git-hooks.settings.rust.cargoManifestPath = "./Cargo.toml";

  git-hooks.hooks = {
    rustfmt.enable = true;
    clippy.enable = true;
  };

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

  enterTest = "devenv tasks run test:fmt test:clippy test:check test:unit";

  packages = [
    pkgs.pkgsCross.mingwW64.buildPackages.gcc
    pkgs.pkgsCross.mingwW64.windows.pthreads
  ];
}
