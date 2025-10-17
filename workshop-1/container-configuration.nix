{ config, pkgs, ... }:

{
  # Required for containers
  boot.isContainer = true;

  # Allow container to access the internet
  networking.useHostResolvConf = true;

  # Basic system settings
  networking.hostName = "demo-container";
  
  # Enable SSH
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # Add your SSH public key (replace with your actual key!)
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
