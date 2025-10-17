{
  description = "Bitcoin NixOS Container - Workshop 3 (Mutinynet)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }: 
    let
      system = "x86_64-linux";
      
      # Fetch Mutinynet source from benthecarman's fork
      mutinynetSrc = nixpkgs.legacyPackages.${system}.fetchFromGitHub {
        owner = "benthecarman";
        repo = "bitcoin";
        rev = "v29.0";  # Mutinynet v29.0 release
        sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # We'll fix this
      };
      
      # Create custom package set with overridden bitcoin
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
    in {
      nixosConfigurations.bitcoin-container = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          { nixpkgs.overlays = [ (final: prev: { inherit (pkgs) bitcoin; }) ]; }
          ./container-configuration.nix
        ];
      };
    };
}