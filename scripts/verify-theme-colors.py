#!/usr/bin/env python3
"""
Verify that theme Nix files match their SVG sources.
Quick visual comparison to ensure extraction was successful.
"""

import re
from pathlib import Path


def extract_from_svg(svg_path):
    """Extract colors from SVG - using x-coordinate to detect dark vs light."""
    content = svg_path.read_text()
    lines = content.split("\n")

    dark_colors = {}
    light_colors = {}

    for i, line in enumerate(lines):
        color_match = re.search(r'(base[0-9A-F]{2})\s*=\s*"(#[0-9a-fA-F]{6})"', line)
        if color_match:
            base_name = color_match.group(1)
            color_value = color_match.group(2).lower()

            # Check x coordinate in the SAME line (not backward context)
            x_match = re.search(r'x="(\d+)"', line)

            if x_match:
                x_pos = int(x_match.group(1))
                # Use same threshold as extraction script
                if x_pos < 300:  # Dark theme (left side)
                    if base_name not in dark_colors:
                        dark_colors[base_name] = color_value
                else:  # Light theme (right side)
                    if base_name not in light_colors:
                        light_colors[base_name] = color_value

    return dark_colors, light_colors


def extract_from_nix(nix_path):
    """Extract colors from Nix theme file."""
    content = nix_path.read_text()

    dark_colors = {}
    light_colors = {}

    # Parse dark section
    dark_match = re.search(r"dark\s*=\s*\{([^}]+)\}", content, re.DOTALL)
    if dark_match:
        for match in re.finditer(
            r'(base[0-9A-F]{2})\s*=\s*"(#[0-9a-fA-F]{6})"', dark_match.group(1)
        ):
            dark_colors[match.group(1)] = match.group(2).lower()

    # Parse light section
    light_match = re.search(r"light\s*=\s*\{([^}]+)\}", content, re.DOTALL)
    if light_match:
        for match in re.finditer(
            r'(base[0-9A-F]{2})\s*=\s*"(#[0-9a-fA-F]{6})"', light_match.group(1)
        ):
            light_colors[match.group(1)] = match.group(2).lower()

    return dark_colors, light_colors


def verify_theme(theme_name, svg_path, nix_path):
    """Verify a single theme matches."""
    if not svg_path.exists():
        return False, "SVG not found"

    if not nix_path.exists():
        return False, "Nix file not found"

    svg_dark, svg_light = extract_from_svg(svg_path)
    nix_dark, nix_light = extract_from_nix(nix_path)

    # Check dark variant (base00-base0E, excluding base0F which may not be in SVG)
    dark_mismatches = []
    for i in range(15):  # base00-base0E
        base = f"base{i:02X}"
        svg_color = svg_dark.get(base)
        nix_color = nix_dark.get(base)

        if svg_color and nix_color and svg_color != nix_color:
            dark_mismatches.append(f"{base}: SVG={svg_color} vs Nix={nix_color}")

    # Check light variant
    light_mismatches = []
    for i in range(15):  # base00-base0E
        base = f"base{i:02X}"
        svg_color = svg_light.get(base)
        nix_color = nix_light.get(base)

        if svg_color and nix_color and svg_color != nix_color:
            light_mismatches.append(f"{base}: SVG={svg_color} vs Nix={nix_color}")

    if dark_mismatches or light_mismatches:
        details = []
        if dark_mismatches:
            details.append(f"Dark: {', '.join(dark_mismatches)}")
        if light_mismatches:
            details.append(f"Light: {', '.join(light_mismatches)}")
        return False, "; ".join(details)

    return True, "Perfect match"


def main():
    """Test all themes."""
    # Project root is one level up from scripts/
    repo_root = Path(__file__).parent.parent
    themes_dir = repo_root / "themes"
    assets_dir = repo_root / "assets"

    theme_files = sorted(themes_dir.glob("*.nix"))

    print("🔍 Verifying Theme Extraction")
    print("=" * 80)

    results = []

    for nix_path in theme_files:
        theme_name = nix_path.stem
        svg_path = assets_dir / f"vogix16_{theme_name}.svg"

        success, message = verify_theme(theme_name, svg_path, nix_path)
        results.append((theme_name, success, message))

        status = "✅" if success else "❌"
        print(f"{status} {theme_name:20s} {message}")

    print("\n" + "=" * 80)
    passed = sum(1 for _, success, _ in results if success)
    print(f"Results: {passed}/{len(results)} themes verified")

    if passed == len(results):
        print("🎉 All themes match their SVG sources!")
        return 0
    else:
        print(f"⚠️  {len(results) - passed} themes have mismatches")
        return 1


if __name__ == "__main__":
    import sys

    sys.exit(main())
