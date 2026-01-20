#
# Size inspection for vogix theme data
# New architecture:
# - Themes: ~/.local/share/vogix/themes/
# - State: ~/.local/state/vogix/
#
{ pkgs
, vogix16Themes
, home-manager
, self
,
}:

let
  testLib = import ./lib.nix {
    inherit
      pkgs
      home-manager
      self
      vogix16Themes
      ;
  };
in
testLib.mkTest "runtime-size" ''
  print("=== Theme Data Size (dereferenced) ===")
  output = machine.succeed(f"su - vogix -c 'du -hL --max-depth=2 {vogix_themes}'")
  print(output)

  print("\n=== Theme Inventory ===")
  theme_count = machine.succeed(f"su - vogix -c 'ls -1 {vogix_themes} | wc -l'")
  print(f"Total theme-variant directories: {theme_count.strip()}")
  theme_list = machine.succeed(f"su - vogix -c 'ls -1 {vogix_themes} | head -20'")
  print("First 20 theme-variants:\n" + theme_list)

  print("\n=== Theme File Counts (dereferenced) ===")
  total_files = machine.succeed(f"su - vogix -c 'find -L {vogix_themes} -type f | wc -l'")
  print(f"Total files across all themes: {total_files.strip()}")
  current_files = machine.succeed(f"su - vogix -c 'find -L {current_theme} -type f | wc -l'")
  print(f"Files in current-theme: {current_files.strip()}")

  print("\n=== Current Theme Tree (top level) ===")
  current_apps = machine.succeed(f"su - vogix -c 'ls -1 {current_theme}'")
  print(current_apps)

  print("\n=== State Directory ===")
  state_content = machine.succeed(f"su - vogix -c 'ls -la {vogix_state}'")
  print(state_content)

  print("\n" + "="*60)
  print("SIZE CHECK COMPLETE")
  print("="*60)
''
