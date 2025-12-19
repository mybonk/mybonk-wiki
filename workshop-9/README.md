---
layout: default
title: Workshop 9
nav_order: 9
---

# Containers Management in NixOS (nix-bitcoin, REGTEST)

## Introduction

This workshop teaches you how to run Bitcoin and Lightning Network nodes in NixOS containers using **nix-bitcoin**. You'll learn to create Bitcoin nodes on-demand, interact with them via CLI, and understand how blockchain data persists in containers.

**IMPORTANT**: Workshop-8 is the **mandatory foundation** for this workshop. Workshop-9 builds directly on top of the container infrastructure established in workshop-8. You must complete workshop-8 first to understand the container management concepts and setup.

### What Makes This Workshop Special?

- **Built on Workshop-8 Foundation**: Extends the dynamic container management with Bitcoin-specific services
- **nix-bitcoin Integration**: Secure, pre-configured Bitcoin and Lightning services
- **Regtest Mode**: Local testing environment with instant block generation
- **Multiple Nodes**: Create and manage multiple Bitcoin nodes simultaneously
- **Automated Testing**: Use the `test.sh` to run automatically all the commands in this document.
- **Practical CLI Skills**: Real-world Bitcoin and Lightning commands

### Why nix-bitcoin?

[nix-bitcoin](https://github.com/fort-nix/nix-bitcoin) is a collection of Nix packages and NixOS modules for Bitcoin services. It provides:

- **Security-first design**: Hardened configurations following best practices
- **Easy setup**: Pre-configured services that just work
- **Comprehensive**: Bitcoin Core, Lightning (CLN, LND), Electrs, BTCPay, and more
- **Reproducible**: Declarative configurations for consistent deployments
- **Battle-tested**: Used in production by many Bitcoin users

For this workshop, we use it to easily spin up Bitcoin Core (bitcoind) and Core Lightning (CLN) in containers.

### Prerequisites

- **Must have completed [workshop-8](../workshop-8)** - This workshop builds directly on workshop-8's infrastructure
- The host system must already have:
  - Bridge network (br-containers) configured
  - DHCP server (dnsmasq) running with DNS configured to point containers to itself (10.233.0.1)
    - **Important**: This DNS configuration allows containers to resolve each other's hostnames (e.g., `ping demo`)
    - See [workshop-8's DNS section](../workshop-8/README.md#key-networking-concepts) for details on how dnsmasq enables container-to-container hostname resolution
  - NAT and IP forwarding enabled
- Basic understanding of Bitcoin and Lightning concepts (helpful but not required)

### Learning Objectives

By the end of this workshop, you will:

- Understand how to integrate nix-bitcoin into container configurations
- Create Bitcoin and Lightning node containers from the command line
- Interact with bitcoind using bitcoin-cli
- Interact with Core Lightning using lightning-cli
- Understand where blockchain data is stored and how to monitor it
- Manage multiple Bitcoin nodes simultaneously

---

## Step 1: Verify Workshop-8 Setup

Before proceeding, ensure your workshop-8 infrastructure is working correctly.

### Clone or Navigate to Repository

```bash
cd /path/to/mybonk-wiki/workshop-9
```

### Verify Host Prerequisites

Run these checks from your host system:

```bash
# 1. Check bridge interface exists
ip addr show br-containers
# Should show: inet 10.233.0.1/24

# 2. Verify IP forwarding is enabled
cat /proc/sys/net/ipv4/ip_forward
# Should output: 1

# 3. Check DHCP server is running
systemctl status dnsmasq.service
# Should show: active (running)

# 4. Verify NAT rules exist
sudo iptables -t nat -L -n -v | grep MASQUERADE
# Should show MASQUERADE rule for br-containers
```

If any of these checks fail, return to [workshop-8](../workshop-8) and complete the host setup steps.

### Test Basic Container Creation (Optional)

You can verify the container management works by returning to [workshop-8](../workshop-8) and testing there first. If workshop-8 containers work correctly, you're ready for Bitcoin containers in workshop-9!

---

## Step 2: Understand the Workshop-9 Files

This workshop adds Bitcoin-specific configuration on top of workshop-8's foundation.

### File: flake.nix

The key difference from workshop-8 is the addition of nix-bitcoin:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  
  # NEW: nix-bitcoin provides Bitcoin and Lightning services
  nix-bitcoin.url = "github:fort-nix/nix-bitcoin/release";
};

mkContainerConfig = { hostname }: {
  imports = [
    ./configuration.nix
    # NEW: Import nix-bitcoin module
    nix-bitcoin.nixosModules.default
  ];
  # ... rest of config
};
```

**What this enables**: Access to pre-configured, secure Bitcoin services (bitcoind, clightning, electrs, etc.)

### File: configuration.nix

The main additions are in the nix-bitcoin configuration section:

```nix
# Enable Bitcoin Core daemon
services.bitcoind = {
  enable = true;
  regtest = true;  # Run in regtest mode (perfect for learning)

  extraConfig = ''
    txindex=1  # Enable transaction indexing
  '';
};

# Enable Core Lightning
services.clightning = {
  enable = true;
  # CLN automatically follows bitcoind's network (regtest)
};
```

**What this does**:
- Installs and configures Bitcoin Core
- Installs and configures Core Lightning
- Sets up RPC access for CLI interaction
- Configures integration between bitcoind and clightning

### Common Packages Added

The configuration includes useful tools for Bitcoin development:

```nix
environment.systemPackages = with pkgs; [
  vim htop btop curl git jq  # jq is essential for parsing bitcoin-cli JSON output
];
```

---

## Step 3: Understanding Regtest vs Mainnet

Before creating containers, it's important to understand the difference between regtest and mainnet.

### Regtest (What We Use)

**Characteristics:**
- Local testing environment (no external network)
- No blockchain download required (starts empty)
- Instant block generation - mine blocks on demand!
- Works completely offline
- Perfect control over the network
- No real financial value

**Ports:**
- RPC: 18443
- P2P: 18444

**Use cases:**
- Learning and development
- Instant testing (no waiting for blocks)
- Workshop environments
- Application development

**Getting regtest coins:**
```bash
# Inside container, generate an address
bitcoin-cli -regtest getnewaddress

# Mine 101 blocks to that address (need 100 confirmations for coinbase)
bitcoin-cli -regtest generatetoaddress 101 <your-address>

# Check your balance - you now have 50 BTC per block!
bitcoin-cli -regtest getbalance
```

### Mainnet (Production)

**Characteristics:**
- Real Bitcoin with real value
- Full blockchain (~500GB+)
- Requires proper security
- Initial sync takes days
- Real financial consequences

**Ports:**
- RPC: 8332
- P2P: 8333

**Important:** We do NOT use mainnet in this workshop. Always use regtest for learning.

---

## Step 4: Create Your First Bitcoin Node Container

Now let's create a Bitcoin node container. The `manage-containers.sh` script (included in this workshop directory) picks up the flake configuration from the **current directory**. All commands in this workshop should be run from within the workshop-9 directory.

### Important: Git Tracking Required

Nix flakes require files to be tracked by git. Before creating containers, ensure files are staged:

```bash
# Initialize git if not already done
git init

# Stage the workshop files
git add flake.nix configuration.nix manage-containers.sh

# Or stage everything
git add .
```

You don't need to commit, just stage the files with `git add`.

### Create Bitcoin Container

```bash
# Make sure you're in workshop-9 directory
cd ./workshop-9

# Create a Bitcoin node container
# The script uses the flake.nix from current directory (workshop-9)
sudo ./manage-containers.sh create btc1

# Expected output:
# ================================
# Creating NixOS Container
# ================================
# Container Name: btc1
# ...
# Container Setup Complete!
# ================================
```

**How this works:**
- Script is in `workshop-8/` but executes from `workshop-9/` directory
- It automatically finds `flake.nix` in current directory (workshop-9)
- Adds `--bridge br-containers` for networking
- Container gets IP via DHCP (10.233.0.50-150 range)

### Verify Container Status

```bash
# Check container is running and has IP
sudo ./manage-containers.sh list

# Get specific container IP
sudo ./manage-containers.sh ip btc1
```

---

## Step 5: Quick Connectivity Check

Verify basic networking works (same tests from workshop-8, using the management script).

```bash
# Test container-to-host ping
sudo ./manage-containers.sh run btc1 -- ping -c 2 10.233.0.1

# Test internet access
sudo ./manage-containers.sh run btc1 -- ping -c 2 8.8.8.8

# Test DNS resolution
sudo ./manage-containers.sh run btc1 -- curl -I https://bitcoin.org/

# Access container shell for interactive testing
sudo ./manage-containers.sh shell btc1
# (Type 'exit' to return to host)
```

For detailed networking information, see [workshop-8 Step 4](../workshop-8/README.md#step-4-test-container-connectivity).

---

## Step 6: Interact with bitcoind

Now for the main event - working with your Bitcoin node!

### Access the Container

```bash
sudo ./manage-containers.sh shell btc1
```

### Understanding Bitcoin Core Startup in Regtest

When the container first starts in regtest mode, bitcoind creates an **empty blockchain** - no download required!

**What happens during startup:**
1. Creates regtest directory structure
2. Starts with genesis block only (block 0)
3. Waits for you to generate blocks on demand
4. No network connections (regtest is local-only)
5. Ready to use immediately!

**Total time:** Seconds! No blockchain sync needed.

### Check Bitcoin Daemon Status

```bash
# Check that bitcoind is running
systemctl status bitcoind.service

# Expected output:
# ● bitcoind.service - Bitcoin daemon
#      Loaded: loaded
#      Active: active (running)
```

### Monitor Blockchain Sync Progress


```bash
# Check blockchain sync status
bitcoin-cli getblockchaininfo
```

**Key fields in output:**

```json
{
  "chain": "regtest",                 # Confirms regtest mode
  "blocks": 0,                        # Starts at 0 (only genesis block)
  "headers": 0,                       # No headers to download
  "verificationprogress": 1.0,        # Always 100% (no sync needed in regtest)
  "initialblockdownload": false,      # Already "synced" (empty chain)
  "size_on_disk": 293,                # Tiny! Just genesis block
}
```

### Generate Your Blocks On Demand

Unlike on MAINET, in regtest YOU control the blocks generation. Let's create some blocks:

```bash
# 1. Generate a new address to receive mining rewards
bitcoin-cli -regtest getnewaddress

# 2. Mine 101 blocks to that address
# (Need 100 confirmations before spendable)
bitcoin-cli -regtest generatetoaddress 101 <your-address-from-step-1>

# 3. Check your balance - you should have 50 BTC per block!
bitcoin-cli -regtest getbalance

# 4. Verify block count increased
bitcoin-cli -regtest getblockchaininfo | jq '.blocks'
# Should show: 101
```

**What just happened:**
- You created 101 blocks instantly (no waiting!)
- Each block gave you 50 BTC mining reward
- You now have ~5050 BTC to experiment with!

### Basic Bitcoin CLI Commands

Now you can explore with your regtest Bitcoin:

```bash
# Get network information
bitcoin-cli -regtest getnetworkinfo

# See peer connections (will be 0 in regtest - local only)
bitcoin-cli -regtest getpeerinfo | jq length

# Get wallet info
bitcoin-cli -regtest getwalletinfo

# Create a new receiving address
bitcoin-cli -regtest getnewaddress

# Mine more blocks anytime you need them!
bitcoin-cli -regtest generatetoaddress 10 <address>

# Get blockchain info (we saw this earlier)
bitcoin-cli -regtest getblockchaininfo

# Check mempool (unconfirmed transactions)
bitcoin-cli -regtest getmempoolinfo

# Get info about a specific block (example: block 0 = genesis)
bitcoin-cli -regtest getblockhash 0
bitcoin-cli -regtest getblock $(bitcoin-cli -regtest getblockhash 0)
```

### Understanding bitcoin-cli Output

Most bitcoin-cli commands return JSON. Use `jq` to parse it:

```bash
# Get just the block count
bitcoin-cli -regtest getblockchaininfo | jq '.blocks'

# Get verification progress as percentage
bitcoin-cli -regtest getblockchaininfo | jq '.verificationprogress * 100'

# List peer IPs
bitcoin-cli -regtest getpeerinfo | jq '.[].addr'

# Count connections
bitcoin-cli -regtest getnetworkinfo | jq '.connections'
```
---

## Step 7: Interact with Core Lightning

Core Lightning (CLN) is a Lightning Network implementation that runs on top of Bitcoin.

### Prerequisites

Lightning requires a synced Bitcoin node. Check:

```bash
bitcoin-cli -regtest getblockchaininfo | jq '.initialblockdownload'
# Must be: false
```

If still true, bitcoind is still syncing. Lightning will wait.

### Check Lightning Status

```bash
# Check that clightning service is running
systemctl status clightning.service

```

### Basic Lightning CLI Commands

```bash
# Get Lightning node information
lightning-cli --network=regtest getinfo

# Expected output includes:
# {
#   "id": "03a1b2c3...",              # Your node's public key
#   "alias": "btc1",                  # Your node's alias (hostname)
#   "color": "000000",                # Node color in explorers
#   "num_peers": 0,                   # Connected Lightning peers
#   "num_active_channels": 0,         # Open payment channels
#   "num_inactive_channels": 0,
#   "num_pending_channels": 0,
#   "blockheight": 101,               # Bitcoin block height (regtest starts at 0)
#   "network": "regtest"              # Confirms regtest mode
# }
```

### Lightning Wallet Commands

Core Lightning has its own on-chain wallet for managing channel funds:

```bash
# Check Lightning wallet balance
lightning-cli --network=regtest listfunds

# Generate new Lightning wallet address
lightning-cli --network=regtest newaddr

# List all wallet addresses
lightning-cli --network=regtest listfunds | jq '.outputs'
```

### Funding Your Lightning Node

To open Lightning channels, you need Bitcoin in your Lightning wallet. In regtest, send from your bitcoind wallet:

```bash
# 1. Generate a Lightning wallet address
LIGHTNING_ADDR=$(lightning-cli --network=regtest newaddr | jq -r '.bech32')
echo "Lightning wallet address: $LIGHTNING_ADDR"

# 2. Send Bitcoin from your bitcoind wallet to Lightning
bitcoin-cli -regtest sendtoaddress "$LIGHTNING_ADDR" 1

# 3. Mine a block to confirm the transaction
bitcoin-cli -regtest generatetoaddress 1 $(bitcoin-cli -regtest getnewaddress)

# 4. Check funds are now available in Lightning wallet
lightning-cli --network=regtest listfunds
```

### Connect to Another Lightning Node

To test Lightning in regtest, connect to another container's Lightning node:

```bash
# In regtest, connect to other containers on your local network
# Format: lightning-cli --network=regtest connect <node_id>@<container_ip>:9735

# Example: Get node ID from second container first
# On btc2 container: lightning-cli --network=regtest getinfo | jq -r '.id'

# Then from btc1, connect to btc2:
# lightning-cli --network=regtest connect <btc2_node_id>@<btc2_ip>:9735

# List connected peers
lightning-cli --network=regtest listpeers

# Open a payment channel (requires funds)
# lightning-cli --network=regtest fundchannel <node_id> <amount_in_satoshis>
```

### Lightning Commands Reference

```bash
# Node information
lightning-cli --network=regtest getinfo

# Wallet management
lightning-cli --network=regtest listfunds           # Show wallet balance
lightning-cli --network=regtest newaddr             # Generate new address

# Peer connections
lightning-cli --network=regtest listpeers           # Show connected peers
lightning-cli --network=regtest connect <id>@<ip>   # Connect to peer

# Channel management
lightning-cli --network=regtest listchannels        # List all channels
lightning-cli --network=regtest fundchannel         # Open new channel
lightning-cli --network=regtest close               # Close channel

# Payments
lightning-cli --network=regtest invoice             # Create invoice
lightning-cli --network=regtest pay                 # Pay invoice
lightning-cli --network=regtest listinvoices        # List invoices
lightning-cli --network=regtest listpays            # List payments
```

---

## Step 8: Container Storage and Data Persistence

Understanding where blockchain data lives is crucial for managing Bitcoin nodes.

### Blockchain Data Location

**Inside Container:**
```
/var/lib/bitcoind/              # Bitcoin data directory
├── regtest/                    # Regtest-specific data
│   ├── blocks/                 # Block data (tiny - only blocks you generate)
│   ├── chainstate/             # UTXO set (current state)
│   ├── indexes/                # txindex if enabled
│   └── debug.log               # Bitcoin debug logs
```

**On Host System:**
```
/var/lib/nixos-containers/btc1/var/lib/bitcoind/
```

The container's filesystem is just a directory on the host!

### Check Disk Usage

From inside the container:

```bash
# Check Bitcoin data directory size
du -sh /var/lib/bitcoind/

# In regtest: starts tiny (<1MB), grows only as you generate blocks

# Check specific subdirectories
du -sh /var/lib/bitcoind/regtest/blocks/
du -sh /var/lib/bitcoind/regtest/chainstate/
```

From the host:

```bash
# Check container's total disk usage
sudo du -sh /var/lib/nixos-containers/btc1/

# Check Bitcoin data specifically
sudo du -sh /var/lib/nixos-containers/btc1/var/lib/bitcoind/
```

### Lightning Data Location

Core Lightning data is stored separately:

**Inside Container:**
```
/var/lib/clightning/             # Lightning data directory
├── regtest/                     # Regtest-specific data
│   ├── lightningd.sqlite3       # Lightning database
│   ├── hsm_secret               # Node identity (KEEP SECRET!)
│   └── bitcoin/                 # Bitcoin backend integration
```

**On Host:**
```
/var/lib/nixos-containers/btc1/var/lib/clightning/
```

### Data Persistence

**Container stopped:**
```bash
sudo ./manage-containers.sh stop btc1
# Data remains in /var/lib/nixos-containers/btc1/
```

**Container started again:**
```bash
sudo ./manage-containers.sh start btc1
# bitcoind and clightning continue from where they left off
```

**Container destroyed:**
```bash
sudo ./manage-containers.sh destroy btc1
# ALL DATA DELETED including generated blocks and channels!
# You'll start fresh if you create a new container
```

### Monitoring Logs

Bitcoin and Lightning logs are managed by systemd:

```bash
# View Bitcoin logs (inside container)
journalctl -u bitcoind.service -f

# View Lightning logs
journalctl -u clightning.service -f

# View logs from host (without entering container)
sudo ./manage-containers.sh run btc1 -- journalctl -u bitcoind.service -n 50
```

### Checking File Locations

Verify paths from inside container:

```bash
# Bitcoin files
ls -lh /var/lib/bitcoind/regtest/

# Lightning files
ls -lh /var/lib/clightning/regtest/

# Check Bitcoin config
cat /etc/bitcoin/bitcoin.conf

# Check Lightning config
cat /etc/clightning/config
```

---

## Step 9: Create Multiple Bitcoin Nodes

One powerful feature: running multiple Bitcoin nodes simultaneously!

### Why Multiple Nodes?

- **Testing**: Simulate multi-node Bitcoin networks
- **Lightning**: Open channels between your own nodes
- **Development**: Test applications against multiple nodes
- **Learning**: Compare node states and behaviors

### Create a Second Node

```bash
cd /path/to/mybonk-wiki/workshop-9

# Create second Bitcoin node (auto-starts after creation)
sudo ./manage-containers.sh create btc2
```

### Create Multiple Nodes at Once

```bash
# Create btc3, btc4, btc5 (each auto-starts after creation)
for i in 3 4 5; do
  sudo ./manage-containers.sh create btc$i
done
```

Note: The manage-containers.sh script uses the flake from the current directory (workshop-9), so all containers get the Bitcoin configuration.

### List All Bitcoin Containers

```bash
# Show all containers with IPs and status
sudo ./manage-containers.sh list

# Expected output shows: NAME, STATUS, IP, CREATION-DATE
```

### Get IPs of All Nodes

```bash
# Get IP of specific container
sudo ./manage-containers.sh ip btc1

# Or use the list command to see all IPs at once
sudo ./manage-containers.sh list
```

### Test Node-to-Node Communication

Bitcoin nodes can communicate with each other:

```bash
# Get btc2's IP
BTC2_IP=$(sudo ./manage-containers.sh ip btc2)

# From btc1, ping btc2
sudo ./manage-containers.sh run btc1 -- ping -c 2 $BTC2_IP

# From btc1, SSH to btc2
sudo ./manage-containers.sh run btc1 -- ssh root@$BTC2_IP hostname
# Enter password when prompted: nixos
```

### Connect Bitcoin Nodes as Peers

Bitcoin nodes can connect to each other directly:

```bash
# Inside btc1, connect to btc2 as a peer
sudo ./manage-containers.sh shell btc1

# Get btc2's IP first (from another terminal or remember from above)
# Then add btc2 as a peer:
bitcoin-cli -regtest addnode "$BTC2_IP:18444" "add"

# Verify connection
bitcoin-cli -regtest getpeerinfo | jq '.[] | select(.addr | contains("10.233.0"))'

# Shows btc2 in peer list!
```

### Managing Multiple Nodes

```bash
# Check sync status of all nodes
for container in btc1 btc2 btc3; do
  echo "=== $container ==="
  sudo ./manage-containers.sh run $container -- bitcoin-cli -regtest getblockchaininfo | jq '{blocks, progress: .verificationprogress}'
done

# Stop all Bitcoin containers
for container in btc1 btc2 btc3 btc4 btc5; do
  sudo ./manage-containers.sh stop $container 2>/dev/null || true
done

# Start all Bitcoin containers
for container in btc1 btc2 btc3 btc4 btc5; do
  sudo ./manage-containers.sh start $container 2>/dev/null || true
done

# Destroy all Bitcoin containers (WARNING: deletes blockchain data!)
for container in btc1 btc2 btc3 btc4 btc5; do
  echo "Destroying $container"
  sudo ./manage-containers.sh destroy $container 2>/dev/null || true
done
```

### Opening Lightning Channels Between Your Nodes

Once btc1 and btc2 are synced and funded:

```bash
# In btc1: Get btc1's Lightning node ID
sudo ./manage-containers.sh shell btc1
BTC1_ID=$(lightning-cli --network=regtest getinfo | jq -r '.id')
echo $BTC1_ID
exit

# In btc2: Connect to btc1 and open channel
sudo ./manage-containers.sh shell btc2
BTC1_IP=$(sudo ./manage-containers.sh ip btc1)
lightning-cli --network=regtest connect $BTC1_ID@$BTC1_IP:9735

# Open a channel (requires btc2 to have funds)
# lightning-cli --network=regtest fundchannel $BTC1_ID 1000000  # 0.01 tBTC in satoshis

# Check channel status
lightning-cli --network=regtest listchannels
```

This creates a payment channel between your two nodes!

---

## Troubleshooting

### Container Has No Network Connectivity

**Problem:** Container can't ping host or internet.

**Diagnosis:**
```bash
# Check that container has IP
sudo ./manage-containers.sh run btc1 -- ip addr show eth0

# Check that bridge exists
ip addr show br-containers
```

**Solution:**
```bash
# Recreate container using manage-containers.sh (automatically adds --bridge)
sudo ./manage-containers.sh destroy btc1
sudo ./manage-containers.sh create btc1
```

See [workshop-8 troubleshooting](../workshop-8/README.md#troubleshooting-connectivity) for detailed networking diagnostics.

### Bitcoin Daemon Won't Start

**Problem:** `systemctl status bitcoind` shows failed.

**Diagnosis:**
```bash
# Check logs
sudo ./manage-containers.sh run btc1 -- journalctl -u bitcoind.service -n 50

# Common issues:
# - Corrupted blockchain data
# - Insufficient disk space
# - Configuration errors
```

**Solution:**
```bash
# Check disk space
df -h

# If corrupted, destroy and recreate container
sudo ./manage-containers.sh destroy btc1
sudo ./manage-containers.sh create btc1
```

### Blockchain Sync Very Slow

**Problem:** Sync taking longer than expected.

**Diagnosis:**
```bash
# Check number of peers
bitcoin-cli -regtest getnetworkinfo | jq '.connections'

# Should have 8-10 peers minimum
```

**Solution:**
```bash
# In regtest, there are no external peers
# Only connect to other local containers

# Check progress
bitcoin-cli -regtest getblockchaininfo | jq '.verificationprogress'
```

### bitcoin-cli Returns "Connection Refused"

**Problem:** `bitcoin-cli` can't connect to bitcoind.

**Diagnosis:**
```bash
# Check that bitcoind is running
systemctl status bitcoind

# Check that RPC is listening
ss -tlnp | grep 18443
```

**Solution:**
```bash
# Start bitcoind if not running
systemctl start bitcoind

# Wait a moment, then retry
bitcoin-cli -regtest getblockchaininfo
```

### Lightning Won't Start

**Problem:** Core Lightning service fails to start.

**Diagnosis:**
```bash
# Check Lightning logs
journalctl -u clightning.service -n 50

# Common cause: Bitcoin not synced yet
```

**Solution:**
```bash
# Verify Bitcoin is synced
bitcoin-cli -regtest getblockchaininfo | jq '.initialblockdownload'

# Must be: false

# If false and Lightning still fails, check logs for specific error
journalctl -u clightning.service -f
```

### "Not Enough Space" Error

**Problem:** Container runs out of disk space during sync.

**Solution:**
```bash
# Check host disk space
df -h

# If using a small disk, consider:
# 1. Enable pruning in configuration.nix (reduces to ~5GB)
# 2. Use external storage
# 3. Use a host with more space
```

---

## What You Learned

Congratulations! You've gained practical experience with:

### Bitcoin and Lightning Skills

- **nix-bitcoin Integration**: How to use nix-bitcoin modules in NixOS configurations
- **Bitcoin Node Management**: Creating, starting, and managing Bitcoin Core nodes
- **Lightning Node Management**: Running Core Lightning on top of Bitcoin Core
- **CLI Proficiency**: Using bitcoin-cli and lightning-cli for node interaction
- **Blockchain Monitoring**: Checking sync status, peers, mempool, and network info
- **Data Persistence**: Understanding where blockchain data lives and how it persists

### NixOS and Container Skills

- **Flake Integration**: Combining multiple flake inputs (nixpkgs + nix-bitcoin)
- **Module System**: How NixOS modules enable complex services with simple config
- **Container Networking**: Using workshop-8's networking for Bitcoin containers
- **Declarative Bitcoin**: Defining Bitcoin services in code, not manual setup
- **Multi-Node Management**: Running multiple Bitcoin nodes simultaneously

### Bitcoin Concepts

- **Regtest vs Mainnet**: Why regtest is perfect for learning and development
- **Blockchain Sync**: The initial block download process and how to monitor it
- **RPC Interface**: How bitcoin-cli communicates with bitcoind
- **Lightning Network**: How Lightning builds on Bitcoin for fast, cheap payments
- **Node Connectivity**: How Bitcoin nodes discover and communicate with peers

---

## Going Further

### Ideas for Experimentation

**Explore Bitcoin Transactions:**
```bash
# Generate blocks to fund your wallet
ADDR=$(bitcoin-cli -regtest getnewaddress)
bitcoin-cli -regtest generatetoaddress 101 $ADDR

# Watch balance grow as blocks mature
watch -n 5 'bitcoin-cli -regtest getbalance'

# Send coins to another address
bitcoin-cli -regtest sendtoaddress <address> 0.001

# Mine a block to confirm the transaction
bitcoin-cli -regtest generatetoaddress 1 $ADDR
```

**Set Up a Private Bitcoin Network:**

Create multiple regtest nodes and connect them in a private local network.

**Integrate with Applications:**

- Run Electrs (Electrum server) in a container
- Run BTCPay Server for accepting Bitcoin payments
- Connect Specter Desktop for wallet management

**Lightning Experiments:**

- Open channels between your nodes
- Send payments over Lightning
- Explore routing and multi-hop payments

### Automated Testing

This workshop includes an automated test suite (`test.sh`) that validates all configurations and commands using **actual NixOS containers** - the same infrastructure you use in the workshop!

**Why use automated tests?**

- **Validation**: Confirm the workshop configuration works before running manually
- **Regression testing**: Catch breaking changes when updating dependencies
- **Learning tool**: See all workshop commands executed automatically
- **Authentic**: Uses real containers via `manage-containers.sh`, not VMs
- **Fast**: Containers start in seconds, tests run quickly
- **Documentation**: Tests serve as executable examples

**Test coverage:**

The `test.sh` script validates all key workshop scenarios:

✅ Bitcoin Core starts in regtest mode
✅ Initial blockchain state (0 blocks)
✅ Block generation (101 blocks to reach coinbase maturity)
✅ Wallet balance after mining
✅ Core Lightning service starts and syncs
✅ Lightning wallet operations (newaddr, listfunds)
✅ Bitcoin transactions with fallbackfee enabled
✅ Multi-node Bitcoin peer connections
✅ Multi-node Lightning peer connections

**Running the tests:**

```bash
# Run all tests (containers auto-cleanup after)
cd /path/to/mybonk-wiki/workshop-9
sudo ./test.sh

# Expected output:
# ========================================
# Automated Test Suite
# Using: Actual NixOS Containers
# ========================================
#
# Test 1: Verify directory
# ✅ All required files present
#
# Test 2: Create first Bitcoin container (tbtc1)
# ✅ Container tbtc1 created successfully
#
# Test 3: Verify bitcoind service is running
# ✅ bitcoind.service is running
# [... tests continue ...]
#
# ========================================
# 🎉 All Tests Passed!
# ========================================

# Keep containers after testing (for debugging)
sudo ./test.sh --keep

# This leaves tbtc1 and tbtc2 running so you can inspect them:
# sudo ./manage-containers.sh shell tbtc1
# sudo ./manage-containers.sh list
```

**What happens during tests:**

1. **Container Creation**: Creates two containers (`tbtc1` and `tbtc2`) using `manage-containers.sh`
2. **Service Startup**: Waits for bitcoind and clightning to start
3. **Command Execution**: Runs all workshop commands (block generation, transactions, peer connections)
4. **Validation**: Verifies expected outputs (block counts, balances, network connections)
5. **Multi-node Testing**: Connects Bitcoin and Lightning nodes as peers
6. **Cleanup**: Destroys test containers (unless `--keep` flag is used)

**Understanding the test output:**

Each test displays:
- **Blue text**: Test number and description
- **Green ✅**: Successful test with details
- **Red ❌**: Failed test with error information
- **Yellow ℹ️**: Informational messages

Example:
```
Test 5: Generate 101 blocks (coinbase maturity)
ℹ️  Generated address: bcrt1qxy7z8k9...
✅ Generated 101 blocks

Test 6: Verify blockchain updated
✅ Block height: 101

Test 7: Check wallet balance after mining
✅ Wallet balance: 50.0 BTC
```

**When to run tests:**

- **Before starting the workshop**: Verify your configuration is correct
- **After modifying configuration.nix**: Ensure changes don't break functionality
- **Before committing changes**: Validate workshop still works
- **After system updates**: Ensure NixOS/nix-bitcoin updates don't break the workshop

**Debugging failed tests:**

If a test fails:

1. **Run with --keep flag** to inspect containers:
   ```bash
   sudo ./test.sh --keep
   ```

2. **Access the test container**:
   ```bash
   sudo ./manage-containers.sh shell tbtc1
   ```

3. **Check service logs**:
   ```bash
   sudo ./manage-containers.sh run tbtc1 -- journalctl -u bitcoind.service -n 50
   sudo ./manage-containers.sh run tbtc1 -- journalctl -u clightning.service -n 50
   ```

4. **Manually clean up** when done:
   ```bash
   sudo ./manage-containers.sh destroy tbtc1
   sudo ./manage-containers.sh destroy tbtc2
   ```

**How it works:**

The test script:
- Uses bash with strict error checking (`set -e`, `set -u`)
- Creates actual containers using the workshop's `manage-containers.sh` script
- Runs commands using `./manage-containers.sh run <container> -- <command>`
- Parses outputs using `grep`, `jq`, and other standard tools
- Tracks passed/failed tests with counters
- Returns exit code 0 on success, number of failures on error (for CI/CD)
- Automatically cleans up test containers on exit

This approach tests the **exact same infrastructure** students use in the workshop!

### Additional Resources

**nix-bitcoin:**
- [GitHub Repository](https://github.com/fort-nix/nix-bitcoin)
- [Documentation](https://github.com/fort-nix/nix-bitcoin/tree/master/docs)
- [Example Configurations](https://github.com/fort-nix/nix-bitcoin/tree/master/examples)

**Bitcoin:**
- [Bitcoin Core Documentation](https://bitcoin.org/en/bitcoin-core/)
- [Bitcoin Developer Guide](https://developer.bitcoin.org/)
- [Bitcoin Regtest Guide](https://developer.bitcoin.org/examples/testing.html)

**Lightning:**
- [Core Lightning Documentation](https://docs.corelightning.org/)
- [Lightning Network Specs](https://github.com/lightning/bolts)
- [Lightning Labs Guides](https://docs.lightning.engineering/)

**NixOS:**
- [NixOS Manual - Containers](https://nixos.org/manual/nixos/stable/#ch-containers)
- [Nix Flakes Guide](https://nixos.wiki/wiki/Flakes)
- [Workshop-8](../workshop-8) - Container networking foundation

---



## Summary

This workshop demonstrated how to:

1. Build on workshop-8's container networking infrastructure
2. Integrate nix-bitcoin for Bitcoin and Lightning services
3. Create Bitcoin node containers from the command line
4. Interact with bitcoind using bitcoin-cli
5. Interact with Core Lightning using lightning-cli
6. Understand blockchain data storage and persistence
7. Manage multiple Bitcoin nodes simultaneously

You now have the skills to experiment with Bitcoin and Lightning in a safe, reproducible environment using NixOS containers!

---

## Notes

**Workshop Duration**: 1-2 hours (no blockchain sync required!)
**Difficulty**: Intermediate
**NixOS Version**: 25.05
**Network Range**: 10.233.0.0/24 (from workshop-8)
**Bitcoin Network**: Regtest
**Data Storage**: <1MB per regtest node initially (grows as you generate blocks)
