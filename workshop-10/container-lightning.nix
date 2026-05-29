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
    firewall.enable = false;
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

# Configure Tailscale to run in userspace mode (required for containers without kernel access)
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  # Modify the tailscaled systemd service to use userspace networking and wait for the network
  systemd.services.tailscaled = {
    serviceConfig = {
      ExecStart = pkgs.lib.mkForce [
        ""
        "${pkgs.tailscale}/bin/tailscaled --tun=userspace-networking --statedir=/var/lib/tailscale --socket=/run/tailscale/tailscaled.sock"
      ];
    };
  };

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

    (pkgs.writeShellApplication {
      name = "ln-status";
      runtimeInputs = [ pkgs.jq pkgs.util-linux config.services.clightning.package ];
      text = ''
        #curl -s --user "$(sudo cat /var/lib/bitcoind/signet/.cookie)" --data-binary '{"jsonrpc": "1.0", "id":"test", "method": "getnetworkinfo", "params": [] }' -H 'content-type: text/plain;' http://localhost:38332/ | jq '.result| "BITCOIN: \(.subversion), protocol: \(.protocolversion), active: \(.networkactive), connections: \(.connections), relayfee: \(.relayfee )"'
        #curl -s --user "$(sudo cat /var/lib/bitcoind/signet/.cookie)" --data-binary '{"jsonrpc": "1.0", "id":"test", "method": "getblockchaininfo", "params": [] }' -H 'content-type: text/plain;' http://localhost:38332/ | jq '.result| "Chain: \(.chain), pruned: \(.pruned), IBD: \(.initialblockdownload), blocks: \(.blocks), headers: \(.headers), size_on_disk: \(.size_on_disk)"'
        #curl -s --user "$(sudo cat /var/lib/bitcoind/signet/.cookie)" --data-binary '{"jsonrpc": "1.0", "id":"test", "method": "getblockchaininfo", "params": [] }' -H 'content-type: text/plain;' http://localhost:38332/ | jq '.result| "Signet challenge: \(.signet_challenge)"'
        curl -s --user "bitcoin:bitcoin" --data-binary '{"jsonrpc": "1.0", "id":"test", "method": "getnetworkinfo", "params": [] }' -H 'content-type: text/plain;' http://localhost:38332/ | jq '.result| "BITCOIN: \(.subversion), protocol: \(.protocolversion), active: \(.networkactive), connections: \(.connections), relayfee:\(.relayfee )"'
        curl -s --user "bitcoin:bitcoin" --data-binary '{"jsonrpc": "1.0", "id":"test", "method": "getblockchaininfo", "params": [] }' -H 'content-type: text/plain;' http://localhost:38332/ | jq '.result| "Chain: \(.chain), pruned: \(.pruned), IBD: \(.initialblockdownload), blocks: \(.blocks), headers: \(.headers), size_on_disk: \(.size_on_disk)"'
        curl -s --user "bitcoin:bitcoin" --data-binary '{"jsonrpc": "1.0", "id":"test", "method": "getblockchaininfo", "params": [] }' -H 'content-type: text/plain;' http://localhost:38332/ | jq '.result| "Signet challenge: \(.signet_challenge)"'


        lightning-cli --network=signet --lightning-dir=${config.services.clightning.dataDir} getinfo | jq -r '
          (["clightning","network","alias","channels","height","id"] | (., map(length*"-"))),
          ([.version, .network, .alias, .num_active_channels, .blockheight, .id])
          | @tsv
        ' | column --table -ts $'\t'
        printf "TOTAL LN ONCHAIN BALANCE: %s SATs\n", "$(lightning-cli --network=signet --lightning-dir=${config.services.clightning.dataDir} listfunds | jq '[.outputs[].amount_msat] | add / 1000')"
        lightning-cli --network=signet --lightning-dir=${config.services.clightning.dataDir} listpeerchannels | jq -r '
          (["peer_id","state","to_us","capacity"] | (., map(length*"-"))),
          (.channels[] | [.peer_id, .state, .to_us_msat, .total_msat])
          | @tsv
        ' | column --table -ts $'\t'
        lightning-cli --network=signet --lightning-dir=${config.services.clightning.dataDir} listpeers | jq -r '
          (["id","connected","netaddr"] | (., map(length*"-"))),
          (.peers[] | [.id, .connected, (.netaddr[0] // "n/a")]),
          ([(.peers | length), "", "", ""])
          | @tsv
        ' | column --table -ts $'\t'
      '';
    })
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

  # Start clightning automatically, ordered after nginx (regardless of its status).
  # `after`    = ordering only: clightning starts after nginx, whether it succeeded or failed.
  # `wantedBy` = weak dependency on multi-user.target: auto-starts at boot but a failure
  #              does NOT block the container or cause restarts.
  systemd.services.clightning.wantedBy = lib.mkForce [ "multi-user.target" ];
  systemd.services.clightning.after = [ "nginx.service" ];
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
    enable = true;
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
    ("+${pkgs.writeShellScript "rtl-ensure-admin-rune" ''
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
    ''}")
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
  networking.firewall.allowedTCPPorts = [ 9735 3000 ];
  

  # ============================================================================
  # ELECTRS (Electrum Server)
  # ============================================================================

  # Enable electrs for Mutinynet signet
  # Must explicitly specify both RPC and P2P ports for signet
  services.electrs = {
    enable = true;
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

  # ── nginx stream proxy — transparent Bitcoin RPC forward ────────────────────
  # Listens on 127.0.0.1:38332 and forwards the raw TCP stream to bitcoin:38332
  # on the remote VM. CLightning connects to localhost as normal; nginx is invisible.
  # The resolver directive re-resolves the bitcoin hostname on each new connection.

  services.nginx = {
    enable = true;
    streamConfig = ''
      resolver 10.233.0.1 valid=10s;
      server {
        listen 127.0.0.1:38332;
        proxy_pass bitcoin:38332;
        proxy_connect_timeout 5s;
        proxy_timeout 300s;
      }
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
  # nginx RPC proxy:
  #   - Listens on 127.0.0.1:38332, forwards to bitcoin:38332 on the remote VM
  #   - CLightning and any other service connects to localhost as normal
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
