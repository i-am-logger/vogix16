# Application Configuration Modules

This directory contains Vogix16 theme configuration generators for various applications.

## Configuration Strategy

Vogix16's minimalist philosophy ("functional colors for minimalist minds") is enforced at **all levels**:

### Terminal Emulators: Minimal ANSI by Default

**Examples**: alacritty, console (Linux VT)

ANSI color slots are mapped minimally:
- **Monochromatic base** for most slots (blue, magenta, cyan → foreground colors)
- **Semantic colors only** for red/green/yellow (danger/success/warning)

This creates a minimal terminal by default. Applications that need more nuanced coloring should be configured individually.

### Application-Specific Configurations

**Examples**: btop, ls/eza, git, ripgrep, bat, vim, neovim, tmux, etc.

Each application gets its own Vogix16-aware configuration file with thoughtful color semantics:

- Use monochromatic base colors (base00-base07) for UI structure
- Reserve functional colors (base08-base0F) **only** for semantic meaning
- No decorative use of color

**Examples**:
- `btop`: All box borders use `foreground-border`, not different colors per type
- `ls`/`eza`: File types use monochromatic scale, only permissions/errors use functional colors
- `git`: Diffs use `danger`/`success` for removed/added lines
- `ripgrep`: Match highlights use `active` or `highlight`

## Key Principle

**Minimal by default, specific when needed**: The terminal provides a minimal ANSI palette. Applications that need more expressive coloring get their own Vogix16 configs where every color choice is intentional.

This ensures:
1. No "accidental" colors from unconfigured apps
2. Complete control over what colors appear and why
3. Consistent minimalist aesthetic across the system

## Adding New Application Modules

When adding a new application:

1. **Identify what colors it currently uses**: Check default color output
2. **Map semantically**: Only use functional colors for actual semantic meaning
3. **Stay monochromatic otherwise**: Use base colors for structure and organization
4. **Document choices**: Add comments explaining why each color was chosen

### Determining Semantic vs. Monochromatic

Ask: "Does this color convey information the user needs to know?"

**YES - Use functional colors:**
- Error states, warnings, success indicators
- Resource utilization levels (CPU at 90% vs 10%)
- Temperature/status gradients (cool → warm → hot)
- Active/selected/focused items
- Added/removed/modified content (git diffs, file changes)
- Important notifications or alerts

**NO - Use monochromatic:**
- UI borders, dividers, structural elements
- File type differentiation (unless indicating errors)
- Syntax highlighting for aesthetics
- Category labels without status meaning
- Navigation elements
- Decorative accents

**Real Examples:**

✓ btop CPU gradient: low (comment) → moderate (warning) → high (danger)
  - Semantic: User needs to know resource utilization levels

✓ git diff: added (success) / removed (danger) / modified (warning)
  - Semantic: Indicates type of change

✗ btop box borders: all use foreground-border
  - Not semantic: Just organizational structure

✗ File listing colors by type: use monochromatic
  - Not semantic: Type differentiation is informational, not status
