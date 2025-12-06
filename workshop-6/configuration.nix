# Generic container configuration with DHCP
# This module accepts a containerConfig parameter with: hostname
# IP address is automatically assigned via DHCP from the host

{ config, pkgs, lib, containerConfig, ... }:

{
  # Use the passed hostname parameter
  networking.hostName = containerConfig.hostname;

  # Enable DHCP to get IP automatically
  networking.useDHCP = lib.mkDefault true;

  # Don't use host's resolv.conf (required when host uses systemd-resolved)
  networking.useHostResolvConf = lib.mkForce false;

  # Disable firewall for maximum openness
  networking.firewall.enable = false;

  # Basic system packages
  environment.systemPackages = with pkgs; [
    iputils  # ping
    curl     # test HTTP connectivity
    wget
    bind     # nslookup, dig
    iproute2 # ip command
    nettools # ifconfig, netstat
  ];

  # Enable SSH for easier access
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # Add your SSH public key (recommended for production)
  users.users.root.openssh.authorizedKeys.keys = [
    # "ssh-ed25519 AAAAC3NzaC... your-email@example.com"
  ];

  # Set a simple root password (change this in production!)
  users.users.root.password = "nixos";

  # DECLARATIVE NETWORKING CONFIGURATION
  # Configure container to use DHCP
  boot.isContainer = true;

  systemd.network = {
    enable = true;
    networks."10-container-dhcp" = {
      matchConfig.Name = "host0";
      networkConfig = {
        DHCP = "yes";
      };
      dhcpV4Config = {
        UseDNS = true;
        UseRoutes = true;
      };
    };
  };

  # System state version
  system.stateVersion = "24.11";
}
