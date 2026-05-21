# barkd container configuration
# Runs the Bark wallet daemon as a NixOS container.
# Connect to the REST API at http://<container-ip>:7070

{ config, pkgs, lib, barkd, ... }:

{
  boot.isContainer = true;

  # ── Network (DHCP from host bridge) ─────────────────────────────────────────

  systemd.network = {
    enable = true;
    networks."10-container-dhcp" = {
      matchConfig.Name = "eth0*";
      networkConfig.DHCP = "yes";
      dhcpV4Config = {
        UseDNS = false;
        UseRoutes = true;
      };
    };
  };

  networking = {
    useHostResolvConf = lib.mkForce false;
    useDHCP           = lib.mkForce false;
    nameservers       = [ "10.233.0.1" ];
    firewall.allowedTCPPorts = [ 7070 ];  # barkd REST API
  };

  services.resolved.enable = false;

  # ── Users ────────────────────────────────────────────────────────────────────

  users.users.root = {
    password = "nixos";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILmCXubTHcQrMO+LFTmWq6sN8L7gJEmyu+mL8DR0NvBf root@nixos"
    ];
  };

  users.users.operator = {
    isNormalUser = true;
    password     = "operator";
    extraGroups  = [ "wheel" "barkd" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILmCXubTHcQrMO+LFTmWq6sN8L7gJEmyu+mL8DR0NvBf operator@nixos"
      "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAHHDGRW40CXAlSbZ7G3zYO0CucwfsDUFnD+bI1+KbUFsDyBwHDhbpNZ1S12cDhcF6inszd8bkxKs0giyfr3cHtrrgEZqf9Ec8UXTMsnq12bbKT9zr0S8MPDzrIWdrpi2IpAaJ+qaXqT0lF+pp24ZtYBKbvBBScoGxx7tYA8QYe+MZ/7rg== operator@nixostestsbckitchen"
    ];
  };

  security.sudo.extraRules = [{
    users    = [ "operator" ];
    commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
  }];

  # ── SSH ──────────────────────────────────────────────────────────────────────

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin       = "yes";
      PasswordAuthentication = true;
    };
  };

  # ── barkd service user ───────────────────────────────────────────────────────

  users.users.barkd = {
    isSystemUser = true;
    group        = "barkd";
    home         = "/var/lib/barkd";
    createHome   = true;
  };
  users.groups.barkd = {};

  # ── barkd systemd service ────────────────────────────────────────────────────
  #
  # barkd stores all wallet state in StateDirectory (/var/lib/barkd).
  # Data persists across container restarts; destroying the container deletes it.
  #
  # REST API is available at http://0.0.0.0:7070 inside the container.
  # Authentication uses a bearer token — check /var/lib/barkd/ after first start.
  #
  # To adjust flags, run `barkd --help` inside the container and edit ExecStart.

  systemd.services.barkd = {
    description = "Bark wallet daemon (Ark protocol, signet)";
    after       = [ "network-online.target" ];
    wants       = [ "network-online.target" ];
    wantedBy    = [ "multi-user.target" ];

    serviceConfig = {
      User           = "barkd";
      Group          = "barkd";
      StateDirectory = "barkd";
      ExecStart      = "${barkd}/bin/barkd --datadir /var/lib/barkd";
      Restart        = "on-failure";
      RestartSec     = "10s";
    };
  };

  # ── System packages ──────────────────────────────────────────────────────────

  environment.systemPackages = with pkgs; [
    barkd   # barkd binary available system-wide for manual invocation
    curl
    jq
    vim
    htop
  ];

  system.stateVersion = "25.05";
}
