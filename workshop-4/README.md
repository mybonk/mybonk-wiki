---
layout: default
title: Workshop 4
nav_order: 5
---

# How to Run a Bitcoin Stack on NixOS in 5 Minutes

## Overview

This workshop demonstrates how to deploy a complete, integrated Bitcoin stack using **nix-bitcoin** - a collection of battle-tested NixOS modules designed specifically for Bitcoin infrastructure. Instead of manually configuring each service as we did in workshops 2 and 3, nix-bitcoin provides pre-integrated configurations that work together seamlessly.

**What is nix-bitcoin?**

nix-bitcoin is a collection of NixOS modules that makes deploying Bitcoin infrastructure simple and secure. It handles:
- Service integration and authentication
- Security hardening by default
- Secret management
- Inter-service communication
- Consistent configuration patterns
- Production-ready defaults

**What we're deploying:**

In this workshop, we'll deploy a complete stack in minutes:
- **Bitcoin Core** (bitcoind) - the foundation
- **Electrs** - Electrum server for wallet integration
- **Core Lightning** (c-lightning) - Lightning Network daemon
- **RTL** (Ride The Lightning) - web-based Lightning Network management interface

All of this with just a few lines of configuration!

**Why nix-bitcoin vs manual setup?**

As you saw in workshops 2 and 3, deploying even a single Bitcoin service requires careful configuration. Imagine manually setting up:
- Bitcoin Core with the right RPC settings
- Electrs connected to bitcoind with proper authentication
- Lightning daemon reading bitcoind's RPC credentials
- Web interface with secure access to Lightning
- Proper user permissions and file access
- Secret management across all services
- Firewall rules for each component

nix-bitcoin does all of this automatically, using secure defaults and proven integration patterns developed over years by the Bitcoin NixOS community.

**What you'll learn:**

- Deploy a complete Bitcoin stack with minimal configuration
- Use nix-bitcoin modules for service integration
- Access and manage Lightning nodes via web interface
- Understand how nix-bitcoin handles secrets and authentication
- (Advanced) Override the Bitcoin package with a custom fork

**Prerequisites:**

- Completed [workshop-1](../workshop-1/) (NixOS containers)
- Completed [workshop-2](../workshop-2/) (Bitcoin service)
- Completed [workshop-3](../workshop-3/) (package overrides)
- Understanding of Bitcoin and Lightning Network basics

**Time:** ~5 minutes setup + 30-60 minutes for signet sync

**Reality check on deployment speed:**

The "5 minutes" refers to configuration and container startup. However:
- **First build:** nix-bitcoin will build all services from source (10-20 minutes)
- **Blockchain sync:** Even on signet, initial block download takes 30-60 minutes
- **Lightning setup:** Channel funding requires synced blockchain

This is still dramatically faster than mainnet (days/weeks) or even testnet (hours).

---

## Step 1: Clone the Workshop Repository

Clone the repository if you haven't already:

```bash
git clone git@github.com:mybonk/mybonk-wiki.git
cd mybonk-wiki/workshop-4
```

The directory contains:
- `flake.nix` - Adds nix-bitcoin as a flake input
- `container-configuration.nix` - Bitcoin stack configuration

Let's examine what we're about to deploy.

---

## Step 2: Understanding the Configuration

Let's look at `flake.nix` first:

```nix
{
  description = "Bitcoin Stack NixOS Container - Workshop 4 (nix-bitcoin)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nix-bitcoin.url = "github:fort-nix/nix-bitcoin/master";
  };

  outputs = { self, nixpkgs, nix-bitcoin }: {
    nixosConfigurations.demo-container = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nix-bitcoin.nixosModules.default
        ./container-configuration.nix
      ];
    };
  };
}
```

**What's happening:**

1. **`nix-bitcoin` input**: Fetches the nix-bitcoin module collection from GitHub
2. **`nixosModules.default`**: Imports all nix-bitcoin service modules into our system
3. **Module composition**: Our `container-configuration.nix` can now use nix-bitcoin's pre-configured service options

This is how nix-bitcoin becomes available to our configuration. The flake system fetches it, pins it to a specific version, and makes all its modules available.

Now look at `container-configuration.nix`:

