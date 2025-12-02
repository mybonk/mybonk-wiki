# Generic NixOS container configuration
# This module is shared by all containers created from this workshop
# IP addresses are assigned automatically via DHCP from the host
# Hostname is automatically set by nixos-container to match the container name
#
# IMPORTANT: This configuration is for IMPERATIVE containers
# (created with nixos-container create --bridge br-containers)
# If using declarative containers (in host config), change:
#   - matchConfig.Name from "eth0" to "host0"
#   - No --bridge flag needed (configured in host container definition)

{ config, pkgs, lib, ... }:

{
  # ============================================================================
  # CONTAINER-SPECIFIC SETTINGS
  # ============================================================================

  # REQUIRED: Tells NixOS this is a container, not a full system
  # This setting:
  #   - Disables bootloader configuration (containers don't boot like VMs)
  #   - Skips kernel module loading (containers share host kernel)
  #   - Optimizes for container environment
  boot.isContainer = true;

  # ============================================================================
  # NETWORK CONFIGURATION - ENABLES ALL CONNECTIVITY
  # ============================================================================

  # CONTAINER-TO-CONTAINER + CONTAINER-TO-HOST + INTERNET ACCESS:
  # Enable systemd-networkd for network interface management
  # This is REQUIRED for containers to have working networking
  systemd.network = {
    enable = true;

    # Configure the container's network interface
    # This configuration:
    #   1. Requests an IP address via DHCP from the host
    #   2. Configures DNS for internet domain resolution
    #   3. Sets up default gateway for internet routing
    #
    # Network name "10-container-dhcp":
    #   - The "10-" prefix ensures this network config loads early (systemd-networkd processes in numerical order)
    #   - "container-dhcp" is descriptive of what this config does
    #   - This name can be anything, it's just a systemd-networkd unit identifier
    networks."10-container-dhcp" = {
      # Match the container's virtual ethernet interface
      #
      # WHY "eth0*"?
      #   - IMPERATIVE containers (nixos-container create) use "eth0"
      #   - DECLARATIVE containers (in host config) use "host0"
      #   - This is hardcoded in NixOS - not configurable
      #   - Since we create containers imperatively, we match "eth0*"
      #   - The wildcard (*) matches eth0 and variations like "eth0@if40"
      #   - The @ifXX suffix indicates a veth pair - the number is the host-side interface index
      #   - On the host side, the interface is named something like "vb-<container-name>" or "ve-<container-name>"
      matchConfig.Name = "eth0*";

      # ENABLES: Container-to-Container, Container-to-Host, Internet Access
      # Request IP address, gateway, and DNS via DHCP from host
      networkConfig = {
        DHCP = "yes";  # Automatically obtain network configuration
      };

      # ENABLES: Internet Access (DNS resolution and routing)
      # Configure how DHCP information is used
      dhcpV4Config = {
        # INTERNET ACCESS: Accept DNS servers from DHCP
        # Without this, container can't resolve domain names (e.g., google.com)
        # Host provides DNS servers (typically 8.8.8.8, 8.8.4.4) via DHCP
        UseDNS = true;

        # INTERNET ACCESS: Accept default gateway from DHCP
        # Without this, container can't route packets to the internet
        # Host provides its bridge IP (10.233.0.1) as the gateway
        UseRoutes = true;
      };
    };
  };

  # INTERNET ACCESS: Don't inherit host's resolv.conf
  # This is CRITICAL when the host uses systemd-resolved
  # Without this, containers may not resolve DNS correctly
  # Instead, use the DNS servers provided by DHCP (configured above)
  networking.useHostResolvConf = lib.mkForce false;

  # IMPORTANT: Disable old-style DHCP when using systemd-networkd
  # systemd-networkd (configured above) handles DHCP - don't use both!
  # Having both enabled causes conflicts in network management
  networking.useDHCP = lib.mkForce false;

  # CRITICAL: Disable systemd-resolved in containers
  # systemd-resolved intercepts DNS and uses 127.0.0.53 as nameserver
  # This breaks container-to-container hostname resolution
  # We want containers to use DNS from DHCP (dnsmasq at 10.233.0.1)
  services.resolved.enable = false;


  # Lab environment: Disable firewall for maximum connectivity
  # In a lab, we want unrestricted access for testing
  # NOTE: In production, configure firewall rules appropriately
  networking.firewall.enable = false;

  # ============================================================================
  # USER CONFIGURATION
  # ============================================================================

  # Root user configuration
  users.users.root = {
    # Lab environment: Set simple password for easy access
    # Default: "nixos"
    password = "nixos";

    # SSH public keys for root user (copied from workshop-1)
    # Replace these with your own keys for secure access
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILmCXubTHcQrMO+LFTmWq6sN8L7gJEmyu+mL8DR0NvBf root@nixos"
      # Add your own key here:
      # "ssh-ed25519 AAAAC3NzaC... your-email@example.com"
    ];
  };

  # Operator user configuration (standard non-root user)
  users.users.operator = {
    # Create as a normal user (not system user)
    isNormalUser = true;

    # Lab environment: Set simple password
    # Default: "operator"
    password = "operator";

    # Grant sudo access for administrative tasks
    extraGroups = [ "wheel" ];

    # SSH public keys for operator user (copied from workshop-1)
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILmCXubTHcQrMO+LFTmWq6sN8L7gJEmyu+mL8DR0NvBf operator@nixos"
      # Add your own key here:
      # "ssh-ed25519 AAAAC3NzaC... your-email@example.com"
    ];
  };

  # ============================================================================
  # SSH SERVICE CONFIGURATION
  # ============================================================================

  # Enable OpenSSH server for remote access
  services.openssh = {
    enable = true;

    settings = {
      # Lab environment: Allow root login for convenience
      PermitRootLogin = "yes";

      # Lab environment: Allow password authentication (in addition to keys)
      # This allows login with the passwords set above
      PasswordAuthentication = true;
    };
  };

  # ============================================================================
  # SYSTEM PACKAGES
  # ============================================================================

  # Essential command-line tools for container management and debugging
  environment.systemPackages = with pkgs; [
    # Network diagnostics
    iputils   # ping, traceroute - test connectivity
    iproute2  # ip command - view/configure network interfaces
    nettools  # ifconfig, netstat - legacy network tools
    bind      # nslookup, dig - DNS debugging

    # Network utilities
    curl      # HTTP client - test web connectivity
    wget      # Download files from internet

    # System utilities
    vim       # Text editor
    htop      # Process monitor
    btop      # Process monitor
    git       # Version control
  ];

  # ============================================================================
  # SYSTEM VERSION
  # ============================================================================

  # NixOS state version - should match the NixOS release being used
  # This ensures system compatibility and stable behavior
  # DO NOT change this unless upgrading to a new NixOS release
  system.stateVersion = "24.11";
}
