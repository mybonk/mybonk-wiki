# Host Prerequisites for NixOS Container Networking
# This configuration sets up the host system to support NixOS containers with:
#   - Bridge network for container connectivity
#   - NAT for container internet access
#   - DHCP server for automatic IP assignment
#   - IP forwarding for routing
#
# This file should be imported into your host's NixOS configuration.
# After importing, rebuild with: sudo nixos-rebuild switch

{ config, pkgs, lib, ... }:

{
  # ============================================================================
  # CONTAINER SUPPORT
  # ============================================================================

  # Enable NixOS container support in the kernel
  # This loads necessary kernel modules and sets up container infrastructure
  boot.enableContainers = true;

  # ============================================================================
  # BRIDGE NETWORK CONFIGURATION
  # ============================================================================

  # Create a virtual bridge network for containers
  # A bridge acts like a virtual network switch that connects containers together
  # Container interfaces are automatically added to this bridge when created
  networking.bridges = {
    "br-containers" = {
      # Start with no physical interfaces attached
      # Container virtual interfaces (veth pairs) are added automatically
      interfaces = [];
    };
  };

  # Assign IP address to the bridge interface
  # This IP serves as:
  #   1. The gateway for containers (their default route)
  #   2. The DHCP server address
  #   3. The host's address on the container network
  networking.interfaces.br-containers = {
    ipv4.addresses = [{
      # Host's IP on the container network
      address = "10.233.0.1";

      # CIDR prefix length (24 = 255.255.255.0 subnet mask)
      # This gives us 254 usable addresses: 10.233.0.1 - 10.233.0.254
      prefixLength = 24;
    }];
  };

  # ============================================================================
  # NAT CONFIGURATION - ENABLES INTERNET ACCESS FOR CONTAINERS
  # ============================================================================

  # Configure Network Address Translation (NAT)
  # NAT allows containers (with private IPs) to access the internet
  # by translating their private IPs to the host's public IP
  networking.nat = {
    # Enable NAT functionality
    enable = true;

    # Internal interfaces that need internet access (containers)
    # Traffic from br-containers will be NATted to the external interface
    internalInterfaces = [ "br-containers" ];

    # External interface that provides internet access
    # This should match your actual internet-facing interface
    # Find your interface with: ip route | grep default
    # Common names: eth0, enp1s0, enp3s0, wlan0, wlp2s0
    externalInterface = "enp3s0";
  };

  # ============================================================================
  # IP FORWARDING - REQUIRED FOR NAT
  # ============================================================================

  # Enable IP forwarding at the kernel level
  # This allows the host to route packets between network interfaces
  # Required for containers to access internet through NAT
  boot.kernel.sysctl = {
    # Enable IPv4 packet forwarding
    # 0 = disabled (default), 1 = enabled
    # Without this, NAT won't work and containers can't reach the internet
    "net.ipv4.ip_forward" = 1;
  };

  # ============================================================================
  # FIREWALL CONFIGURATION
  # ============================================================================

  # Lab environment: Disable firewall for maximum openness
  # This allows unrestricted access between host and containers
  # and between containers and the internet
  #
  # NOTE: In production, you would:
  #   1. Keep firewall enabled (networking.firewall.enable = true)
  #   2. Allow specific interfaces: networking.firewall.trustedInterfaces = [ "br-containers" ]
  #   3. Configure specific port rules as needed
  networking.firewall.enable = false;

  # ============================================================================
  # DHCP SERVER CONFIGURATION
  # ============================================================================

  # Enable dnsmasq as DHCP and DNS server for containers
  # dnsmasq provides:
  #   1. DHCP service (assigns IP addresses to containers)
  #   2. DNS service (provides name resolution for containers)
  services.dnsmasq = {
    enable = true;

    settings = {
      # Only listen on the container bridge interface
      # This prevents dnsmasq from interfering with host's network
      interface = "br-containers";

      # Only bind to specified interfaces (don't listen on all interfaces)
      # This is a security measure to prevent DHCP on other networks
      bind-interfaces = true;

      # DHCP range configuration
      # Assigns IPs from 10.233.0.50 to 10.233.0.150
      # Lease time: 12 hours (containers will renew before expiration)
      # This gives us 101 available IP addresses for containers
      dhcp-range = "10.233.0.50,10.233.0.150,12h";

      # Local domain name for containers
      # Containers can use fully qualified names like: container1.containers.local
      domain = "containers.local";

      # Don't read /etc/resolv.conf from host
      # We'll provide DNS servers explicitly below
      no-resolv = true;

      # Don't read /etc/hosts from host
      # Containers will use DHCP-provided DNS instead
      no-hosts = true;

      # Upstream DNS servers for internet name resolution
      # These are provided to containers via DHCP
      # Using Google's public DNS servers (reliable and fast)
      # Alternative: [ "1.1.1.1" "1.0.0.1" ] for Cloudflare DNS
      server = [ "8.8.8.8" "8.8.4.4" ];

      # Optional: Enable DHCP logging for debugging
      # Uncomment to see DHCP assignments in system logs:
      # log-dhcp = true;
    };
  };

  # ============================================================================
  # NIX CONFIGURATION
  # ============================================================================

  # Enable Nix flakes and nix-command
  # Required for using flake-based container configurations
  # The manage-containers.sh script uses flakes to create containers
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ============================================================================
  # SYSTEM VERSION
  # ============================================================================

  # NixOS state version - should match your NixOS release
  # This ensures system compatibility
  # DO NOT change this unless upgrading to a new NixOS release
  system.stateVersion = "25.05";
}

# ============================================================================
# VERIFICATION COMMANDS
# ============================================================================
# After applying this configuration (sudo nixos-rebuild switch), verify with:
#
# 1. Check bridge was created:
#    ip addr show br-containers
#    (should show: inet 10.233.0.1/24)
#
# 2. Verify IP forwarding is enabled:
#    cat /proc/sys/net/ipv4/ip_forward
#    (should output: 1)
#
# 3. Check NAT rules exist:
#    sudo iptables -t nat -L -n -v | grep MASQUERADE
#    (should show MASQUERADE rule)
#
# 4. Verify DHCP server is running:
#    systemctl status dnsmasq.service
#    (should show: active (running))
#
# 5. Test bridge connectivity:
#    ping -c 2 10.233.0.1
#    (should succeed)
