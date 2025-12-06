{
  description = "NixOS VM configuration with nix-bitcoin for Bitcoin and Lightning nodes using Mutinynet fork";

  inputs = {
    # Use NixOS 24.11 stable channel
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    # nix-bitcoin: Bitcoin and Lightning node configurations
    nix-bitcoin.url = "github:fort-nix/nix-bitcoin/master";
  };

  outputs = { self, nixpkgs, nix-bitcoin }:
  let
    system = "x86_64-linux";

    # Fetch Mutinynet source from benthecarman's fork
    # This is the same fork used in workshop-3
    mutinynetSrc = nixpkgs.legacyPackages.${system}.fetchFromGitHub {
      owner = "benthecarman";
      repo = "bitcoin";
      rev = "v29.0";  # Mutinynet v29.0 release
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # Placeholder - will be updated on first build
    };

    # Create custom package set with overridden bitcoin (Mutinynet fork)
    pkgs = import nixpkgs {
      inherit system;
      overlays = [
        (final: prev: {
          bitcoin = prev.bitcoin.overrideAttrs (oldAttrs: {
            src = mutinynetSrc;
            version = "29.0-mutinynet";
          });
        })
      ];
    };

    # Helper function to create a Bitcoin/Lightning container configuration
    # Used for imperative container creation
    mkContainerConfig = { ... }: {
      imports = [
        nix-bitcoin.nixosModules.default
        ./configuration.nix
      ];

      # CONTAINER-SPECIFIC: Tell NixOS this is a container
      boot.isContainer = true;

      # Enable systemd-networkd for container network management
      systemd.network.enable = true;

      # Apply Mutinynet overlay
      nixpkgs.overlays = [ (final: prev: { inherit (pkgs) bitcoin; }) ];
    };

    # Helper function to create a VM configuration
    # Used for NixOS tests
    mkVMConfig = { ... }: {
      imports = [
        nix-bitcoin.nixosModules.default
        ./configuration.nix
      ];

      # VM-SPECIFIC: Tell NixOS this is NOT a container
      boot.isContainer = false;

      # Apply Mutinynet overlay
      nixpkgs.overlays = [ (final: prev: { inherit (pkgs) bitcoin; }) ];
    };
  in
  {
    # Container configuration (for imperative container creation)
    # Usage: sudo nixos-container create <name> --flake .#default
    nixosConfigurations = {
      default = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          (mkContainerConfig {})
        ];
      };

      # VM configuration (for NixOS tests)
      # This configuration is designed to run in a VM, not a container
      default-vm = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          (mkVMConfig {})
        ];
      };
    };

    # Automated tests using NixOS VM test framework
    # Usage: nix build .#checks.x86_64-linux.bitcoin-lightning-mutinynet
    #        nix flake check
    checks.x86_64-linux = {
      bitcoin-lightning-mutinynet = import ./test.nix {
        inherit nixpkgs system;
        nix-bitcoin = nix-bitcoin;
        mutinynetOverlay = (final: prev: { inherit (pkgs) bitcoin; });
      };
    };
  };
}
