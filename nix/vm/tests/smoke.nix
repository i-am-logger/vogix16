# Smoke tests - Quick sanity checks
#
# Tests: Binary exists, status command, list command, systemd service
# These should run fast and catch obvious failures early.
#
{ pkgs
, home-manager
, self
,
}:

let
  testLib = import ./lib.nix { inherit pkgs home-manager self; };
in
testLib.mkTest "smoke" ''
  print("=== Test: Vogix Binary Exists ===")
  machine.succeed("which vogix")
  print("✓ vogix binary found")

  print("\n=== Test: Check Status Command ===")
  output = machine.succeed("su - vogix -c 'vogix status'")
  assert "theme:" in output
  assert "variant:" in output
  assert "scheme:" in output
  print("✓ Status command works")
  print(f"Output: {output}")

  print("\n=== Test: List Themes ===")
  output = machine.succeed("su - vogix -c 'vogix list'")
  assert "aikido" in output or "Available themes:" in output
  print("✓ List command works")
  print(f"Output: {output}")

  print("\n=== Test: No Config Files in ~/.config/vogix/ ===")
  result = machine.execute("su - vogix -c 'test -d ~/.config/vogix'")
  if result[0] != 0:
      print("✓ ~/.config/vogix/ does not exist (correct - everything in /run)")
  else:
      print("⚠ WARNING: ~/.config/vogix/ exists but shouldn't")

  print("\n=== Test: Systemd Service Ran at Login ===")
  service_status = machine.succeed("systemctl --user -M vogix@.host status vogix-setup.service")
  assert "active" in service_status or "exited" in service_status, "vogix-setup service didn't run!"
  print("✓ vogix-setup.service ran successfully at login")

  # Verify symlink creation
  machine.succeed("su - vogix -c 'journalctl --user --flush'")
  service_log = machine.succeed("su - vogix -c 'journalctl --user -u vogix-setup.service --no-pager'")

  has_directory_verification = "✓ Verified directory symlink:" in service_log
  has_files_verification = "✓ Verified config symlink:" in service_log

  if not (has_directory_verification or has_files_verification):
      print("\n❌ ERROR: Service log doesn't show symlink verification!")
      raise AssertionError("Service didn't verify absolute symlinks")

  if has_directory_verification:
      print("✓ Service verified all directory symlinks are absolute paths (directory mode)")
  else:
      print("✓ Service verified all config file symlinks are absolute paths (files mode)")

  print("\n=== Test: Shell Completions ===")
  output = machine.succeed("su - vogix -c 'vogix completions bash | head -5'")
  assert "_vogix" in output or "completion" in output
  print("✓ Shell completions work")

  print("\n" + "="*60)
  print("SMOKE TESTS PASSED!")
  print("="*60)
''
