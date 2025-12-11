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
      "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAHHDGRW40CXAlSbZ7G3zYO0CucwfsDUFnD+bI1+KbUFsDyBwHDhbpNZ1S12cDhcF6inszd8bkxKs0giyfr3cHtrrgEZqf9Ec8UXTMsnq12bbKT9zr0S8MPDzrIWdrpi2IpAaJ+qaXqT0lF+pp24ZtYBKbvBBScoGxx7tYA8QYe+MZ/7rg== operator@nixostestsbckitchen"
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

security.sudo.extraRules= [
  {  users = [ "operator" ];
    commands = [
       { command = "ALL" ;
         options= [ "NOPASSWD" ]; # "SETENV" # Adding the following could be a good idea
      }
    ];
  }
  ];

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

  # Enable secret management through nix-bitcoin
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

      # Connect to Mutinynet
      # to our bitcoin node VM on our private network
      addnode=bitcoin:38333
      # to another mutinynet node
      addnode=45.79.52.207:38333
      
      dnsseed=1

      # Mutinynet fork features (30-second blocks)
      signetblocktime=30

      # RPC settings (must be in [signet] section when signet=1)
      rpcbind=127.0.0.1
      rpcport=38332
      rpcallowip=127.0.0.0/8
      rpcallowip=10.233.0.0/16
      
      rpcuser=bitcoin
      rpcpassword=bitcoin

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
    enable = false;
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

  # ============================================================================
  # IPTABLES REDIRECT - Local Bitcoin RPC to External VM
  # ============================================================================

  # Redirect local Bitcoin RPC requests (127.0.0.1:38332) to external bitcoin VM
  # This allows local services and commands to use localhost but reach the bitcoin VM
  systemd.services.bitcoin-rpc-redirect = {
    description = "Redirect local Bitcoin signet RPC to external bitcoin VM";
    # Wait for network-online.target so DNS is fully functional
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "60s";  # Allow up to 60 seconds for DNS and iptables setup
    };

    script = ''
      # Wait for DNS to be available (max 45 seconds)
      # DNS takes ~20-30 seconds to become available during boot
      TIMEOUT=45
      ELAPSED=0
      until ${pkgs.bind}/bin/host bitcoin > /dev/null 2>&1; do
        if [ $ELAPSED -ge $TIMEOUT ]; then
          echo "WARNING: Could not resolve 'bitcoin' hostname after $TIMEOUT seconds"
          echo "Bitcoin RPC redirect NOT configured - bitcoin VM may not be running"
          exit 0  # Exit successfully to not block boot
        fi
        echo "Waiting for DNS resolution of 'bitcoin'... ($ELAPSED/$TIMEOUT)"
        sleep 1
        ELAPSED=$((ELAPSED + 1))
      done

      # Redirect localhost:38332 to bitcoin:38332
      # This rewrites the destination for packets going to 127.0.0.1:38332
      ${pkgs.iptables}/bin/iptables -t nat -A OUTPUT -p tcp -d 127.0.0.1 --dport 38332 -j DNAT --to-destination bitcoin:38332

      echo "Bitcoin RPC redirect configured: 127.0.0.1:38332 -> bitcoin:38332"
    '';
  };

  # ============================================================================
  # HOW IT WORKS
  # ============================================================================
  #
  # Local bitcoind:
  #   - Runs Mutinynet signet (Bitcoin Inquisition fork)
  #   - Mostly unused - here to satisfy nix-bitcoin dependencies
  #   - All RPC requests to 127.0.0.1:38332 are redirected to bitcoin VM via iptables
  #
  # iptables Redirect:
  #   - systemd service bitcoin-rpc-redirect sets up NAT rules at boot
  #   - Redirects 127.0.0.1:38332 → bitcoin:38332
  #   - Waits for DNS to be available before setting up rules
  #   - Allows local commands like "bitcoin-cli -signet" to reach external bitcoin VM
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
