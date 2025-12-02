# Vogix16 Automated Testing

## Overview

Vogix16 includes comprehensive automated integration tests using the NixOS testing framework. The tests verify all features work correctly in an isolated VM environment.

## Running Tests

### Quick Test Run

```bash
# Run all integration tests
nix flake check

# Or explicitly run the integration test
nix build .#checks.x86_64-linux.integration
```

### What Gets Tested

The automated test suite verifies **16 comprehensive test scenarios**:

1. **Binary Installation** - Vogix16 binary is installed and accessible
2. **Status Command** - `vogix16 status` shows current theme and variant
3. **List Command** - `vogix16 list` displays available themes
4. **Config File** - Configuration file created with correct settings
5. **Theme Files** - Theme definitions installed correctly
6. **State Management** - State file created and persists changes
7. **Variant Switching with Config Updates** - `vogix16 switch light/dark` works and updates app configs with reversed colors
8. **Theme Switching with Config Updates** - `vogix16 theme <name>` switches themes and regenerates app configs with new colors
9. **Symlink Architecture** - Verifies ~/.config symlinks point to vogix16-managed themed configs
10. **Template Bundling** - Templates bundled in Nix package
11. **Systemd Service** - Daemon service defined and can start
12. **Shell Completions** - Completion generation works for all shells
13. **Application Config Generation** - Alacritty and btop configs generated with correct hex colors
14. **Theme Validation** - Theme files are valid Nix expressions
15. **Error Handling** - Invalid inputs rejected gracefully
16. **Version Check** - `--version` flag works

## Test Output

When tests pass, you'll see:

```
=== Test 1: Vogix16 Binary Exists ===
✓ vogix16 binary found

=== Test 2: Check Status Command ===
✓ Status command works
Output: Current theme: aikido
Current variant: dark

=== Test 7: Switch Variant and Verify Config Updates ===
✓ Successfully switched from dark to light
✓ Alacritty config updated after variant switch (colors reversed)
✓ Switched back to dark variant

=== Test 8: Switch Theme and Verify Config Updates ===
✓ Successfully switched to forest theme
✓ Alacritty config updated after theme switch

=== Test 13: Application Config Generation ===
✓ Alacritty config generated
✓ Alacritty config has color scheme
✓ Alacritty config contains hex colors
✓ Btop config generated
✓ Btop config contains hex colors

... (more tests) ...

============================================================
🎉 ALL TESTS PASSED!
============================================================

Test Summary:
✓ Binary installation
✓ CLI commands (status, list, switch, theme)
✓ Configuration management
✓ State persistence
✓ Variant switching with config updates
✓ Theme switching with config updates
✓ Symlink architecture verification
✓ Application config generation (alacritty, btop)
✓ Template bundling
✓ Systemd daemon service
✓ Shell completions
✓ Theme validation
✓ Error handling
✓ Version check
```

## Test Architecture

### NixOS Test Framework

The tests use `pkgs.nixosTest`, which:
- Spins up a lightweight QEMU VM
- Runs commands in the VM
- Asserts expected outcomes
- Tears down the VM automatically

### Test Configuration

**Test VM**: `nix/vm/test-vm.nix`
- Minimal NixOS system
- Terminal-only (no GUI)
- Pre-configured test user
- All vogix16 features enabled

**Test Script**: `nix/vm/test.nix`
- Python-based test script
- 15 test scenarios
- Machine lifecycle management
- Detailed logging

**Home Config**: `nix/vm/home.nix`
- User configuration for testing
- Themes installed
- Apps configured
- Daemon enabled

## Manual Testing

If you want to manually explore the test environment:

```bash
# Build the VM
nix build .#nixosConfigurations.vogix16-test-vm.config.system.build.vm

# Run it
./result/bin/run-vogix16-test-vm-vm

# Inside VM, run commands manually:
vogix16 status
vogix16 list
vogix16 theme forest
vogix16 switch light
```

## Continuous Integration

Add to your CI pipeline:

```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: cachix/install-nix-action@v22
        with:
          nix_path: nixpkgs=channel:nixos-unstable
      - run: nix flake check
```

## Test Development

### Adding New Tests

Edit `nix/vm/test.nix` and add test cases:

```python
print("\n=== Test N: Your Test Name ===")
output = machine.succeed("su - vogix -c 'your command'")
assert "expected output" in output
print("✓ Your test passed")
```

### Test Helpers

- `machine.succeed(cmd)` - Run command, expect exit code 0
- `machine.fail(cmd)` - Run command, expect non-zero exit
- `machine.wait_for_unit(unit)` - Wait for systemd unit
- `machine.wait_for_file(path)` - Wait for file to exist
- `time.sleep(seconds)` - Wait for async operations

### Debugging Failed Tests

```bash
# Run test with more verbose output
nix build .#checks.x86_64-linux.integration --print-build-logs

# Access the test VM interactively
nix build .#nixosConfigurations.vogix16-test-vm.config.system.build.vm
./result/bin/run-vogix16-test-vm-vm
```

## Performance

- **Test duration**: ~30-60 seconds
- **VM RAM**: 2GB
- **VM CPUs**: 2 cores
- **Storage**: Ephemeral (no persistence between runs)

## Coverage

The automated tests cover:

✅ All CLI commands
✅ Configuration management
✅ State persistence
✅ Theme and variant switching
✅ **Application config generation** (alacritty, btop)
✅ **Config updates on theme/variant changes**
✅ **Hex color validation in generated configs**
✅ Symlink architecture verification
✅ Template bundling
✅ Systemd integration
✅ Error cases
✅ Package installation

**Not covered** (requires real desktop environment):
- Actual live application reload (apps reading the configs)
- DBus reload signals in running applications
- Filesystem watching with running daemon
- Visual verification of colors in terminal

These require manual testing on a real system, but the core functionality - config generation and updates - is fully tested.

## Troubleshooting

### Test fails with "vogix16: command not found"

Check package installation in `test-vm.nix`:
```nix
services.vogix16.enable = true;
```

### Test fails with "theme not found"

Check themes are installed in `home.nix`:
```nix
programs.vogix16.themes = {
  aikido = ../../themes/aikido.nix;
};
```

### Test VM won't start

```bash
# Check VM build
nix build .#nixosConfigurations.vogix16-test-vm.config.system.build.toplevel

# Check for errors
nix flake check --print-build-logs
```

### Tests timeout

Increase timeout in `test.nix`:
```python
machine.wait_for_unit("multi-user.target", timeout=120)
```

## Next Steps

After tests pass:

1. ✅ **CI Integration** - Add to GitHub Actions
2. ✅ **Release Testing** - Test on real NixOS system
3. ✅ **Documentation** - Update user docs with test results
4. ✅ **Benchmarks** - Add performance benchmarks (optional)

## Resources

- [NixOS Testing](https://nixos.org/manual/nixos/stable/#sec-nixos-tests)
- [VM Testing Examples](https://github.com/NixOS/nixpkgs/tree/master/nixos/tests)
- [Vogix16 Docs](../docs/)
