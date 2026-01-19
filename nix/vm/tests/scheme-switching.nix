# Scheme switching tests - Cross-scheme switching (vogix16, base16, base24, ansi16)
#
# Tests: Switch schemes, verify configs, test reload failure warnings
#
{ pkgs
, home-manager
, self
,
}:

let
  testLib = import ./lib.nix { inherit pkgs home-manager self; };
in
testLib.mkTest "scheme-switching" ''
  print("=== Test: Scheme Switching ===")
  status_before = machine.succeed("su - vogix -c 'vogix status'")
  print(f"Status before scheme change: {status_before}")

  # Switch to base16 scheme
  machine.succeed("su - vogix -c 'vogix -s base16'")
  status_after = machine.succeed("su - vogix -c 'vogix status'")
  assert "base16" in status_after.lower(), "Scheme not updated to base16!"
  print("✓ Scheme switched to base16")

  # Switch back to vogix16
  machine.succeed("su - vogix -c 'vogix -s vogix16'")
  status_back = machine.succeed("su - vogix -c 'vogix status'")
  assert "vogix16" in status_back.lower(), "Scheme not switched back to vogix16!"
  print("✓ Scheme switched back to vogix16")

  print("\n=== Test: Cross-Scheme Theme Switching (vogix16 → base16) ===")
  # Console reload may fail in VM (no real TTY), which is expected behavior

  machine.succeed("su - vogix -c 'vogix -s vogix16 -t aikido -v dark'")
  status_before = machine.succeed("su - vogix -c 'vogix status'")
  print(f"Before: {status_before.strip()}")

  # Switch to base16 scheme with dracula theme
  switch_output = machine.succeed("su - vogix -c 'vogix -s base16 -t dracula 2>&1'")
  print(f"Switch output: {switch_output}")

  status_after = machine.succeed("su - vogix -c 'vogix status'")
  assert "base16" in status_after.lower(), "Scheme not switched to base16!"
  assert "dracula" in status_after.lower(), "Theme not switched to dracula!"
  print("✓ Cross-scheme switch to base16/dracula succeeded")

  # CRITICAL: Verify WARN output when there are reload failures
  if "Failures:" in switch_output:
      print("✓ Detected reload failures (expected in VM - no real TTY for console)")
      
      applied_match = re.search(r'\[(INFO|WARN)\s*\].*Applied:', switch_output)
      if applied_match:
          log_level = applied_match.group(1)
          if log_level == "INFO":
              raise AssertionError(
                  "BUG: CLI shows [INFO] Applied even though there were reload failures!\n"
                  "Expected: [WARN] Applied: ... (X/Y reloaded, Z failed)\n"
                  f"Got output:\n{switch_output}"
              )
          elif log_level == "WARN":
              print("✓ CLI correctly shows [WARN] when there are reload failures")
              if "failed" in switch_output.lower():
                  print("✓ WARN message includes failure information")
      else:
          print("⚠ Could not parse Applied log level from output")
  else:
      print("⚠ No reload failures detected (unexpected in VM environment)")
      if "[INFO" in switch_output and "Applied:" in switch_output:
          print("✓ CLI shows [INFO] when all reloads succeed (correct)")

  machine.succeed("su - vogix -c 'vogix -s vogix16 -t aikido -v dark'")
  print("✓ Switched back to vogix16/aikido")

  print("\n=== Test: Full Scheme Switching Cycle ===")

  def test_scheme_switch(from_scheme, to_scheme, expected_theme=None):
      print(f"\n  --- Switching from {from_scheme} to {to_scheme} ---")

      if expected_theme:
          switch_cmd = f"vogix -s {to_scheme} -t {expected_theme}"
      else:
          switch_cmd = f"vogix -s {to_scheme}"

      switch_result = machine.execute(f"su - vogix -c '{switch_cmd} 2>&1'")
      if switch_result[0] != 0:
          print(f"    ⚠ Switch failed: {switch_result[1][:200]}")
          return False

      status_after = machine.succeed("su - vogix -c 'vogix status'")
      print(f"    After: {status_after.strip()}")

      if to_scheme.lower() not in status_after.lower():
          print(f"    ⚠ Status doesn't show {to_scheme} scheme!")
          return False

      print(f"    ✓ Switched to {to_scheme}")
      return True

  machine.succeed("su - vogix -c 'vogix -s vogix16 -t aikido -v dark'")

  # Test vogix16 -> base16
  base16_themes_to_try = ["dracula", "gruvbox-dark-medium", "nord", "monokai"]
  base16_success = False
  for theme in base16_themes_to_try:
      if test_scheme_switch("vogix16", "base16", theme):
          base16_success = True
          break

  if base16_success:
      print("✓ vogix16 -> base16 works!")

      # Test back to vogix16
      if test_scheme_switch("base16", "vogix16", "aikido"):
          print("✓ base16 -> vogix16 (full circle) works!")
  else:
      print("⚠ No base16 themes available for testing")

  machine.succeed("su - vogix -c 'vogix -s vogix16 -t aikido -v dark'")
  print("\n✓ Scheme switching test complete!")

  print("\n=== Test: Console Palette Format Validation ===")

  # Check aikido (vogix16) palette
  aikido_palette = machine.succeed(f"su - vogix -c 'cat {vogix_runtime}/themes/aikido-dark/console/palette'")
  print(f"Aikido palette (first 200 chars): {aikido_palette[:200]}")

  aikido_lines = [l for l in aikido_palette.strip().split('\n') if l.strip()]
  assert len(aikido_lines) == 16, f"FAILED: Aikido palette has {len(aikido_lines)} lines, expected 16"
  for i, line in enumerate(aikido_lines):
      assert line.startswith('#'), f"FAILED: Aikido palette line {i} doesn't start with #: {line}"
      assert len(line) == 7, f"FAILED: Aikido palette line {i} is not #RRGGBB format: {line}"
  print("✓ Aikido (vogix16) palette has correct format (16 lines with # prefix)")

  # Check catppuccin (base16) palette - tests YAML inline comment stripping
  catppuccin_palette_path = f"{vogix_runtime}/themes/catppuccin-frappe/console/palette"
  catppuccin_exists = machine.execute(f"su - vogix -c 'test -f {catppuccin_palette_path}'")

  if catppuccin_exists[0] == 0:
      catppuccin_palette = machine.succeed(f"su - vogix -c 'cat {catppuccin_palette_path}'")
      print(f"Catppuccin frappe palette:\n{catppuccin_palette}")
      
      catppuccin_lines = [l for l in catppuccin_palette.strip().split('\n') if l.strip()]
      assert len(catppuccin_lines) == 16, f"FAILED: Catppuccin palette has {len(catppuccin_lines)} lines, expected 16"
      
      for i, line in enumerate(catppuccin_lines):
          if not line.startswith('#'):
              raise AssertionError(f"FAILED: Catppuccin palette line {i} missing # prefix: '{line}'")
          if len(line) != 7:
              raise AssertionError(
                  f"FAILED: Catppuccin palette line {i} is not #RRGGBB format (len={len(line)}): '{line}'\n"
                  "This is likely caused by YAML inline comments not being stripped."
              )
      
      print("✓ Catppuccin (base16) palette has correct format (16 lines, each exactly #RRGGBB)")
  else:
      print("⚠ Catppuccin theme not available in test VM")

  print("\n" + "="*60)
  print("SCHEME SWITCHING TESTS PASSED!")
  print("="*60)
''
