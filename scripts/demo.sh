#!/usr/bin/env bash
# Demo script optimized for OBS recording
# Run this in the VM terminal while recording with OBS

# Configuration
TYPING_SPEED=0.021 # seconds between characters (30% faster than before)
COMMAND_PAUSE=0.8  # pause after typing command before executing
RESULT_PAUSE=1.5   # pause to show results
# shellcheck disable=SC2034
BTOP_DURATION=6 # seconds to show btop (reserved for future use)

# Typing effect function
type_text() {
  local text="$1"
  for ((i = 0; i < ${#text}; i++)); do
    echo -n "${text:i:1}"
    sleep "$TYPING_SPEED"
  done
  echo ""
}

# Show text instantly
show() {
  echo "$@"
}

# Pause
pause() {
  sleep "${1:-$RESULT_PAUSE}"
}

# Clear and show section header
section() {
  clear
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  show "$1"
  echo "═══════════════════════════════════════════════════════════"
  echo ""
  pause 1
}

# Run command with typing effect
run_cmd() {
  type_text "$ $1"
  pause "$COMMAND_PAUSE"
  eval "$1"
  pause "$RESULT_PAUSE"
}

# Main demo flow
main() {
  clear
  echo ""
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║                                                            ║"
  echo "║              VOGIX16 - Runtime Theme Manager              ║"
  echo "║                                                            ║"
  echo "║      Instant theme switching for NixOS - no rebuild!      ║"
  echo "║                                                            ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo ""
  pause 2

  # Introduction
  clear
  show ""
  type_text "# VOGIX16 lets you switch themes instantly without rebuilding NixOS"
  pause 1
  type_text "# Let's see the current theme and available options..."
  pause 1
  echo ""
  run_cmd "vogix status"
  echo ""
  run_cmd "vogix list"

  # Show current theme
  section "Current Theme: aikido-dark"
  type_text "# Let's see the color palette"
  pause 1
  run_cmd "fastfetch"

  # Switch to light variant
  section "Switch Variant: dark → light"
  type_text "# Now let's switch from dark to light variant"
  type_text "# This updates ONE symlink and reloads apps"
  pause 1
  run_cmd "vogix switch"
  echo ""
  type_text "# Notice how colors change instantly:"
  pause 1
  run_cmd "fastfetch"

  # Switch theme to sepia
  section "Switch Theme: aikido → sepia"
  type_text "# Now let's try a completely different theme"
  pause 1
  run_cmd "vogix theme sepia"
  echo ""
  type_text "# Sepia theme with light variant:"
  pause 1
  run_cmd "fastfetch"

  # Switch to ocean_depths
  section "Switch Theme: sepia → ocean_depths"
  type_text "# One more theme switch..."
  pause 1
  run_cmd "vogix theme ocean_depths"
  echo ""
  type_text "# Ocean depths theme:"
  pause 1
  run_cmd "fastfetch"

  # Back to dark
  section "Switch Variant: light → dark"
  type_text "# And switch back to dark variant"
  pause 1
  type_text "# Watch the entire screen update..."
  pause 1
  run_cmd "vogix switch"
  pause 3
  echo ""
  type_text "# Dark variant of ocean_depths:"
  pause 1
  run_cmd "fastfetch"
  pause 3

  # Explain architecture
  clear
  echo ""
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║                     HOW IT WORKS                           ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo ""
  pause 1

  type_text "# Let's examine the three-tier symlink architecture"
  echo ""
  pause 2

  type_text "# Tier 1: Your app config points to runtime directory"
  pause 1
  run_cmd "ls -l ~/.config/btop/themes"
  echo ""
  type_text "# This symlink points to the runtime directory..."
  pause 2

  type_text "# Tier 2: Runtime directory structure"
  pause 1
  # shellcheck disable=SC2016  # Single quotes intentional - expanded by eval in run_cmd
  run_cmd 'tree -L 1 $XDG_RUNTIME_DIR/vogix16/themes/'
  echo ""
  type_text "# All theme variants + 'current-theme' symlink"
  pause 2

  type_text "# Let's see what current-theme points to:"
  pause 1
  # shellcheck disable=SC2016  # Single quotes intentional - expanded by eval in run_cmd
  run_cmd 'ls -l $XDG_RUNTIME_DIR/vogix16/themes/ | grep current'
  echo ""
  pause 2

  type_text "# Tier 3: Inside a theme variant (all configs)"
  pause 1
  # shellcheck disable=SC2016  # Single quotes intentional - expanded by eval in run_cmd
  run_cmd 'tree -L 2 $XDG_RUNTIME_DIR/vogix16/themes/ocean_depths-dark/'
  echo ""
  type_text "# Each app has its themed config here"
  pause 2

  type_text "# The complete chain:"
  pause 1
  show ""
  show "  ~/.config/btop/themes"
  show "    ↓ (symlink)"
  show "  /run/user/UID/vogix16/themes/current-theme/btop"
  show "    ↓ (symlink)"
  show "  /run/user/UID/vogix16/themes/ocean_depths-dark/btop"
  show "    ↓ (symlink)"
  show "  /nix/store/xxxxx-ocean_depths-dark/btop/vogix.theme"
  pause 3
  echo ""

  type_text "# When you run 'vogix theme matrix':"
  pause 1
  type_text "  1. Update ONE symlink: current-theme → matrix-dark"
  type_text "  2. All apps instantly see new theme (same paths!)"
  type_text "  3. Apps auto-reload (file watch triggers)"
  type_text "  4. No NixOS rebuild needed!"
  pause 4

  # Summary
  clear
  echo ""
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║                        SUMMARY                             ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo ""
  type_text "  ✓ Instant theme switching with full true color support"
  type_text "  ✓ No NixOS rebuild required"
  type_text "  ✓ Applications reload automatically"
  type_text "  ✓ Works with alacritty, btop, vim, shell, console, etc."
  type_text "  ✓ Supports both dark and light variants"
  echo ""
  type_text "  Try it yourself: run btop, ls --color, or your favorite apps!"
  echo ""
  pause 3

  # Final message
  echo ""
  type_text "# Learn more: https://github.com/i-am-logger/vogix16"
  echo ""
  pause 2
}

# Run the demo
main
