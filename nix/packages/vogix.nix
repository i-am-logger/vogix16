{ lib
, rustPlatform
, pkg-config
, dbus
}:

let
  cargoToml = builtins.fromTOML (builtins.readFile ../../Cargo.toml);
in
rustPlatform.buildRustPackage rec {
  pname = cargoToml.package.name;
  version = cargoToml.package.version;

  src = lib.cleanSource ../..;

  cargoLock = {
    lockFile = ../../Cargo.lock;
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    dbus
  ];

  # Install templates
  postInstall = ''
    mkdir -p $out/share/vogix16
    cp -r ${../../templates} $out/share/vogix16/templates
  '';

  meta = with lib; {
    description = cargoToml.package.description;
    homepage = "https://github.com/i-am-logger/vogix16";
    license = licenses.cc-by-nc-sa-40;
    maintainers = [ ];
    mainProgram = cargoToml.package.name;
  };
}
