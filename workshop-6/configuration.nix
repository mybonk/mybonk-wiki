# Parameterized container configuration
# This module accepts a containerConfig parameter with: hostname, ipAddress, gateway, prefixLength
# Used by ALL containers - only the parameters differ

{ config, pkgs, lib, containerConfig, ... }:

{
  # Use the passed hostname parameter
  networking.hostName = containerConfig.hostname;

  # Disable DHCP since we're using static IP
  networking.useDHCP = false;

  # Configure static IP address and gateway
  networking.defaultGateway = {
    address = containerConfig.gateway;
    interface = "enp1s0";
  };

  networking.interfaces.enp1s0 = {
    ipv4.addresses = [{
      address = containerConfig.ipAddress;
      prefixLength = containerConfig.prefixLength;
    }];
  };

  # DNS configuration for internet access
  networking.nameservers = [
    "8.8.8.8"
    "8.8.4.4"
  ];

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
  # This is the key difference - configure privateNetwork directly
  boot.isContainer = true;

  systemd.network = {
    enable = true;
    networks."enp1s0" = {
      matchConfig.Name = "enp1s0";
      networkConfig = {
        Address = "${containerConfig.ipAddress}/${toString containerConfig.prefixLength}";
        Gateway = containerConfig.gateway;
        DNS = [ "8.8.8.8" "8.8.4.4" ];
      };
    };
  };

  # System state version
  system.stateVersion = "25.05";
}
