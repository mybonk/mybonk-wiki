{
  description = "NixOS container configurations for CLI-based management";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }:
  let
    # Helper function to create container configuration
    # Containers use DHCP, so only hostname is needed
    mkContainerConfig = { hostname }: {
      imports = [ ./configuration.nix ];

      # Pass containerConfig to the imported module
      _module.args.containerConfig = {
        inherit hostname;
      };

      # Container-specific settings
      boot.isContainer = true;
      systemd.network.enable = true;
    };
  in
  {
    # Container configurations - used with nixos-container create command
    # IP addresses are assigned automatically via DHCP from the host
    nixosConfigurations = {
      container1 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (mkContainerConfig {
            hostname = "container1";
          })
        ];
      };

      container2 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (mkContainerConfig {
            hostname = "container2";
          })
        ];
      };

      # Add more containers by copying the pattern above:
      # container3 = nixpkgs.lib.nixosSystem {
      #   system = "x86_64-linux";
      #   modules = [
      #     (mkContainerConfig {
      #       hostname = "container3";
      #     })
      #   ];
      # };
    };
  };
}
