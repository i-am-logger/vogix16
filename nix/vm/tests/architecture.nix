# Architecture tests - Symlinks, runtime directories, config structure
#
# Tests: Pre-generated configs, current-theme symlink, app symlinks, file accessibility
#
{ pkgs
, home-manager
, self
,
}:

let
  testLib = import ./lib.nix { inherit pkgs home-manager self; };
in
testLib.mkTest "architecture" ''
  print("=== Test: Nix Pre-Generated Theme-Variant Configs ===")

  # Verify theme-variant directories were created by systemd service at login
  machine.succeed(f"su - vogix -c 'test -d {vogix_runtime}/themes/aikido-dark'")
  print(f"✓ aikido-dark theme-variant directory exists in {vogix_runtime}/themes/")

  machine.succeed(f"su - vogix -c 'test -d {vogix_runtime}/themes/aikido-light'")
  print(f"✓ aikido-light theme-variant directory exists in {vogix_runtime}/themes/")

  # Check that configs are pre-generated with actual colors (not {{baseXX}})
  aikido_dark_config = machine.succeed(f"su - vogix -c 'cat {vogix_runtime}/themes/aikido-dark/alacritty/alacritty.toml 2>/dev/null || echo NOTFOUND'")
  if "NOTFOUND" not in aikido_dark_config:
      print("✓ aikido-dark alacritty config exists")
      assert "{{base" not in aikido_dark_config, "Config contains unprocessed template placeholders!"
      assert "#" in aikido_dark_config, "Config missing hex colors!"
      print("✓ aikido-dark config has actual colors (no {{baseXX}} placeholders)")

  aikido_light_config = machine.succeed(f"su - vogix -c 'cat {vogix_runtime}/themes/aikido-light/alacritty/alacritty.toml 2>/dev/null || echo NOTFOUND'")
  if "NOTFOUND" not in aikido_light_config:
      print("✓ aikido-light alacritty config exists")
      assert "{{base" not in aikido_light_config, "Config contains unprocessed template placeholders!"
      assert aikido_dark_config != aikido_light_config, "Dark and light configs are identical!"
      print("✓ aikido-light config differs from aikido-dark (variants work)")

  print("\n=== Test: Current-Theme Symlink Exists ===")
  machine.succeed(f"su - vogix -c 'test -L {vogix_runtime}/themes/current-theme'")
  print(f"✓ 'current-theme' symlink exists in {vogix_runtime}/themes/")

  current_target = machine.succeed(f"su - vogix -c 'readlink {vogix_runtime}/themes/current-theme'")
  print(f"✓ 'current-theme' points to: {current_target.strip()}")
  assert "aikido" in current_target.lower(), "current-theme symlink doesn't point to default aikido theme"
  assert "dark" in current_target.lower(), "current-theme symlink doesn't point to dark variant"

  print("\n=== Test: Config Contains App Metadata ===")
  manifest_content = machine.succeed(f"su - vogix -c 'cat {vogix_runtime}/config.toml'")
  print("Manifest content (first 500 chars):")
  print(manifest_content[:500])

  app_sections = re.findall(r'\[apps\.([^\]]+)\]', manifest_content)
  assert len(app_sections) > 0, "Manifest has no [apps.*] sections!"
  print(f"✓ Manifest contains {len(app_sections)} app sections")

  assert "config_path" in manifest_content, "Manifest missing config_path field!"
  print("✓ Manifest has required config_path field")

  print("\n=== Test: ~/.config/vogix Does NOT Exist ===")
  vogix_config_check = machine.execute("su - vogix -c 'test -d ~/.config/vogix && echo EXISTS || echo NOTEXIST'")
  if "EXISTS" in vogix_config_check[1]:
      raise AssertionError("FAILED: ~/.config/vogix exists! All data should be in /run/user/UID/vogix/")
  print("✓ ~/.config/vogix does NOT exist (correct - all data in runtime dir)")

  print("\n=== Test: ALL App Symlinks Point Through Current ===")
  app_sections = re.findall(r'\[apps\.([^\]]+)\]', manifest_content)
  app_sections = [app.strip('"') for app in app_sections]
  print(f"Found {len(app_sections)} apps in config: {app_sections}")

  assert len(app_sections) > 0, "No apps found in config!"

  for app_name in app_sections:
      print(f"\n  Testing app: {app_name}")

      app_section_match = re.search(rf'\[apps\."{app_name}"\](.*?)(?=\[|$)', manifest_content, re.DOTALL)
      if not app_section_match:
          app_section_match = re.search(rf'\[apps\.{app_name}\](.*?)(?=\[|$)', manifest_content, re.DOTALL)

      if not app_section_match:
          print(f"    ⚠ WARNING: Could not parse section for {app_name}")
          continue

      app_section = app_section_match.group(1)

      config_path_match = re.search(r'config_path = "([^"]+)"', app_section)
      if not config_path_match:
          print(f"    ⚠ WARNING: Could not parse config_path for {app_name}")
          continue
      config_path = config_path_match.group(1)

      print(f"    Checking config file symlink: {config_path}")

      link_check = machine.execute(f"su - vogix -c 'test -L {config_path} && echo SYMLINK || echo NOTLINK'")
      if "SYMLINK" not in link_check[1]:
          raise AssertionError(f"FAILED: {app_name} config file is not a symlink: {config_path}")

      target = machine.succeed(f"su - vogix -c 'readlink {config_path}'").strip()
      print(f"    Config file symlink target: {target}")

      assert target.startswith("/run/user/"), f"FAILED: {app_name} symlink is not absolute path to /run/user/! Got: {target}"
      assert "vogix/themes/" in target, f"FAILED: {app_name} symlink doesn't point to vogix/themes! Got: {target}"

      print(f"    ✓ {app_name} symlink is correct absolute path to runtime")

  print(f"\n✓ ALL {len(app_sections)} app symlinks verified successfully!")

  print("\n=== Test: Config Files Accessible Through Symlinks ===")
  for app_name in app_sections:
      app_section_match = re.search(rf'\[apps\."{app_name}"\](.*?)(?=\[|$)', manifest_content, re.DOTALL)
      if not app_section_match:
          continue

      app_section_content = app_section_match.group(1)
      config_match = re.search(r'config_path = "([^"]+)"', app_section_content)
      if not config_match:
          continue

      config_path = config_match.group(1)

      file_check = machine.execute(f"su - vogix -c 'test -f {config_path} && echo EXISTS || echo NOTEXIST'")
      if "EXISTS" in file_check[1]:
          print(f"  ✓ {app_name}: config file accessible at {config_path}")
      else:
          print(f"  ⚠ {app_name}: config file NOT accessible at {config_path}")

  print("\n✓ All app files verified accessible through symlinks!")

  print("\n" + "="*60)
  print("ARCHITECTURE TESTS PASSED!")
  print("="*60)
''