```nix
{ config, pkgs, lib, ... }:

{
  boot.isContainer = true;
  networking.hostName = "demo-container";

  # Generate secrets automatically (for development/workshop purposes)
  # In production, manage secrets manually in /etc/nix-bitcoin-secrets
  nix-bitcoin.generateSecrets = true;

  # Enable Bitcoin Core
  services.bitcoind = {
    enable = true;

    # Use signet for workshop (faster sync, free test coins)
    extraConfig = ''
      # Signet configuration (default signet)
      signet=1

      # RPC settings
      server=1

      # Index transactions (required for electrs)
      txindex=1

      # Reduce memory usage for workshop/demo
      dbcache=450
      maxmempool=300
    '';
  };

  # Enable Electrs (Electrum server)
  services.electrs = {
    enable = true;
    # electrs will automatically connect to bitcoind
    # and serve on default port 50001
  };

  # Enable c-lightning (Lightning Network daemon)
  services.clightning = {
    enable = true;
    # c-lightning automatically integrates with bitcoind
  };

  # Enable RTL (Ride The Lightning web interface)
  services.rtl = {
    enable = true;

    # Enable c-lightning node in RTL
    nodes.clightning.enable = true;

    # Configure network access
    address = "0.0.0.0";  # Listen on all interfaces
    port = 3000;
  };

  # Enable the nix-bitcoin operator user for easy CLI access
  nix-bitcoin.operator = {
    enable = true;
    name = "operator";
  };

  # Create the operator user with password
  users.users.operator = {
    isNormalUser = true;
    password = "workshop4";  # For demo only - use SSH keys in production!
  };

  # Useful utilities
  environment.systemPackages = with pkgs; [
    vim
    btop
    curl
  ];

  # Container networking
  networking.useHostResolvConf = lib.mkForce false;
  services.resolved.enable = true;

  # Open firewall for services
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22    # SSH
      3000  # RTL web interface
    ];
  };

  system.stateVersion = "24.11";
}
```

**Configuration breakdown:**

1. **`nix-bitcoin.generateSecrets = true`**: Automatically generates RPC passwords, macaroons, and other secrets
2. **`services.bitcoind`**: Bitcoin Core with signet for fast testing
3. **`services.electrs`**: Electrum server - nix-bitcoin automatically configures it to connect to bitcoind
4. **`services.clightning`**: Lightning Network node - automatically connected to bitcoind
5. **`services.rtl`**: Web interface - automatically configured with Lightning credentials
6. **`nix-bitcoin.operator`**: Special user with access to all Bitcoin/Lightning CLI tools

**What nix-bitcoin does automatically:**

- Generates secure RPC credentials for bitcoind
- Configures electrs to use those credentials
- Sets up c-lightning with bitcoind RPC access
- Configures RTL with c-lightning macaroons
- Creates proper Unix users and permissions
- Sets up systemd service dependencies
- Manages data directories and file ownership
- Handles secret rotation and secure storage

You didn't have to configure any of this manually!

---

## Step 3: Build and Start the Container

Build the container configuration:

```bash
sudo nixos-container create demo --flake .#demo-container
```

This will:
1. Fetch nix-bitcoin from GitHub
2. Build Bitcoin Core, electrs, c-lightning, and RTL from source
3. Create the container with all services configured
4. Set up users, permissions, and secrets

**This takes 10-20 minutes on first build** as everything compiles from source. Subsequent builds use Nix's cache.

Start the container:

```bash
sudo nixos-container start demo
```

Check the container status:

```bash
sudo nixos-container status demo
```

You should see `up`.

---

## Step 4: Watch Services Start

Get a root shell in the container:

```bash
sudo nixos-container root-login demo
```

Inside the container, check running services:

```bash
# Check NixOS version
nixos-version

# List all running services
systemctl --type=service --state=running

# Check Bitcoin services specifically
systemctl status bitcoind
systemctl status electrs
systemctl status clightning
systemctl status rtl
```

All four services should show as `active (running)`.

Watch Bitcoin sync in real-time:

```bash
# Follow bitcoind logs
journalctl -f -u bitcoind
```

You'll see Bitcoin connecting to signet peers and downloading blocks. Press `Ctrl+C` when you've seen enough.

