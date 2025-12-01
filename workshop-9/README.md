# Build and Destroy Bitcoin Nodes in NixOS Containers

## Introduction

This workshop teaches you how to run Bitcoin and Lightning Network nodes in NixOS containers using **nix-bitcoin**. You'll learn to create Bitcoin nodes on-demand, interact with them via CLI, and understand how blockchain data persists in containers.

### What Makes This Workshop Special?

- **Built on Workshop-8**: Uses the same dynamic container management approach
- **nix-bitcoin Integration**: Secure, pre-configured Bitcoin and Lightning services
- **Testnet Only**: Safe experimentation without risking real Bitcoin
- **Multiple Nodes**: Create and manage multiple Bitcoin nodes simultaneously
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
  - DHCP server (dnsmasq) running
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
  testnet = true;  # Run on testnet (safe for learning)
  
  extraConfig = ''
    txindex=1        # Enable transaction indexing
    mempoolfullrbf=1 # Maintain full mempool
  '';
};

# Enable Core Lightning
services.clightning = {
  enable = true;
  testnet = true;  # Must match bitcoind network
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

## Step 3: Understanding Testnet vs Mainnet

Before creating containers, it's important to understand the difference between testnet and mainnet.

### Testnet (What We Use)

**Characteristics:**
- Separate blockchain for testing
- No real financial value
- Smaller blockchain (~30-50GB as of 2025)
- Faster initial sync (hours vs days)
- Free testnet coins from faucets
- Same functionality as mainnet

**Ports:**
- RPC: 18332
- P2P: 18333

**Use cases:**
- Learning and experimentation
- Application development
- Testing without financial risk

**Getting testnet coins:**
```bash
# Inside container, generate address
bitcoin-cli -testnet getnewaddress

# Use a testnet faucet to send coins to this address:
# https://testnet-faucet.mempool.co/
# https://bitcoinfaucet.uo1.net/
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

**Important:** We do NOT use mainnet in this workshop. Always use testnet for learning.

---

## Step 4: Create Your First Bitcoin Node Container

Now let's create a Bitcoin node container. The `manage-containers.sh` script (included in this workshop directory) picks up the flake configuration from the **current directory**. All commands in this workshop should be run from within the workshop-9 directory.

### Create Bitcoin Container

```bash
# Make sure you're in workshop-9 directory
cd /path/to/mybonk-wiki/workshop-9

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

### Understanding Bitcoin Core Startup

When the container first starts, bitcoind begins downloading and verifying the testnet blockchain. This takes time!

**What happens during initial sync:**
1. Connects to Bitcoin testnet peers
2. Downloads block headers (~1-2 minutes)
3. Downloads full blocks (~30-50GB)
4. Verifies all blocks and transactions
5. Builds transaction index (if txindex=1)

**Total time:** Several hours depending on your system and network.

### Check Bitcoin Daemon Status

```bash
# Check if bitcoind is running
systemctl status bitcoind.service

# Expected output:
# ● bitcoind.service - Bitcoin daemon
#      Loaded: loaded
#      Active: active (running)
```

### Monitor Blockchain Sync Progress

The most important command for a new node:

```bash
# Check blockchain sync status
bitcoin-cli -testnet getblockchaininfo
```

**Key fields in output:**

```json
{
  "chain": "test",                    # Confirms testnet
  "blocks": 2615000,                  # Current block height
  "headers": 2615432,                 # Total headers downloaded
  "verificationprogress": 0.9998,     # 99.98% synced (1.0 = 100%)
  "initialblockdownload": false,      # true = still syncing, false = synced
  "size_on_disk": 45283934720,        # ~45GB blockchain data
}
```

**Understanding sync progress:**
- `blocks` < `headers`: Still downloading blocks
- `verificationprogress` < 1.0: Still verifying
- `initialblockdownload: true`: Initial sync in progress
- `initialblockdownload: false`: Sync complete! Node is ready.

### Monitor Sync in Real-Time

Watch sync progress update every 10 seconds:

```bash
# Watch blocks increase
watch -n 10 'bitcoin-cli -testnet getblockchaininfo | jq ".blocks, .verificationprogress"'

# Or more detailed view
watch -n 10 'bitcoin-cli -testnet getblockchaininfo | jq "{ blocks, headers, progress: .verificationprogress, syncing: .initialblockdownload }"'
```

Press Ctrl+C to stop watching.

### Basic Bitcoin CLI Commands

Once sync is complete (or even during sync), you can explore:

```bash
# Get network information
bitcoin-cli -testnet getnetworkinfo

# See peer connections
bitcoin-cli -testnet getpeerinfo | jq length
# Shows how many peers you're connected to

# Get wallet info (if you have a wallet)
bitcoin-cli -testnet getwalletinfo

# Create a new receiving address
bitcoin-cli -testnet getnewaddress

# Get blockchain info (we saw this earlier)
bitcoin-cli -testnet getblockchaininfo

# Check mempool (unconfirmed transactions)
bitcoin-cli -testnet getmempoolinfo

# Get info about a specific block (example: block 0 = genesis)
bitcoin-cli -testnet getblockhash 0
bitcoin-cli -testnet getblock $(bitcoin-cli -testnet getblockhash 0)
```

### Understanding bitcoin-cli Output

Most bitcoin-cli commands return JSON. Use `jq` to parse it:

```bash
# Get just the block count
bitcoin-cli -testnet getblockchaininfo | jq '.blocks'

# Get verification progress as percentage
bitcoin-cli -testnet getblockchaininfo | jq '.verificationprogress * 100'

# List peer IPs
bitcoin-cli -testnet getpeerinfo | jq '.[].addr'

# Count connections
bitcoin-cli -testnet getnetworkinfo | jq '.connections'
```

### Wait for Initial Sync

For the remaining steps in this workshop, you'll want bitcoind to be fully synced. You can:

**Option 1:** Wait for sync to complete (several hours)

```bash
# Check periodically
bitcoin-cli -testnet getblockchaininfo | jq '.initialblockdownload, .verificationprogress'
```

**Option 2:** Continue the workshop and return later

The blockchain will sync in the background. You can still:
- Create more containers
- Test networking
- Read ahead in the workshop
- Check logs

**Option 3:** Check logs to see what's happening

```bash
# View bitcoind logs
journalctl -u bitcoind.service -f

# Shows: Block download progress, peer connections, verification status
```

---

## Step 7: Interact with Core Lightning

Core Lightning (CLN) is a Lightning Network implementation that runs on top of Bitcoin.

### Prerequisites

Lightning requires a synced Bitcoin node. Check:

```bash
bitcoin-cli -testnet getblockchaininfo | jq '.initialblockdownload'
# Must be: false
```

If still true, bitcoind is still syncing. Lightning will wait.

### Check Lightning Status

```bash
# Check if clightning service is running
systemctl status clightning.service

# Expected output:
# ● clightning.service - Core Lightning daemon
#      Active: active (running)
```

### Basic Lightning CLI Commands

```bash
# Get Lightning node information
lightning-cli --testnet getinfo

# Expected output includes:
# {
#   "id": "03a1b2c3...",              # Your node's public key
#   "alias": "btc1",                  # Your node's alias (hostname)
#   "color": "000000",                # Node color in explorers
#   "num_peers": 0,                   # Connected Lightning peers
#   "num_active_channels": 0,         # Open payment channels
#   "num_inactive_channels": 0,
#   "num_pending_channels": 0,
#   "blockheight": 2615432,           # Bitcoin block height
#   "network": "testnet"              # Confirms testnet
# }
```

### Lightning Wallet Commands

Core Lightning has its own on-chain wallet for managing channel funds:

```bash
# Check Lightning wallet balance
lightning-cli --testnet listfunds

# Generate new Lightning wallet address
lightning-cli --testnet newaddr

# List all wallet addresses
lightning-cli --testnet listfunds | jq '.outputs'
```

### Funding Your Lightning Node

To open Lightning channels, you need testnet Bitcoin in your Lightning wallet:

```bash
# 1. Generate a Lightning wallet address
LIGHTNING_ADDR=$(lightning-cli --testnet newaddr | jq -r '.bech32')
echo "Lightning wallet address: $LIGHTNING_ADDR"

# 2. Send testnet coins to this address
#    Use a testnet faucet: https://testnet-faucet.mempool.co/

# 3. Wait for confirmation (1 block = ~10 minutes)
#    Watch for incoming transaction:
watch -n 10 'lightning-cli --testnet listfunds | jq ".outputs"'

# 4. Once confirmed, you'll see funds available
lightning-cli --testnet listfunds
```

### Connect to Another Lightning Node

To test Lightning, you need to connect to other Lightning nodes:

```bash
# Connect to a public testnet Lightning node
# Format: lightning-cli --testnet connect <node_id>@<ip>:<port>

# Example (replace with actual testnet node):
# lightning-cli --testnet connect 03a1b2c3d4...@testnet.lnode.example.com:9735

# List connected peers
lightning-cli --testnet listpeers

# Open a payment channel (requires funds)
# lightning-cli --testnet fundchannel <node_id> <amount_in_satoshis>
```

### Lightning Commands Reference

```bash
# Node information
lightning-cli --testnet getinfo

# Wallet management
lightning-cli --testnet listfunds           # Show wallet balance
lightning-cli --testnet newaddr             # Generate new address

# Peer connections
lightning-cli --testnet listpeers           # Show connected peers
lightning-cli --testnet connect <id>@<ip>   # Connect to peer

# Channel management
lightning-cli --testnet listchannels        # List all channels
lightning-cli --testnet fundchannel         # Open new channel
lightning-cli --testnet close               # Close channel

# Payments
lightning-cli --testnet invoice             # Create invoice
lightning-cli --testnet pay                 # Pay invoice
lightning-cli --testnet listinvoices        # List invoices
lightning-cli --testnet listpays            # List payments
```

---

## Step 8: Container Storage and Data Persistence

Understanding where blockchain data lives is crucial for managing Bitcoin nodes.

### Blockchain Data Location

**Inside Container:**
```
/var/lib/bitcoind/              # Bitcoin data directory
├── testnet3/                   # Testnet-specific data
│   ├── blocks/                 # Block data (~45GB for testnet)
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

# Expected during sync: 5GB -> 10GB -> 20GB -> 45GB (full testnet)

# Check specific subdirectories
du -sh /var/lib/bitcoind/testnet3/blocks/
du -sh /var/lib/bitcoind/testnet3/chainstate/
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
├── testnet/                     # Testnet-specific data
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
# Blockchain data remains in /var/lib/nixos-containers/btc1/
```

**Container started again:**
```bash
sudo ./manage-containers.sh start btc1
# bitcoind continues from where it left off (no re-sync needed)
```

**Container destroyed:**
```bash
sudo ./manage-containers.sh destroy btc1
# ALL DATA DELETED including blockchain sync!
# You'll need to re-sync if you create a new container
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
ls -lh /var/lib/bitcoind/testnet3/

# Lightning files
ls -lh /var/lib/clightning/testnet/

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
bitcoin-cli -testnet addnode "$BTC2_IP:18333" "add"

# Verify connection
bitcoin-cli -testnet getpeerinfo | jq '.[] | select(.addr | contains("10.233.0"))'

# Shows btc2 in peer list!
```

### Managing Multiple Nodes

```bash
# Check sync status of all nodes
for container in btc1 btc2 btc3; do
  echo "=== $container ==="
  sudo ./manage-containers.sh run $container -- bitcoin-cli -testnet getblockchaininfo | jq '{blocks, progress: .verificationprogress}'
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
BTC1_ID=$(lightning-cli --testnet getinfo | jq -r '.id')
echo $BTC1_ID
exit

# In btc2: Connect to btc1 and open channel
sudo ./manage-containers.sh shell btc2
BTC1_IP=$(sudo ./manage-containers.sh ip btc1)
lightning-cli --testnet connect $BTC1_ID@$BTC1_IP:9735

# Open a channel (requires btc2 to have funds)
# lightning-cli --testnet fundchannel $BTC1_ID 1000000  # 0.01 tBTC in satoshis

# Check channel status
lightning-cli --testnet listchannels
```

This creates a payment channel between your two nodes!

---

## Troubleshooting

### Container Has No Network Connectivity

**Problem:** Container can't ping host or internet.

**Diagnosis:**
```bash
# Check if container has IP
sudo ./manage-containers.sh run btc1 -- ip addr show eth0

# Check if bridge exists
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
bitcoin-cli -testnet getnetworkinfo | jq '.connections'

# Should have 8-10 peers minimum
```

**Solution:**
```bash
# Add more peers manually (find testnet peers online)
bitcoin-cli -testnet addnode "testnet-seed.bitcoin.example.com" "add"

# Check progress
bitcoin-cli -testnet getblockchaininfo | jq '.verificationprogress'
```

### bitcoin-cli Returns "Connection Refused"

**Problem:** `bitcoin-cli` can't connect to bitcoind.

**Diagnosis:**
```bash
# Check if bitcoind is running
systemctl status bitcoind

# Check if RPC is listening
ss -tlnp | grep 18332
```

**Solution:**
```bash
# Start bitcoind if not running
systemctl start bitcoind

# Wait a moment, then retry
bitcoin-cli -testnet getblockchaininfo
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
bitcoin-cli -testnet getblockchaininfo | jq '.initialblockdownload'

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

- **Testnet vs Mainnet**: Why testnet is essential for learning and development
- **Blockchain Sync**: The initial block download process and how to monitor it
- **RPC Interface**: How bitcoin-cli communicates with bitcoind
- **Lightning Network**: How Lightning builds on Bitcoin for fast, cheap payments
- **Node Connectivity**: How Bitcoin nodes discover and communicate with peers

---

## Going Further

### Ideas for Experimentation

**Explore Bitcoin Transactions:**
```bash
# Get testnet coins from faucet
ADDR=$(bitcoin-cli -testnet getnewaddress)
echo $ADDR
# Visit: https://testnet-faucet.mempool.co/

# Watch for incoming transaction
watch -n 10 'bitcoin-cli -testnet getbalance'

# Send coins
bitcoin-cli -testnet sendtoaddress <address> 0.001
```

**Set Up a Private Bitcoin Network:**

Create multiple nodes and connect them in a private network (regtest mode instead of testnet).

**Integrate with Applications:**

- Run Electrs (Electrum server) in a container
- Run BTCPay Server for accepting Bitcoin payments
- Connect Specter Desktop for wallet management

**Lightning Experiments:**

- Open channels between your nodes
- Send payments over Lightning
- Explore routing and multi-hop payments

### Additional Resources

**nix-bitcoin:**
- [GitHub Repository](https://github.com/fort-nix/nix-bitcoin)
- [Documentation](https://github.com/fort-nix/nix-bitcoin/tree/master/docs)
- [Example Configurations](https://github.com/fort-nix/nix-bitcoin/tree/master/examples)

**Bitcoin:**
- [Bitcoin Core Documentation](https://bitcoin.org/en/bitcoin-core/)
- [Bitcoin Developer Guide](https://developer.bitcoin.org/)
- [Testnet Faucets](https://testnet-faucet.mempool.co/)

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

**Workshop Duration**: 2-4 hours (mostly waiting for blockchain sync)
**Difficulty**: Intermediate
**NixOS Version**: 25.05
**Network Range**: 10.233.0.0/24 (from workshop-8)
**Bitcoin Network**: Testnet
**Data Storage**: ~45GB per testnet node (full sync)
