{ config, pkgs, lib, modulesPath, ... }:

{
  # Enable SSH server for remote installation
  services.openssh = {
    enable = true;
    settings = {
      # Allow root login with public key authentication
      PermitRootLogin = "prohibit-password";
      # Disable password authentication for security
      PasswordAuthentication = false;
      # Only allow public key authentication
      PubkeyAuthentication = true;
    };
  };

  # Enable Tailscale for remote access from anywhere
  services.tailscale.enable = true;

  # Add your SSH public key here
  # Replace this with your actual public key generated from ssh-keygen
  users.users.root.openssh.authorizedKeys.keys = [
    # Example: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG... your-email@example.com"
    # Add your public key here after running: ssh-keygen -t ed25519
  ];

  # Essential packages for installation and diagnostics
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    htop
    btop
    tmux
    parted
    gptfdisk
    cryptsetup
    rsync
  ];

  # Network configuration
  networking = {
    # Disable wireless (conflicts with NetworkManager)
    wireless.enable = lib.mkForce false;
    # Enable network manager for easy WiFi/Ethernet setup
    networkmanager.enable = true;
    # Use systemd-resolved for DNS
    useNetworkd = false;
    useDHCP = lib.mkDefault true;
    # Enable firewall but allow SSH and Tailscale
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      # Tailscale uses UDP port 41641 for DERP relay connections
      allowedUDPPorts = [ config.services.tailscale.port ];
      # Allow Tailscale's network interfaces
      trustedInterfaces = [ "tailscale0" ];
    };
  };

  # Set a temporary root password for initial access
  # This allows console login if needed before SSH is set up
  # Change this password immediately or remove after adding SSH key
  users.users.root.initialPassword = "nixos";

  # Console configuration
  console = {
    font = "Lat2-Terminus16";
    keyMap = lib.mkDefault "us";
  };

  # Time zone (adjust as needed)
  time.timeZone = lib.mkDefault "UTC";

  # Internationalization
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  # NixOS version
  system.stateVersion = "24.11";
}
