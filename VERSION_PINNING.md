# Version Pinning for Ollama

## Current Approach

This repository tracks nixpkgs-unstable, which typically updates Ollama within 1-2 weeks of new releases. The build automatically uses whatever version is in nixpkgs.

To update to the latest available version in nixpkgs:
```bash
# Update Nix flake
nix flake update --extra-experimental-features 'nix-command flakes'

# Update Flox
flox upgrade

# Build
NIXPKGS_ALLOW_BROKEN=1 nix build --extra-experimental-features 'nix-command flakes' --impure -L
flox build ollama-cuda
```

## Why Direct Source Override is Complex

Overriding to a specific Ollama version (like v0.13.2) is non-trivial because:

1. **Vendored Dependencies**: Ollama vendors Go dependencies with a specific hash that must match
2. **Patches**: Nixpkgs applies patches that may need updating for different versions
3. **Build Process Changes**: Different versions may have different build requirements

The nixpkgs maintainers handle all these complexities when they update Ollama.

## Options for Specific Versions

### Option 1: Wait for nixpkgs (Recommended)
- Nixpkgs usually updates within 1-2 weeks
- Check PRs: https://github.com/NixOS/nixpkgs/pulls?q=is%3Apr+ollama
- Most reliable, least maintenance

### Option 2: Use nixpkgs PR
If there's an open PR for the version you want:
```nix
# In flake.nix inputs:
nixpkgs.url = "github:NixOS/nixpkgs/pull/XXXXX/head";
```

### Option 3: Fork nixpkgs ollama
For immediate access to new versions:
1. Fork nixpkgs
2. Update `pkgs/by-name/ol/ollama/package.nix`
3. Update version, src hash, and vendorHash
4. Point your flake to your fork

Example of what needs updating:
```nix
{
  version = "0.13.2";
  src = fetchFromGitHub {
    owner = "ollama";
    repo = "ollama";
    rev = "v0.13.2";
    hash = "sha256-..."; # Get with nix-prefetch-git
    fetchSubmodules = true;
  };
  vendorHash = "sha256-..."; # Build once to get the expected hash
}
```

### Option 4: Track Specific nixpkgs Commits

Create branches for specific versions (as we've done):
- `v0.12.6` branch - frozen at that version
- `master` - tracks latest from nixpkgs

Users can checkout the version they need:
```bash
git checkout v0.12.6  # For older version
git checkout master   # For latest
```

## Current Version Status

As of December 2025:
- Latest Ollama stable: v0.13.2
- This repo builds: v0.13.1 (from nixpkgs)
- Previous branch: v0.12.6

The one-version lag is typical and expected when tracking nixpkgs.