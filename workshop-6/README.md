---
layout: default
title: Workshop 6
nav_order: 7
---

# Manage NixOS Containers via CLI

## Overview

This workshop demonstrates how to create and manage NixOS containers entirely via command-line tools, without embedding them in your host configuration. Unlike previous workshops, this approach gives you the flexibility to create, destroy, and manage containers independently from your host system rebuilds.

**Key Innovation**: All containers share ONE configuration.nix file containing all common settings (networking, packages, SSH, etc). Only unique parameters (hostname, IP address) differ and are defined in flake.nix.

**What you'll learn:**
- Set up bridge networking and NAT on NixOS host
- Create containers using nixos-container CLI commands
- Share configuration across multiple containers with parameterization
- Manage container lifecycle (start, stop, update, destroy)
- Test container-to-container and internet connectivity
- Access containers via SSH and root-login

**Prerequisites:**
- NixOS system (host machine)
- Basic understanding of Nix flakes
- Familiarity with NixOS containers (See [workshop-1](../workshop-1))
- Basic networking knowledge

**Time:** ~5-15 minutes (setup + container creation)

---

## Architecture Overview

### Design Principles

1. **Separation**: Host setup is independent from container definitions
2. **CLI Management**: Containers created, started, stopped via nixos-container commands
3. **Shared Config**: One configuration.nix, different parameters per container
4. **Declarative Parameters**: Unique values (hostname, IP) in flake.nix

### File Structure

- **host-setup.nix**: Host prerequisites ONLY (bridge, NAT, IP forwarding) - NO container definitions
- **flake.nix**: Container configurations with unique parameters (hostname, IP) for CLI usage
- **configuration.nix**: **SHARED** parameterized module used by ALL containers
- **create-container.sh**: Helper script for automated container creation
- **README.md**: This file

### Network Architecture

**IP Address Scheme:**
```
Host System:        10.100.0.1/24    (bridge: br-containers)
Container 1:        10.100.0.10/24   (hostname: container1)
Container 2:        10.100.0.20/24   (hostname: container2)
Gateway:            10.100.0.1
DNS:                8.8.8.8, 8.8.4.4
```

**Network Components:**
- **Bridge**: br-containers - Virtual switch for containers
- **NAT**: Enabled on host for internet access
- **IP Forwarding**: Enabled via sysctl
- **Firewall**: Disabled for maximum openness (development/testing only)

---

## Step 1: Clone the Workshop Repository

Clone the workshop repository containing the configuration:

```bash
git clone git@github.com:mybonk/mybonk-wiki.git
cd mybonk-wiki/workshop-6
```

The repository contains:
- `host-setup.nix` - Host prerequisites configuration
- `flake.nix` - Container definitions
- `configuration.nix` - Shared container configuration
- `create-container.sh` - Helper script for container creation

---

## Step 2: Host Prerequisites Setup

First, set up the host machine with bridge networking and NAT.

### Identify Your Internet Interface

```bash
ip route | grep default
```

This will show output like:
```
default via 192.168.1.1 dev eth0 proto dhcp
```

The interface name (e.g., `eth0`, `wlan0`, `enp0s3`) is what you need.

### Edit host-setup.nix

Open `host-setup.nix` and update line 29 with your actual interface:

```nix
networking.nat.externalInterface = "eth0";  # Change to your interface (e.g., wlan0, enp0s3)
```

### Apply Host Configuration

**Option A - Add to your existing NixOS configuration:**

Edit your `/etc/nixos/configuration.nix` and add the import:

```nix
imports = [
  /absolute/path/to/host-setup.nix
  # ... your other imports
];
```

Then rebuild:

```bash
sudo nixos-rebuild switch
```

**Option B - Import in your flake:**

If you use flakes for your system configuration:

```nix
# In your system flake.nix:
{
  nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
    modules = [
      ./host-setup.nix
      # ... your other modules
    ];
  };
}
```

Then rebuild:

```bash
sudo nixos-rebuild switch --flake .#yourhostname
```

### Verify Host Setup

After rebuilding, verify the bridge was created:

```bash
# Check bridge exists
ip addr show br-containers

# Should show:
# br-containers: <BROADCAST,MULTICAST,UP,LOWER_UP> ...
#     inet 10.100.0.1/24 ...
```

Check IP forwarding is enabled:

```bash
cat /proc/sys/net/ipv4/ip_forward  # Should output: 1
```

Check NAT rules exist:

