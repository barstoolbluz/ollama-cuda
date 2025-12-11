#!/usr/bin/env bash
set -e

echo "Checking for Ollama updates..."

# Get latest release from GitHub
LATEST=$(curl -s https://api.github.com/repos/ollama/ollama/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
echo "Latest Ollama release: $LATEST"

# Get current version
if [ -f result/bin/ollama ]; then
    CURRENT=$(OLLAMA_MODELS=/tmp/test ./result/bin/ollama -v 2>&1 | grep "client version" | awk '{print $NF}')
    echo "Current build version: v$CURRENT"
else
    echo "No current build found"
    CURRENT="unknown"
fi

# Check nixpkgs version
echo "Updating flake inputs..."
nix flake update --extra-experimental-features 'nix-command flakes'

echo "Upgrading Flox packages..."
flox upgrade

# Try to build
echo "Building with updated packages..."
export NIXPKGS_ALLOW_BROKEN=1
if nix build --extra-experimental-features 'nix-command flakes' --impure -L; then
    NEW_VERSION=$(OLLAMA_MODELS=/tmp/test ./result/bin/ollama -v 2>&1 | grep "client version" | awk '{print $NF}')
    echo "Successfully built version: v$NEW_VERSION"

    if [ "$NEW_VERSION" != "${LATEST#v}" ]; then
        echo "⚠️  Built version v$NEW_VERSION is behind latest $LATEST"
        echo "nixpkgs may not have the latest version yet. Check:"
        echo "  https://github.com/NixOS/nixpkgs/pulls?q=is%3Apr+ollama"
    else
        echo "✅ Built version matches latest release!"
    fi
else
    echo "❌ Build failed"
    exit 1
fi

# Test GPU detection
echo "Testing GPU detection..."
if OLLAMA_DEBUG=1 OLLAMA_MODELS=/tmp/test timeout 5 ./result/bin/ollama serve 2>&1 | grep -q "NVIDIA GeForce"; then
    echo "✅ GPU detection working"
else
    echo "⚠️  GPU not detected"
fi