---
layout: default
title: Workshop 8
nav_order: 8
---

# Proposed Lab Setup (DHCP, DNS, NAT ...)

## Introduction

This workshop teaches you how to create and manage NixOS containers dynamically from the command line. Instead of defining containers in your host configuration, you'll create and interact with the containers simply from the command line.

### What Makes This Workshop Different?

- **Dynamic Container Creation**: Create containers by name (auto-generated name if not specified)
- **Shared Configuration**: A single configuration.nix file serves all containers
- **Private Network**: All containers communicate on a shared network (10.233.0.0/24)
- **Full Connectivity**: Containers can ping each other by hostname, reach the host, and access the internet
- **CLI Management**: Create, start, stop, and destroy containers on the fly without having to edit a config file for each one.

### Prerequisites

- A machine running NixOS (referred to hereafter as the "Host")
- Basic command line knowledge
- Familiarity with NixOS containers (see [workshop-1](../workshop-1) if new to containers)
- Basic understanding of networking concepts (IP addresses, subnets, NAT)

### Learning Resources

If you're new to NixOS or networking:

- [Workshop-1](../workshop-1) - Introduction to NixOS VMs and containers
- [MYBONK wiki's Baby Rabbit Holes](../baby-rabbit-holes.md) useful cheat sheet
- [The NixOS and Flakes book](https://nixos-and-flakes.thiscute.world/introduction/) - Comprehensive beginner-friendly guide
- [NixOS Manual - Containers](https://nixos.org/manual/nixos/stable/#ch-containers) - Official container documentation
- [IP Subnetting Basics](https://www.subnet-calculator.com/) - Understanding CIDR notation


---

## Understanding Container Networking

Let's clarify how container networking works in this setup.

### Network Architecture

```
                           Internet
                              |
                    ┌─────────┴─────────┐
                    │   Host System     │
                    │   10.233.0.1/24   │
                    │                   │
                    │  br-containers    │ (bridge interface)
                    │  (NAT enabled)    │
                    └─────────┬─────────┘
              ┌───────────────┼───────────────┐
              │               │               │
        ┌─────┴─────┐   ┌─────┴─────┐   ┌─────┴─────┐
        │Container A│   │Container B│   │Container C│
        │10.233.0.50│   │10.233.0.51│   │10.233.0.52│
        │(DHCP)     │   │(DHCP)     │   │(DHCP)     │
        └───────────┘   └───────────┘   └───────────┘
```

### Key Networking Concepts

**Bridge Network (`br-containers`)**:
- Acts as a virtual network switch
- Connects all containers together
- Has IP address 10.233.0.1 (serves as gateway for containers)
- Enables container-to-container communication

**NAT (Network Address Translation)**:
- Allows containers to access the internet
- Translates container private IPs to host's public IP
- Enabled on the host system for the br-containers interface

**DHCP (Dynamic Host Configuration Protocol)**:
- Automatically assigns IP addresses to containers
- Range: 10.233.0.50 - 10.233.0.150
- Also provides DNS and gateway information to containers
- We use **dnsmasq** as the DHCP server - it's a lightweight, easy-to-configure service that provides both DHCP and DNS forwarding in one package
- dnsmasq is the simplest way to set up DHCP for container networks without complex configuration

**DNS (Domain Name System) for Container-to-Container Communication**:
- Containers receive 10.233.0.1 (the host's dnsmasq) as their DNS server via DHCP
- This is **critical** for containers to resolve each other's hostnames
- **How it works:**
  1. When a container queries another container's hostname (e.g., `ping demo`), the query goes to dnsmasq at 10.233.0.1
  2. dnsmasq knows about container hostnames because it learns them from DHCP assignments
  3. dnsmasq returns the container's IP address (e.g., 10.233.0.52)
  4. When a container queries an internet hostname (e.g., `ping google.com`), dnsmasq forwards the query to upstream DNS servers (8.8.8.8, 8.8.4.4)
- **Why this configuration is essential:**
  - Without pointing containers to dnsmasq (10.233.0.1), containers would use external DNS (8.8.8.8) directly
  - External DNS servers don't know about your local container hostnames
  - Result: containers could reach the internet but couldn't ping each other by hostname
- Configured in `host-setup.nix` with: `dhcp-option = "option:dns-server,10.233.0.1";`

**IP Forwarding**:
- Kernel feature that allows the host to route packets between networks
- Required for containers to access the internet through NAT
- Enabled via sysctl setting: net.ipv4.ip_forward = 1

**⚠️ Imperative vs Declarative Containers - MUST KNOWS**:

This workshop uses **imperative containers** (created with `nixos-container create` command). This approach differs from **declarative containers** (defined in host's `/etc/nixos/configuration.nix`) in TWO critical ways:

| Aspect | Imperative Containers | Declarative Containers |
|--------|----------------------|------------------------|
| **Interface Name** | `eth0` | `host0` |
| **Bridge Connection** | Requires explicit `--bridge` flag | Automatic (from host config) |

**Why this matters:**

1. **Interface naming (`eth0` vs `host0`):**
   - Our `configuration.nix` matches `eth0` because we create imperative containers
   - If you were using declarative containers, you'd need to match `host0` instead
   - This is hardcoded in NixOS container infrastructure

2. **Bridge connection requirement:**
   - **Imperative**: MUST use `--bridge br-containers` when creating
     - Without it: isolated network (10.233.X.1), no DHCP, no connectivity
   - **Declarative**: Bridge configured in host's container definition
     - Automatically connected when container starts

**⚠️ CRITICAL: The `--bridge` flag**:
- When creating containers with `nixos-container create`, you MUST use `--bridge br-containers`
- Without this flag:
  - Container gets isolated network (10.233.X.1 per container)
  - Container CANNOT reach other containers
  - Container CANNOT reach dnsmasq DHCP server
  - Container CANNOT get an IP from our DHCP range
  - All networking fails!
- How it works:
  - Creates a veth pair (virtual ethernet cable)
  - One end goes inside container (appears as `eth0`)
  - Other end stays on host (named `vb-CONTAINERNAME`)
  - Host end is connected to `br-containers` bridge
  - This makes the container part of the bridge network

### What Each Component Enables

| Component | Container-to-Container | Container-to-Host | Internet Access |
|-----------|------------------------|-------------------|-----------------|
| Bridge    | ✓ Yes                  | ✓ Yes             | No              |
| NAT       | -                      | -                 | ✓ Yes           |
| IP Forward| -                      | -                 | ✓ Yes (required)|
| DHCP      | ✓ (assigns IPs)        | ✓ (provides GW)   | ✓ (provides DNS)|

---

## Step 0: Verify Host Prerequisites

Before creating containers, verify your NixOS host is properly configured to host and serve containers.

### Clone the Workshop Repository

```bash
git clone git@github.com:mybonk/mybonk-wiki.git
cd mybonk-wiki/workshop-8
```

### Verify Nix Flakes Are Enabled

```bash
# This should work without error:
nix flake show

# If you get "experimental feature 'flakes' not enabled":
# Add to /etc/nixos/configuration.nix:
# nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

### Check IP Forwarding on the Host

IP forwarding must be enabled at the kernel level of the Host for NAT to work:

```bash
# Check current setting (should output: 1)
cat /proc/sys/net/ipv4/ip_forward

# If it outputs 0, the host won't be able to serve the containers with access to 
# the internet. You need to integrate the configuration from host-setup.nix into the host's configuration (and don't forget to nixos-rebuild the system after the configuration change - might even be better to rebuild and reboot the host because it's deep into the kernel and rebooting might be a good idea).
```

**What this checks**: Whether the kernel allows packets routing between network interfaces (required for NAT and the containers to access the internet through the host connectivity).

### Check NAT Kernel Module

```bash
# Check that the module exists:
modinfo iptable_nat

# Verify iptable_nat module is available
lsmod | grep iptable_nat
# If module exists but isn't loaded, it will load when NAT is enabled
```

**What this checks**: Whether the kernel has NAT capabilities available.

### Check Network Interface

Identify your internet-facing network interface:

```bash
ip route | grep default

# Example output:
# default via 192.168.1.1 dev eth0 proto dhcp
#                                ^^^^
#                         This is your interface name
```

Common interface names (here `eth0`):
- `eth0`, `enp0s3`, `enp1s0` - Ethernet
- `wlan0`, `wlp2s0` - WiFi
- `br0` - Bridge (if already using one)

**What this checks**: Which network interface provides internet access (needed for NAT configuration).


**What this checks**: Whether your NixOS system is configured to supports flake-based configurations.

---

## Step 1: Configuration of the Host System

The host system needs to provide 4 things to all the containers: 

- bridge networking
- DHCP
- NAT
- IP forwarding

IMPORTANT: If any of these is not working the workshop may not continue.

### Edit host-setup.nix

Open `host-setup.nix` and update the external interface on line 29:

```nix
networking.nat.externalInterface = "eth0";  # Change to YOUR interface (as seen earlier, using `ip route | grep default`)
```

Replace `"eth0"` with the interface name you found in the prerequisites step.

### Apply Host Configuration

**Option A - Add to existing configuration:**

Edit `/etc/nixos/configuration.nix` and add:

```nix
{
  imports = [
    /absolute/path/to/mybonk-wiki/workshop-8/host-setup.nix
    # ... your other imports
  ];
}
```

Then rebuild:

```bash
sudo nixos-rebuild switch
```

**Option B - Flake-based system:**

If your system uses flakes, add to your system flake:

```nix
nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
  modules = [
    /absolute/path/to/mybonk-wiki/workshop-8/host-setup.nix
    # ... your other modules
  ];
};
```

Then rebuild:

```bash
sudo nixos-rebuild switch --flake .#yourhostname
```

### Verify Host Configuration

After rebuilding, verify the setup:

```bash
# 1. Check bridge interface was created
ip addr show br-containers
# Should show: inet 10.233.0.1/24

# 2. Verify IP forwarding is enabled
cat /proc/sys/net/ipv4/ip_forward
# Should output: 1

# 3. Check NAT rules exist
sudo iptables -t nat -L -n -v | grep MASQUERADE
# Should show MASQUERADE rule for br-containers

# 4. Verify DHCP server is running
systemctl status dnsmasq.service
# Should show: active (running)

# 5. Test bridge is reachable (should work)
ping 10.233.0.1
```

---

## Step 2: Understanding the Configuration Files

Let's understand the configuration structure.

### File: flake.nix

```nix
{
  description = "NixOS container configurations with dynamic CLI management";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }:
  let
    # Helper function to create container configuration
    # Only requires a hostname - DHCP assigns the IP automatically
    mkContainerConfig = { hostname }: {
      imports = [ ./configuration.nix ];

      # Pass container-specific parameters to the imported module
      _module.args.containerConfig = {
        inherit hostname;
      };

      # Container-specific settings (required for all containers)
      boot.isContainer = true;
      systemd.network.enable = true;
    };
  in
  {
    # Pre-defined container configurations
    # These can be created with: sudo nixos-container create NAME --flake .#NAME
    nixosConfigurations = {
      # Example containers - you can add more by copying this pattern
      demo = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ (mkContainerConfig { hostname = "demo"; }) ];
      };
    };
  };
}
```

**Key points**:
- Uses NixOS 25.05 (latest stable)
- `mkContainerConfig` function creates container configs with just a hostname
- Each container imports the shared `configuration.nix`
- Parameters are passed via `_module.args.containerConfig`
- Pre-define containers in `nixosConfigurations` for easy access

### File: configuration.nix

This is the shared configuration used by ALL containers. It's parameterized to accept a hostname.

**Networking configuration explained**:

```nix
# CONTAINER SETTING: Tells NixOS this is a container, not a full system
boot.isContainer = true;

# CONTAINER-TO-CONTAINER + CONTAINER-TO-HOST COMMUNICATION:
# Enables systemd-networkd for network management (required for containers)
systemd.network = {
  enable = true;

  # Configure the eth0 interface (container's network interface)
  networks."10-container-dhcp" = {
    # Match the container's network interface (named "eth0" for imperative containers)
    matchConfig.Name = "eth0";

    # INTERNET ACCESS: Enable DHCP to get IP, gateway, and DNS automatically
    networkConfig = {
      DHCP = "yes";  # Request IP address from host's DHCP server
    };

    # INTERNET ACCESS: Use DNS servers provided by DHCP
    dhcpV4Config = {
      UseDNS = true;      # Accept DNS servers from DHCP (enables internet resolution)
      UseRoutes = true;   # Accept default gateway from DHCP (enables internet routing)
    };
  };
};

# INTERNET ACCESS: Don't use host's resolv.conf (use DHCP-provided DNS instead)
# This is REQUIRED when the host uses systemd-resolved
networking.useHostResolvConf = lib.mkForce false;
```

**What enables what**:
- `boot.isContainer = true`: Required for container operation
- `systemd.network.enable = true`: Enables network management in container
- `DHCP = "yes"`: Gets IP from host (enables container-to-container and container-to-host)
- `UseDNS = true`: Gets DNS from DHCP (enables internet domain name resolution)
- `UseRoutes = true`: Gets gateway from DHCP (enables internet routing via NAT)
- `useHostResolvConf = false`: Uses DHCP DNS instead of host's (required for systemd-resolved hosts)

### File: manage-containers.sh

The bash script provides convenient wrapper commands for managing containers. For detailed usage information:

```bash
sudo ./manage-containers.sh --help
```

---

## Step 3: Create Containers

Now let's create some containers using the management script (don't forget to run `chmod +x manage-containers.sh` to make it executable).

**⚠️ Important:** The `manage-containers.sh` script automatically uses `--bridge br-containers` when creating containers. This is **crucial** - without it, containers wouldn't be able to connect to the bridge network nor get DHCP IPs. If you create containers manually with `nixos-container create`, you MUST include `--bridge br-containers`.

**Quick examples** (copy and paste to try):

```bash
# Create container with custom name
sudo ./manage-containers.sh create mycont

# Create container with auto-generated name
sudo ./manage-containers.sh create

# Create 3 containers with random names
sudo ./manage-containers.sh create -n 3

# List all containers (with output shown below)
sudo ./manage-containers.sh list
```

Output of `list` command:
```
================================
NixOS Containers
================================

Name            Status    IP Address         Created
----            ------    ----------         -------
mycont          up        10.233.0.50        2025-02-11 14:01
web             up        10.233.0.72        2025-02-11 14:21
db              up        10.233.0.82        2025-02-12 14:22
a3f2            up        10.233.0.78        2025-02-11 14:14
7d91            up        10.233.0.67        2025-02-24 14:24

Total containers: 5
```

---

## Step 4: Test Container Connectivity

Verify that containers can communicate with each other, the host, and the internet.

### Access a Container

```bash
# Get root shell in container
sudo nixos-container root-login mycont

# Or use the script
sudo ./manage-containers.sh shell mycont
```

### Test Container-to-Host Communication

From inside the container:

```bash
ping 10.233.0.1
```

**Why this works**: The container's DHCP configuration sets the host's bridge IP as the gateway.

### Test Container-to-Container Communication

From inside one container:

```bash
# Get IP of another container first (from host): sudo ./manage-containers.sh ip web

ping 10.233.0.51  # Replace with actual IP from "list" command


# You can even ping by container host name because the DNS is also resolved by the bridge

ping mycont
```

**Why this works**: The bridge network connects all containers like a virtual switch. It also benefits from DNS resolution.

### Test Internet Access

From inside the container:

```bash
# Ping a public DNS
ping 8.8.8.8

# Test DNS resolution and HTTP
curl -I https://www.gnu.org/
```

**Why this works**:
1. Container has default gateway (10.233.0.1) from DHCP
2. Host has IP forwarding enabled
3. Host has NAT enabled to translate container traffic
4. Container has DNS servers (8.8.8.8) from DHCP

### Troubleshooting Connectivity

**Container has no IP address**:
- **MOST COMMON**: Container not connected to bridge
  - Check: `bridge link show | grep vb-mycont` (should show something)
  - If nothing shows, the container wasn't created with `--bridge` flag
  - Fix: Destroy and recreate: `sudo ./manage-containers.sh destroy mycont && sudo ./manage-containers.sh create mycont`
- Check dnsmasq is running: `systemctl status dnsmasq`
- Check container interface status: `sudo nixos-container run mycont -- networkctl list` (should show `routable`, not `degraded`)

**Container-to-host ping fails**:
- Check bridge interface: `ip addr show br-containers` (should show 10.233.0.1)
- Verify container got IP: `sudo nixos-container run mycont -- ip addr show eth0`

**Container-to-container ping fails**:
- Both containers must be on same bridge (they are by default)
- Check both containers got IPs: `sudo ./manage-containers.sh list`
- Verify bridge is up: `ip link show br-containers` (should show state UP)

**Internet access fails**:
- Check IP forwarding: `cat /proc/sys/net/ipv4/ip_forward` (must be 1)
- Check NAT rules: `sudo iptables -t nat -L -n -v | grep MASQUERADE`
- Verify container has gateway: `sudo nixos-container run mycont -- ip route`
- Check DNS: `sudo nixos-container run mycont -- cat /etc/resolv.conf`

---

## Step 5: Container Lifecycle

### Stop a Container

```bash
sudo ./manage-containers.sh stop mycont

# Or directly:
sudo nixos-container stop mycont
```

The container is stopped but all data remains in `/var/lib/nixos-containers/mycont`.

### Start a Container

```bash
sudo ./manage-containers.sh start mycont

# Or directly:
sudo nixos-container start mycont
```

### Update Container Configuration

If you modify `configuration.nix`, update running containers:

```bash
# Update container to use new configuration
sudo nixos-container update mycont --flake .#mycont

# Or update and restart
sudo nixos-container update mycont --flake .#mycont
sudo nixos-container restart mycont
```

### Destroy a Container

Permanently delete a container and all its data:

```bash
sudo ./manage-containers.sh destroy mycont

# Or directly:
sudo nixos-container destroy mycont
```

**Warning**: This deletes all data in the container. The `/nix/store` is shared, so packages aren't duplicated or deleted.

### Quick Rebuild Pattern

For development, this workflow is common:

```bash
# 1. Edit configuration.nix
vim configuration.nix

# 2. Destroy old container
sudo ./manage-containers.sh destroy test

# 3. Create new container with updated config
sudo ./manage-containers.sh create test

# 4. Test your changes
sudo ./manage-containers.sh shell test
```

---

## Step 6: Access Containers via SSH

Containers are configured with SSH access for both `root` and `operator` users. You can connect from and to any of the containers and the host.

### SSH Keys

The configuration includes SSH public keys for:
- `root` user
- `operator` user (password: "operator")

**For your own lab**: Replace these keys in `configuration.nix` with your own:

```nix
users.users.root.openssh.authorizedKeys.keys = [
  "ssh-ed25519 YOUR_KEY_HERE your-email@example.com"
];
```

Generate your own key if needed:

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
cat ~/.ssh/id_ed25519.pub  # Copy this public key
```

---

## Going Further: Use Cases

Now that you understand container management, here are practical applications.

### Development Environment

Create isolated development environments:

```bash
# Python development
sudo ./manage-containers.sh create python-dev

# Node.js development
sudo ./manage-containers.sh create node-dev

# Rust development
sudo ./manage-containers.sh create rust-dev
```

Customize `configuration.nix` to add language-specific packages:

```nix
environment.systemPackages = with pkgs; [
  # Default packages
  vim curl git

  # Add your development tools
  python311
  nodejs
  rustc cargo
];
```

### Multi-Service Application

Deploy a multi-container application:

```bash
sudo ./manage-containers.sh create frontend
sudo ./manage-containers.sh create backend
sudo ./manage-containers.sh create database
sudo ./manage-containers.sh create cache
```

Each container can run a different service, all communicating over the private network.

### Testing and CI/CD

Create ephemeral test environments:

```bash
#!/usr/bin/env bash
# Automated test script

# Create test container
sudo ./manage-containers.sh create test-env

# Run tests inside
sudo nixos-container run test-env -- /path/to/test-script.sh

# Cleanup
sudo ./manage-containers.sh destroy test-env
```

### Learning and Experimentation

Create throwaway containers for experimentation:

```bash
# Try out a package
sudo ./manage-containers.sh create
# Note the auto-generated name (e.g., "a3f2"), then:
sudo nixos-container root-login a3f2
# ... experiment ...
exit
sudo ./manage-containers.sh destroy a3f2
```

---

## Understanding What You've Learned

This workshop covered several important concepts:

### Container Networking Fundamentals

You now understand:
- **Bridge networks**: Virtual switches that connect containers
- **NAT**: How containers access the internet through the host
- **DHCP**: Automatic IP address assignment
- **IP forwarding**: Kernel routing between network interfaces

### NixOS Container Architecture

You've learned:
- **Parameterizable configurations**: One config file, multiple instances
- **Flake-based management**: Declarative container definitions
- **Shared Nix store**: Containers don't duplicate packages
- **CLI container lifecycle**: Create, start, stop, destroy without host rebuilds

### Network Connectivity Types

You verified three types of connectivity:
1. **Container-to-Host**: Via bridge network (10.233.0.1)
2. **Container-to-Container**: Via bridge network (same subnet)
3. **Container-to-Internet**: Via NAT and IP forwarding

### Practical Skills

You can now:
- Set up NixOS host for container networking
- Create containers dynamically from the command line
- Troubleshoot container network connectivity
- Manage container lifecycle independently
- Access containers via SSH or direct shell

---

## Best Practices for Lab Environments

### Resource Management

Containers are lightweight but still consume resources:

```bash
# Check disk usage
du -sh /var/lib/nixos-containers/*

# Check running containers
sudo ./manage-containers.sh list

# Stop unused containers
sudo ./manage-containers.sh stop unused-container
```


### Cleanup After Experiments

Clean up regularly:

```bash
# List all containers
sudo ./manage-containers.sh list

# Destroy containers you don't need
sudo ./manage-containers.sh destroy old-test

# Garbage collect Nix store
nix-collect-garbage -d
```

---

## Troubleshooting Common Issues


### Network Not Working

```bash
# Container can't ping host
# Check: Bridge exists and has IP
ip addr show br-containers  # Should show 10.233.0.1

# Container can't ping internet
# Check: IP forwarding enabled
cat /proc/sys/net/ipv4/ip_forward  # Should be 1

# Check: NAT rules exist
sudo iptables -t nat -L -n -v | grep MASQUERADE

# Container has no IP
# Check: DHCP server running
systemctl status dnsmasq
```

### SSH Access Issues

```bash
# Can't SSH to container
# Check: Container has IP
sudo ./manage-containers.sh ip container-name

# Check: SSH service running in container
sudo nixos-container run container-name -- systemctl status sshd

# Check: Correct SSH key is configured
sudo nixos-container run container-name -- cat /root/.ssh/authorized_keys
```

## Additional Resources

### Official NixOS Documentation

- [NixOS Manual - Containers](https://nixos.org/manual/nixos/stable/#ch-containers)
- [NixOS Manual - Networking](https://nixos.org/manual/nixos/stable/#sec-networking)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)

### Networking Resources

- [IP Subnetting Guide](https://www.subnet-calculator.com/)
- [Understanding NAT](https://www.karlrupp.net/en/computer/nat_tutorial)
- [Linux IP Forwarding](https://linuxconfig.org/how-to-turn-on-off-ip-forwarding-in-linux)

### Community Resources

- [NixOS Discourse](https://discourse.nixos.org/)
- [NixOS Reddit](https://www.reddit.com/r/NixOS/)
- [NixOS Wiki - Containers](https://nixos.wiki/wiki/NixOS_Containers)

---

## What You've Accomplished

Congratulations! You have:

- ✓ Set up NixOS host with bridge networking and NAT
- ✓ Created containers dynamically from the command line
- ✓ Understood container networking architecture (bridge, NAT, DHCP)
- ✓ Verified container-to-container, container-to-host, and internet connectivity
- ✓ Managed container lifecycle (create, start, stop, destroy)
- ✓ Accessed containers via SSH and root-login
- ✓ Learned to troubleshoot common container networking issues
- ✓ Used parameterizable configuration for multiple containers

---

## Next Steps

1. **Experiment**: Create containers for different use cases
2. **Customize**: Add your own packages and services to configuration.nix
3. **Automate**: Write scripts to automate container creation for projects
4. **Network**: Explore advanced networking (VLANs, multiple bridges)
5. **Services**: Deploy multi-container applications (web + db + cache)
6. **Monitor**: Set up monitoring and logging for containers

Happy container hacking!

---

## Notes

**Workshop Duration**: 30-45 minutes
**Difficulty**: Intermediate
**NixOS Version**: 25.05
**Network Range**: 10.233.0.0/24
