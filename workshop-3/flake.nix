{
  description = "Nginx version override using multiple nixpkgs inputs";

  inputs = {
    # Older stable release
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.05";

    # Newer release
    nixpkgs-latest.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs-stable, nixpkgs-latest }:
    let
      system = "x86_64-linux";
    in {
      # Container using OLDER nginx from nixos-23.05
      nixosConfigurations.nginx-old = nixpkgs-stable.lib.nixosSystem {
        inherit system;
        modules = [ ./container-configuration.nix ];
      };

      # Container using NEWER nginx from nixos-24.11
      nixosConfigurations.nginx-new = nixpkgs-latest.lib.nixosSystem {
        inherit system;
        modules = [ ./container-configuration.nix ];
      };
    };
}
