#!/usr/bin/env python3
"""
Extract theme colors from SVG files and generate Nix theme files.
Properly handles dark/light variants side-by-side in SVG.
"""

import re
import sys
from pathlib import Path


def extract_colors_from_svg(svg_path):
    """
    Extract dark and light variant colors from an SVG file.

    SVG structure:
    - Left side (x < 500): Dark theme
    - Right side (x >= 500): Light theme
    """
    content = svg_path.read_text()
    theme_name = svg_path.stem.replace("vogix16_", "")

    # Parse SVG line by line looking for baseXX definitions
    lines = content.split("\n")

    dark_colors = {}
    light_colors = {}

    for i, line in enumerate(lines):
        # Look for text with baseXX = "#RRGGBB"
        # Pattern: base00 = "#262626"
        color_match = re.search(r'(base[0-9A-F]{2})\s*=\s*"(#[0-9a-fA-F]{6})"', line)

        if color_match:
            base_name = color_match.group(1)
            color_value = color_match.group(2).lower()

            # Check x coordinate in the SAME line - dark is left (x < 300), light is right (x >= 300)
            x_match = re.search(r'x="(\d+)"', line)
            if x_match:
                x_pos = int(x_match.group(1))

                if x_pos < 300:
                    # Dark theme (left side)
                    if base_name not in dark_colors:
                        dark_colors[base_name] = color_value
                else:
                    # Light theme (right side)
                    if base_name not in light_colors:
                        light_colors[base_name] = color_value
            else:
                # Fallback: use order - first occurrence = dark, second = light
                if base_name not in dark_colors:
                    dark_colors[base_name] = color_value
                elif base_name not in light_colors:
                    light_colors[base_name] = color_value

    # Validate we have at least base00-base07 for both variants
    required_bases = [f"base{i:02X}" for i in range(8)]

    dark_missing = [b for b in required_bases if b not in dark_colors]
    light_missing = [b for b in required_bases if b not in light_colors]

    if dark_missing:
        print(f"  ⚠️  Dark variant missing: {', '.join(dark_missing)}", file=sys.stderr)

    if light_missing:
        print(
            f"  ⚠️  Light variant missing: {', '.join(light_missing)}", file=sys.stderr
        )

    if len(dark_colors) < 8 or len(light_colors) < 8:
        print(
            f"  ❌ Insufficient colors: dark={len(dark_colors)}, light={len(light_colors)}",
            file=sys.stderr,
        )
        return None

    return {"name": theme_name, "dark": dark_colors, "light": light_colors}


def generate_nix_file(theme_data, output_path):
    """Generate a Nix theme file from extracted theme data."""
    name = theme_data["name"]
    dark = theme_data["dark"]
    light = theme_data["light"]

    # Check if theme file already exists and preserve base0F if not in SVG
    if output_path.exists() and "base0F" not in dark:
        existing_content = output_path.read_text()
        # Extract existing base0F values
        dark_0f_match = re.search(
            r'dark\s*=\s*\{[^}]*base0F\s*=\s*"(#[0-9a-fA-F]{6})"',
            existing_content,
            re.DOTALL,
        )
        light_0f_match = re.search(
            r'light\s*=\s*\{[^}]*base0F\s*=\s*"(#[0-9a-fA-F]{6})"',
            existing_content,
            re.DOTALL,
        )

        if dark_0f_match:
            dark["base0F"] = dark_0f_match.group(1).lower()
            print(f"  ℹ️  Preserved existing dark base0F: {dark['base0F']}")

        if light_0f_match:
            light["base0F"] = light_0f_match.group(1).lower()
            print(f"  ℹ️  Preserved existing light base0F: {light['base0F']}")

    # Ensure we have base00-base0F, use what we have
    all_bases = sorted(
        set(list(dark.keys()) + list(light.keys())), key=lambda x: int(x[4:], 16)
    )

    content = f"""{{
  name = "{name}";

  dark = {{
"""

    for key in all_bases:
        if key in dark:
            content += f'    {key} = "{dark[key]}";\n'

    content += """  };

  light = {
"""

    for key in all_bases:
        if key in light:
            content += f'    {key} = "{light[key]}";\n'

    content += """  };
}
"""

    output_path.write_text(content)
    return True


