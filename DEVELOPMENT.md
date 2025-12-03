# Development Guide

This guide covers setting up a development environment and contributing to Vogix16.

## Prerequisites

- Nix with flakes enabled
- Rust Edition 2024 (provided by Nix)
- devenv (optional, for enhanced development environment)

## Quick Start

### Clone the Repository

```bash
git clone https://github.com/i-am-logger/vogix16
cd vogix16
```

### Enter Development Environment

```bash
# Using Nix flakes
nix develop

# Or using devenv (if installed)
devenv shell
```

This provides:
- Rust toolchain (rustc, cargo, rustfmt, clippy)
- Rust analyzer for IDE support
- Required system dependencies (pkg-config, dbus)

## Building

### Rust Binary

```bash
# Development build
cargo build

# Release build
cargo build --release

# Check without building
cargo check
```

### Nix Package

```bash
# Build the package
nix build

# Build for specific architecture
nix build .#packages.x86_64-linux.vogix16
nix build .#packages.aarch64-linux.vogix16
```

## Testing

### Unit Tests

```bash
# Run Rust unit tests
cargo test

# Run with output
cargo test -- --nocapture
```

### Integration Tests

```bash
# Quick integration test
./test.sh

# Full Nix flake check (includes all tests)
nix flake check

# Run VM-based integration tests
nix build .#checks.x86_64-linux.integration
```

### VM Testing

```bash
# Launch test VM
nix run .#vogix-vm

# Inside the VM, test commands:
vogix status
vogix list
vogix theme forest
vogix switch
```

See [TESTING.md](TESTING.md) for comprehensive testing documentation.

## Code Quality

### Formatting

```bash
# Check formatting
cargo fmt --check

# Auto-format code
cargo fmt
```

### Linting

```bash
# Run Clippy
cargo clippy

# Clippy with all warnings as errors
cargo clippy -- -D warnings
```

### Pre-commit Checks

Before committing, ensure:
```bash
cargo fmt --check && \
cargo clippy -- -D warnings && \
cargo test && \
nix flake check --no-build
```

## Project Structure

```
vogix16/
├── src/                    # Rust source code
│   ├── cli.rs              # Command-line interface (clap)
│   ├── config.rs           # Configuration management
│   ├── theme.rs            # Theme discovery and parsing
│   ├── generator.rs        # Theme validation
│   ├── reload.rs           # Application reload mechanisms
│   ├── symlink.rs          # Symlink management
│   ├── state.rs            # State persistence
│   ├── errors.rs           # Error handling
│   └── main.rs             # Entry point
│
├── themes/                 # Theme library (19 themes × 2 variants)
│   ├── aikido.nix
│   ├── forest.nix
│   └── ...
│
├── nix/
│   ├── modules/
│   │   ├── home-manager.nix        # Home Manager module
│   │   ├── nixos.nix               # NixOS module
│   │   └── applications/           # Application theme generators
│   │       ├── alacritty.nix
│   │       ├── btop.nix
│   │       └── console.nix
│   ├── packages/
│   │   └── vogix.nix               # Package definition
│   └── vm/
│       ├── test-vm.nix             # VM configuration
│       ├── test.nix                # Integration tests
│       └── home.nix                # Test user config
│
├── docs/                   # Documentation
│   ├── architecture.md     # System architecture
│   ├── cli.md              # CLI reference
│   ├── design-system.md    # Color system
│   ├── theming.md          # Theme format
│   └── reload.md           # Reload mechanisms
│
├── scripts/                # Development scripts
│   ├── preview-themes.sh   # Preview theme colors
│   ├── extract-themes.py   # Extract themes from SVG
│   └── validate-themes.py  # Validate theme completeness
│
├── .github/
│   ├── workflows/          # CI/CD pipelines
│   │   ├── ci.yml          # PR checks
│   │   ├── release-please.yml  # Automated releases
│   │   └── release.yml     # Binary releases
│   └── ISSUE_TEMPLATE/     # Issue templates
│
├── Cargo.toml              # Rust dependencies (version source of truth)
├── flake.nix               # Nix flake definition
├── test.sh                 # Quick integration test script
├── CONTRIBUTING.md         # Contribution guidelines
├── CHANGELOG.md            # Version history
└── README.md               # Project overview
```

## Common Development Tasks

### Adding a New Theme

1. Create theme file in `themes/`:
   ```nix
   # themes/mytheme.nix
   {
     dark = {
       base00 = "#...";  # All 16 colors
       # ...
     };
     light = {
       base00 = "#...";
       # ...
     };
   }
   ```

2. Test the theme:
   ```bash
   nix flake check
   vogix list  # Should show your theme
   ```

3. Add to theme catalog in `themes/README.md`

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed theme submission guidelines.

### Adding Application Support

1. Create generator in `nix/modules/applications/`:
   ```nix
   # nix/modules/applications/myapp.nix
   { lib }: colors: ''
   # Application config using semantic colors
   background = ${colors.background}
   foreground = ${colors.foreground-text}
   error = ${colors.danger}
   ''
   ```

