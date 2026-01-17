# Vogix Testing VM

This directory contains a NixOS VM configuration for testing Vogix functionality in an isolated environment.

## Building the VM

```bash
# Build the VM
nix build .#nixosConfigurations.vogix-test-vm.config.system.build.vm

# Or use the shorthand
nix run .#nixosConfigurations.vogix-test-vm.config.system.build.vm
```

## Running the VM

```bash
# Run the built VM
./result/bin/run-vogix-test-vm-vm

# The VM will auto-login as user 'vogix' with password 'vogix'
```

## VM Configuration

- **User**: vogix / vogix
- **Hostname**: vogix-test
- **Memory**: 2GB
- **Cores**: 2
- **Display**: Terminal only (no GUI)

## Installed Applications

- `alacritty` - Terminal emulator (themed)
- `btop` - System monitor (themed)
- `tmux` - Terminal multiplexer
- `vim` - Text editor
- `git` - Version control

## Testing Vogix

Once logged in, you can test Vogix features:

### 1. Check Status
```bash
vogix status
```

### 2. List Available Themes
```bash
vogix list
# Should show: aikido, forest
```

### 3. Switch Themes
```bash
# Switch to forest theme
vogix -t forest -s vogix16

# Check alacritty config was updated
cat ~/.config/alacritty/colors.yml

# Switch back
vogix -t aikido -s vogix16
```

### 4. Switch Variants
```bash
# Switch to light variant
vogix -v light

# Switch back to dark
vogix -v dark
```

### 5. Test Daemon
```bash
# Check daemon status
systemctl --user status vogix-daemon

# View daemon logs
journalctl --user -u vogix-daemon -f
```

### 6. Test Auto-Regeneration
```bash
# Edit base config (simulating home-manager change)
# The daemon should detect and regenerate themes

# Watch daemon logs in one terminal
journalctl --user -u vogix-daemon -f

# In another terminal, touch a config file
touch ~/.config/vogix/base-configs/alacritty/.keep
```

### 7. Generate Shell Completions
```bash
# Generate bash completions
vogix completions bash > ~/.local/share/bash-completion/completions/vogix

# Source it
source ~/.local/share/bash-completion/completions/vogix

# Test tab completion
vogix <TAB>
```

## Cleanup

```bash
# Exit the VM
exit  # or Ctrl+D

# Remove the VM
rm -rf result
```

## Modifying the VM

Edit `test-vm.nix` or `home.nix` and rebuild:

```bash
nix build .#nixosConfigurations.vogix-test-vm.config.system.build.vm
```
