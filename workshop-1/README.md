# Run NixOS in a VM on Your Machine in 5 Minutes

## Introduction

### What Are We Talking About?

Before diving in, let's clarify some terminology that often confuses newcomers:

- **Nix (the language)**: A purely functional, lazily-evaluated programming language with unique syntax designed for package management and system configuration
- **Nix (the package manager)**: A powerful package manager that works on any Linux distribution and macOS, providing reproducible builds and atomic upgrades
- **NixOS**: A complete Linux distribution built on top of the Nix package manager, where the entire system configuration is declared in Nix language files

Understanding these distinctions is crucial. You can use the Nix package manager without NixOS, but NixOS requires Nix.

### Learning Resources

If you're new to the Nix ecosystem, these resources will help:


- [Nix Pills](https://nixos.org/guides/nix-pills/) - Deep dive � into Nix (the *language*)
- [NixOS & Nix Flakes Book](https://nixos-and-flakes.thiscute.world/introduction/) - �️ ❤️ The unofficial & opinionated � for beginners! Check it out!
- [Basic Linux Commands Cheat Sheet](../baby-rabbit-holes.md) - Our own cheat sheet you can copy/past commands from �

### Prerequisites

To follow this workshop, you'll need:

- A laptop running NixOS
- Basic command line knowledge
- Basic Git knowledge
- To at least have heard of Nix or NixOS before

The commands used herein `nixos-container` and `nixos-rebuild` (for containers and VMs respectively as we'll see later) are NixOS-specific commands: They use NixOS' systemd-nspawn for containerization, depend on NixOS's system configuration model and require NixOS's container management infrastructure that's part of the base system. Thus these steps must be executed on a machine with NixOS installed on it or a machine running an image of a NixOS system.

### Important: Disk Space Considerations

Nix keeps multiple generations of your system, cached packages, and build artifacts in `/nix/store`. This can possibly consume a lot of disk space when experimenting and building often. Here's what you need to know:

**Why does Nix use so much space?**
- Every system generation is preserved (for rollback capability)
- Build dependencies are cached
- Multiple versions of packages can coexist
- Garbage collection doesn't happen automatically *by design*

**How to manage disk space:**

```bash
# View what's using space
nix-store --query --requisites /run/current-system | wc -l
du -sh /nix/store

# Delete old generations (e.x. older than 7 days)
nix-collect-garbage --delete-older-than 7d

# Aggressive cleanup (delete everything not currently in use)
nix-collect-garbage -d

# For NixOS systems, clean old boot entries too
sudo nix-collect-garbage -d
sudo nixos-rebuild boot  # Recreate boot menu
```

**Best practice**: Have a look at your disk space now and then, run garbage collection as needed when experimenting.

---

## Understanding VMs vs Containers

### Historical Context

**Virtual Machines came first:**
- VMware (1998), VirtualBox, QEMU/KVM
- Full hardware virtualization
- Complete isolation with separate kernel
- Heavier resource usage

**Containers came later:**
- Docker (2013), LXC, systemd-nspawn
- OS-level virtualization
- Share host kernel
- Lighter resource usage

### Key Differences

| Aspect | Virtual Machines (QEMU) | Containers |
|--------|------------------------|------------|
| **Isolation** | Complete (separate kernel) | Process-level (shared kernel) |
| **Startup Time** | Slower (boots full OS) | Fast (seconds) |
| **Resource Usage** | Higher (dedicated RAM, CPU) | Lower (shared resources) |
| **Portability** | Run any OS | Must match host kernel |
| **Security** | Stronger isolation | Weaker (kernel exploits affect host) |

### NixOS "Containers"

NixOS containers are **not Docker containers**. They use `systemd-nspawn` under the hood and are more similar to LXC containers. Key characteristics:

- Lightweight *system* containers (not *application* containers)
- Share the Nix store with the host
- Managed declaratively through standard NixOS configuration
- Perfect for development and testing
- Share the host's Linux kernel
- Tools exist to convert Docker containers into NixOS containers and the other way around.

### When to Use Each Approach

**Use NixOS Containers when:**
- Running on your local laptop/workstation
- You need fast iteration cycles
- Testing system configurations
- Disk space is limited
- You're running NixOS as the host
- On VPS where nested virtualization is unavailable or limited

**Use QEMU VMs when:**
- You need complete isolation
- Testing different kernel versions
- Running on non-NixOS systems
- Nested virtualization is available and well-supported
- You need to test different kernels or boot configurations

**Important note about VPS**: NixOS containers may work on cloud VPS (e.x. Hetzner) but require careful network configuration (bridging, routing). On the other hand QEMU may not work on VPS as they usually disable nested virtualization.

---

## Getting Started

We'll create a minimal NixOS system:
- Set a hostname
- Enable SSH access
- Add your SSH public key
- Include basic command-line tools

This involves configuring just two files:
- `flake.nix` - Defines inputs and outputs for our system
- `configuration.nix` - The actual system configuration

### Clone the Workshop Repository

```bash
# Clone the repository with example configurations
git clone git@github.com:mybonk/mybonk-wiki.git
cd mybonk-wiki/workshop-1
```

---

## Approach 1: NixOS Container

### What Makes Containers Special

NixOS containers:
- **Share the Nix store** with the host (no duplication!)
- **Share the kernel** (lightweight)
- **Isolated filesystem** (appears as separate system)
- **Persistent by default** (unless explicitly destroyed)
- **Very fast startup** (2-3 seconds)

### Configuration Files

**File: `flake.nix`**

```nix
{
  description = "NixOS VM Workshop - Container Edition";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.demo-container = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./container-configuration.nix ];
    };
  };
}
```

**File: `container-configuration.nix`**

```nix
{ config, pkgs, ... }:

{
  # Required for containers
  boot.isContainer = true;

  # Allow container to access the internet
  networking.useHostResolvConf = true;

  # Basic system settings
  networking.hostName = "demo-container";
  
  # Enable SSH
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # Add your SSH public key (replace with your actual key!)
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC... your-email@example.com"
  ];

  # Essential packages
  environment.systemPackages = with pkgs; [
    vim
    btop
    curl
    git
  ];
  system.stateVersion = "24.05";
}
```

### Building and Running

**Step 1: Build the container**

```bash
# Build the configuration
sudo nixos-container create demo --flake .#demo-container
```

**Step 2: Start the container**

```bash
# Start it
sudo nixos-container start demo

# Check status
sudo nixos-container status demo
```

**Step 3: Connect to the container**

```bash
# Option 1: Direct root shell
sudo nixos-container root-login demo

# Option 2: SSH (if you configured keys)
# First, get the container's IP
sudo nixos-container show-ip demo
# Then SSH to it
ssh root@<container-ip>
```

**Step 4: Managing the container**

```bash
# Stop the container
sudo nixos-container stop demo

# Restart it
sudo nixos-container start demo

# Destroy the container completely
sudo nixos-container destroy demo
```

### What Persists and What Doesn't

**Persists after stopping:**
- Container configuration in `/etc/nixos-containers/demo/`
- Container filesystem in `/var/lib/nixos-containers/demo/`
- Any files you created inside

**Shared with host:**
- The `/nix/store` (read-only, no duplication!)
- Network namespace (configurable)

**Lost after destroying:**
- Everything except the Nix store entries

**Why so lightweight?**
The container doesn't duplicate packages. If `vim` is already in your host's Nix store, the container just references it. A typical container uses only 50-100MB of unique data!

---

## Approach 2: QEMU Virtual Machine

### What Makes VMs Different

QEMU VMs:
- **Separate Nix store** (full duplication)
- **Own kernel** (complete isolation)
- **Own filesystem** (full disk image)
- **Slower startup** (30-60 seconds)
- **Higher resource usage** (allocates RAM, CPU)
- **Works anywhere** (even on already-virtualized hosts)

### Configuration Files

**File: `flake.nix`** (VM version)

```nix
{
  description = "NixOS VM Workshop - QEMU Edition";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.demo-vm = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./vm-configuration.nix ];
    };
  };
}
```

**File: `vm-configuration.nix`**

```nix
{ config, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # Basic system settings
  networking.hostName = "demo-vm";
  
  # VM-specific settings, do not change
  boot.loader.grub.device = "/dev/vda";
  
  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };


  # Allow empty password for easy testing (NOT for production!)
  users.users.root.initialPassword = "root";

  # Enable SSH
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # Add your SSH public key
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC... your-email@example.com"
  ];

  # Essential packages
  environment.systemPackages = with pkgs; [
    vim
    btop
    curl
    git
  ];

  system.stateVersion = "24.05";
}
```

### Building and Running

**Step 1: Build the VM**

```bash
# Build the VM configuration
nix build .#nixosConfigurations.demo-vm.config.system.build.vm

# Or use the direct command
nixos-rebuild build-vm --flake .#demo-vm
```

**Step 2: Run the VM**

```bash
# Start the VM (it creates a disk image on first run)
./result/bin/run-demo-vm-vm

# Or with more memory
QEMU_OPTS="-m 2048" ./result/bin/run-demo-vm-vm
```

**Step 3: Connect to the VM**

The VM will open in a QEMU window. You can:

```bash
# Option 1: Use the QEMU console directly
# (login as root with password "root")

# Option 2: SSH via port forwarding
# Add this to your vm-configuration.nix:
# services.openssh.ports = [ 22 ];
# 
# Then run VM with port forwarding:
# QEMU_NET_OPTS="hostfwd=tcp::2222-:22" ./result/bin/run-demo-vm-vm
#
# Then SSH:
# ssh -p 2222 root@localhost
```

**Step 4: Managing the VM**

```bash
# Stop the VM
# Just close the QEMU window or press Ctrl+C in terminal

# Restart
# Run the script again
./result/bin/run-demo-vm-vm

# Destroy
# Remove the disk image
rm demo-vm.qcow2
# Remove the build result
rm result
```

### What Persists and What Doesn't

**Persists after stopping:**
- Disk image file (`demo-vm.qcow2`)
- Any changes you made inside the VM

**Separate from host:**
- Complete `/nix/store` (duplicated packages!)
- Own filesystem
- Own kernel and modules

**Lost after destroying:**
- Everything in the disk image

**Why so heavy?**
A minimal NixOS VM typically requires:
- 500MB-1GB for the base system in `/nix/store`
- 100-200MB for the kernel and initrd
- Additional space for any packages you install

The disk image can quickly grow to 2-5GB for a working system.

---

## Going Further: Adding a Web Server

Let's add a simple web server to demonstrate system configuration changes.

### For Container

Add this to `container-configuration.nix`:

```nix
  # Enable nginx web server
  services.nginx = {
    enable = true;
    virtualHosts."demo-container" = {
      root = "/var/www";
      locations."/" = {
        index = "index.html";
      };
    };
  };

  # Create a simple webpage
  systemd.tmpfiles.rules = [
    "d /var/www 0755 root root -"
    "f /var/www/index.html 0644 root root - <!DOCTYPE html><html><body><h1>Hello from NixOS Container!</h1></body></html>"
  ];

  # Open firewall for HTTP
  networking.firewall.allowedTCPPorts = [ 80 ];
```

**Update the container:**

```bash
# Rebuild the container configuration
sudo nixos-container update demo --flake .#demo-container

# Get the IP and test
CONTAINER_IP=$(sudo nixos-container show-ip demo)
curl http://$CONTAINER_IP
```

### For QEMU VM

Add the same nginx configuration to `vm-configuration.nix`, then:

```bash
# Rebuild the VM
nixos-rebuild build-vm --flake .#demo-vm

# You'll need to destroy and recreate for major changes
rm demo-vm.qcow2
./result/bin/run-demo-vm-vm
```

### Best Practices for Updates

**For Containers (fast iteration):**
```bash
# Quick changes: update in place
sudo nixos-container update demo --flake .#demo-container

# Major changes: destroy and recreate
sudo nixos-container destroy demo
sudo nixos-container create demo --flake .#demo-container
sudo nixos-container start demo
```

**For QEMU VMs (testing):**
```bash
# Quick changes: rebuild inside the VM
# (SSH or console into VM)
nixos-rebuild switch --flake .#demo-vm

# Major changes: destroy disk image and rebuild
rm demo-vm.qcow2
nixos-rebuild build-vm --flake .#demo-vm
./result/bin/run-demo-vm-vm
```

**General rule**: For testing and learning, destroying and rebuilding is often cleaner and faster than debugging in-place updates.

---

## Production Usage: Should You Use VMs or Containers?

### In Production Environments

**NixOS Containers in production:**
- ✅ Excellent for multi-tenant systems on bare metal
- ✅ Great for microservices on a single host
- ✅ Perfect for isolating different applications
- ✅ Work on cloud VPS (but need network configuration)
- ⚠️ Less isolation than VMs (shared kernel vulnerabilities)
- ⚠️ Require more networking setup on VPS

**QEMU VMs in production:**
- ✅ Strong isolation guarantees
- ✅ Standard for traditional virtualization
- ⚠️ May not work on VPS without nested virtualization
- ❌ Higher resource overhead
- ❌ Slower to start/stop
- ❌ Not available on all cloud providers

**What's commonly done:**
- Most NixOS production deployments run directly on hardware or cloud VMs
- NixOS containers are popular for development and certain multi-tenant scenarios
- For cloud deployment, deploy NixOS directly to the VPS (no nested virtualization)
- Docker/Podman containers with Nix-built images are common for applications

**The NixOS approach:**
Instead of running many VMs or containers, consider:
- **Declarative configuration**: Use NixOS modules to configure everything
- **System profiles**: Multiple system configurations on one machine
- **Nixpkgs overlays**: Custom package sets per application
- **Home Manager**: Per-user environment management

---

## Cautions and Best Practices

### ⚠️ This Is a Demo

The configurations provided in this workshop are for learning purposes only. **Do not use them in production without:**

- Removing default passwords
- Properly configuring SSH keys
- Setting up firewall rules
- Configuring backups
- Implementing monitoring
- Following security hardening guides

### �️ Managing Disk Space

Nix's approach to reproducibility means it keeps everything, which can quickly consume disk space.

**Symptoms you're running out of space:**
- Builds failing with "No space left on device"
- Slow system performance
- `/nix/store` consuming 50GB+

**Prevention strategies:**

```bash
# 1. Regular garbage collection (weekly)
nix-collect-garbage --delete-older-than 7d

# 2. Aggressive cleanup when needed
nix-collect-garbage -d

# 3. Optimize the store (deduplicates)
nix-store --optimise

# 4. Check disk usage
df -h /nix/store
du -sh /nix/store

# 5. For NixOS: limit generations
# Add to configuration.nix:
# boot.loader.grub.configurationLimit = 10;
# nix.gc.automatic = true;
# nix.gc.dates = "weekly";
# nix.gc.options = "--delete-older-than 30d";
```

**Space-saving tips:**
- Don't keep unnecessary build results
- Use `nix-collect-garbage` after experiments
- Enable automatic garbage collection
- Monitor `/nix/store` size regularly
- Consider a larger disk for active development

### � Additional Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)


---

## What We Learned

You've learned how to:
- ✅ Understand the difference between Nix, Nix package manager, and NixOS
- ✅ Distinguish between VMs and containers
- ✅ Run NixOS in a lightweight container
- ✅ Run NixOS in a full QEMU virtual machine
- ✅ Add services to your systems
- ✅ Manage disk space effectively
- ✅ Understand when to use each approach


---

## Next Steps

1. Experiment with different services
2. Try building your own configurations
3. Explore NixOS modules and options
4. Join the NixOS community
5. Consider deploying NixOS for real workloads

Happy hacking! �

---
**Coming up:**

**Workshop 2 - "[Installing Bitcoin as a service on NixOS in 2 Minutes](../workshop-2/)"**
## Notes

**Workshop Duration:** 45 minutes 
**Difficulty:** Beginner  

