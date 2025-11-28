# Host Prerequisites for NixOS Containers
# This configuration sets up ONLY the bridge network, NAT, and IP forwarding
# NO container definitions - containers are created and managed via CLI commands

{ config, pkgs, lib, ... }:

{
  # Enable container support
  boot.enableContainers = true;

  # Bridge network configuration for containers
  networking.bridges = {
    "br-containers" = {
      interfaces = [];
    };
  };

  networking.interfaces.br-containers = {
    ipv4.addresses = [{
      address = "10.100.0.1";
      prefixLength = 24;
    }];
  };

  # Enable NAT for container internet access
  networking.nat = {
    enable = true;
    internalInterfaces = [ "br-containers" ];
    externalInterface = "eth0"; # Change this to your actual internet interface (e.g., "wlan0", "enp0s3")
  };

  # Enable IP forwarding
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  # Disable firewall for maximum openness
  networking.firewall.enable = false;

  # Enable nix flakes (required for container creation with flakes)
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System state version
  system.stateVersion = "25.05";
}