```bash
sudo iptables -t nat -L -n -v | grep MASQUERADE
```

---

## Step 3: Create Containers Using the Helper Script

Now we'll create containers using the nixos-container command-line tool.

Make the script executable:

```bash
chmod +x create-container.sh
```

Create container1:

```bash
sudo ./create-container.sh container1 10.100.0.10
```

Create container2:

```bash
sudo ./create-container.sh container2 10.100.0.20
```

### Verify Container Creation

Check container status:

```bash
sudo nixos-container list
sudo nixos-container status container1
sudo nixos-container status container2
```

---

## Step 4: Test Container Connectivity

### Test 1: Access Containers

**Interactive shell access:**

```bash
# Access container1
sudo nixos-container root-login container1

# Inside container1, verify:
hostname  # Should show: container1
ip addr   # Should show: 10.100.0.10/24
exit
```

**Run single command:**

```bash
sudo nixos-container run container1 -- hostname
sudo nixos-container run container2 -- ip addr show eth0
```

### Test 2: Container-to-Container Communication

Test ping between containers:

```bash
# From host, test container1 to container2
sudo nixos-container run container1 -- ping -c 4 10.100.0.20
sudo nixos-container run container1 -- ping -c 4 container2

# And vice versa
sudo nixos-container run container2 -- ping -c 4 10.100.0.10
sudo nixos-container run container2 -- ping -c 4 container1
```

### Test 3: Container-to-Host Communication

```bash
# Ping host bridge from containers
sudo nixos-container run container1 -- ping -c 4 10.100.0.1
sudo nixos-container run container2 -- ping -c 4 10.100.0.1
```

### Test 4: Internet Connectivity

**Test ICMP (ping):**

```bash
sudo nixos-container run container1 -- ping -c 4 8.8.8.8
sudo nixos-container run container1 -- ping -c 4 google.com
```

**Test DNS resolution:**

```bash
sudo nixos-container run container1 -- nslookup google.com
sudo nixos-container run container2 -- dig cloudflare.com
```

**Test HTTP/HTTPS:**

```bash
sudo nixos-container run container1 -- curl -I https://google.com
sudo nixos-container run container2 -- wget -O- https://icanhazip.com
```

### Test 5: SSH Access

**From host to container:**

```bash
# SSH to container1 (password: nixos)
ssh root@10.100.0.10

# SSH to container2 (password: nixos)
ssh root@10.100.0.20
```

**From container to container:**

```bash
sudo nixos-container root-login container1

# Inside container1:
ssh root@10.100.0.20  # Access container2
# Or:
ssh root@container2
```

---

## Container Management

### Essential Commands

```bash
# List all containers
sudo nixos-container list

# Start/Stop
sudo nixos-container start container1
sudo nixos-container stop container1
sudo nixos-container restart container1

# Check status
sudo nixos-container status container1

# Access container (interactive shell)
sudo nixos-container root-login container1

# Run single command
sudo nixos-container run container1 -- COMMAND

# Update container configuration
sudo nixos-container update container1 --flake .#container1

# Destroy container
sudo nixos-container stop container1
sudo nixos-container destroy container1
```

### Updating Container Configuration

After modifying `flake.nix` or `configuration.nix`:

```bash
# Update container1 to latest configuration
sudo nixos-container update container1 --flake .#container1

# Update container2
sudo nixos-container update container2 --flake .#container2

# Restart to apply changes
sudo nixos-container restart container1
sudo nixos-container restart container2
```

### Monitoring Container Resources

```bash
# CPU and memory usage (all containers)
systemd-cgtop

# Specific container status
systemctl status container@container1

# Container logs
sudo journalctl -u container@container1 -f
```

---

## Adding More Containers

### Step 1: Add Container Definition

Edit `flake.nix` and add before the closing braces:

```nix
container3 = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    (mkContainerConfig {
      hostname = "container3";
      ipAddress = "10.100.0.30";
    })
  ];
};
```

### Step 2: Create and Start Container

**Using helper script:**

```bash
sudo ./create-container.sh container3 10.100.0.30
```

**Manual creation:**

```bash
# Create container3
sudo nixos-container create container3 \
  --flake .#container3 \
  --config-file /dev/null

# Configure networking
sudo mkdir -p /etc/nixos-containers/container3
sudo tee /etc/nixos-containers/container3.conf << 'EOF'
PRIVATE_NETWORK=yes
HOST_BRIDGE=br-containers
LOCAL_ADDRESS=10.100.0.30/24
EOF

# Start container3
sudo nixos-container start container3

# Enable auto-start
sudo systemctl enable container@container3

# Test connectivity
sudo nixos-container run container3 -- ping -c 4 google.com
```