Check electrs logs:

```bash
# Electrs waits for bitcoind to sync before indexing
journalctl -f -u electrs
```

Electrs will show "waiting for bitcoind" messages until the blockchain is synced. Press `Ctrl+C` to stop.

Check Lightning logs:

```bash
# c-lightning also waits for full sync
journalctl -f -u clightning
```

Press `Ctrl+C` to stop.

Exit the container for now:

```bash
exit
```

---

## Step 5: Monitor Blockchain Sync Progress

From your host system, you can check sync progress without entering the container:

```bash
# Check sync status
sudo nixos-container run demo -- su operator -c "bitcoin-cli -signet getblockchaininfo"
```

Look for these fields:
- **`blocks`**: Current block height
- **`headers`**: Known block headers (target height)
- **`verificationprogress`**: Percentage synced (0.0 to 1.0)

When `blocks` equals `headers` and `verificationprogress` is close to 1.0, sync is complete.

Watch storage grow:

```bash
# Check Bitcoin data directory size
sudo du -sh /var/lib/nixos-containers/demo/var/lib/bitcoind/

# Update every 5 seconds
watch -n 5 'sudo du -sh /var/lib/nixos-containers/demo/var/lib/bitcoind/'
```

Signet blockchain is much smaller than testnet (~5-10GB) and mainnet (~600GB), but you'll still see it growing.

---

## Step 6: Use Bitcoin CLI

Once sync begins, you can interact with your node. Get back into the container:

```bash
sudo nixos-container root-login demo
```

Switch to the operator user (has access to all CLI tools):

```bash
su - operator
```

**Important:** The operator user has special privileges configured by nix-bitcoin. It can access:
- `bitcoin-cli` with automatic RPC credentials
- `lightning-cli` with proper authentication
- All necessary socket files and data directories

Use Bitcoin CLI:

```bash
# Get network info
bitcoin-cli -signet getnetworkinfo

# Check peer connections
bitcoin-cli -signet getconnectioncount
bitcoin-cli -signet getpeerinfo | head -30

# Check blockchain sync status
bitcoin-cli -signet getblockchaininfo
```

The `-signet` flag tells bitcoin-cli to use the signet network configuration.

---

## Step 7: Use Lightning Network CLI

With the operator user, you can also manage your Lightning node:

```bash
# Get Lightning node info
lightning-cli --network=signet getinfo
```

You'll see your node's public key, block height, and other information.

Create a Lightning wallet:

```bash
# Generate a new Lightning wallet address
lightning-cli --network=signet newaddr
```

Get faucet coins (if needed):

1. Note the address from `newaddr`
2. Visit a signet faucet: https://signetfaucet.com/
3. Send signet coins to your address

Check your on-chain balance:

```bash
# Check Lightning wallet balance
lightning-cli --network=signet listfunds
```

List Lightning channels (will be empty at first):

```bash
# View Lightning channels
lightning-cli --network=signet listchannels | head -50
```

Open a Lightning channel (requires synced blockchain and on-chain funds):

```bash
# Connect to a peer (example peer ID)
lightning-cli --network=signet connect <node-pubkey>@<host>:<port>

# Fund a channel (requires on-chain balance)
lightning-cli --network=signet fundchannel <node-pubkey> <amount-in-sats>
```

Exit the operator user and container:

```bash
exit  # Exit operator user
exit  # Exit container
```

---

## Step 8: Access RTL Web Interface

RTL (Ride The Lightning) provides a web interface for managing your Lightning node. Let's access it.

Get the container's IP address:

```bash
sudo nixos-container show-ip demo
```

Note the IP address (e.g., `10.233.1.2`).

RTL runs on port 3000. However, **you need an access password** that nix-bitcoin generates automatically.

Get the RTL password:

```bash
# The password is stored in nix-bitcoin's secrets directory
sudo nixos-container root-login demo
cat /var/secrets/rtl/cl-rest/access.key
exit
```

Copy the password (long hex string).

Open your browser and navigate to:

```
http://<container-ip>:3000
```

For example: `http://10.233.1.2:3000`

**RTL Login:**
- **Password:** Paste the access key you copied

