# Core Lightning container configuration
# This container runs Core Lightning and connects to external bitcoind
# Network: Uses host's DHCP/DNS/NAT (like workshop-9)

{ config, pkgs, lib, ... }:

{
  # Import modules
  imports = [
    ./modules/tmux.nix
  ];

  # ============================================================================
  # CONTAINER CONFIGURATION
  # ============================================================================

  boot.isContainer = true;
  networking.hostName = "lightning";

  # ============================================================================
  # NETWORK CONFIGURATION (DHCP from host)
  # ============================================================================

  # Use systemd-networkd for container networking (workshop-9 pattern)
  systemd.network = {
    enable = true;
    wait-online.enable = false;  # Don't block boot waiting for network

    networks."10-container-dhcp" = {
      matchConfig.Name = "eth0*";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = false;  # Disable IPv6 to speed up
      };
      dhcpV4Config = {
        UseDNS = false;
        UseRoutes = true;
      };
    };
  };

  # Container-specific network settings (workshop-9 pattern)
  networking = {
    useHostResolvConf = lib.mkForce false;
    useDHCP = lib.mkForce false;
    nameservers = [ "10.233.0.1" ];  # Host DNS
    search = [ "containers.local" ];
    firewall.enable = false;  # Lab environment
  };

  # Disable systemd-resolved (workshop-9 pattern)
  services.resolved.enable = false;

  # ============================================================================
  # USER CONFIGURATION
  # ============================================================================

  users.users.root = {
    password = "nixos";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILmCXubTHcQrMO+LFTmWq6sN8L7gJEmyu+mL8DR0NvBf root@nixos"
    ];
  };

  users.users.operator = {
    isNormalUser = true;
    password = "operator";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILmCXubTHcQrMO+LFTmWq6sN8L7gJEmyu+mL8DR0NvBf operator@nixos"
    ];
  };

  # ============================================================================
  # SSH SERVICE
  # ============================================================================

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # ============================================================================
  # SYSTEM PACKAGES
  # ============================================================================

  environment.systemPackages = with pkgs; [
    iputils
    iproute2
    nettools
    bind
    curl
    wget
    vim
    htop
    git
    jq
    asciinema # Used to record videos of workshops' terminals
  ];

  # ============================================================================
  # CORE LIGHTNING CONFIGURATION
  # ============================================================================

  # Enable nix-bitcoin for Core Lightning management
  nix-bitcoin.generateSecrets = true;

  # Enable bitcoind with Mutinynet fork (Bitcoin Inquisition) from overlay
  # Local bitcoind runs, but iptables redirects RPC to external VM for testing
  services.bitcoind = {
    enable = true;

    # Disable nix-bitcoin's default RPC settings (we'll set them in extraConfig)
    rpc.address = lib.mkForce "";
    listen = lib.mkForce false;

    # Put all configuration in extraConfig to avoid nix-bitcoin conflicts
    extraConfig = ''
      # Mutinynet signet configuration
      signet=1

      [signet]
      # Mutinynet-specific signet challenge
      signetchallenge=512102f7561d208dd9ae99bf497273e16f389bdbd6c4742ddb8e6b216e64fa2928ad8f51ae

      # Connect to Mutinynet infrastructure
      addnode=45.79.52.207:38333
      dnsseed=0

      # Mutinynet fork features (30-second blocks)
      signetblocktime=30

      # RPC settings (must be in [signet] section when signet=1)
      rpcbind=127.0.0.1
      rpcport=38332
      rpcallowip=127.0.0.1

      # Enable debug logging
      debug=rpc
    '';
  };
  # Fix nix-bitcoin's post-start script for signet mode
  # The cookie file is at /var/lib/bitcoind/signet/.cookie, not /var/lib/bitcoind/.cookie
  systemd.services.bitcoind.postStart = lib.mkForce ''
    # Wait for cookie file (in signet subdirectory for signet mode)
    while [ ! -f /var/lib/bitcoind/signet/.cookie ]; do
      sleep 1
    done
    # Set permissions on signet cookie
    chmod o+r /var/lib/bitcoind/signet/.cookie
  '';

  # Configure clightning to connect to external Bitcoin VM (not local bitcoind)
  services.clightning = {
    enable = true;
    extraConfig = ''
      # Network: signet (Mutinynet)
      network=signet

      # Connect to external Bitcoin VM
      bitcoin-rpcconnect=bitcoin
      bitcoin-rpcport=38332
      bitcoin-rpcuser=bitcoin
      bitcoin-rpcpassword=bitcoin

      # Lightning P2P settings
      bind-addr=0.0.0.0:9735
      announce-addr=0.0.0.0:9735
    '';
  };

  # NOTE: No iptables redirect needed - clightning connects directly to bitcoin:38332

  # ============================================================================
  # HOW IT WORKS
  # ============================================================================
  #
  # Local bitcoind:
  #   - Runs Mutinynet signet (Bitcoin Inquisition fork)
  #   - Mostly unused - here to satisfy nix-bitcoin dependencies
  #
  # Core Lightning:
  #   - Connects directly to external Bitcoin VM (bitcoin:38332)
  #   - Configured via extraConfig to use external VM
  #
  # External Bitcoin VM:
  #   - Hostname: bitcoin (resolved via DNS to 10.233.0.x)
  #   - RPC Port: 38332 (Mutinynet signet)
  #   - Credentials: bitcoin/bitcoin
  #
  # Container Network:
  #   - Gets IP via DHCP from host (10.233.0.x range)
  #   - DNS: 10.233.0.1 (host)
  #   - Lightning P2P: 9735

  system.stateVersion = "24.11";
}