**That's it!** No host rebuild needed.

---

## Troubleshooting

### Containers Can't Reach Each Other

**Check bridge exists:**

```bash
ip addr show br-containers
```

**Verify container IPs:**

```bash
sudo nixos-container run container1 -- ip addr show eth0
sudo nixos-container run container2 -- ip addr show eth0
```

**Check routing in container:**

```bash
sudo nixos-container run container1 -- ip route
```

**Test connectivity:**

```bash
sudo nixos-container run container1 -- ping -c 4 10.100.0.20
```

### No Internet Access

**Verify IP forwarding:**

```bash
cat /proc/sys/net/ipv4/ip_forward  # Should be 1
```

**Check NAT rules:**

```bash
sudo iptables -t nat -L -n -v | grep MASQUERADE
```

**Verify external interface:**

```bash
ip route | grep default
```

Ensure `externalInterface` in host-setup.nix matches actual interface.

**Test DNS from container:**

```bash
sudo nixos-container run container1 -- nslookup google.com
```

**Test gateway reachability:**

```bash
sudo nixos-container run container1 -- ping -c 4 10.100.0.1
```

### Container Won't Start

**Check logs:**

```bash
sudo journalctl -u container@container1 -xe
```

**Verify configuration:**

```bash
nix flake check
```

**Check container configuration:**

```bash
cat /etc/nixos-containers/container1.conf
```

Should contain:
```
PRIVATE_NETWORK=yes
HOST_BRIDGE=br-containers
LOCAL_ADDRESS=10.100.0.10/24
```

**Manually restart systemd service:**

```bash
sudo systemctl restart container@container1
sudo systemctl status container@container1
```

### Bridge Not Created

**Verify host configuration applied:**

```bash
ip link show br-containers
```

**Manually restart networking:**

```bash
sudo systemctl restart network-addresses-br-containers.service
```

**Rebuild host configuration:**

```bash
sudo nixos-rebuild switch
```

---

## Security Notes

### Default Configuration Security

**WARNING: Current configuration is for development/testing:**
- Root password: "nixos"
- SSH password authentication enabled
- Firewalls disabled
- PermitRootLogin enabled

### Production Hardening

For production, modify configuration.nix:

```nix
# Remove password
users.users.root.hashedPassword = null;
users.users.root.password = null;

# SSH keys only
services.openssh.settings.PasswordAuthentication = false;
users.users.root.openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAAC3NzaC... your-email@example.com"
];

# Enable firewall
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ 22 ];
};
```

Update containers:

```bash
sudo nixos-container update container1 --flake .#container1
sudo nixos-container update container2 --flake .#container2
sudo nixos-container restart container1
sudo nixos-container restart container2
```

---

## Advanced Usage

### Accessing Container Filesystem

Container root filesystem location:

```bash
/var/lib/nixos-containers/container1/
/var/lib/nixos-containers/container2/
```

Access files:

```bash
sudo ls -la /var/lib/nixos-containers/container1/etc/
sudo cat /var/lib/nixos-containers/container1/etc/hostname
```

### Container Backup and Migration

**Backup container:**

```bash
sudo tar czf container1-backup.tar.gz /var/lib/nixos-containers/container1/
```

**Restore container:**

```bash
sudo nixos-container destroy container1
sudo tar xzf container1-backup.tar.gz -C /
sudo nixos-container start container1
```

### Network Traffic Monitoring

**Monitor bridge traffic:**

```bash
sudo tcpdump -i br-containers
```

**Monitor specific container:**

```bash
# Find container's veth interface
ip link | grep veth

# Monitor that interface
sudo tcpdump -i veth-container1
```

---

## Version Compatibility

- **NixOS**: 25.05
- **nixpkgs**: nixos-25.05 channel
- **Nix**: 2.32.0+ (with flakes)

---

## References

- [NixOS Containers](https://nixos.org/manual/nixos/stable/#ch-containers)
- [nixos-container command](https://nixos.org/manual/nixos/stable/#sec-container-management)
- [Networking](https://nixos.org/manual/nixos/stable/#sec-networking)
- [Flakes](https://nixos.wiki/wiki/Flakes)