Once logged in, you'll see:
- **Dashboard**: Node info, balances, channels
- **On-chain**: Wallet transactions and addresses
- **Lightning**: Channels, peers, payments
- **Transactions**: Payment history
- **Routing**: Routing statistics

You can manage your Lightning node entirely from this interface!

---

## Step 9: Verify Service Integration

Let's verify all services are properly integrated and talking to each other.

Get back into the container:

```bash
sudo nixos-container root-login demo
su - operator
```

Check electrs is serving data:

```bash
# Electrs listens on port 50001
# Check if it's serving blockchain data
curl http://localhost:50001 2>&1 | head -5
```

Electrs uses a binary protocol, so you'll see garbled output - that's expected. The important thing is it responds.

Verify c-lightning sees the blockchain:

```bash
# Lightning should show the same block height as bitcoind
lightning-cli --network=signet getinfo | grep blockheight
bitcoin-cli -signet getblockchaininfo | grep blocks
```

The heights should match (or be very close).

Check that RTL can communicate with c-lightning:

```bash
# Check RTL logs
journalctl -u rtl -n 20
```

You should see successful connections to the c-lightning REST API.

Exit:

```bash
exit  # Exit operator
exit  # Exit container
```

---

## Understanding nix-bitcoin's Architecture

**What makes nix-bitcoin special:**

1. **Secret Management**: All secrets are generated and stored in `/var/secrets/` with proper permissions
2. **Service Integration**: Services automatically discover each other's credentials
3. **Security Hardening**: Services run as dedicated users with minimal permissions
4. **Declarative**: Entire stack defined in configuration files
5. **Reproducible**: Same configuration = same result everywhere

**Directory Structure:**

```
/var/lib/bitcoind/          # Bitcoin data (blockchain, chainstate)
/var/lib/electrs/           # Electrs index database
/var/lib/clightning/        # Lightning Network data (channels, wallet)
/var/secrets/               # Auto-generated secrets (RPC passwords, macaroons)
/etc/nix-bitcoin-secrets/   # Optional manual secret overrides
```

**User and Permissions:**

nix-bitcoin creates these users automatically:
- `bitcoin`: Runs bitcoind
- `electrs`: Runs electrs, can read bitcoind RPC credentials
- `clightning`: Runs c-lightning, can read bitcoind RPC credentials
- `rtl`: Runs RTL web interface, can read c-lightning macaroons
- `operator`: Special user with access to all CLI tools

Each service user can only access what it needs - principle of least privilege.

---

## Comparing Manual Setup vs nix-bitcoin

Let's compare what we did in workshop 2 vs what nix-bitcoin does:

| Configuration | Workshop 2 (Manual) | Workshop 4 (nix-bitcoin) |
|---------------|---------------------|--------------------------|
| Bitcoin Core | Manually configure RPC | `services.bitcoind.enable = true` |
| RPC credentials | Hardcode in config | Auto-generated secrets |
| Electrs | Not covered | `services.electrs.enable = true` |
| Electrs auth | Would need manual setup | Automatic integration |
| Lightning | Not covered | `services.clightning.enable = true` |
| Lightning auth | Would need manual setup | Automatic integration |
| Web interface | Simple http server | Full RTL interface |
| Secret management | Plaintext passwords | Encrypted, proper permissions |
| User permissions | Root or manual users | Dedicated service users |
| Service dependencies | Manual systemd config | Automatic ordering |

**Manual setup for workshop 2 equivalent:**
- 1 service (bitcoind)
- ~20 lines of configuration
- RPC password in plaintext

**nix-bitcoin setup:**
- 4 integrated services
- ~30 lines of configuration
- Automatic secret generation
- Production-ready security

---

## Going Further: Using a Custom Bitcoin Fork

Remember workshop 3 where we used a custom Bitcoin fork (Mutinynet)? You can do the same with nix-bitcoin using overlays.

**Scenario:** You want to use Mutinynet's Bitcoin fork with nix-bitcoin.

Add this to your `flake.nix`:

