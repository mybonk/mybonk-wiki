{
  description = "NixOS container configurations with nix-bitcoin for Bitcoin and Lightning nodes";

  inputs = {
    # Use NixOS 25.05 stable channel
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    # nix-bitcoin: Secure Bitcoin and Lightning node configurations
    # Provides pre-configured, hardened services for Bitcoin and Lightning
    nix-bitcoin.url = "github:fort-nix/nix-bitcoin/release";
  };

  outputs = { self, nixpkgs, nix-bitcoin }:
  let
    # Helper function to create a parameterized container configuration
    # This function takes a hostname and returns a complete NixOS configuration
    # that can be used with: ./manage-containers.sh create <name>
    mkContainerConfig = { hostname }: {
      # Import the shared configuration file used by all containers
      imports = [
        ./configuration.nix
        # Import nix-bitcoin module to enable Bitcoin and Lightning services
        nix-bitcoin.nixosModules.default
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
    # Each configuration here can be instantiated with:
    #   cd /path/to/mybonk-wiki/workshop-9 && sudo ./manage-containers.sh create <name>
    #
    # These pre-defined Bitcoin node containers are ready to use
    nixosConfigurations = {
      # Example Bitcoin node container
      # Create with: sudo ./manage-containers.sh create btc1
      btc1 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (mkContainerConfig {
            hostname = "btc1";
          })
        ];
      };

      # Example second Bitcoin node for testing multi-node setups
      # Create with: sudo ./manage-containers.sh create btc2
      btc2 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (mkContainerConfig {
            hostname = "btc2";
          })
        ];
      };

      # You can add more pre-defined containers here by copying the pattern:
      #
      # lightning1 = nixpkgs.lib.nixosSystem {
      #   system = "x86_64-linux";
      #   modules = [
      #     (mkContainerConfig {
      #       hostname = "lightning1";
      #     })
      #   ];
      # };
    };
  };
}
