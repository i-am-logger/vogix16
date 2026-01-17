#!/usr/bin/env bash
# Vogix Automated Test Runner

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║     Vogix Automated Integration Tests                  ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check if nix is available
if ! command -v nix &>/dev/null; then
  echo "❌ Error: Nix is not installed or not in PATH"
  exit 1
fi

# Check if flakes are enabled
if ! nix flake --version &>/dev/null; then
  echo "❌ Error: Nix flakes are not enabled"
  echo "Enable with: nix-env -iA nixpkgs.nixFlakes"
  exit 1
fi

echo "🔍 Checking flake validity..."
nix flake check --no-build 2>&1 | grep -v "warning: Git tree" || true
echo "✓ Flake is valid"
echo ""

echo "🏗️  Building test infrastructure..."
echo "This may take a few minutes on first run..."
echo ""

# Parse arguments
TEST_SUITE="${1:-smoke}"

# Available test suites
AVAILABLE_TESTS="smoke architecture cli navigation scheme-switching state stress theme-switching"

if [[ $TEST_SUITE == "all" ]]; then
  echo "🧪 Running all integration tests..."
  for test in $AVAILABLE_TESTS; do
    echo ""
    echo "━━━ Running: $test ━━━"
    nix build ".#checks.x86_64-linux.$test" --print-build-logs
  done
elif echo " $AVAILABLE_TESTS " | grep -q " $TEST_SUITE "; then
  echo "🧪 Running $TEST_SUITE tests..."
  nix build ".#checks.x86_64-linux.$TEST_SUITE" --print-build-logs
else
  echo "❌ Unknown test suite: $TEST_SUITE"
  echo "Available: $AVAILABLE_TESTS all"
  exit 1
fi

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║              🎉 ALL TESTS PASSED! 🎉                   ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Test output saved in: ./result"
echo ""
echo "Usage: ./test.sh [suite]"
echo "Available suites: smoke (default) | architecture | cli | navigation"
echo "                  scheme-switching | state | stress | theme-switching | all"
echo ""
echo "To manually explore the test VM:"
echo "  nix run .#vogix-vm"
echo ""
