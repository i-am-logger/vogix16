# Contributing to Vogix

Thank you for your interest in contributing to Vogix! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Commit Convention](#commit-convention)
- [Submitting Themes](#submitting-themes)
- [Adding Application Support](#adding-application-support)
- [Code Style](#code-style)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

Be respectful and constructive in all interactions. We're here to build something useful together.

## Getting Started

For detailed development setup instructions, see [DEVELOPMENT.md](DEVELOPMENT.md).

### Quick Setup

```bash
# Clone the repository
git clone https://github.com/i-am-logger/vogix
cd vogix

# Enter development shell
nix develop

# Build and test
cargo build --release
cargo test
./test.sh
```

## Development Workflow

### 1. Create a Branch

```bash
git checkout -b feat/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

### 2. Make Your Changes

- Write code following our style guidelines
- Add tests for new functionality
- Update documentation as needed
- Ensure all tests pass

### 3. Test Your Changes

```bash
# Run Rust tests
cargo test

# Run integration tests
./test.sh

# Or use Nix
nix flake check

# Format code
cargo fmt

# Check for issues
cargo clippy
```

## Commit Convention

We use [Conventional Commits](https://www.conventionalcommits.org/) for automated changelog generation and version bumping.

### Commit Message Format

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `ci`: CI/CD changes

### Examples

```bash
feat(themes): add nord theme with dark and light variants

fix(cli): correct symlink path resolution on variant switch

docs(architecture): update to reflect Nix-based generation

test(integration): add test for per-app theme overrides
```

### Breaking Changes

For breaking changes, add `BREAKING CHANGE:` in the footer:

```
feat(cli): change switch command to auto-toggle

BREAKING CHANGE: `vogix switch dark/light` is now `vogix switch` with auto-detection
```

## Submitting Themes

Vogix welcomes new theme submissions for the native **vogix16** scheme. For base16/base24/ansi16 themes, contribute to their respective upstream repositories.

### Theme Requirements

1. **Follow the vogix16 Design System**: See [docs/vogix16-design-system.md](docs/vogix16-design-system.md)
2. **Use Multi-Variant Format**: Define variants with polarity
3. **Use Semantic Colors**: Assign functional colors by purpose, not aesthetics
4. **Test Thoroughly**: Verify colors work across all supported applications

### Theme Submission Process

1. **Create Theme File**

```nix
# themes/vogix16/your-theme-name.nix
{
  name = "your-theme-name";
  variants = {
    dark = {
      polarity = "dark";
      colors = {
        # Base colors (monochromatic scale - darkest to lightest)
        base00 = "#......";  # Background
        base01 = "#......";  # Surface
        base02 = "#......";  # Selection
        base03 = "#......";  # Comments
        base04 = "#......";  # Borders
        base05 = "#......";  # Text
        base06 = "#......";  # Headings
        base07 = "#......";  # Bright

        # Functional colors (semantic purpose)
        base08 = "#......";  # Danger
        base09 = "#......";  # Warning
        base0A = "#......";  # Notice
        base0B = "#......";  # Success
        base0C = "#......";  # Active
        base0D = "#......";  # Link
        base0E = "#......";  # Highlight
        base0F = "#......";  # Special
      };
    };
    light = {
      polarity = "light";
      colors = {
        # Light variant (reverse base colors, adjust functional colors)
        base00 = "#......";  # Background (lightest)
        # ... (all 16 colors)
      };
    };
  };
  defaults = {
    dark = "dark";
    light = "light";
  };
}
```

2. **Update Theme Catalog**

Add your theme to `themes/README.md` in the appropriate category:
- Natural (nature-inspired, organic palettes)
- Hacker (tech, cyberpunk, terminal aesthetics)
- Modern (contemporary, clean, minimalist)
- Vintage (retro, nostalgic, classic)

3. **Test Your Theme**

```bash
# Build with your theme
nix flake check

# Test in VM
nix run .#vogix-vm

# Inside VM, switch to your theme
vogix -s vogix16 -t your-theme-name -v dark
```

4. **Submit Pull Request**

Use conventional commit format:
```
feat(themes): add [Your Theme Name] with dark and light variants

- Describe the theme's inspiration or purpose
- Note any unique color choices or characteristics
- Include screenshots if possible
```

### Theme Guidelines

- **Monochromatic Base**: base00-base07 should form a cohesive progression
  - Can be any color family (grayscale, sepia, green, blue, etc.)
  - Must progress from darkest to lightest (dark variant) or lightest to darkest (light variant)

- **Functional Colors**: base08-base0F should maintain semantic meaning
  - base08 (Danger): Errors, destructive actions
  - base09 (Warning): Cautions, important notifications
  - base0A (Notice): Status, announcements
  - base0B (Success): Completed, positive indicators
  - base0C (Active): Current selection, focused elements
  - base0D (Link): Interactive elements, informational content
  - base0E (Highlight): Focus indicators, emphasized content
  - base0F (Special): System messages, specialized elements

- **Contrast**: Ensure sufficient contrast for accessibility
- **Consistency**: Both variants should feel cohesive

## Adding Application Support

To add support for a new application, implement generators for all 4 color schemes. See [docs/vogix16-design-system.md](docs/vogix16-design-system.md) for detailed guidelines on when to use functional colors vs. monochromatic colors.

### Key Principle

Each scheme has its own philosophy:
- **vogix16**: Semantic colors for functional indicators only
- **base16/base24**: Standard syntax highlighting mappings  
- **ansi16**: Traditional ANSI terminal colors

See [nix/modules/applications/README.md](nix/modules/applications/README.md) for implementation examples.

### 1. Create Generator Function

```nix
# nix/modules/applications/myapp.nix
{ lib, appLib }:
{
  configFile = "myapp/config.conf";
  reloadMethod = { method = "touch"; };
  
  schemes = {
    vogix16 = colors: ''
      # Use semantic names for vogix16
      background = ${colors.background}
      foreground = ${colors.foreground-text}
      error-color = ${colors.danger}
    '';
    
    base16 = colors: ''
      # Use base16 names
      background = ${colors.base00}
      foreground = ${colors.base05}
      red = ${colors.base08}
    '';
    
    base24 = colors: ''
      # Use base24 names (includes base12-base17)
      background = ${colors.base00}
      foreground = ${colors.base05}
      bright-red = ${colors.base12}
    '';
    
    ansi16 = colors: ''
      # Use ANSI names
      background = ${colors.background}
      foreground = ${colors.foreground}
      red = ${colors.red}
    '';
  };
}
```

### 2. Define Reload Method

Reload configuration is now part of the generator file:

```nix
{
  configFile = "myapp/config.conf";
  reloadMethod = {
    method = "signal";        # or "touch", "command", "none"
    signal = "SIGUSR1";       # if method = "signal"
    process_name = "myapp";   # if method = "signal"
  };
  schemes = { /* ... */ };
}
```

### 3. Test Integration

```bash
# Add to test configuration
programs.myapp.enable = true;
programs.vogix.enable = true;

# Rebuild and test
home-manager switch
vogix status
vogix -t aikido -v dark  # Test theme switching
```

### 4. Document

- Add application to README.md
- Include example configuration in docs/theming.md

## Code Style

### Rust Code

- **Format**: Use `cargo fmt` (rustfmt)
- **Linting**: Pass `cargo clippy` with no warnings
- **Edition**: Rust Edition 2024
- **Naming**:
  - Functions: `snake_case`
  - Types: `PascalCase`
  - Constants: `SCREAMING_SNAKE_CASE`

### Nix Code

- **Indentation**: 2 spaces
- **Naming**: `camelCase` for variables and functions
- **Comments**: Document complex logic
- **Purity**: Avoid impure operations where possible

### Documentation

- **Markdown**: Follow CommonMark spec
- **Headers**: Use ATX-style (`#` not underlining)
- **Code Blocks**: Always specify language
- **Links**: Use reference-style for readability

## Testing

### Test Requirements

All contributions must:

1. **Pass existing tests**: `./test.sh` or `nix flake check`
2. **Add new tests**: For new features
3. **Maintain coverage**: Don't reduce test coverage

### Running Tests

```bash
# Quick Rust tests
cargo test

# Full integration test suite
./test.sh

# Nix flake checks (includes all tests)
nix flake check

# VM testing
nix run .#vogix-vm
```

### Writing Tests

- Add Rust unit tests in the same file as the code
- Add integration tests to `nix/vm/test.nix`
- Document test scenarios in TESTING.md

## Pull Request Process

### Before Submitting

- [ ] All tests pass (`cargo test`, `./test.sh`)
- [ ] Code is formatted (`cargo fmt`)
- [ ] No clippy warnings (`cargo clippy`)
- [ ] Documentation is updated
- [ ] Commit messages follow conventional format
- [ ] CHANGELOG.md is NOT manually edited (automated by release-please)

### Submission Steps

1. **Push your branch**
   ```bash
   git push origin feat/your-feature-name
   ```

2. **Create Pull Request** on GitHub
   - Use a clear, descriptive title
   - Follow conventional commit format in title
   - Describe changes in detail
   - Link related issues
   - Add screenshots for UI changes

3. **Respond to Review**
   - Address feedback promptly
   - Make requested changes
   - Keep discussion focused and constructive

4. **Merge**
   - Maintainer will merge when approved
   - Delete branch after merge

### PR Title Format

```
<type>(<scope>): <description>
```

Examples:
```
feat(themes): add nord theme
fix(cli): resolve symlink race condition
docs(architecture): clarify Nix generation process
```

## Questions?

- **Documentation**: Check [docs/](docs/) directory
- **Issues**: Search existing issues or create a new one
- **Discussion**: Open a GitHub Discussion for general questions

## License

By contributing, you agree that your contributions will be licensed under the CC BY-NC-SA 4.0 license.

---

Thank you for contributing to Vogix!
