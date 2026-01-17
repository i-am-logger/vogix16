# Vogix Scripts

Development, theme management, and demo scripts for Vogix.

## Demo

### `demo.sh`

Automated demo script with typing effects for recording with OBS or screen capture.

```bash
# Run in test VM or on your system
./scripts/demo.sh
```

**What it does:**
- Simulates typing commands with configurable speed
- Shows theme switching between aikido, sepia, and ocean_depths
- Demonstrates both dark and light variants
- Displays fastfetch color palette for each theme
- Includes explanatory comments and architecture diagram
- Fully automated - runs from start to finish

**Used by:** `vogix-demo` command in test VM

**Recording:** Start OBS, run this script, capture the terminal window

## Theme Development

### `extract-themes.py`

Extracts theme colors from SVG files and generates Nix theme files.

```bash
# Extract all themes from assets/*.svg to themes/*.nix
python3 scripts/extract-themes.py

# Test extraction on a single theme
python3 scripts/extract-themes.py test
```

**What it does:**
- Parses SVG files from `assets/vogix16_*.svg`
- Extracts base00-base0F colors for both dark and light variants
- Generates `.nix` theme files in `themes/`
- Preserves existing base0F values if not present in SVG
- Uses x-coordinate to distinguish dark (left) vs light (right) variants

### `validate-themes.py`

Validates that all theme files have complete structure.

```bash
# Check all themes have base00-base0F in both dark and light variants
python3 scripts/validate-themes.py
```

**What it does:**
- Checks each theme has all 16 base colors (base00-base0F)
- Verifies both dark and light variants are present
- Reports any missing colors
- Exit code 0 if all valid, 1 if any issues

### `verify-theme-colors.py`

Verifies extracted theme colors match their SVG sources.

```bash
# Compare theme .nix files against SVG sources
python3 scripts/verify-theme-colors.py
```

**What it does:**
- Extracts colors from both SVG and Nix files
- Compares them to ensure extraction was correct
- Reports mismatches
- Useful after modifying extraction script

### `preview-themes.sh`

Quick preview of theme colors in terminal.

```bash
# Display sample colors from all themes
./scripts/preview-themes.sh
```

**What it does:**
- Shows base00 (background), base05 (foreground), base08 (error) for each theme
- Quick way to verify themes have unique colors
- Useful for spotting extraction issues

## Workflow

When adding new themes or modifying existing ones:

1. **Add/update SVG** in `assets/vogix16_<name>.svg`
2. **Extract**: `python3 scripts/extract-themes.py`
3. **Validate**: `python3 scripts/validate-themes.py`
4. **Verify**: `python3 scripts/verify-theme-colors.py`
5. **Preview**: `./scripts/preview-themes.sh`
6. **Test in VM**: `nix run .#vogix-vm`

## Requirements

All scripts require Python 3 with standard library only (no external dependencies).

For NixOS users:
```bash
nix-shell -p python3 --run "python3 scripts/extract-themes.py"
```

## Notes

- **SVG Structure**: Scripts expect SVGs with dark variant on left (x < 300) and light on right (x >= 300)
- **base0F**: Often not in SVGs, scripts preserve existing values
- **Nix Format**: Generated files use consistent formatting for readability
- **Demo Script**: Configure typing speed and pauses at the top of `demo.sh`
