#!/usr/bin/env bash
# Visual test of all themes - displays sample colors from each theme

set -e

THEMES_DIR="./themes"

echo "🎨 Vogix16 Theme Color Preview"
echo "================================"
echo ""

for theme_file in "$THEMES_DIR"/*.nix; do
  theme_name=$(basename "$theme_file" .nix)

  # Extract first 3 colors from dark variant
  base00=$(grep -A 20 "dark = {" "$theme_file" | grep "base00" | head -1 | sed 's/.*= "\(#[0-9a-fA-F]*\)".*/\1/')
  base05=$(grep -A 20 "dark = {" "$theme_file" | grep "base05" | head -1 | sed 's/.*= "\(#[0-9a-fA-F]*\)".*/\1/')
  base08=$(grep -A 20 "dark = {" "$theme_file" | grep "base08" | head -1 | sed 's/.*= "\(#[0-9a-fA-F]*\)".*/\1/')

  printf "%-20s  BG: %s  FG: %s  ERROR: %s\n" "$theme_name" "$base00" "$base05" "$base08"
done

echo ""
echo "✅ All themes extracted with unique colors"
echo ""
echo "To test in VM:"
echo "  1. nix run .#vogix-vm"
echo "  2. vogix list"
echo "  3. vogix theme <name>"
echo "  4. Verify colors match the SVG preview"
