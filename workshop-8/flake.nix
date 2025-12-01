{
  description = "NixOS container configurations with dynamic CLI management";

  inputs = {
    # Use NixOS 25.05 stable channel
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }:
  let
    # Helper function to create a parameterized container configuration
    # This function takes a hostname and returns a complete NixOS configuration
    # that can be used with: nixos-container create <name> --flake .#<name>
    mkContainerConfig = { hostname }: {
      # Import the shared configuration file used by all containers
      imports = [ ./configuration.nix ];

      # Pass container-specific parameters to the imported configuration module
      # This allows configuration.nix to access containerConfig.hostname
      _module.args.containerConfig = {
        inherit hostname;
      };

      # Essential container-specific settings (required for all containers)

      # Tells NixOS this is a container, not a full system
      # This disables bootloader, kernel modules, and other host-only features
      boot.isContainer = true;

      # Enable systemd-networkd for container network management
      # Required for DHCP and proper network configuration
      systemd.network.enable = true;
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
      # Create with: sudo nixos-container create demo --flake .#demo
      demo = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (mkContainerConfig {
            hostname = "demo";
          })
        ];
      };

      # You can add more pre-defined containers here by copying the pattern:
      #
      # myapp = nixpkgs.lib.nixosSystem {
      #   system = "x86_64-linux";
      #   modules = [
      #     (mkContainerConfig {
      #       hostname = "myapp";
      #     })
      #   ];
      # };
      #
      # web = nixpkgs.lib.nixosSystem {
      #   system = "x86_64-linux";
      #   modules = [
      #     (mkContainerConfig {
      #       hostname = "web";
      #     })
      #   ];
      # };
    };
  };
}
