# Theme switching tests - Theme and variant switching with config verification
#
# Tests: Switch variants, switch themes, verify symlink changes, verify config updates
#
{ pkgs
, home-manager
, self
,
}:

let
  testLib = import ./lib.nix { inherit pkgs home-manager self; };
in
testLib.mkTest "theme-switching" ''
  # Get manifest for app discovery
  manifest_content = machine.succeed(f"su - vogix -c 'cat {vogix_runtime}/config.toml'")
  app_sections = re.findall(r'\[apps\.([^\]]+)\]', manifest_content)
  app_sections = [app.strip('"') for app in app_sections]

  aikido_dark_colors = aikido_colors['dark']

  print("=== Test: SWITCH VARIANT Dark→Light ===")

  # Get current symlink target BEFORE switch
  current_before = machine.succeed(f"su - vogix -c 'readlink {vogix_runtime}/themes/current-theme'")
  print(f"Before switch - 'current' symlink: {current_before.strip()}")
  assert "dark" in current_before.lower(), "Expected to start with dark variant"

  # Store config contents for ALL apps before switch
  app_configs_before = {}
  for app_name in app_sections:
      app_section_match = re.search(rf'\[apps\."{app_name}"\].*?config_path = "([^"]+)"', manifest_content, re.DOTALL)
      if not app_section_match:
          app_section_match = re.search(rf'\[apps\.{app_name}\].*?config_path = "([^"]+)"', manifest_content, re.DOTALL)

      if not app_section_match:
          continue

      config_path = app_section_match.group(1)
      config_content = machine.succeed(f"su - vogix -c 'cat {config_path} 2>/dev/null || echo NOTFOUND'")

      if "NOTFOUND" not in config_content:
          app_configs_before[app_name] = config_content

  print(f"Captured config for {len(app_configs_before)} apps before switch")

  # Capture mtime BEFORE switch (for apps with touch reload method)
  app_mtimes_before = {}
  for app_name in app_configs_before.keys():
      app_section_match = re.search(rf'\[apps\."{app_name}"\](.*?)(?=\[|$)', manifest_content, re.DOTALL)
      if not app_section_match:
          app_section_match = re.search(rf'\[apps\.{app_name}\](.*?)(?=\[|$)', manifest_content, re.DOTALL)

      if app_section_match:
          app_section = app_section_match.group(1)
          reload_method_match = re.search(r'reload_method = "([^"]+)"', app_section)
          if reload_method_match and reload_method_match.group(1) == "touch":
              config_path_match = re.search(r'config_path = "([^"]+)"', app_section)
              if config_path_match:
                  config_path = config_path_match.group(1)
                  mtime_cmd = f"su - vogix -c 'stat -c %Y {shlex.quote(config_path)} 2>/dev/null || echo 0'"
                  mtime_result = machine.succeed(mtime_cmd).strip()
                  app_mtimes_before[app_name] = (int(mtime_result), config_path)
                  print(f"  Captured mtime for {app_name}: {mtime_result}")

  # SWITCH TO LIGHT VARIANT
  switch_output = machine.succeed("su - vogix -c 'vogix -v light 2>&1'")
  print(f"Switch command output:\n{switch_output}")

  new_state = machine.succeed("su - vogix -c 'vogix status'")
  assert "light" in new_state.lower()
  print("✓ Status command reports 'light' variant")

  assert "Reloaded" in switch_output, "FAILED: Reload dispatcher didn't run!"
  print("✓ Reload dispatcher ran during switch")

  # CRITICAL: Check that 'current' symlink actually changed
  current_after = machine.succeed(f"su - vogix -c 'readlink {vogix_runtime}/themes/current-theme'")
  print(f"After switch - 'current' symlink: {current_after.strip()}")

  assert current_before != current_after, "'current' symlink didn't change!"
  assert "light" in current_after.lower(), "'current' symlink doesn't point to light variant!"
  print("✓ 'current' symlink changed from dark to light")

  # Verify mtime was updated for apps with touch reload method
  if len(app_mtimes_before) > 0:
      print(f"\n  Verifying mtime updates for {len(app_mtimes_before)} apps with 'touch' reload method:")
      for app_name, (mtime_before, check_path) in app_mtimes_before.items():
          mtime_cmd = f"su - vogix -c 'stat -c %Y {shlex.quote(check_path)} 2>/dev/null || echo 0'"
          mtime_after = int(machine.succeed(mtime_cmd).strip())
          print(f"    {app_name}: mtime before={mtime_before}, after={mtime_after}")

          if mtime_after <= mtime_before:
              raise AssertionError(
                  f"FAILED: {app_name} mtime was NOT updated by touch! "
                  f"Path: {check_path}, Before: {mtime_before}, After: {mtime_after}."
              )
          print(f"    ✓ {app_name}: mtime updated")
      print("✓ All mtimes updated successfully")

  # Verify ALL app configs changed and have correct light colors
  light_bg = aikido_colors['light']['base00'].lower()
  for app_name in app_configs_before.keys():
      app_section_match = re.search(rf'\[apps\."{app_name}"\].*?config_path = "([^"]+)"', manifest_content, re.DOTALL)
      if not app_section_match:
          app_section_match = re.search(rf'\[apps\.{app_name}\].*?config_path = "([^"]+)"', manifest_content, re.DOTALL)

      if not app_section_match:
          continue

      config_path = app_section_match.group(1)
      config_after = machine.succeed(f"su - vogix -c 'cat {config_path} 2>/dev/null || echo NOTFOUND'")

      assert "NOTFOUND" not in config_after, f"{app_name} config not found after switch!"

      # Check if app has theme_file_path (hybrid app)
      app_section_match = re.search(rf'\[apps\."{app_name}"\](.*?)(?=\[|$)', manifest_content, re.DOTALL)
      if not app_section_match:
          app_section_match = re.search(rf'\[apps\.{app_name}\](.*?)(?=\[|$)', manifest_content, re.DOTALL)

      theme_file_match = None
      if app_section_match:
          app_section_content = app_section_match.group(1)
          theme_file_match = re.search(r'theme_file_path = "([^"]+)"', app_section_content)

      has_theme_file = theme_file_match is not None

      if not has_theme_file:
          assert app_configs_before[app_name] != config_after, f"{app_name} config didn't change after switch!"
          if "#" in config_after:
              assert light_bg in config_after.lower(), f"{app_name}: Expected light color {light_bg} after switch"
          print(f"  ✓ {app_name}: config changed and has correct light colors")

  print(f"\n✓ ALL {len(app_configs_before)} app configs verified - colors switched from dark to light!")

  # Switch back to dark
  machine.succeed("su - vogix -c 'vogix -v dark'")
  current_back = machine.succeed(f"su - vogix -c 'readlink {vogix_runtime}/themes/current-theme'")
  assert "dark" in current_back.lower(), "Failed to switch back to dark!"
  print("✓ Switched back to dark variant")

  print("\n=== Test: Switch Theme and Verify Symlink Changes ===")
  theme_names = [name for name in all_themes.keys() if name != 'aikido']

  if len(theme_names) == 0:
      print("⚠ Only aikido theme available, skipping theme switch test")
  else:
      themes_to_test = theme_names[:3]  # Test first 3

      for theme_name in themes_to_test:
          print(f"\n--- Testing theme: {theme_name} ---")

          dark_variant = f"{theme_name}-dark"
          light_variant = f"{theme_name}-light"
          machine.succeed(f"su - vogix -c 'test -d {vogix_runtime}/themes/{dark_variant}'")
          machine.succeed(f"su - vogix -c 'test -d {vogix_runtime}/themes/{light_variant}'")
          print(f"✓ {theme_name} theme-variant directories exist (dark & light)")

          current_before = machine.succeed(f"su - vogix -c 'readlink {vogix_runtime}/themes/current-theme'")
          alacritty_before = machine.succeed("su - vogix -c 'cat ~/.config/alacritty/alacritty.toml 2>/dev/null || echo NOTFOUND'")

          machine.succeed(f"su - vogix -c 'vogix -t {theme_name}'")
          new_state = machine.succeed("su - vogix -c 'vogix status'")
          assert theme_name in new_state, f"Status doesn't show {theme_name} theme!"
          print(f"✓ Status command reports '{theme_name}' theme")

          current_after = machine.succeed(f"su - vogix -c 'readlink {vogix_runtime}/themes/current-theme'")

          assert current_before != current_after, f"'current' symlink didn't change when switching to {theme_name}!"
          assert theme_name in current_after.lower(), f"'current' symlink doesn't point to {theme_name} theme!"
          print(f"✓ 'current' symlink changed to {theme_name}")

          alacritty_after = machine.succeed("su - vogix -c 'cat ~/.config/alacritty/alacritty.toml 2>/dev/null || echo NOTFOUND'")
          if alacritty_before != "NOTFOUND" and alacritty_after != "NOTFOUND":
              assert alacritty_before != alacritty_after, f"App config didn't change after switching to {theme_name}!"
              print("✓ App config updated (colors changed)")

          machine.succeed("su - vogix -c 'vogix -t aikido'")
          current_back = machine.succeed(f"su - vogix -c 'readlink {vogix_runtime}/themes/current-theme'")
          assert "aikido" in current_back.lower(), "Failed to switch back to aikido!"
          print(f"✓ Successfully switched back to aikido from {theme_name}")

      print(f"\n✓ All {len(themes_to_test)} tested themes switch correctly!")

  print("\n" + "="*60)
  print("THEME SWITCHING TESTS PASSED!")
  print("="*60)
''
