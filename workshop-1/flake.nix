{
  description = "NixOS containers with parameterized configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ config, pkgs, lib, ... }: {
          # Basic host system configuration
          boot.isContainer = false;

          # Enable container support
          boot.enableContainers = true;

          # Host networking configuration
          networking.hostName = "nixos-container-host";
          networking.useDHCP = lib.mkDefault true;
          networking.firewall.enable = false;

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

          # Container 1 definition
          containers.container1 = {
            autoStart = true;
            privateNetwork = true;
            hostBridge = "br-containers";
            localAddress = "10.100.0.10/24";

            config = import ./configuration.nix {
              containerConfig = {
                hostname = "container1";
                ipAddress = "10.100.0.10";
                gateway = "10.100.0.1";
                prefixLength = 24;
              };
            };
          };

          # Container 2 definition
          containers.container2 = {
            autoStart = true;
            privateNetwork = true;
            hostBridge = "br-containers";
            localAddress = "10.100.0.20/24";

            config = import ./configuration.nix {
              containerConfig = {
                hostname = "container2";
                ipAddress = "10.100.0.20";
                gateway = "10.100.0.1";
                prefixLength = 24;
              };
            };
          };

          # Minimal system configuration
          system.stateVersion = "25.05";

          # Enable nix flakes
          nix.settings.experimental-features = [ "nix-command" "flakes" ];
        })
      ];
    };
  };
}
