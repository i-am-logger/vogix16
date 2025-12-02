# Vogix16 Testing VM

This directory contains a NixOS VM configuration for testing vogix16 functionality in an isolated environment.

## Building the VM

```bash
# Build the VM
nix build .#nixosConfigurations.vogix16-test-vm.config.system.build.vm

# Or use the shorthand
nix run .#nixosConfigurations.vogix16-test-vm.config.system.build.vm
```

## Running the VM

```bash
# Run the built VM
./result/bin/run-vogix16-test-vm-vm

# The VM will auto-login as user 'vogix' with password 'vogix'
```

## VM Configuration

- **User**: vogix / vogix
- **Hostname**: vogix16-test
- **Memory**: 2GB
- **Cores**: 2
- **Display**: Terminal only (no GUI)

## Installed Applications

- `alacritty` - Terminal emulator (themed)
- `btop` - System monitor (themed)
- `tmux` - Terminal multiplexer
- `vim` - Text editor
- `git` - Version control

## Testing Vogix16

Once logged in, you can test vogix16 features:

### 1. Check Status
```bash
vogix16 status
```

### 2. List Available Themes
```bash
vogix16 list
# Should show: aikido, forest
```

### 3. Switch Themes
```bash
# Switch to forest theme
vogix16 theme forest

# Check alacritty config was updated
cat ~/.config/alacritty/colors.yml

# Switch back
vogix16 theme aikido
```

### 4. Switch Variants
```bash
# Switch to light variant
vogix16 switch light

# Switch back to dark
vogix16 switch dark
```

### 5. Test Daemon
```bash
# Check daemon status
systemctl --user status vogix16-daemon

# View daemon logs
journalctl --user -u vogix16-daemon -f
```

### 6. Test Auto-Regeneration
```bash
# Edit base config (simulating home-manager change)
# The daemon should detect and regenerate themes

# Watch daemon logs in one terminal
journalctl --user -u vogix16-daemon -f

# In another terminal, touch a config file
touch ~/.config/vogix16/base-configs/alacritty/.keep
```

### 7. Generate Shell Completions
```bash
# Generate bash completions
vogix16 completions bash > ~/.local/share/bash-completion/completions/vogix16

# Source it
source ~/.local/share/bash-completion/completions/vogix16

# Test tab completion
vogix16 <TAB>
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
nix build .#nixosConfigurations.vogix16-test-vm.config.system.build.vm
```
