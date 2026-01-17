# Stress tests - Rapid switching
#
# Tests: Rapid theme/variant switching to catch race conditions
#
{ pkgs
, home-manager
, self
,
}:

let
  testLib = import ./lib.nix { inherit pkgs home-manager self; };
in
testLib.mkTest "stress" ''
  print("=== Test: Rapid Theme Switching (Stress Test) ===")
  # Rapidly switch themes to ensure no race conditions or state corruption

  themes_cycle = ["aikido", "nordic", "matrix", "desert", "aikido"]
  for i, theme in enumerate(themes_cycle):
      machine.succeed(f"su - vogix -c 'vogix -t {theme}'")
      status = machine.succeed("su - vogix -c 'vogix status'")
      assert theme in status.lower(), f"Rapid switch {i}: theme should be {theme}!"
  print("    ✓ Rapid theme switching works")

  variants_cycle = ["dark", "light", "dark", "light", "dark"]
  for i, variant in enumerate(variants_cycle):
      machine.succeed(f"su - vogix -c 'vogix -v {variant}'")
      status = machine.succeed("su - vogix -c 'vogix status'")
      assert variant in status.lower(), f"Rapid switch {i}: variant should be {variant}!"
  print("    ✓ Rapid variant switching works")

  print("\n=== Test: Rapid Combined Switching ===")
  # Rapidly switch both theme and variant together
  combinations = [
      ("aikido", "dark"),
      ("nordic", "light"),
      ("matrix", "dark"),
      ("desert", "light"),
      ("aikido", "dark"),
  ]
  for i, (theme, variant) in enumerate(combinations):
      machine.succeed(f"su - vogix -c 'vogix -t {theme} -v {variant}'")
      status = machine.succeed("su - vogix -c 'vogix status'")
      assert theme in status.lower(), f"Combo switch {i}: theme should be {theme}!"
      assert variant in status.lower(), f"Combo switch {i}: variant should be {variant}!"
  print("    ✓ Rapid combined switching works")

  print("\n=== Test: Symlink Integrity After Stress ===")
  # After rapid switching, verify symlinks are still correct

  # Final state should be aikido-dark
  current_link = machine.succeed(f"su - vogix -c 'readlink {vogix_runtime}/themes/current-theme'").strip()
  assert "aikido" in current_link.lower(), "Symlink should point to aikido after stress test!"
  assert "dark" in current_link.lower(), "Symlink should point to dark variant after stress test!"
  print("    ✓ Symlink integrity maintained after stress test")

  # Verify config is accessible and correct
  alacritty = machine.succeed("su - vogix -c 'cat ~/.config/alacritty/alacritty.toml'")
  aikido_dark_bg = all_themes['aikido']['dark']['base00'].lower()
  assert aikido_dark_bg in alacritty.lower(), "Config should have aikido dark colors after stress test!"
  print("    ✓ Config content correct after stress test")

  print("\n✓ Stress test passed!")

  print("\n" + "="*60)
  print("STRESS TESTS PASSED!")
  print("="*60)
''
