#
# Runtime size inspection for /run/user/UID/vogix
#
{ pkgs
, home-manager
, self
,
}:

let
  testLib = import ./lib.nix { inherit pkgs home-manager self; };
in
testLib.mkTest "runtime-size" ''
  print("=== Runtime Size: /run/user/UID/vogix (dereferenced) ===")
  output = machine.succeed("su - vogix -c 'du -hL --max-depth=2 /run/user/1000/vogix'")
  print(output)

  print("\n=== Theme Inventory ===")
  theme_count = machine.succeed("su - vogix -c 'ls -1 /run/user/1000/vogix/themes | wc -l'")
  print(f"Total theme entries (including current-theme): {theme_count.strip()}")
  theme_list = machine.succeed("su - vogix -c 'ls -1 /run/user/1000/vogix/themes | head -20'")
  print("First 20 themes:\n" + theme_list)

  print("\n=== Theme File Counts (dereferenced) ===")
  total_files = machine.succeed("su - vogix -c 'find -L /run/user/1000/vogix/themes -type f | wc -l'")
  print(f"Total files across all themes: {total_files.strip()}")
  current_files = machine.succeed("su - vogix -c 'find -L /run/user/1000/vogix/themes/current-theme -type f | wc -l'")
  print(f"Files in current-theme: {current_files.strip()}")

  print("\n=== Current Theme Tree (top level) ===")
  current_apps = machine.succeed("su - vogix -c 'ls -1 /run/user/1000/vogix/themes/current-theme'")
  print(current_apps)

  print("\n" + "="*60)
  print("RUNTIME SIZE CHECK COMPLETE")
  print("="*60)
''
