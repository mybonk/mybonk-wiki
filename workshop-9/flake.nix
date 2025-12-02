{
  description = "NixOS container configurations with nix-bitcoin for Bitcoin and Lightning nodes";

  inputs = {
    # Use NixOS 24.11 stable channel
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    # nix-bitcoin: Bitcoin and Lightning node configurations
    # Provides pre-configured services for Bitcoin, Lightning and many others
    nix-bitcoin.url = "github:fort-nix/nix-bitcoin/master";
    #nix-bitcoin.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-bitcoin }:
  let
    # Helper function to create a Bitcoin/Lightning container configuration
    # Hostname is automatically set by nixos-container to match the container name
    mkContainerConfig = { ... }: {
      imports = [
        # Import nix-bitcoin module to enable Bitcoin and Lightning services
        nix-bitcoin.nixosModules.default
        # Import the shared configuration file used by all containers
        ./configuration.nix
      ];

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
    # Hostname will automatically be set to match the container name
    nixosConfigurations = {
      default = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (mkContainerConfig {
            # hostname = "default";
          })
        ];
      };
    };
  };
}
