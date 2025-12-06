# Core Lightning container configuration
# This container runs Core Lightning and connects to external bitcoind
# Network: Uses host's DHCP/DNS/NAT (like workshop-9)

{ config, pkgs, lib, ... }:

{
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

    networks."10-container-dhcp" = {
      matchConfig.Name = "eth0*";
      networkConfig.DHCP = "yes";
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
  ];

  # ============================================================================
  # CORE LIGHTNING CONFIGURATION
  # ============================================================================

  # Enable nix-bitcoin for Core Lightning management
  nix-bitcoin.generateSecrets = true;

  services.bitcoin = {
    enable = false;
  }

  # Configure Core Lightning to connect to external bitcoind
  services.clightning = {
    enable = true;

    # Network: signet (Mutinynet)
    # NOTE: nix-bitcoin's clightning module doesn't directly support signet
    # We need to configure it via extraConfig

    extraConfig = ''
      # Network configuration
      network=signet

      # External bitcoind connection via hostname (DNS from host)
      bitcoin-rpcconnect=bitcoin
      bitcoin-rpcport=38332
      bitcoin-rpcuser=bitcoin
      bitcoin-rpcpassword=bitcoin

      # Bind to all interfaces so we can connect from outside
      bind-addr=0.0.0.0:9735

      # Announce our address for peer connections
      announce-addr=0.0.0.0:9735
    '';
  };

  # ============================================================================
  # IMPORTANT NOTES
  # ============================================================================

  # BITCOIND CONNECTION:
  #   - Core Lightning connects to external bitcoind via RPC
  #   - Uses hostname "bitcoin" (DNS resolution provided by host)
  #   - No manual IP configuration needed - host DNS resolves "bitcoin" to VM IP
  #   - bitcoind must be accessible on port 38332 (Mutinynet signet RPC)
  #   - Connection: bitcoin-rpcconnect=bitcoin (hostname, not IP)

  # RPC CREDENTIALS:
  #   - Must match bitcoind's bitcoin.conf:
  #     rpcuser=bitcoin
  #     rpcpassword=bitcoin

  # ACCESSING LIGHTNING CLI:
  #   - Inside container: lightning-cli --network=signet <command>
  #   - From host: sudo nixos-container run lightning -- lightning-cli --network=signet <command>
  #   - Examples:
  #     lightning-cli --network=signet getinfo
  #     lightning-cli --network=signet listfunds
  #     lightning-cli --network=signet newaddr

  # NETWORKING:
  #   - Container uses host's DHCP (10.233.x.x network)
  #   - DNS provided by host (10.233.0.1)
  #   - Lightning port: 9735 (P2P)
  #   - Can connect to other Lightning nodes

  system.stateVersion = "24.11";
}
