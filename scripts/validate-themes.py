#!/usr/bin/env python3
"""
Proof test: Verify all themes have proper structure with all required colors.
"""

import re
from pathlib import Path


def test_theme_structure(nix_path):
    """Test that a theme file has all required base00-base0F colors."""
    content = nix_path.read_text()

    # Check for name
    if not re.search(r'name\s*=\s*"[^"]+";', content):
        return False, "Missing name"

    # Extract dark section
    dark_match = re.search(r"dark\s*=\s*\{([^}]+)\}", content, re.DOTALL)
    if not dark_match:
        return False, "Missing dark section"

    dark_section = dark_match.group(1)

    # Extract light section
    light_match = re.search(r"light\s*=\s*\{([^}]+)\}", content, re.DOTALL)
    if not light_match:
        return False, "Missing light section"

    light_section = light_match.group(1)

    # Check for all base00-base0F in both variants
    required_bases = [f"base{i:02X}" for i in range(16)]

    dark_missing = []
    light_missing = []

    for base in required_bases:
        # Check dark
        if not re.search(rf'{base}\s*=\s*"#[0-9a-fA-F]{{6}}"', dark_section):
            dark_missing.append(base)

        # Check light
        if not re.search(rf'{base}\s*=\s*"#[0-9a-fA-F]{{6}}"', light_section):
            light_missing.append(base)

    errors = []
    if dark_missing:
        errors.append(f"Dark missing: {', '.join(dark_missing)}")
    if light_missing:
        errors.append(f"Light missing: {', '.join(light_missing)}")

    if errors:
        return False, "; ".join(errors)

    return True, "Complete structure"


def main():
    """Test all theme files."""
    # themes/ is in project root, one level up from scripts/
    themes_dir = Path(__file__).parent.parent / "themes"
    theme_files = sorted(themes_dir.glob("*.nix"))

    print("🔬 PROOF TEST: Theme Structure Validation")
    print("=" * 80)
    print(f"Testing {len(theme_files)} theme files for complete structure...\n")

    passed = 0
    failed = []

    for theme_path in theme_files:
        theme_name = theme_path.stem
        success, message = test_theme_structure(theme_path)

        status = "✅" if success else "❌"
        print(f"{status} {theme_name:20s} {message}")

        if success:
            passed += 1
        else:
            failed.append((theme_name, message))

    print("\n" + "=" * 80)
    print(f"Results: {passed}/{len(theme_files)} themes have complete structure")

    if failed:
        print(f"\n❌ FAILED THEMES:")
        for name, error in failed:
            print(f"  - {name}: {error}")
        return 1
    else:
        print("\n✅ ALL THEMES HAVE COMPLETE STRUCTURE")
        return 0


if __name__ == "__main__":
    import sys

    sys.exit(main())
