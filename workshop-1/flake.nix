{
  description = "NixOS VM Workshop - Container Edition";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.demo-container = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./container-configuration.nix ];
    };

    nixosConfigurations.demo-vm = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./vm-configuration.nix ];
    };
  };
}

