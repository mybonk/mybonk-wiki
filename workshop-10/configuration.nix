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
  # For VMs: test framework handles networking automatically

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

  networking = lib.mkIf config.boot.isContainer {
    useHostResolvConf = lib.mkForce false;
    useDHCP = lib.mkForce false;
    nameservers = [ "10.233.0.1" ];
    search = [ "containers.local" ];
  };

  # Disable systemd-resolved in containers (breaks DNS resolution)
  services.resolved.enable = lib.mkIf config.boot.isContainer false;

  # Lab environment: Disable firewall for maximum connectivity
  networking.firewall.enable = false;

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
  ];

  # ============================================================================
  # NIX-BITCOIN CONFIGURATION - MUTINYNET SIGNET
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

  nix-bitcoin.generateSecrets = true;

  # Enable bitcoind service with Mutinynet configuration
  services.bitcoind = {
    enable = true;

    # SIGNET MODE (not regtest!)
    # Mutinynet is a custom signet network
    # For testnet vs regtest comparison, see workshop-9
    # For Mutinynet details, see workshop-3

    # Additional bitcoind configuration for Mutinynet
    extraConfig = ''
      # Enable signet mode
      signet=1

      # Mutinynet-specific signet challenge
      # This identifies which signet network to join (Mutinynet)
      # Required - tells bitcoind to connect to Mutinynet signet
      signetchallenge=512102f7561d208dd9ae99bf497273e16f389bdbd6c4742ddb8e6b216e64fa2928ad8f51ae

      # Connect to Mutinynet infrastructure node
      # Required for initial peer discovery
      addnode=45.79.52.207:38333

      # Disable DNS seeding (use manual addnode instead)
      dnsseed=0

      # 30-second block time
      # This parameter only works because we're using benthecarman's Mutinynet fork
      # Standard Bitcoin doesn't have this parameter
      signetblocktime=30

      # Enable transaction index (allows querying any transaction)
      # Required for Lightning Network and some applications
      txindex=1

      # Fallback fee rate (required for signet transactions)
      # Sets a default fee of 0.00001 BTC/kB
      fallbackfee=0.00001
    '';
  };

  # Enable Core Lightning (CLN) service
  # Core Lightning automatically connects to local bitcoind
  # and follows its network configuration (signet in our case)
  services.clightning = {
    enable = true;
  };

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
