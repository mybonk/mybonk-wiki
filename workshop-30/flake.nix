{
  description = "Workshop-30 — Nostr relay container";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }:
  let
    mkContainerConfig = { hostname }: {
      imports = [ ./configuration.nix ];
      _module.args.containerConfig = { inherit hostname; };
      boot.isContainer = true;
      systemd.network.enable = true;
    };
  in
  {
    nixosConfigurations = {
      nostr = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (mkContainerConfig { hostname = "nostr"; })
          ./nostr.nix
        ];
      };
    };
  };
}
