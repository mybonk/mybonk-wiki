---
layout: default
title: Workshop 11
nav_order: 12
---

# Compiling Packages from Source with fetchFromGitHub

## Overview

This workshop explains the **compile from source** approach to package overrides using `fetchFromGitHub` and `overrideAttrs`. This is a more advanced technique compared to the **no compilation** approach shown in [Workshop 3](../workshop-3/).

**Why this matters:**
- Understand how Nix builds packages from source
- Learn to use custom forks or unreleased versions
- See the difference between binary cache (fast) vs local compilation (slow but flexible)

---

## Two Approaches to Package Overrides

### Approach 1: No Compilation (Fast) - Workshop 3

**Concept**: Use different nixpkgs versions that already have pre-built binaries in the cache.

```nix
inputs = {
  nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.05";  # nginx 1.24.0
  nixpkgs-latest.url = "github:NixOS/nixpkgs/nixos-24.11";  # nginx 1.26.0
};
```

**What happens:**
1. ✅ Downloads pre-compiled binary from cache.nixos.org
2. ✅ **No compilation needed** - instant!
3. ✅ Uses official NixOS builds

**When to use:**
- You want a version that exists in some nixpkgs release
- Speed is important (workshops, CI/CD, quick testing)
- You trust the official binary cache

See [Workshop 3](../workshop-3/) for the full tutorial on this approach.

---

### Approach 2: Compile from Source (Flexible) - This Workshop

**Concept**: Fetch source code from GitHub and compile it locally.

```nix
{
  description = "Nginx from source override";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";

      # Fetch nginx source from GitHub
      nginxSrc = nixpkgs.legacyPackages.${system}.fetchFromGitHub {
        owner = "nginx";
        repo = "nginx";
        rev = "release-1.25.3";  # Specific version tag
        sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # Placeholder
      };

      # Create custom package set with overridden nginx
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            nginx = prev.nginx.overrideAttrs (oldAttrs: {
              src = nginxSrc;
              version = "1.25.3-custom";
            });
          })
        ];
      };
    in {
      nixosConfigurations.mycont = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          { nixpkgs.overlays = [ (final: prev: { inherit (pkgs) nginx; }) ]; }
          ./container-configuration.nix
        ];
      };
    };
}
```

**What happens:**
1. 📥 Downloads nginx source code from GitHub (the `.tar.gz` or git repository)
2. 🔨 **Compiles nginx locally** on your machine (30 seconds to a few minutes)
3. 📦 Stores the compiled binary in `/nix/store/...`
4. ✅ You get exactly the version/commit you specified

**When to use:**
- You need a version NOT in any nixpkgs release
- You're using a custom fork with modifications
- You want unreleased/development versions
- You're patching the source code
- You need a very specific commit hash

---

## How Local Compilation Works

### Step 1: fetchFromGitHub Downloads Source

```nix
nginxSrc = pkgs.fetchFromGitHub {
  owner = "nginx";
  repo = "nginx";
  rev = "release-1.25.3";
  sha256 = "sha256-...";  # Verifies download integrity
};
```

This downloads the source tarball and verifies it matches the hash.

### Step 2: overrideAttrs Replaces Source

```nix
nginx = prev.nginx.overrideAttrs (oldAttrs: {
  src = nginxSrc;  # Replace source
  version = "1.25.3-custom";  # Update version string
});
```

This tells Nix: "Use the existing nginx build recipe, but replace the source code."

### Step 3: Nix Compiles Locally

When you run:
```bash
sudo nixos-container update mycont --flake .#mycont
```

Nix will:
1. Fetch dependencies (build tools, libraries)
2. Run `./configure` (if applicable)
3. Run `make` to compile
4. Run tests (if any)
5. Install to `/nix/store/...`

**This takes time** - for nginx, about 30 seconds to a few minutes depending on your hardware.

---

## Finding the Correct Hash

The `sha256` hash verifies the downloaded source. Here's how to get it:

### Method 1: Let Nix Tell You (Recommended)

1. Use a placeholder hash:
```nix
sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
```

2. Try to build:
```bash
nix flake check
```

3. Nix will fail and show you the correct hash:
```
error: hash mismatch in fixed-output derivation '/nix/store/...':
         specified: sha256-AAAAAAAAA...
            got:    sha256-xyz123abc...
```

4. Copy the "got:" hash into your flake.nix

### Method 2: Use nix-prefetch-github

```bash
nix-shell -p nix-prefetch-github
nix-prefetch-github nginx nginx --rev release-1.25.3
```

This outputs the correct hash immediately.

---

## Comparison: Binary Cache vs Compile from Source

| Aspect | Binary Cache (Workshop 3) | Compile from Source (Workshop 11) |
|--------|---------------------------|-----------------------------------|
| **Speed** | ✅ Instant (download only) | ❌ Slow (minutes to compile) |
| **Flexibility** | ❌ Limited to nixpkgs versions | ✅ Any version/commit/fork |
| **Reproducibility** | ✅ Official builds | ✅ Build from source |
| **Disk space** | ✅ Smaller (just binary) | ❌ Larger (source + binary) |
| **Trust model** | ❌ Trust cache.nixos.org | ✅ Verify source yourself |
| **Use case** | Quick version switches | Custom forks, unreleased versions |

---

## Real-World Example: Bitcoin Mutinynet (Workshop 10)

Workshop 10 uses the compile-from-source approach because:

- **Mutinynet is a fork** of Bitcoin Core (by benthecarman)
- **Not in nixpkgs** - no pre-built binary available
- **Needs specific commit** with 30-second block time support
- **Custom modifications** that don't exist in official Bitcoin Core

This is a perfect use case for `fetchFromGitHub` + local compilation!

See [Workshop 10](../workshop-10/) for the full Bitcoin/Mutinynet implementation.

---

## When to Choose Each Approach

### Choose Binary Cache (Workshop 3) when:
- ✅ The version you want exists in some nixpkgs release
- ✅ Speed matters (CI/CD, workshops, development)
- ✅ You're okay with official nixpkgs versions
- ✅ You want reproducible builds without compilation time

### Choose Compile from Source (Workshop 11) when:
- ✅ You need a version NOT in nixpkgs
- ✅ You're using a fork or custom modifications
- ✅ You need bleeding-edge unreleased code
- ✅ You want to verify the source yourself
- ✅ You're patching the source code

---

## Next Steps

- **Start with [Workshop 3](../workshop-3/)** to learn the fast binary cache approach
- **Try [Workshop 10](../workshop-10/)** to see a real-world compile-from-source example (Bitcoin Mutinynet)
- **Experiment** with overriding other packages from source

---

## Summary

The compile-from-source approach gives you **maximum flexibility** at the cost of **compilation time**. Use it when you need versions, forks, or modifications that aren't available in the binary cache.

For most use cases, the binary cache approach (Workshop 3) is faster and sufficient. But when you need that extra flexibility, `fetchFromGitHub` + `overrideAttrs` is your tool!