2. Define config filename in `home-manager.nix`:
   ```nix
   getConfigFilename = app: {
     myapp = "config.conf";
   }.${app} or "config";
   ```

3. Define reload method:
   ```nix
   getAppReloadMethod = app: {
     myapp = {
       method = "signal";
       signal = "SIGUSR1";
       process_name = "myapp";
     };
   }.${app} or { method = "none"; };
   ```

4. Test integration:
   ```bash
   nix flake check
   ```

### Debugging

#### Enable Rust Backtrace
```bash
RUST_BACKTRACE=1 cargo run -- status
RUST_BACKTRACE=full cargo run -- theme forest
```

#### Check Generated Configs
```bash
# After home-manager switch
ls -la /run/user/$(id -u)/vogix16/themes/
cat /run/user/$(id -u)/vogix16/manifest.toml

# Check symlinks
ls -la ~/.config/alacritty/colors.toml
readlink ~/.config/alacritty/colors.toml
```

#### Nix Debugging
```bash
# Show flake outputs
nix flake show

# Evaluate specific attribute
nix eval .#packages.x86_64-linux.vogix16.version

# Build with verbose output
nix build --print-build-logs

# Show trace on errors
nix flake check --show-trace
```

## Known Issues

### Nix Eval Cache During Development

**Problem**: When modifying application modules (e.g., `nix/modules/applications/btop.nix`), Nix's evaluation cache may return stale results even though files are git-tracked and the flake detects a dirty tree.

**Symptoms**:
- You modify an application module file
- Run `git add` to track the change
- Build the VM or run flake check
- Generated configs still have OLD content

**Root Cause**: This is a known limitation of Nix flakes evaluation cache for local repositories under active development. The eval cache has race conditions/bugs with dirty git trees. See: [NixOS/nix#12102](https://github.com/NixOS/nix/pull/12102)

**Workarounds**:

1. **Use development helpers** (recommended):
   ```bash
   # VM launcher (automatically disables eval cache)
   nix run .#vogix-vm

   # Check flake without eval cache
   nix run .#dev-check

   # From inside devenv shell
   nix-build-dev         # Build VM without eval cache
   nix-check-dev         # Check flake without eval cache
   ```

2. **Manual flag** (for other nix commands):
   ```bash
   nix build --option eval-cache false
   nix flake check --option eval-cache false
   ```

3. **Force cache invalidation** (make trivial edit to `flake.nix`):
   ```bash
   # Add/remove a comment in flake.nix
   # This changes the flake fingerprint → cache invalidates
   ```

**Status**: Waiting for upstream Nix to implement automatic eval cache disabling for local repos. Track progress in issue [#101](https://github.com/i-am-logger/vogix16/issues/101).

## Architecture Overview

### Build Time (Nix)
1. Home-manager module discovers themes from `themes/*.nix`
2. Discovers application generators from `nix/modules/applications/`
3. For each (theme × variant × app) combination, generates configs
4. Stores generated configs in `/nix/store` (immutable)
5. Systemd service symlinks configs to `/run/user/UID/vogix16/themes/`

### Runtime (Rust CLI)
1. CLI updates `current-theme` symlink (only this!)
2. Triggers application reloads per manifest.toml
3. Persists state to `/run/user/UID/vogix16/state/`

**Key Principle**: Nix generates everything at build time. Rust CLI only manages symlinks.

## Version Management

**Single Source of Truth**: `Cargo.toml` (version field)

All components derive from here:
- CLI: Uses `env!("CARGO_PKG_VERSION")` at compile time
- Nix package: Reads Cargo.toml via `builtins.fromTOML`
- release-please: Updates Cargo.toml automatically

Users pin versions via Git tags:
```nix
inputs.vogix16.url = "github:i-am-logger/vogix16/v0.5.0";
```

## Conventional Commits

We use conventional commits for automated changelog and versioning:

```
feat(themes): add nord theme
fix(cli): resolve symlink race condition
docs(architecture): clarify Nix generation
chore(deps): update rust dependencies
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`

Breaking changes:
```
feat(cli): change switch command to auto-toggle

BREAKING CHANGE: vogix switch no longer takes arguments
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for complete guidelines.

## CI/CD Pipeline

### PR Checks (`.github/workflows/ci.yml`)
- Rust formatting check
- Clippy linting
- Unit tests
- Release build
- Nix flake check
- Integration tests
- Multi-arch package builds

### Release Process (`.github/workflows/release-please.yml`)
1. Conventional commits merged to master
2. release-please creates/updates release PR
3. Merge release PR → creates Git tag
4. Binary release workflow builds and publishes

### Binary Releases (`.github/workflows/release.yml`)
- Builds for x86_64-linux and aarch64-linux
- Uploads to GitHub Releases
- Uses GitHub Actions cache

## Resources

- [Rust Book](https://doc.rust-lang.org/book/)
- [Clap Documentation](https://docs.rs/clap/)
- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [NixOS Wiki](https://nixos.wiki/)
- [Conventional Commits](https://www.conventionalcommits.org/)

## Getting Help

- **Documentation**: Check [docs/](docs/) directory
- **Issues**: Search or create on GitHub
- **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md)

---

Happy hacking! 🚀
