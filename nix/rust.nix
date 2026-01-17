{ pkgs
, lib
, ...
}:

{
  # Rust language configuration
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

  # Cross-compilation packages for Windows
  # Only include on Linux where cross-compilation is supported
  packages = lib.optionals pkgs.stdenv.isLinux [
    pkgs.pkgsCross.mingwW64.buildPackages.gcc
  ];
}
