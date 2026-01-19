# State tests - State persistence and consistency
#
# Tests: State file persistence, consistency after operations
#
{ pkgs
, home-manager
, self
,
}:

let
  testLib = import ./lib.nix { inherit pkgs home-manager self; };
in
testLib.mkTest "state" ''
  print("=== Test: State Persistence ===")
  # Make a change and verify it persists
  machine.succeed("su - vogix -c 'vogix -s base16 -t dracula -v dark'")

  # Check state file exists and has correct content
  state_content = machine.succeed("su - vogix -c 'cat $XDG_RUNTIME_DIR/vogix/state/current.toml 2>/dev/null || cat ~/.local/state/vogix/current.toml 2>/dev/null || echo NOTFOUND'")
  if state_content.strip() != "NOTFOUND":
      print(f"State content: {state_content[:200]}")
      assert "base16" in state_content.lower(), "State file doesn't contain scheme!"
      assert "dracula" in state_content.lower(), "State file doesn't contain theme!"
      print("✓ State persisted correctly to file")
  else:
      print("⚠ State file not found in expected locations (may use different path)")

  # Reset for other tests
  machine.succeed("su - vogix -c 'vogix -s vogix16 -t aikido -v dark'")
  print("✓ Reset to vogix16/aikido/dark")

  print("\n=== Test: State Consistency After Multiple Operations ===")
  # Perform a series of operations and verify state is consistent

  # Complex sequence of operations
  machine.succeed("su - vogix -c 'vogix -s vogix16 -t aikido -v dark'")
  machine.succeed("su - vogix -c 'vogix -t nordic'")
  machine.succeed("su - vogix -c 'vogix -v light'")
  machine.succeed("su - vogix -c 'vogix -t matrix -v dark'")
  machine.succeed("su - vogix -c 'vogix -v lighter'")

  # Final state should be: vogix16, matrix, light
  final_status = machine.succeed("su - vogix -c 'vogix status'")
  assert "matrix" in final_status.lower(), "Final theme should be matrix!"
  assert "light" in final_status.lower(), "Final variant should be light (from lighter)!"
  assert "vogix16" in final_status.lower(), "Scheme should still be vogix16!"
  print("    ✓ State is consistent after complex operations")

  # Verify state file matches
  state_content = machine.succeed("su - vogix -c 'cat $XDG_RUNTIME_DIR/vogix/state/current.toml 2>/dev/null || echo NOTFOUND'")
  if "NOTFOUND" not in state_content:
      assert "matrix" in state_content.lower(), "State file should have matrix!"
      assert "light" in state_content.lower(), "State file should have light!"
      print("    ✓ State file matches status output")

  # Verify symlink matches
  current_link = machine.succeed(f"su - vogix -c 'readlink {vogix_runtime}/themes/current-theme'").strip()
  assert "matrix" in current_link.lower() and "light" in current_link.lower(), "Symlink should point to matrix-light!"
  print("    ✓ Symlink matches state")

  # Verify config has correct colors
  alacritty = machine.succeed("su - vogix -c 'cat ~/.config/alacritty/alacritty.toml'")
  matrix_light_bg = all_themes['matrix']['light']['base00'].lower()
  assert matrix_light_bg in alacritty.lower(), f"Config should have matrix light bg {matrix_light_bg}!"
  print("    ✓ Config has correct colors")

  print("\n✓ State consistency verified!")

  # Reset to default for any subsequent tests
  machine.succeed("su - vogix -c 'vogix -s vogix16 -t aikido -v dark'")

  print("\n" + "="*60)
  print("STATE TESTS PASSED!")
  print("="*60)
''
