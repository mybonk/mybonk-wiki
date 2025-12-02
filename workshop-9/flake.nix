{
  description = "NixOS container configurations with nix-bitcoin for Bitcoin and Lightning nodes";

  inputs = {
    # Use NixOS 25.05 stable channel
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    # nix-bitcoin: Bitcoin and Lightning node configurations
    # Provides pre-configured services for Bitcoin, Lightning and many others
    nix-bitcoin.url = "github:fort-nix/nix-bitcoin/master";
    #nix-bitcoin.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-bitcoin }:
  let
    # Helper function to create a parameterized container configuration
    # This function takes a hostname and returns a complete NixOS configuration
    # that can be used with: ./manage-containers.sh create <name>
    mkContainerConfig = { hostname }: {
      imports = [
        # Import nix-bitcoin module to enable Bitcoin and Lightning services
        nix-bitcoin.nixosModules.default
        # Import the shared configuration file used by all containers
        ./configuration.nix
      ];

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
    # Can be instantiated with:
    #   sudo ./manage-containers.sh create <name>
    #
    # This pre-defined container is ready to use
    nixosConfigurations = {
      default = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (mkContainerConfig {
            hostname = "default";
          })
        ];
      };
    };
  };
}