```nix
{
  description = "Bitcoin Stack NixOS Container - Workshop 4 (nix-bitcoin + Mutinynet)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nix-bitcoin.url = "github:fort-nix/nix-bitcoin/release";
  };

  outputs = { self, nixpkgs, nix-bitcoin }:
    let
      system = "x86_64-linux";

      # Create an overlay for custom bitcoin package
      bitcoinOverlay = final: prev: {
        bitcoin = prev.bitcoin.overrideAttrs (oldAttrs: {
          src = final.fetchFromGitHub {
            owner = "benthecarman";
            repo = "bitcoin";
            rev = "v29.0";
            sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # Get real hash
          };
          version = "29.0-mutinynet";
        });
      };
    in {
      nixosConfigurations.demo-container = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # Apply the overlay
          { nixpkgs.overlays = [ bitcoinOverlay ]; }

          # Import nix-bitcoin modules
          nix-bitcoin.nixosModules.default

          # Your configuration
          ./container-configuration.nix
        ];
      };
    };
}
```

Then update `container-configuration.nix` with Mutinynet signet parameters:

```nix
  services.bitcoind = {
    enable = true;

    extraConfig = ''
      # Mutinynet signet (as in workshop 3)
      signet=1
      signetchallenge=512102f7561d208dd9ae99bf497273e16f389bdbd6c4742ddb8e6b216e64fa2928ad8f51ae
      addnode=45.79.52.207:38333
      dnsseed=0
      signetblocktime=30

      # Required for electrs
      server=1
      txindex=1

      # Memory settings
      dbcache=450
      maxmempool=300
    '';
  };
```

**What's happening:**

1. **Overlay**: Replaces the bitcoin package with Mutinynet fork (same technique as workshop 3)
2. **nix-bitcoin integration**: All nix-bitcoin modules now use your custom Bitcoin package
3. **Automatic propagation**: electrs, c-lightning, and CLI tools all use the Mutinynet fork

This is the power of Nix overlays - change the package once, and all dependent services automatically use the new version.

**Important notes:**

- You must use the same hash-verification process from workshop 3
- nix-bitcoin's modules work with Bitcoin forks as long as they maintain RPC compatibility
- Some advanced forks might need additional module customization

---

## Storage Considerations

Like workshop 2, blockchain data grows continuously.

