# host-storage-vms.nix — include this in your HOST machine's NixOS configuration,
# not in any VM or container module.
#
# WHY THIS IS DIFFERENT FROM host-storage.nix (containers)
# Containers all live under one shared directory (/var/lib/nixos-containers) that
# can be redirected with a single bind-mount. VMs work differently: each VM has
# its own disk image (.qcow2 file) whose path is set explicitly, either via
# virtualisation.diskImage in the NixOS config or via a launch script argument.
# There is no single directory to redirect — each path must be set individually.
#
# What this file does is one thing only: ensure /data/vms/ exists on the host
# before any VM tries to write its disk image there. The actual image paths are
# then set in two places:
#
#   flake.nix           virtualisation.diskImage = "/data/vms/bitcoin-vm.qcow2"
#                       → the NixOS system disk (vda inside the VM)
#
#   run-bitcoin-vm.sh   DATA_DISK="/data/vms/bitcoin-vm-data.qcow2"
#                       → the persistent Bitcoin data disk (vdb inside the VM)
#
# Include in your host's /etc/nixos/configuration.nix:
#
#   imports = [ /path/to/workshop-10/host-storage-vms.nix ];
#
# then rebuild: sudo nixos-rebuild switch

{ ... }:

{
  # Create /data/vms/ on first boot so VM disk images can be written there.
  systemd.tmpfiles.rules = [
    "d /data/vms 0700 root root -"
  ];
}
