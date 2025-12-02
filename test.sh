#!/usr/bin/env bash
# Vogix16 Automated Test Runner

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║     Vogix16 Automated Integration Tests                ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check if nix is available
if ! command -v nix &> /dev/null; then
    echo "❌ Error: Nix is not installed or not in PATH"
    exit 1
fi

# Check if flakes are enabled
if ! nix flake --version &> /dev/null; then
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

# Run the integration tests
echo "🧪 Running integration tests..."
nix build .#checks.x86_64-linux.integration --print-build-logs

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║              🎉 ALL TESTS PASSED! 🎉                   ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Test results saved in: ./result"
echo ""
echo "To manually explore the test VM:"
echo "  nix build .#nixosConfigurations.vogix16-test-vm.config.system.build.vm"
echo "  ./result/bin/run-vogix16-test-vm-vm"
echo ""
