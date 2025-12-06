# Generic NixOS container configuration for Bitcoin and Lightning nodes
# This module is shared by all Bitcoin node containers created from this workshop
# IP addresses are assigned automatically via DHCP from the host
# Hostname is automatically set by nixos-container to match the container name
#
# IMPORTANT: This configuration is for IMPERATIVE containers
# (created with ./manage-containers.sh create <name>)

{ config, pkgs, lib, ... }:

{
  # ============================================================================
  # CONTAINER-SPECIFIC SETTINGS
  # ============================================================================

  # REQUIRED: Tells NixOS this is a container, not a full system
  boot.isContainer = true;

  # ============================================================================
  # NETWORK CONFIGURATION - ENABLES ALL CONNECTIVITY
  # ============================================================================

  # Enable systemd-networkd for network interface management
  # This is REQUIRED for containers to have working networking
  systemd.network = {
    enable = true;

    # Configure the container's network interface with DHCP
    networks."10-container-dhcp" = {
      # Match the container's virtual ethernet interface (eth0 for imperative containers)
      matchConfig.Name = "eth0*";

      # Request IP address, gateway, and DNS via DHCP from host
      networkConfig = {
        DHCP = "yes";
      };

      # Configure how DHCP information is used
      dhcpV4Config = {
        UseDNS = false;     # Don't use DNS from DHCP - we configure it statically
        UseRoutes = true;   # Accept default gateway from DHCP (enables internet routing)
      };
    };
  };

  # Don't inherit host's resolv.conf - use DHCP-provided DNS instead
  networking.useHostResolvConf = lib.mkForce false;

  # IMPORTANT: Disable old-style DHCP when using systemd-networkd
  # systemd-networkd (configured above) handles DHCP - don't use both!
  # Having both enabled causes conflicts in network management
  networking.useDHCP = lib.mkForce false;

  # CRITICAL: Disable systemd-resolved in containers
  # systemd-resolved intercepts DNS and uses 127.0.0.53 as nameserver
  # This breaks container-to-container hostname resolution
  # We want containers to use DNS from DHCP (dnsmasq at 10.233.0.1)
  services.resolved.enable = false;

  # Statically configure DNS in /etc/resolv.conf
  # Point directly to dnsmasq on the host for container hostname resolution
  networking.nameservers = [ "10.233.0.1" ];
  networking.search = [ "containers.local" ];

  # Lab environment: Disable firewall for maximum connectivity
  # NOTE: In production, configure firewall rules appropriately
  networking.firewall.enable = false;

  # ============================================================================
  # USER CONFIGURATION
  # ============================================================================

  # Root user configuration
  users.users.root = {
    # Lab environment: Set simple password for easy access (default: "nixos")
    password = "nixos";

    # SSH public keys for root user (copied from workshop-1)
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILmCXubTHcQrMO+LFTmWq6sN8L7gJEmyu+mL8DR0NvBf root@nixos"
    ];
  };

  # Operator user configuration (standard non-root user)
  users.users.operator = {
    isNormalUser = true;
    password = "operator";
    extraGroups = [ "wheel" ];

    # SSH public keys for operator user
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

  # Essential command-line tools for container management and debugging
  environment.systemPackages = with pkgs; [
    # Network diagnostics
    iputils   # ping, traceroute
    iproute2  # ip command
    nettools  # ifconfig, netstat
    bind      # nslookup, dig

    # Network utilities
    curl      # HTTP client
    wget      # Download files

    # System utilities
    vim       # Text editor
    htop      # Process monitor
    btop      # Modern process monitor
    git       # Version control
    jq        # JSON processor (useful for bitcoin-cli output)
  ];

  # ============================================================================
  # NIX-BITCOIN CONFIGURATION
  # ============================================================================

  # nix-bitcoin provides secure, pre-configured Bitcoin and Lightning services
  # Documentation: https://github.com/fort-nix/nix-bitcoin

  # REGTEST MODE: This configuration runs Bitcoin in regtest mode
  # Regtest is a local testing environment for development and learning
  # Perfect for workshops - no blockchain download, instant block generation

  nix-bitcoin.generateSecrets = true;

  # Enable bitcoind service
  # Bitcoin Core is the reference implementation of the Bitcoin protocol
  services.bitcoind = {
    enable = true;

    # REGTEST MODE: Local testing environment
    # nix-bitcoin officially supports regtest (not testnet)
    # Why regtest for learning?
    #   - No blockchain download (starts empty)
    #   - Instant block generation (mine blocks on demand)
    #   - Works completely offline
    #   - Full control over the network
    #   - Perfect for development and testing
    #   - Default RPC port: 18443, P2P port: 18444
    regtest = true;

    # Additional bitcoind configuration options
    extraConfig = ''
      # Enable transaction index (allows querying any transaction)
      # Required for Lightning Network and some applications
      txindex=1

      # Fallback fee rate (required for regtest transactions)
      # In regtest, fee estimation doesn't work (no mempool activity)
      # This sets a default fee of 0.00001 BTC/kB
      fallbackfee=0.00001
    '';
  };

  # Enable Core Lightning (CLN) service
  # Core Lightning is a Lightning Network implementation
  # Lightning enables fast, cheap Bitcoin transactions via payment channels
  services.clightning = {
    enable = true;

    # Core Lightning automatically connects to the local bitcoind
    # and follows its network configuration (regtest in our case)
    # nix-bitcoin handles the integration between bitcoind and clightning

    # Additional clightning configuration options
    # extraConfig = ''
    #   # Example: Set custom Lightning node alias
    #   # alias=MyLightningNode
    #
    #   # Example: Set node color (shown in explorers)
    #   # rgb=0088FF
    # '';
  };

  # nix-bitcoin operator user
  # The 'operator' user has access to Bitcoin and Lightning CLI tools
  # This is already configured above in users.users.operator
  # nix-bitcoin will add the operator user to appropriate groups automatically

  # ============================================================================
  # IMPORTANT NOTES
  # ============================================================================

  # REGTEST vs MAINNET:
  #   - REGTEST (regtest = true):
  #     * Perfect for learning and development
  #     * No blockchain download required (starts empty)
  #     * Instant block generation (mine blocks on demand)
  #     * Works completely offline
  #     * Full control over the network
  #     * Default RPC port: 18443
  #     * Default P2P port: 18444
  #
  #   - MAINNET (default):
  #     * Real Bitcoin with real financial value
  #     * Full blockchain sync required (~500GB+)
  #     * Requires proper security hardening
  #     * Default RPC port: 8332
  #     * Default P2P port: 8333
  #     * NOT RECOMMENDED for learning environments

  # NO BLOCKCHAIN SYNC NEEDED:
  #   - Regtest starts with an empty blockchain
  #   - You generate blocks instantly with:
  #     bitcoin-cli -regtest generatetoaddress 101 <address>
  #   - Perfect for workshops and testing!

  # DATA PERSISTENCE:
  #   - Blockchain data is stored in the container's filesystem
  #   - Location inside container: /var/lib/bitcoind
  #   - Location on host: /var/lib/nixos-containers/<container-name>/var/lib/bitcoind
  #   - Data persists even when container is stopped
  #   - Data is deleted when container is destroyed

  # ACCESSING BITCOIN CLI:
  #   - As root: bitcoin-cli -regtest <command>
  #   - As operator: bitcoin-cli -regtest <command>
  #   - Examples:
  #     bitcoin-cli -regtest getblockchaininfo
  #     bitcoin-cli -regtest getnewaddress
  #     bitcoin-cli -regtest generatetoaddress 101 <address>

  # ACCESSING LIGHTNING CLI:
  #   - As root: lightning-cli --network=regtest <command>
  #   - As operator: lightning-cli --network=regtest <command>
  #   - Examples:
  #     lightning-cli --network=regtest getinfo
  #     lightning-cli --network=regtest listfunds
  #     lightning-cli --network=regtest newaddr

  # ============================================================================
  # SYSTEM VERSION
  # ============================================================================

  # NixOS state version - should match the NixOS release being used
  system.stateVersion = "24.11";
}
