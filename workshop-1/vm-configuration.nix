{ config, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # Basic system settings
  networking.hostName = "demo-vm";

  # Store the disk image under /data/vms/ rather than the default ./demo-vm.qcow2
  # in whichever directory you run the VM from.
  # See host-storage-vms.nix for how /data/vms/ is created on the host.
  virtualisation.diskImage = "/data/vms/demo-vm.qcow2";

  # VM-specific settings, do not change
  boot.loader.grub.device = "/dev/vda";
  
  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };


  # Allow empty password for easy testing (NOT for production!)
  users.users.root.initialPassword = "root";

  # Enable SSH
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # Add your SSH public key
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC... your-email@example.com"
  ];

  # Essential packages
  environment.systemPackages = with pkgs; [
    vim
    btop
    curl
    git
  ];

  system.stateVersion = "24.05";
}
