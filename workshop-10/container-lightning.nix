# Core Lightning container configuration
# This container runs Core Lightning and connects to external bitcoind
# Network: Uses host's DHCP/DNS/NAT (like workshop-9)

{ config, pkgs, lib, nix-bitcoin, ... }:

{
  # Import modules
  imports = [
    ./modules/tmux.nix
  ];

  # ============================================================================
  # CONTAINER CONFIGURATION
  # ============================================================================

  boot.isContainer = true;

  # ============================================================================
  # NETWORK CONFIGURATION (DHCP from host)
  # ============================================================================

  # Use systemd-networkd for container networking (workshop-9 pattern)
  systemd.network = {
    enable = true;
    wait-online.enable = true;  # Block boot waiting for network

    networks."10-container-dhcp" = {
      matchConfig.Name = "eth0*";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;  # set to false to disable IPv6 to speed up
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
    firewall.enable = true;  # Would leave it as false in a workshop to simplify things but in this case we'll need IPTABLES to redirect some traffic. IPTABLES is enabled when this setting is true.
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
    extraGroups = [ "wheel" "clightning" "systemd-journal" "proc" ];
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

  # lightning-cli requires --network=signet on every call because it defaults to mainnet.
  # This alias injects the flag automatically so users can just type `lightning-cli <command>`.
  environment.shellAliases = {
    lightning-cli = "lightning-cli --network=signet";
  };

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
  # BITCOIN-RELATED CONFIGURATION
  # ============================================================================

  # Enable secret management through nix-bitcoin
  nix-bitcoin.generateSecrets = true;

  # Enable bitcoind with Mutinynet fork (Bitcoin Inquisition) from overlay
  # Local bitcoind runs for complete self-contained stack
  services.bitcoind = {
    enable = true;

    # Enable ZMQ for electrs and other services
    zmqpubrawblock = "tcp://127.0.0.1:28332";
    zmqpubrawtx = "tcp://127.0.0.1:28333";

    # Disable nix-bitcoin's default RPC settings (we'll set them in extraConfig)
    # Don't use listen=true - it generates bind= outside [signet] section which fails
    #rpc.address = lib.mkForce "";

    # Put all configuration in extraConfig to avoid nix-bitcoin conflicts
    extraConfig = ''

      # Enable debug logging
      #debug=rpc

      # signet configuration
      signet=1
      [signet]

      # Enable P2P listening (must be in [signet] section)
      server=1
      listen=1
      bind=0.0.0.0:38333  # Listens on all interfaces (including localhost)

      # Specific to Mutinynet: Set fallback fee, without this fee estimate is always 0.
      fallbackfee=0.00000253

      blockfilterindex=1
      peerblockfilters=1

      # Mutinynet-specific signet challenge
      signetchallenge=512102f7561d208dd9ae99bf497273e16f389bdbd6c4742ddb8e6b216e64fa2928ad8f51ae

      # Connect to Mutinynet nodes (multiple for redundancy)
      addnode=45.79.52.207:38333
      # Connect to our bitcoin node VM on our private network (if available)
      addnode=bitcoin:38333

      # Note: mutinynet.com and faucet.mutinynet.com resolve to Cloudflare CDN servers
      # but keeping them as fallbacks - even if they fail, having multiple addnodes helps
      addnode=mutinynet.com:38333
      addnode=faucet.mutinynet.com:38333
  
      dnsseed=0

      # Mutinynet fork features (30-second blocks)
      signetblocktime=30

      # Enable transaction index
      txindex=1

      # Fallback fee rate
      fallbackfee=0.00001

      # RPC settings (must be in [signet] section when signet=1)
      rpcbind=0.0.0.0
      rpcport=38332
      rpcallowip=127.0.0.0/8
      rpcallowip=10.233.0.0/16
      #rpcuser=bitcoin
      #rpcpassword=bitcoin


      # NOTE: RPC credentials are auto-generated by nix-bitcoin
      # Stored in: /etc/nix-bitcoin-secrets/bitcoin-rpcpassword-privileged
      #            /etc/nix-bitcoin-secrets/bitcoin-rpcpassword-public
      #
      # To make RPC calls with curl:
      #   RPC_PASS=$(cat /etc/nix-bitcoin-secrets/bitcoin-rpcpassword-privileged)
      #   curl -u privileged:$RPC_PASS \
      #     -d '{"jsonrpc":"1.0","id":"curl","method":"getblockchaininfo","params":[]}' \
      #     -H 'content-type: text/plain;' \
      #     http://127.0.0.1:38332/ | jq .result
      #
      # Or use bitcoin-cli which reads credentials automatically:
      #   bitcoin-cli -signet getblockchaininfo
    '';


     # RPC users configuration
      # Import the public whitelist from nix-bitcoin (read-only safe commands)
      # Same approach used in nix-bitcoin's bitcoind.nix:240
      #rpc.users = {
      #      bitcoin = {
      #        passwordHMAC = "f7efda5c189b999524f151318c0c86$d5b51b3beffbc02b724e5d095828e0bc8b2456e9ac8757ae3211a5d9b16a22ae";
      #        rpcwhitelist = import "${nix-bitcoin}/modules/bitcoind-rpc-public-whitelist.nix";
      #    };
      #};

  };
  # Do not auto-start bitcoind at boot - start manually: systemctl start bitcoind
  systemd.services.bitcoind.wantedBy = lib.mkForce [];

  # Start clightning automatically, ordered after bitcoin-rpc-redirect (regardless of its status).
  # `after`    = ordering only: clightning starts after the redirect service, whether it
  #              succeeded or failed. Does NOT create a hard dependency.
  # `wantedBy` = weak dependency on multi-user.target: auto-starts at boot but a failure
  #              does NOT block the container or cause restarts.
  systemd.services.clightning.wantedBy = lib.mkForce [ "multi-user.target" ];
  systemd.services.clightning.after = [ "bitcoin-rpc-redirect.service" ];
  # nix-bitcoin sets FailureAction=reboot on critical services for production hardening.
  # Override it so clightning can fail/crash without rebooting the container.
  systemd.services.clightning.serviceConfig.FailureAction = lib.mkForce "none";
  systemd.services.clightning.serviceConfig.RestartSec = lib.mkForce "30s";

  # Fix nix-bitcoin's clightning postStart for signet.
  # nix-bitcoin's postStart waits for the RPC socket using a hardcoded "bitcoin" network
  # directory (/var/lib/clightning/bitcoin/lightning-rpc) even when running on signet.
  # The actual socket is at /var/lib/clightning/signet/lightning-rpc.
  # Without this fix the postStart hangs the full 10-minute TimeoutStartSec, then the
  # service fails and FailureAction=reboot restarts the container.
  systemd.services.clightning.postStart = lib.mkForce ''
    for i in $(seq 1 60); do
      if [ -S "/var/lib/clightning/signet/lightning-rpc" ]; then
        echo "CLightning RPC socket ready"
        exit 0
      fi
      sleep 1
    done
    echo "WARNING: CLightning RPC socket not available after 60s"
    exit 0
  '';

  # clightning connects to the external bitcoin VM (bitcoin-rpcconnect=bitcoin in extraConfig),
  # not to local bitcoind. Remove nix-bitcoin's automatic hard dependency so that starting
  # clightning does not pull up the local bitcoind service.
  # Note: `after` is left alone - it only controls ordering, it never starts a service.
  systemd.services.clightning.requires = lib.mkForce [];
  systemd.services.clightning.bindsTo = lib.mkForce [];

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

  services.rtl = {
    enable = false;
    nodes.clightning.enable = true;
  };

  # Fix: nix-bitcoin's RTL module looks for admin-rune in clightning.networkDir,
  # but networkDir incorrectly evaluates to "/var/lib/clightning/bitcoin" even on signet
  # This script generates the rune in the correct signet directory and creates a symlink

  # Ensure RTL waits for CLightning to be fully started
  systemd.services.rtl = {
    after = [ "clightning.service" ];
    requires = [ "clightning.service" ];
  };

  systemd.services.rtl.serviceConfig.ExecStartPre = lib.mkBefore [
    (pkgs.writeShellScript "rtl-ensure-admin-rune" ''
      # Don't exit on error - we'll handle failures gracefully
      set +e

      # Actual CLightning data directory for signet network
      CLIGHTNING_DIR="/var/lib/clightning"
      SIGNET_DIR="$CLIGHTNING_DIR/signet"
      SIGNET_RUNE="$SIGNET_DIR/admin-rune"

      # Path where nix-bitcoin RTL incorrectly expects the rune
      # (due to networkDir not detecting signet properly)
      BITCOIN_DIR="$CLIGHTNING_DIR/bitcoin"
      BITCOIN_RUNE="$BITCOIN_DIR/admin-rune"

      # Wait for CLightning to be ready (with longer timeout since systemd already waits)
      echo "Waiting for CLightning RPC socket..."
      for i in {1..60}; do
        if [ -S "$SIGNET_DIR/lightning-rpc" ]; then
          echo "CLightning is ready"
          break
        fi
        if [ $i -eq 60 ]; then
          echo "WARNING: CLightning RPC socket not available after 60 seconds"
          echo "Checking if CLightning service is running..."
          systemctl is-active clightning.service || echo "CLightning service is not active!"
          exit 1
        fi
        sleep 1
      done

      # Generate admin-rune in the signet directory if it doesn't exist
      if [ ! -f "$SIGNET_RUNE" ]; then
        echo "Generating admin-rune for signet..."
        RUNE=$(${pkgs.sudo}/bin/sudo -u clightning ${pkgs.clightning}/bin/lightning-cli \
          --network=signet \
          --lightning-dir="$CLIGHTNING_DIR" \
          createrune restrictions='[]' 2>&1 | ${pkgs.jq}/bin/jq -r '.rune' 2>/dev/null)

        if [ -n "$RUNE" ] && [ "$RUNE" != "null" ]; then
          echo "$RUNE" > "$SIGNET_RUNE"
          chown clightning:clightning "$SIGNET_RUNE"
          chmod 600 "$SIGNET_RUNE"
          echo "Admin-rune created at $SIGNET_RUNE"
        else
          echo "WARNING: Failed to generate admin-rune (will retry on next start)"
          # Don't fail - let RTL try with existing rune if available
        fi
      else
        echo "Admin-rune already exists at $SIGNET_RUNE"
      fi

      # Create bitcoin directory and symlink for RTL compatibility
      # RTL expects /var/lib/clightning/bitcoin/admin-rune due to nix-bitcoin bug
      mkdir -p "$BITCOIN_DIR"
      chown clightning:clightning "$BITCOIN_DIR"

      if [ ! -L "$BITCOIN_RUNE" ] && [ ! -f "$BITCOIN_RUNE" ]; then
        ln -sf "$SIGNET_RUNE" "$BITCOIN_RUNE"
        echo "Created symlink: $BITCOIN_RUNE -> $SIGNET_RUNE"
      fi

      # Ensure the rune is readable
      if [ -f "$BITCOIN_RUNE" ] || [ -L "$BITCOIN_RUNE" ]; then
        echo "Rune is ready for RTL at $BITCOIN_RUNE"
        exit 0
      else
        echo "ERROR: Rune file not found at $BITCOIN_RUNE"
        exit 1
      fi
    '')
  ];

  # WHY THE ExecStartPre PASSWORD PATCH IS NEEDED:
  #
  # nix-bitcoin's clightning preStart generates /var/lib/clightning/config as:
  #
  #   { cat <static-config-including-extraConfig>
  #     echo "bitcoin-rpcpassword=$(cat /etc/nix-bitcoin-secrets/bitcoin-rpcpassword-public)"
  #   } > /var/lib/clightning/config
  #
  # The generated password (for the LOCAL bitcoind) is appended AFTER our extraConfig,
  # so bitcoin-rpcpassword=bitcoin in extraConfig is always overridden.
  #
  # Fix: an ExecStartPre script runs after nix-bitcoin's preStart and replaces the
  # password line in the already-generated config file with the external VM's password.
  systemd.services.clightning.serviceConfig.ExecStartPre = lib.mkAfter [
    (pkgs.writeShellScript "clightning-fix-bitcoin-rpc-password" ''
      # Fix RPC password: nix-bitcoin appends its locally-generated password last,
      # overriding the one in extraConfig. Replace it with the external VM's password.
      ${pkgs.gnused}/bin/sed -i \
        's/^bitcoin-rpcpassword=.*/bitcoin-rpcpassword=bitcoin/' \
        /var/lib/clightning/config
    '')
  ];

  # Configure clightning to connect to external bitcoin VM
  services.clightning = {
    enable = true;
    # Listen on all interfaces so other Lightning nodes can connect.
    # nix-bitcoin defaults to 127.0.0.1 (loopback only).
    address = "0.0.0.0";
    extraConfig = ''
      log-level=debug
      #log-file=lightning.log

      # Network: signet (Mutinynet)
      network=signet

      # Connect to external VM bitcoind
      bitcoin-rpcconnect=bitcoin
      bitcoin-rpcport=38332

      # bitcoin-rpcuser is set here and wins (extraConfig is appended before nix-bitcoin's
      # password injection, and rpcuser is not re-injected after extraConfig).
      # bitcoin-rpcpassword=bitcoin would be overridden by nix-bitcoin - see ExecStartPre above.
      bitcoin-rpcuser=bitcoin

      # Skip full blockchain scan on startup.
      # CLightning defaults to scanning from the network genesis which takes a very long time.
      # For a fresh node with no channels, rescan=1 is safe: it only looks back 1 block from
      # the current tip. If you need to recover existing channels, increase this value.
      rescan=1

      # Lightning P2P listen address is set via services.clightning.address above
    '';
  };
  networking.firewall.allowedTCPPorts = [ 9735 ];

  # ============================================================================
  # ELECTRS (Electrum Server)
  # ============================================================================

  # Enable electrs for Mutinynet signet
  # Must explicitly specify both RPC and P2P ports for signet
  services.electrs = {
    enable = false;
    # Specify network mode, RPC port, and P2P port for Mutinynet signet
    # RPC: 38332, P2P: 38333 (standard signet ports)
    # Connect to LOCAL bitcoind (same container), not external "bitcoin" VM
    # IMPORTANT: Mutinynet uses custom signet magic derived from its challenge
    # Default signet magic is 0a03cf40, but Mutinynet's is a5df2dcb
    extraArgs = "--network=signet --signet-magic=a5df2dcb --daemon-rpc-addr=127.0.0.1:38332 --daemon-p2p-addr=127.0.0.1:38333";
  };

  # ============================================================================
  # MEMPOOL EXPLORER (mempool.space)
  # ============================================================================

  # Enable mempool block explorer for Mutinynet signet
  # nix-bitcoin automatically connects it to local bitcoind and handles RPC auth
  services.mempool = {
    enable = false;
    address = "0.0.0.0";     # Backend API accessible from host
    # port = 8999;           # Backend API port (default, can omit)

    frontend = {
      enable = false;         # Web interface (enabled by default)
      address = "0.0.0.0";   # Frontend accessible from host
      port = 60845;          # Frontend web UI port (nix-bitcoin default)
    };

    # Override defaults for Mutinynet signet
    settings = {
      MEMPOOL = {
        NETWORK = lib.mkForce "signet";  # Change from default "mainnet" to "signet"
      };
      # Override RPC port - nix-bitcoin defaults to mainnet port (8332)
      # but Mutinynet signet uses 38332
      CORE_RPC = {
        PORT = lib.mkForce 38332;  # Signet RPC port, not mainnet 8332
      };
    };
  };

  # ============================================================================
  # IPTABLES REDIRECT - Local Bitcoin RPC to External VM
  # ============================================================================

  # Required for DNAT on the OUTPUT chain to work with loopback destinations.
  # Without this, the kernel drops packets routed to 127.0.0.1 before they hit NAT.
  boot.kernel.sysctl."net.ipv4.conf.all.route_localnet" = 1;

  # Redirect local Bitcoin RPC requests (127.0.0.1:38332) to external bitcoin VM
  # This allows local services and commands to use localhost but reach the bitcoin VM
  #
  # Type = "oneshot" + RemainAfterExit = true:
  #   The service runs a script and exits. systemd keeps it shown as "active" after
  #   the script completes (not "inactive/dead") so that systemctl status is useful
  #   and so that ExecStop runs when you call systemctl stop.
  #
  # systemctl start  → adds the DNAT rule  (traffic flows to remote bitcoin VM)
  # systemctl stop   → removes the DNAT rule (traffic stays local / is dropped)
  # systemctl status → shows active/inactive accurately
  systemd.services.bitcoin-rpc-redirect = {
    enable = true;
    description = "Redirect local Bitcoin signet RPC port to external bitcoin VM";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    # wantedBy creates a *weak* dependency on multi-user.target (Wants, not Requires):
    # systemd starts it automatically at boot but a failure does NOT affect the container
    # or cause restarts. If the bitcoin VM is unreachable at boot, the service fails
    # gracefully and everything else continues normally.
    wantedBy = [ "multi-user.target" ];

    # Make tools available in the script PATH - the NixOS-idiomatic alternative
    # to hardcoding /nix/store/... paths or adding to environment.systemPackages
    # (which only affects interactive shells, not systemd services)
    # Note: iputils (ping) is used for hostname resolution because the system glibc
    # resolver (used by ping) correctly handles DNS search domains, while pkgs.glibc's
    # getent cannot find the NSS modules needed to do the same.
    path = [ pkgs.iptables pkgs.iputils ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "8s";
      RuntimeDirectory = "bitcoin-rpc-redirect";
    };

    # Exit codes determine systemctl status:
    #   exit 0  → Active   (rule installed, traffic redirected to bitcoin VM)
    #   exit 1  → Failed   (rule NOT installed, status honestly reflects reality)
    script = ''
      set -euo pipefail
      STATE=/run/bitcoin-rpc-redirect/bitcoin-ip

      TIMEOUT=5
      BITCOIN_IP=""

      for i in $(seq 1 $TIMEOUT); do
        # ping resolves via the system glibc (including DNS search domains like containers.local)
        # Extract IP from ping output: "PING bitcoin (10.x.x.x) 56(84) bytes..."
        # Pattern requires dots to avoid matching the byte-count "(84)" on the same line
        BITCOIN_IP=$(ping -c 1 -W 1 bitcoin 2>/dev/null | head -1 | grep -oE '\([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\)' | tr -d '()')
        if [ -n "$BITCOIN_IP" ]; then
          echo "Resolved: bitcoin -> $BITCOIN_IP"
          break
        fi
        echo "Waiting for 'bitcoin' host... ($i/$TIMEOUT)"
        sleep 1
      done

      if [ -z "$BITCOIN_IP" ]; then
        echo "ERROR: Could not reach 'bitcoin' after $TIMEOUT seconds - is the bitcoin VM running?"
        exit 1
      fi

      echo "$BITCOIN_IP" > "$STATE"
      echo "Resolved: bitcoin -> $BITCOIN_IP"

      # Rule 1: DNAT - rewrite destination: 127.0.0.1:38332 → bitcoin_ip:38332
      if iptables -t nat -C OUTPUT -p tcp -d 127.0.0.1 --dport 38332 \
           -j DNAT --to-destination "$BITCOIN_IP:38332" 2>/dev/null; then
        echo "DNAT rule already present"
      else
        iptables -t nat -A OUTPUT -p tcp -d 127.0.0.1 --dport 38332 \
          -j DNAT --to-destination "$BITCOIN_IP:38332"
        echo "DNAT rule added: 127.0.0.1:38332 -> $BITCOIN_IP:38332"
      fi

      # Rule 2: MASQUERADE - rewrite source: 127.0.0.1 → container eth0 IP
      # Without this the bitcoin VM sees src=127.0.0.1 and replies to its own loopback.
      # With this the reply comes back to the container and conntrack restores the original src.
      if iptables -t nat -C POSTROUTING -p tcp -d "$BITCOIN_IP" --dport 38332 \
           -j MASQUERADE 2>/dev/null; then
        echo "MASQUERADE rule already present"
      else
        iptables -t nat -A POSTROUTING -p tcp -d "$BITCOIN_IP" --dport 38332 \
          -j MASQUERADE
        echo "MASQUERADE rule added for return traffic from $BITCOIN_IP:38332"
      fi
    '';

    preStop = ''
      STATE=/run/bitcoin-rpc-redirect/bitcoin-ip

      if [ ! -f "$STATE" ]; then
        echo "No state file - rules were never installed, nothing to remove"
        exit 0
      fi

      BITCOIN_IP=$(cat "$STATE")

      if iptables -t nat -C OUTPUT -p tcp -d 127.0.0.1 --dport 38332 \
           -j DNAT --to-destination "$BITCOIN_IP:38332" 2>/dev/null; then
        iptables -t nat -D OUTPUT -p tcp -d 127.0.0.1 --dport 38332 \
          -j DNAT --to-destination "$BITCOIN_IP:38332"
        echo "DNAT rule removed: 127.0.0.1:38332 -> $BITCOIN_IP:38332"
      else
        echo "DNAT rule not found in kernel, nothing to remove"
      fi

      if iptables -t nat -C POSTROUTING -p tcp -d "$BITCOIN_IP" --dport 38332 \
           -j MASQUERADE 2>/dev/null; then
        iptables -t nat -D POSTROUTING -p tcp -d "$BITCOIN_IP" --dport 38332 \
          -j MASQUERADE
        echo "MASQUERADE rule removed"
      else
        echo "MASQUERADE rule not found in kernel, nothing to remove"
      fi
    '';
  };

  # ============================================================================
  # HOW IT WORKS - Self-Contained Bitcoin + Lightning Stack
  # ============================================================================
  #
  # Local bitcoind:
  #   - Runs Mutinynet signet (Bitcoin Inquisition fork)
  #   - Using nix-bitcoin's bitcoind module with custom Mutinynet package
  #   - RPC on 127.0.0.1:38332
  #   - Credentials: bitcoin/bitcoin
  #   - Signet cookie at /var/lib/bitcoind/signet/.cookie
  #
  # Core Lightning:
  #   - Runs on signet network (Mutinynet)
  #   - Connects to LOCAL bitcoind (127.0.0.1:38332)
  #   - Using nix-bitcoin's clightning module
  #   - P2P port: 9735
  #   - Automatically depends on bitcoind.service
  #
  # iptables Redirect (Optional):
  #   - bitcoin-rpc-redirect service available for testing
  #   - Can redirect to external bitcoin VM if needed
  #   - Not used by default (clightning uses local bitcoind)
  #
  # Architecture:
  #   - Self-contained: All services in one container
  #   - Can test complete Bitcoin + Lightning stack independently
  #   - Separate from bitcoin VM (which continues to run independently)
  #
  # Container Network:
  #   - Gets IP via DHCP from host (10.233.0.x range)
  #   - DNS: 10.233.0.1 (host)
  #   - Bitcoin P2P: 38333 (Mutinynet)
  #   - Bitcoin RPC: 38332 (local only)
  #   - Lightning P2P: 9735

  system.stateVersion = "24.11";
}
