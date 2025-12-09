# Generic NixOS configuration for Bitcoin and Lightning nodes using Mutinynet
# This module is shared by both containers and VMs
# For Mutinynet fork details, see workshop-3
#
# IMPORTANT DIFFERENCE FROM WORKSHOP-9:
# - Uses Mutinynet signet (custom signet with 30-second blocks)
# - Bitcoin package is overridden with benthecarman's fork in flake.nix
# - Signet configuration requires specific challenge and addnode parameters

{ config, pkgs, lib, ... }:

{
  # Import modules
  imports = [
    ./modules/tmux.nix
  ];

  # ============================================================================
  # CONTAINER/VM DETECTION
  # ============================================================================

  # NOTE: boot.isContainer is set in flake.nix:
  # - true for container configurations (default)
  # - false for VM configurations (default-vm)

  # ============================================================================
  # NETWORK CONFIGURATION
  # ============================================================================

  # Network configuration depends on whether this is a container or VM
  # For containers: systemd-networkd with DHCP (see workshop-9)
  # For VMs: simpler DHCP configuration (test framework handles the rest)

  systemd.network = lib.mkIf config.boot.isContainer {
    enable = true;

    networks."10-container-dhcp" = {
      matchConfig.Name = "eth0*";
      networkConfig.DHCP = "yes";
      dhcpV4Config = {
        UseDNS = false;
        UseRoutes = true;
      };
    };
  };

  # Networking configuration
  networking = {
    # Container-specific network settings
    useHostResolvConf = lib.mkIf config.boot.isContainer (lib.mkForce false);
    useDHCP = lib.mkIf config.boot.isContainer (lib.mkForce false);
    nameservers = lib.mkIf config.boot.isContainer [ "10.233.0.1" ];
    search = lib.mkIf config.boot.isContainer [ "containers.local" ];

    # Lab environment: Disable firewall for maximum connectivity
    firewall.enable = false;
  };

  # Disable systemd-resolved in containers (breaks DNS resolution)
  # For VMs, let it use default (enabled)
  services.resolved.enable = lib.mkIf config.boot.isContainer false;

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
  # SSH SERVICE CONFIGURATION
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
    btop
    git
    jq
    bitcoin  # Add bitcoin-cli and other bitcoin utilities to PATH
    asciinema # Used to record videos of workshops' terminals
  ];

  # ============================================================================
  # BITCOIN CONFIGURATION - MUTINYNET SIGNET
  # ============================================================================

  # MUTINYNET: Custom signet with 30-second blocks
  # See workshop-3 for detailed explanation of Mutinynet and fork override
  #
  # Key differences from REGTEST (workshop-9):
  # - Mutinynet is a live network with other nodes
  # - Requires specific signet challenge and infrastructure nodes
  # - 30-second blocks (vs instant generation in regtest)
  # - Requires blockchain sync (but fast! ~30s per block)
  # - Free coins from https://faucet.mutinynet.com/

  # Custom bitcoind systemd service (not using nix-bitcoin)
  # Bitcoin Inquisition requires special signet configuration
  # We manage credentials manually in bitcoin.conf

  # Create bitcoin.conf manually with proper signet configuration
  environment.etc."bitcoin/bitcoin.conf".text = ''
    # Signet mode MUST be declared first
    signet=1

    # ALL signet-specific settings must be in [signet] section for Bitcoin Inquisition
    [signet]
    # Mutinynet-specific signet challenge
    signetchallenge=512102f7561d208dd9ae99bf497273e16f389bdbd6c4742ddb8e6b216e64fa2928ad8f51ae

    # Connect to Mutinynet infrastructure
    addnode=45.79.52.207:38333
    dnsseed=0

    # Mutinynet fork features (30-second blocks)
    signetblocktime=30

    # Enable transaction index
    txindex=1

    # Fallback fee rate
    fallbackfee=0.00001

    # RPC settings - bind to all interfaces for VM/container access
    rpcbind=0.0.0.0
    rpcport=38332
    rpcallowip=127.0.0.0/8
    rpcallowip=10.233.0.0/16
    rpcuser=bitcoin
    rpcpassword=bitcoin
  '';

  # Create custom bitcoind systemd service
  systemd.services.bitcoind = {
    description = "Bitcoin daemon (Mutinynet signet)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "bitcoin";
      Group = "bitcoin";
      ExecStart = "${pkgs.bitcoin}/bin/bitcoind -conf=/etc/bitcoin/bitcoin.conf -datadir=/var/lib/bitcoind";
      Restart = "on-failure";
      RestartSec = "30s";

      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "full";
      ProtectHome = true;
    };
  };

  # Create bitcoin user and group
  users.users.bitcoin = {
    isSystemUser = true;
    group = "bitcoin";
    home = "/var/lib/bitcoind";
    createHome = true;
  };

  users.groups.bitcoin = {};

  # ============================================================================
  # IMPORTANT NOTES
  # ============================================================================

  # MUTINYNET vs REGTEST:
  #   - MUTINYNET (signet with custom parameters):
  #     * Live network with other nodes
  #     * 30-second blocks (20x faster than Bitcoin mainnet)
  #     * Requires blockchain sync (fast!)
  #     * Free coins from faucet
  #     * Active infrastructure (explorer, Lightning nodes, LSP)
  #     * Perfect for realistic testing
  #     * Default RPC port: 38332
  #     * Default P2P port: 38333
  #
  #   - REGTEST (workshop-9):
  #     * Private local network
  #     * Instant block generation on demand
  #     * No blockchain sync needed
  #     * No external peers
  #     * Perfect for isolated testing
  #     * Default RPC port: 18443
  #     * Default P2P port: 18444

  # MUTINYNET FORK OVERRIDE:
  #   - Bitcoin package is overridden in flake.nix
  #   - Uses benthecarman's fork from GitHub
  #   - See workshop-3 for detailed explanation
  #   - Fork adds support for 30-second blocks (signetblocktime parameter)

  # DATA PERSISTENCE:
  #   - Blockchain data is stored in the system's filesystem
  #   - Location: /var/lib/bitcoind
  #   - For containers: persists in /var/lib/nixos-containers/<name>/var/lib/bitcoind
  #   - Data persists when stopped, deleted when destroyed

  # ACCESSING BITCOIN CLI:
  #   - bitcoin-cli -signet <command>
  #   - Examples:
  #     bitcoin-cli -signet getblockchaininfo
  #     bitcoin-cli -signet getnewaddress
  #     bitcoin-cli -signet getbalance

  # ACCESSING LIGHTNING CLI:
  #   - lightning-cli --network=signet <command>
  #   - Examples:
  #     lightning-cli --network=signet getinfo
  #     lightning-cli --network=signet listfunds
  #     lightning-cli --network=signet newaddr

  # GETTING MUTINYNET COINS:
  #   - Faucet: https://faucet.mutinynet.com/
  #   - Explorer: https://mutinynet.com/

  # ============================================================================
  # SYSTEM VERSION
  # ============================================================================

  system.stateVersion = "24.11";
}