**Signet storage (what we're using):**
- Signet blockchain: ~5-10GB
- Electrs index: ~5-10GB
- Lightning data: <1GB
- **Total: ~15-20GB**

**Mainnet storage (production):**
- Blockchain: ~600GB
- Electrs index: ~100GB
- Lightning data: ~1-5GB
- **Total: ~700GB+**

Check storage usage:

```bash
# Total container storage
sudo du -sh /var/lib/nixos-containers/demo/

# Breakdown by service
sudo du -h --max-depth=2 /var/lib/nixos-containers/demo/var/lib/
```

As with workshop 2, **containers are not ideal for production Bitcoin nodes** with large datasets. For production:
- Use dedicated NixOS systems or VMs
- Use external storage or dedicated data partitions
- Consider storage optimization flags in bitcoind
- Plan for continuous growth

---

## Security Considerations

**This workshop uses insecure settings for educational purposes:**

- `nix-bitcoin.generateSecrets = true` - generates secrets automatically
- Operator user with simple password
- RTL accessible without HTTPS
- No SSH key authentication required

**For production, you must:**

1. **Manage secrets manually:**
   ```nix
   nix-bitcoin.generateSecrets = false;
   # Create secrets in /etc/nix-bitcoin-secrets manually
   ```

2. **Use SSH keys:**
   ```nix
   services.openssh.settings.PasswordAuthentication = false;
   users.users.operator.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3..." ];
   ```

3. **Enable HTTPS for RTL:**
   ```nix
   services.rtl.enforceTLS = true;
   # Configure TLS certificates
   ```

4. **Harden network access:**
   ```nix
   services.rtl.address = "127.0.0.1";  # Only localhost
   # Use reverse proxy (nginx) with authentication
   ```

5. **Regular backups:**
   - Lightning channel states
   - Bitcoin wallet files
   - Configuration files

6. **Monitor and update:**
   - Enable automatic security updates
   - Monitor service logs
   - Subscribe to nix-bitcoin security announcements

See the [nix-bitcoin security documentation](https://github.com/fort-nix/nix-bitcoin/blob/master/docs/security.md) for complete hardening guidance.

---

## Cleanup (Optional)

Stop and remove the container:

```bash
# Stop the container
sudo nixos-container stop demo

# Destroy the container
sudo nixos-container destroy demo
```

Remove data directories:

```bash
# Remove all Bitcoin data
sudo rm -rf /var/lib/nixos-containers/demo
```

This frees up all storage used by the blockchain, indexes, and Lightning data.

---

## What We Learned

✅ Deployed a complete Bitcoin stack with nix-bitcoin
✅ Understood how nix-bitcoin handles service integration
✅ Managed Bitcoin and Lightning nodes via CLI
✅ Accessed Lightning node through RTL web interface
✅ Learned about automatic secret management
✅ Compared manual configuration vs nix-bitcoin approach
✅ Explored using custom Bitcoin forks with nix-bitcoin

**The power of nix-bitcoin:**

- **Integration**: Services automatically discover and authenticate with each other
- **Security**: Proper user permissions, secret management, and hardening by default
- **Simplicity**: Deploy complex stacks with minimal configuration
- **Reproducibility**: Same configuration produces identical systems
- **Maintainability**: Update one service without breaking others
- **Production-ready**: Battle-tested configurations used by real Bitcoin nodes

---

## Next Steps

**Explore more nix-bitcoin services:**

nix-bitcoin supports many more Bitcoin services. Add any of these to your `container-configuration.nix`:

```nix
# Lightning Network
services.lnd.enable = true;              # LND (alternative to c-lightning)
services.eclair.enable = true;           # Eclair (another Lightning implementation)

# Web interfaces
services.btcpayserver.enable = true;     # BTCPay Server (payment processor)
services.mempool.enable = true;          # Mempool.space explorer
services.thunderhub.enable = true;       # ThunderHub (RTL alternative)

# Privacy and indexing
services.joinmarket.enable = true;       # JoinMarket (CoinJoin)
services.nbxplorer.enable = true;        # NBXplorer (accounting)

# Monitoring
services.nodeinfo.enable = true;         # Node info web page
```

Each service is automatically integrated with bitcoind and other services!

**Deploy to production:**

When ready for production:
1. Study the [nix-bitcoin documentation](https://github.com/fort-nix/nix-bitcoin)
2. Review the [security guide](https://github.com/fort-nix/nix-bitcoin/blob/master/docs/security.md)
3. Set up proper secret management
4. Configure backups
5. Deploy on dedicated hardware or VPS
6. Enable monitoring and alerting

**Join the community:**

- nix-bitcoin GitHub: https://github.com/fort-nix/nix-bitcoin
- NixOS Discourse: https://discourse.nixos.org/
- Bitcoin StackExchange: https://bitcoin.stackexchange.com/

---

## Resources

- [nix-bitcoin GitHub Repository](https://github.com/fort-nix/nix-bitcoin)
- [nix-bitcoin Documentation](https://github.com/fort-nix/nix-bitcoin/blob/master/docs/)
- [nix-bitcoin Example Configurations](https://github.com/fort-nix/nix-bitcoin/tree/master/examples)
- [RTL Documentation](https://github.com/Ride-The-Lightning/RTL)
- [c-lightning Documentation](https://lightning.readthedocs.io/)
- [Electrs Documentation](https://github.com/romanz/electrs)

---

## Notes

- **First build time:** 10-20 minutes as all services compile from source
- **Sync time:** Signet syncs in 30-60 minutes (much faster than testnet/mainnet)
- **Storage:** Plan for 15-20GB for signet, 700GB+ for mainnet
- **Lightning channels:** Require synced blockchain and on-chain funding
- **RTL access:** Password is in `/var/secrets/rtl/cl-rest/access.key`
- **Operator user:** Has automatic access to all Bitcoin/Lightning CLI tools
- **Production use:** Follow security hardening guidelines before deploying

---

**Workshop Duration:** 45 minutes (configuration, build, initial sync)
**Difficulty:** Intermediate
**Prerequisites:** [workshop-1](../workshop-1/), [workshop-2](../workshop-2/), [workshop-3](../workshop-3/) required
