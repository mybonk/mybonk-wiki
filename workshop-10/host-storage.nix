# host-storage.nix — include this in your HOST machine's NixOS configuration,
# not in any container or VM module.
#
# By default NixOS stores all nixos-container root filesystems under
# /var/lib/nixos-containers/<name>/.  This bind-mount transparently
# redirects that path to /data/nixos-containers, which is useful when:
#
#   - /var/lib lives on a small root partition (e.g. NVMe system drive)
#   - You want container data on a separate, larger disk (e.g. /data on HDD/SSD)
#   - You want container data on a ZFS dataset, btrfs subvolume, etc.
#
# Because it is a bind-mount, nothing else changes: all nixos-container
# commands continue to use their default paths, and no --root flag is needed.
#
# Usage — add to your host's /etc/nixos/configuration.nix (or a file it imports):
#
#   imports = [ /path/to/host-storage.nix ];
#
# Then ensure /data/nixos-containers exists (or let tmpfiles create it) and
# run `sudo nixos-rebuild switch`.

{ ... }:

{
  # Create the target directory on first boot if it does not already exist.
  # tmpfiles runs before any container service so the mount is ready in time.
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
