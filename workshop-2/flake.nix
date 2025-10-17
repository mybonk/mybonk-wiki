{
  description = "Bitcoin Core NixOS Container - Workshop 2";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.bitcoin-container = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./container-configuration.nix
      ];
    };
  };
}