---
layout: default
title: Workshop 3
nav_order: 4
---

# How to Override Package Versions in NixOS (Fast, No Compilation)

## Overview

This workshop demonstrates how to use **different package versions** in NixOS without compiling anything from source. We'll override nginx to use a different version by pulling from different nixpkgs releases.

**Why this approach?**

- ✅ **No compilation** - Uses pre-built binaries from cache.nixos.org
- ✅ **Instant updates** - Downloads in seconds, not minutes
- ✅ **Real-world pattern** - Common technique in production NixOS systems
- ✅ **Multiple versions** - Run different versions side-by-side

**What you'll learn:**

- Use multiple nixpkgs inputs in a single flake
- Override service packages using different nixpkgs versions
- Understand binary caches vs local compilation
- Verify package versions after override
- Test that overridden services work correctly

**Prerequisites:**

- Completed [workshop-2](../workshop-2/) (Understanding of NixOS containers)
- Understanding of Nix flakes
- Basic familiarity with web servers (nginx)

**Time:** ~15 minutes

---

## The Concept: Multiple nixpkgs Inputs

Instead of compiling from source (which takes time), we use **different nixpkgs releases** that already have the versions we want **pre-compiled**.

**Example:**
- `nixos-23.05` has nginx 1.24.0
- `nixos-24.11` has nginx 1.26.2

By using multiple nixpkgs inputs, we can choose which version to use **without any compilation**.

**Comparison to Workshop 11:**

| Approach | Workshop 3 (This) | Workshop 11 |
|----------|-------------------|-------------|
| Method | Multiple nixpkgs inputs | fetchFromGitHub + compile |
| Speed | ✅ Instant (binary cache) | ❌ Slow (compile from source) |
| Versions | ❌ Limited to nixpkgs releases | ✅ Any version/commit/fork |
| Use case | Quick version switches | Custom forks, unreleased code |

See [Workshop 11](../workshop-11/) for the compile-from-source approach.

---

## Step 1: Check Available nginx Versions

Before we start, let's see what nginx versions are available in different nixpkgs releases:

```bash
# Check nginx in nixos-23.05
nix eval github:NixOS/nixpkgs/nixos-23.05#nginx.version

# Check nginx in nixos-24.11
nix eval github:NixOS/nixpkgs/nixos-24.11#nginx.version
```

You'll see different versions. We'll use this to demonstrate the override.

---

## Step 2: Create the Workshop Directory

```bash
cd ~/
mkdir -p workshop-3-nginx
cd workshop-3-nginx
```

---

## Step 3: Create flake.nix with Multiple nixpkgs Inputs

Create `flake.nix`:

```nix
{
  description = "Nginx version override using multiple nixpkgs inputs";

  inputs = {
    # Older stable release
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.05";

    # Newer release
    nixpkgs-latest.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs-stable, nixpkgs-latest }:
    let
      system = "x86_64-linux";
    in {
      # Container using OLDER nginx from nixos-23.05
      nixosConfigurations.nginx-old = nixpkgs-stable.lib.nixosSystem {
        inherit system;
        modules = [ ./container-configuration.nix ];
      };

      # Container using NEWER nginx from nixos-24.11
      nixosConfigurations.nginx-new = nixpkgs-latest.lib.nixosSystem {
        inherit system;
        modules = [ ./container-configuration.nix ];
      };
    };
}
```

**What this does:**

- Defines two nixpkgs inputs: `nixpkgs-stable` (23.05) and `nixpkgs-latest` (24.11)
- Creates two container configurations: `nginx-old` and `nginx-new`
- Each uses a different nixpkgs version, so they get different nginx versions
- **No compilation needed** - both download pre-built binaries!

---

## Step 4: Create container-configuration.nix

Create `container-configuration.nix`:

```nix
{ config, pkgs, lib, ... }:

{
  boot.isContainer = true;
  networking.hostName = "nginx-container";

  # Enable nginx web server
  services.nginx = {
    enable = true;
    virtualHosts."localhost" = {
      root = "/var/www";
      locations."/" = {
        index = "index.html";
      };
    };
  };

  # Create a simple web page
  system.activationScripts.setupWebRoot = ''
    mkdir -p /var/www
    cat > /var/www/index.html <<EOF
    <!DOCTYPE html>
    <html>
    <head><title>NixOS nginx Test</title></head>
    <body>
      <h1>Welcome to nginx on NixOS!</h1>
      <p>This is running nginx version: NGINX_VERSION</p>
      <p>Workshop 3: Package version override demo</p>
    </body>
    </html>
    EOF

    # Replace NGINX_VERSION with actual version
    ${pkgs.gnused}/bin/sed -i "s/NGINX_VERSION/$(${pkgs.nginx}/bin/nginx -v 2>&1 | cut -d'/' -f2)/" /var/www/index.html
  '';

  # Useful utilities
  environment.systemPackages = with pkgs; [
    nginx
    curl
    vim
  ];

  # Allow container to access the internet
  networking.useHostResolvConf = lib.mkForce false;
  services.resolved.enable = true;

  # Open firewall for nginx
  networking.firewall.allowedTCPPorts = [ 80 ];

  system.stateVersion = "24.11";
}
```