def test_extraction(svg_path, expected_dark=None, expected_light=None):
    """Test extraction on a single file with optional validation."""
    print(f"\n{'='*80}")
    print(f"Testing: {svg_path.name}")
    print(f"{'='*80}")

    theme_data = extract_colors_from_svg(svg_path)

    if not theme_data:
        print("❌ Extraction failed!")
        return False

    print(f"\n✅ Extracted {theme_data['name']}")
    print(f"\nDark variant ({len(theme_data['dark'])} colors):")
    for key in sorted(theme_data["dark"].keys(), key=lambda x: int(x[4:], 16)):
        print(f"  {key} = {theme_data['dark'][key]}")

    print(f"\nLight variant ({len(theme_data['light'])} colors):")
    for key in sorted(theme_data["light"].keys(), key=lambda x: int(x[4:], 16)):
        print(f"  {key} = {theme_data['light'][key]}")

    # Validate if expected values provided
    if expected_dark:
        for key, expected_val in expected_dark.items():
            actual_val = theme_data["dark"].get(key, "MISSING")
            if actual_val.lower() != expected_val.lower():
                print(f"  ❌ Dark {key}: expected {expected_val}, got {actual_val}")
                return False

    if expected_light:
        for key, expected_val in expected_light.items():
            actual_val = theme_data["light"].get(key, "MISSING")
            if actual_val.lower() != expected_val.lower():
                print(f"  ❌ Light {key}: expected {expected_val}, got {actual_val}")
                return False

    print("\n✅ All validations passed!")
    return True


def main():
    """Main function to process all SVG files."""
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        # Test mode - validate aikido extraction
        # Project root is one level up from scripts/
        repo_root = Path(__file__).parent.parent
        assets_dir = repo_root / "assets"
        aikido_svg = assets_dir / "vogix16_aikido.svg"

        if not aikido_svg.exists():
            print(f"❌ Test file not found: {aikido_svg}")
            return 1

        # Expected values from SVG visual inspection
        expected_dark = {
            "base00": "#262626",  # Sumi (charcoal)
            "base07": "#f6f5f0",  # Washi (paper)
            "base08": "#4d5645",  # Error
        }
        expected_light = {
            "base00": "#f6f5f0",  # Washi (paper)
            "base07": "#262626",  # Sumi (charcoal)
            "base08": "#2a3328",  # Error
        }

        success = test_extraction(aikido_svg, expected_dark, expected_light)
        return 0 if success else 1

    # Production mode - extract all themes
    # Project root is one level up from scripts/
    repo_root = Path(__file__).parent.parent
    assets_dir = repo_root / "assets"
    themes_dir = repo_root / "themes"

    svg_files = sorted(assets_dir.glob("vogix16_*.svg"))

    if not svg_files:
        print("❌ No SVG files found in assets/ directory", file=sys.stderr)
        return 1

    print(f"🎨 Extracting colors from {len(svg_files)} theme SVG files...")
    print(f"{'='*80}\n")

    successful = 0
    failed = []

    for svg_path in svg_files:
        print(f"Processing {svg_path.name}...", end=" ")
        theme_data = extract_colors_from_svg(svg_path)

        if theme_data:
            output_path = themes_dir / f"{theme_data['name']}.nix"
            if generate_nix_file(theme_data, output_path):
                print(f"✅ {output_path.name}")
                successful += 1
            else:
                print(f"❌ Failed to write")
                failed.append(svg_path.name)
        else:
            print(f"❌ Extraction failed")
            failed.append(svg_path.name)

    print(f"\n{'='*80}")
    print(f"📊 Results: {successful}/{len(svg_files)} successful")

    if failed:
        print(f"\n❌ Failed themes:")
        for name in failed:
            print(f"  - {name}")
        return 1

    print(f"\n✅ All themes extracted successfully!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
