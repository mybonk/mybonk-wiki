# Host Prerequisites for NixOS Containers
# This configuration sets up ONLY the bridge network, NAT, and IP forwarding
# NO container definitions - containers are created and managed via CLI commands

{ config, pkgs, lib, ... }:

{
  imports = [ ./host-storage.nix ];

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
    externalInterface = "enp1s0"; # Change this to your actual internet interface (e.g., "wlan0", "enp0s3")
  };

  # Enable IP forwarding
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  # Disable firewall for maximum openness
  networking.firewall.enable = false;

  # DHCP server for containers (using dnsmasq)
  services.dnsmasq = {
    enable = true;
    settings = {
      # Only listen on the container bridge
      interface = "br-containers";
      # Don't listen on any other interfaces
      bind-interfaces = true;
      # DHCP range: 10.100.0.50 - 10.100.0.150 (12 hour lease)
      dhcp-range = "10.100.0.50,10.100.0.150,12h";
      # Local domain for containers
      domain = "containers.local";
      # Don't read /etc/resolv.conf or /etc/hosts
      no-resolv = true;
      no-hosts = true;
      # Provide DNS for containers (forward to Google DNS)
      server = [ "8.8.8.8" "8.8.4.4" ];
    };
  };

  # Enable nix flakes (required for container creation with flakes)
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ── Workshop-7: Container Monitoring ──────────────────────────────────────
  # Uncomment this entire block when following workshop-7.
  #
  # Prometheus scrapes node_exporter metrics from each container every 15 s.
  # Grafana serves the dashboard at http://<host-ip>:3000 (admin / admin).
  #
  # Before uncommenting, find your containers' DHCP-assigned IPs and replace
  # the placeholders below:
  #   sudo nixos-container run container1 -- ip addr show host0 | grep inet
  #   sudo nixos-container run container2 -- ip addr show host0 | grep inet
  #
  # services.prometheus = {
  #   enable = true;
  #   port = 9090;
  #   scrapeConfigs = [
  #     {
  #       job_name = "containers";
  #       static_configs = [
  #         {
  #           targets = [
  #             "10.100.0.10:9100"   # container1 — replace with actual DHCP IP
  #             "10.100.0.20:9100"   # container2 — replace with actual DHCP IP
  #           ];
  #         }
  #       ];
  #     }
  #   ];
  # };
  #
  # services.grafana = {
  #   enable = true;
  #   settings = {
  #     server = {
  #       http_addr = "0.0.0.0";
  #       http_port = 3000;
  #     };
  #     security = {
  #       admin_user = "admin";
  #       admin_password = "admin";  # Change after first login
  #     };
  #   };
  #   provision = {
  #     enable = true;
  #     datasources.settings.datasources = [
  #       {
  #         name = "Prometheus";
  #         type = "prometheus";
  #         url = "http://localhost:9090";
  #         isDefault = true;
  #       }
  #     ];
  #   };
  # };
  #
  # # Open ports if the host firewall is enabled
  # networking.firewall.allowedTCPPorts = [ 3000 9090 ];
  # ──────────────────────────────────────────────────────────────────────────

  # System state version
  system.stateVersion = "24.11";
}
