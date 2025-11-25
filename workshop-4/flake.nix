{
  description = "Bitcoin Stack NixOS Container - Workshop 4 (nix-bitcoin)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nix-bitcoin.url = "github:fort-nix/nix-bitcoin/master";
  };

  outputs = { self, nixpkgs, nix-bitcoin }: {
    nixosConfigurations.demo-container = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nix-bitcoin.nixosModules.default
        ./container-configuration.nix
      ];
    };
  };
}

