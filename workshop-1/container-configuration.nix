{ config, pkgs, ... }:

{
  # Required for containers
  boot.isContainer = true;

  # Allow container to access the internet
  #networking.useHostResolvConf = true;
  networking.nameservers = [ "8.8.8.8" "8.8.4.4" ]; # Set public DNS inside the container
  # Basic system settings
  networking.hostName = "demo-container";
  
  # Enable SSH
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

    # Enable tailscale
  services.tailscale.enable = true;
  # Tell the firewall to implicitly trust packets routed over Tailscale:
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Use this setting 'loose' because strict reverse path filtering breaks Tailscale exit node use and some subnet routing setups
  networking.firewall.checkReversePath = "loose";
  # networking.networkmanager.enable = true;



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
