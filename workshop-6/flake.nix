{
  description = "NixOS container configurations for CLI-based management";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }:
  let
    # Helper function to create container configuration
    mkContainerConfig = { hostname, ipAddress, gateway ? "10.100.0.1", prefixLength ? 24, hostBridge ? "br-containers" }: {
      imports = [ ./configuration.nix ];

      # Pass containerConfig to the imported module
      _module.args.containerConfig = {
        inherit hostname ipAddress gateway prefixLength;
      };

      # DECLARATIVE CONTAINER-LEVEL NETWORKING
      # This replaces the imperative .conf file approach
      networking.hostName = hostname;

      # Container-specific settings
      boot.isContainer = true;

      # Private network configuration (declarative)
      systemd.network.enable = true;
    };
  in
  {
    # Container configurations - used with nixos-container create command
    nixosConfigurations = {
      container1 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (mkContainerConfig {
            hostname = "container1";
            ipAddress = "10.100.0.10";
          })
        ];
      };

      container2 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (mkContainerConfig {
            hostname = "container2";
            ipAddress = "10.100.0.20";
          })
        ];
      };

      # Add more containers by copying the pattern above:
      # container3 = nixpkgs.lib.nixosSystem {
      #   system = "x86_64-linux";
      #   modules = [
      #     (mkContainerConfig {
      #       hostname = "container3";
      #       ipAddress = "10.100.0.30";
      #     })
      #   ];
      # };
    };
  };
}
