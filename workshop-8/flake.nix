{
  description = "NixOS container configurations with dynamic CLI management";

  inputs = {
    # Use NixOS 24.11 stable channel
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }:
  let
    # Helper function to create a container configuration
    # Hostname is automatically set by nixos-container to match the container name
    mkContainerConfig = { ... }: {
      # Import the shared configuration file used by all containers
      imports = [ ./configuration.nix ];

      # Essential container-specific settings (required for all containers)

      # Tells NixOS this is a container, not a full system
      # This disables bootloader, kernel modules, and other host-only features
      boot.isContainer = true;
    };
  in
  {
    # Define container configurations that can be created from the CLI
    # Each configuration here can be instantiated with:
    #   sudo nixos-container create <name> --flake .#<name>
    #
    # The script will dynamically generate configurations, but these
    # pre-defined ones are available for manual creation
    nixosConfigurations = {
      # Example pre-defined container
      # Create with: sudo nixos-container create default --flake .#default
      default = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (mkContainerConfig {
            hostname = "default";
          })
        ];
      };

      # Another example container
      # Create with: sudo nixos-container create demo --flake .#demo
      demo = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (mkContainerConfig {
            hostname = "demo";
          })
        ];
      };
    };
  };
}
