# host-storage-vms.nix — ensures /data/vms/ exists on the host so VM disk images
# land on a dedicated disk rather than scattered in working directories.
# The mechanism is explained in detail in workshop-10/host-storage-vms.nix.
#
# Include in your host's /etc/nixos/configuration.nix:
#
#   imports = [ /path/to/workshop-1/host-storage-vms.nix ];
#
# then rebuild: sudo nixos-rebuild switch

{ ... }:

{
  systemd.tmpfiles.rules = [
    "d /data/vms 0700 root root -"
  ];
}