**What this does:**

- Enables nginx web server
- Creates a simple HTML page showing the nginx version
- Opens port 80 for web traffic
- Works with ANY nixpkgs version (no hardcoded dependencies)

---

## Step 5: Create the OLD nginx Container

```bash
sudo nixos-container create nginx-old --flake .#nginx-old
```

This creates a container using nginx from `nixos-23.05` (older version).

---

## Step 6: Start and Test the OLD Container

```bash
# Start the container
sudo nixos-container start nginx-old

# Check nginx version inside container
sudo nixos-container run nginx-old -- nginx -v

# Get container IP
sudo nixos-container show-ip nginx-old

# Test web server (replace with actual IP)
curl http://$(sudo nixos-container show-ip nginx-old)
```

You should see the web page with the older nginx version!

---

## Step 7: Create the NEW nginx Container

Now let's create a second container with the newer nginx:

```bash
sudo nixos-container create nginx-new --flake .#nginx-new
sudo nixos-container start nginx-new
```

---

## Step 8: Compare the Versions

```bash
# Check OLD container nginx version
echo "=== OLD Container (nixos-23.05) ==="
sudo nixos-container run nginx-old -- nginx -v

# Check NEW container nginx version
echo "=== NEW Container (nixos-24.11) ==="
sudo nixos-container run nginx-new -- nginx -v
```

You'll see different versions! **Both downloaded instantly from the binary cache - no compilation!**

---

## Step 9: Test Both Web Servers

```bash
# Get IPs
IP_OLD=$(sudo nixos-container show-ip nginx-old)
IP_NEW=$(sudo nixos-container show-ip nginx-new)

echo "OLD container: http://$IP_OLD"
echo "NEW container: http://$IP_NEW"

# Test both
curl http://$IP_OLD
echo ""
curl http://$IP_NEW
```

Both serve web pages, but with different nginx versions!

---

## Understanding What Happened

### No Compilation Needed

When you created the containers, Nix:

1. **Checked the binary cache** (cache.nixos.org)
2. **Found pre-built nginx** for both nixos-23.05 and nixos-24.11
3. **Downloaded the binaries** (seconds, not minutes)
4. **Started the containers** immediately

**No source code compilation happened!**

### Why This Works

- NixOS builds **every package in every release** and puts them in the binary cache
- When you reference `github:NixOS/nixpkgs/nixos-23.05`, you get access to all those pre-built packages
- Switching versions = downloading a different pre-built binary
- Fast, efficient, and reproducible!

---

## Cleanup

```bash
# Stop and destroy containers
sudo nixos-container stop nginx-old
sudo nixos-container stop nginx-new
sudo nixos-container destroy nginx-old
sudo nixos-container destroy nginx-new
```

---

## Advanced: Mix and Match Packages

You can even use different nixpkgs versions for different packages in the **same** container:

```nix
nixosConfigurations.mixed = nixpkgs-latest.lib.nixosSystem {
  inherit system;
  modules = [
    {
      # Use latest nixpkgs as base
      nixpkgs.overlays = [
        (final: prev: {
          # But use nginx from stable
          nginx = nixpkgs-stable.legacyPackages.${system}.nginx;
        })
      ];
    }
    ./container-configuration.nix
  ];
};
```

This gives you:
- System packages from nixos-24.11
- nginx from nixos-23.05

---

## When to Use This Approach

**Use this (Workshop 3) when:**
- ✅ The version you need exists in some nixpkgs release
- ✅ Speed matters (instant downloads)
- ✅ You want official, tested builds
- ✅ You're switching between stable releases

**Use Workshop 11 (compile from source) when:**
- ✅ You need a version NOT in any nixpkgs release
- ✅ You're using a fork or custom modifications
- ✅ You need bleeding-edge unreleased code
- ✅ You're patching the source

---

## Key Takeaways

1. **Multiple nixpkgs inputs** let you access different package versions
2. **Binary caches** make this instant - no compilation needed
3. **Real-world pattern** - production systems use this technique
4. **Flexible** - mix and match packages from different releases

---

## Next Steps

- Try overriding other packages (postgresql, redis, nodejs)
- Explore [Workshop 11](../workshop-11/) for compile-from-source approach
- Learn about overlays for more advanced package customization

---

## Summary

You learned how to override package versions in NixOS using multiple nixpkgs inputs. This gives you instant access to different versions without any compilation time!

- nginx-old: Downloaded from nixos-23.05 cache ⚡
- nginx-new: Downloaded from nixos-24.11 cache ⚡
- Both work perfectly with zero compilation! 🎉
