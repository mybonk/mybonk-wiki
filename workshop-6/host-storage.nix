# host-storage.nix — bind-mounts /var/lib/nixos-containers to /data/nixos-containers
# so that container data lands on a dedicated disk rather than the root partition.
# See workshop-1/host-storage.nix for the full explanation.
#
# This file is already imported by host-setup.nix in this workshop.
# No manual import step needed if you are using host-setup.nix.

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
