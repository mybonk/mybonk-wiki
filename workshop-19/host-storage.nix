# host-storage.nix — bind-mounts /var/lib/nixos-containers to /data/nixos-containers
# so that container data lands on a dedicated disk rather than the root partition.
# See workshop-1/host-storage.nix for the full explanation.
#
# Include in your host's /etc/nixos/configuration.nix:
#
#   imports = [ /path/to/workshop-19/host-storage.nix ];
#
# then rebuild: sudo nixos-rebuild switch

{ ... }:

{
  systemd.tmpfiles.rules = [
    "d /data/nixos-containers 0700 root root -"
  ];

  fileSystems."/var/lib/nixos-containers" = {
    device  = "/data/nixos-containers";
    options = [ "bind" ];
  };
}
