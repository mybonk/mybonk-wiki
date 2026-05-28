# host-storage.nix — include this in your HOST machine's NixOS configuration,
# not in any container module.
#
# WHY THIS EXISTS
# NixOS stores every container's root filesystem under:
#   /var/lib/nixos-containers/<name>/
# That directory lives on the root partition, which is typically small (20–50 GB).
# Container data grows quickly: a Bitcoin signet chain is several GB, a Lightning
# node keeps its own database on top of that, and wallet daemons add more still.
#
# This bind-mount transparently redirects the default path to
# /data/nixos-containers, which you can back with a larger disk, a ZFS dataset,
# or a btrfs subvolume — without changing any nixos-container commands.
# No --root flag is ever needed; the tooling sees the same path as always.
#
# Include in your host's /etc/nixos/configuration.nix:
#
#   imports = [ /path/to/workshop-1/host-storage.nix ];
#
# then rebuild: sudo nixos-rebuild switch
#
# All subsequent workshops assume this redirect is already in place.

{ ... }:

{
  # Create the target directory on first boot before any container service starts.
  systemd.tmpfiles.rules = [
    "d /data/nixos-containers 0700 root root -"
  ];

  # Bind-mount /var/lib/nixos-containers → /data/nixos-containers.
  # All container root filesystems land on whatever disk backs /data.
  fileSystems."/var/lib/nixos-containers" = {
    device  = "/data/nixos-containers";
    options = [ "bind" ];
  };
}
