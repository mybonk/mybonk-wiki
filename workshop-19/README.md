# Workshop 19: Bitcoin and Lightning Recovery

## Overview

Running a Bitcoin and Lightning node is only half the job. The other half is knowing exactly what to do when something breaks — and being able to prove, before disaster strikes, that your backups actually work.

This workshop uses the `lightning` container from workshop-10 as the **healthy reference node**. You will create a second container, `restored`, to act as the **node under recovery**. You will deliberately destroy data at the Bitcoin layer and at the Lightning layer, then restore it, verifying at each step that services come back clean and funds are intact.

> **We are on Mutinynet Signet throughout.** Block time is 30 seconds (20× faster than mainnet). Data sizes are proportionally smaller. Recovery operations that would take hours on mainnet complete in minutes here. The exact numbers are worked out below.

**What you will learn:**

- What data you *must* back up at the Bitcoin layer and why
- What data you *must* back up at the Lightning layer and why
- The hierarchy of Lightning recovery (HSM secret → static channel backup → full database) and what each level gets you back
- How to copy blockchain state between nodes using `rsync` without triggering a full IBD
- What happens if you restore an *old* Lightning database — and why that can be worse than no backup at all
- How to verify a recovery is genuine, not just "the daemon started"

**Prerequisites:**

- [Workshop 10](../workshop-10/) completed — container `lightning` is created and working, `bitcoind` and `clightning` are running and synced to Mutinynet signet
- The host bridge `br-containers` is up (set up in workshop-10)
- `workshop-10/manage-containers.sh` is present — you will use it to create `restored`

---

## Architecture

The `lightning` container is your healthy reference node. `restored` is a fresh container that simulates a new or wiped machine that needs to be restored. Data flows **from `lightning` to `restored`**.

```
┌─────────────────────────────────────────────────────────────────────┐
│                          HOST MACHINE (NixOS)                       │
│                                                                     │
│  ┌─────────────────────────────┐  ┌──────────────────────────────┐  │
│  │  lightning (HEALTHY)        │  │  restored (RECOVERY)│  │
│  │                             │  │                               │  │
│  │  bitcoind (signet)          │  │  bitcoind (signet)            │  │
│  │  /var/lib/bitcoind/signet/  │  │  /var/lib/bitcoind/signet/    │  │
│  │                             │  │                               │  │
│  │  clightning (signet)        │  │  clightning (signet)          │  │
│  │  /var/lib/clightning/signet/│  │  /var/lib/clightning/signet/  │  │
│  │                             ├─►│                               │  │
│  │  IP: 10.233.0.X             │  │  IP: 10.233.0.Y               │  │
│  └─────────────────────────────┘  └──────────────────────────────┘  │
│                                                                     │
│  Host filesystem (direct access, no SSH):                           │
│  /var/lib/nixos-containers/lightning/          (lightning's root)   │
│  /var/lib/nixos-containers/restored/ (recovery node root) │
│                                                                     │
│  Bridge: br-containers (10.233.0.0/16)  DHCP/DNS: 10.233.0.1       │
└─────────────────────────────────────────────────────────────────────┘
```

**Recovery scenarios covered:**

```
PART 1 — Bitcoin layer
  Scenario A: Blockchain data lost (blocks/ and chainstate/ deleted)
    → Restore from healthy node via rsync. No IBD required.

PART 2 — Lightning layer
  Scenario B: Lightning database lost, hsm_secret survives
    → Recover on-chain funds only. Channels are gone.
  Scenario C: Lightning database lost, emergency.recover survives
    → Force-close all channels. Funds return on-chain after timelock.
  Scenario D: Full Lightning database backup available
    → Full recovery. Channels can resume.
```

---

## A note on timing: Mutinynet vs mainnet

Everything in this workshop runs faster than it would on a production node. Before you start, understand the numbers so the workshop does not feel anticlimactic — the operations are real, just compressed.

### Blockchain data size

| Network | Blockchain size | Block time | Approx. block count (May 2026) |
|---------|----------------|------------|-------------------------------|
| **Bitcoin Mainnet** | ~600 GB | 10 min | ~895,000 |
| **Mutinynet Signet** | ~5–8 GB | 30 sec | ~2,700,000 |
| **Regtest (workshop-9)** | < 100 MB | on-demand | ephemeral |

Mutinynet has *more blocks* than mainnet (faster cadence) but each block is nearly empty — only the Mutinynet signer's coinbase transaction and the handful of test transactions people broadcast. At roughly 2–3 KB per block average:

```
2,700,000 blocks × 2.5 KB = ~6.75 GB  (chainstate adds another ~0.5–1 GB)
Total blockchain data to copy: ~5–8 GB
```

### rsync / scp timing between containers on the same host

`lightning` and `restored` are on the same machine. They communicate via the host kernel's bridge (`br-containers`). There is **zero real network latency** — TCP round-trip between them is < 0.1 ms. The only overhead for SSH-based transfers is AES encryption on the CPU.

| Transfer method | Estimated throughput | Time for 7 GB |
|----------------|---------------------|---------------|
| Host filesystem rsync (no SSH) | 500 MB/s – 2 GB/s (disk limited) | **4–14 seconds** |
| rsync over SSH between containers | 150–400 MB/s (CPU/AES limited) | **18–47 seconds** |
| scp between containers | 100–300 MB/s | **24–70 seconds** |
| Fresh IBD from Mutinynet peers | ~10–30 MB/s download + verification | **5–20 minutes** |

**The key insight:** copying verified blockchain state from a healthy peer is 10–30× faster than downloading and re-verifying every block from scratch (IBD). On mainnet, this difference is the gap between 30 minutes and 6+ hours. Backups matter.

For comparison if this were mainnet:
```
600 GB / 200 MB/s (rsync over LAN) = 3000 seconds = ~50 minutes
600 GB / 20 MB/s  (IBD download)   = 30000 seconds = ~8 hours (+ verification)
```

### Lightning data sizes

Lightning's critical files are tiny by comparison:

| File | Size | What it contains |
|------|------|-----------------|
| `hsm_secret` | **32 bytes** | Master key — derives all node keys and on-chain wallet keys |
| `emergency.recover` | **57 bytes** | Static channel backup — enough to trigger force-close of all channels |
| `lightningd.sqlite3` | **1–50 MB** (grows with channels/payments) | Full channel state, HTLCs, payment history |
| `gossip_store` | **1–5 MB** | Channel graph cache — not critical, rebuilt from network |

scp of the critical files: **< 1 second** in all cases.

---

## Terminal setup

This workshop runs commands across three terminals simultaneously. Use the `start_workshop_terms.sh` from workshop-10 to open the right layout, or open terminals manually:

```
Terminal 1 (HOST)                — run commands with sudo on the host machine
Terminal 2 (lightning)           — ssh operator@$(sudo nixos-container show-ip lightning)
Terminal 3 (restored)  — ssh operator@$(sudo nixos-container show-ip restored)
```

Store the container IPs in your host terminal at the start:

```bash
# HOST terminal
LN=$(sudo nixos-container show-ip lightning)
RC=$(sudo nixos-container show-ip restored)
echo "lightning:          $LN"
echo "restored: $RC"
```

---

## Initial setup: create restored

`lightning` is already running from workshop-10. `restored` does not exist yet — create it now using the workshop-10 helper script.

```bash
# HOST terminal — from the workshop-10 directory
cd ~/github/mybonk-wiki/workshop-10

sudo ./manage-containers.sh create restored
```

What this does:
1. Checks that `restored` is not already in `flake.nix` — if not, auto-adds a `nixosConfigurations.restored` entry using the standard `mkContainerConfig {}` function
2. Runs `nixos-container create restored --flake ".#restored" --bridge br-containers`

The result is a fresh container with the same nix-bitcoin stack as `lightning` (bitcoind + clightning, signet), but with an empty blockchain and no wallet history.

```bash
# HOST terminal — start both containers
sudo nixos-container start lightning
sudo nixos-container start restored

# Start bitcoind in each
sudo nixos-container run lightning -- systemctl start bitcoind
sudo nixos-container run restored -- systemctl start bitcoind

# Give bitcoind 30 seconds to initialise
sleep 30

# Verify both are up
sudo nixos-container run lightning -- bitcoin-cli -signet getblockchaininfo | jq '{chain, blocks, headers, verificationprogress}'
sudo nixos-container run restored -- bitcoin-cli -signet getblockchaininfo | jq '{chain, blocks, headers, verificationprogress}'
```

`lightning` should report `"initialblockdownload": false` (already synced). `restored` will show `"initialblockdownload": true` — it will begin IBD. **Do not wait for it to sync.** Part 1 of this workshop demonstrates how to skip IBD entirely by copying blockchain data from `lightning`.

### Open a Lightning channel between the two nodes

Before running recovery scenarios you need at least one open channel to make the Lightning recovery meaningful. First, complete Part 1 (blockchain sync) so `restored`'s bitcoind is functional, then come back here to open the channel.

```bash
# LIGHTNING terminal — get node ID and address
lightning-cli getinfo | jq '{id, alias, "our_address": .address[0]}'

# RESTORED terminal — get node ID and a funding address
lightning-cli getinfo | jq '.id'
lightning-cli newaddr | jq '.bech32'
```

Fund the address from the Mutinynet faucet at https://faucet.mutinynet.com/, then once coins confirm (30-second blocks — wait ~2 minutes):

```bash
# RESTORED terminal — connect to lightning and open a channel
# Replace NODE_ID and IP with lightning's values from above
lightning-cli connect NODE_ID_OF_LIGHTNING@$LN:9735
lightning-cli fundchannel NODE_ID_OF_LIGHTNING 500000

# Wait for the channel to confirm (~3 Mutinynet blocks = ~90 seconds)
watch lightning-cli listchannels
```

Once you see the channel in `listchannels` with `"active": true`, you are ready for Part 2.

---

## Part 1: Bitcoin Layer Recovery

### 1.1 — What to back up

The Bitcoin layer has two distinct classes of data:

**Blockchain data** (`blocks/` and `chainstate/`):
These are fully reproducible from the network. If lost, you can re-download them from peers (IBD). You do not need to back these up — but copying them from a healthy peer is far faster than IBD if you have one available.

**Wallet data** (`wallets/` and the nix-bitcoin HD master seed):
This is where your private keys live. Loss means loss of funds. nix-bitcoin generates the wallet master seed and stores it in `/etc/nix-bitcoin-secrets/bitcoin-hdmaster-seed`. This is what you **must** back up.

```bash
# RESTORED terminal (or any container) — inspect your secrets
sudo ls -la /etc/nix-bitcoin-secrets/
# You will see:
#   bitcoin-hdmaster-seed        ← BACK THIS UP
#   bitcoin-rpcpassword-privileged
#   bitcoin-rpcpassword-public
#   clightning-rpc-password      (if RTL is enabled)
```

```bash
# RESTORED terminal — read the HD master seed (store this offline, securely)
sudo cat /etc/nix-bitcoin-secrets/bitcoin-hdmaster-seed
```

> **Security note:** In a real deployment this seed goes in a hardware wallet, an encrypted offline backup, or a steel plate. In this workshop we treat it as an opaque string to backup and restore.

### 1.2 — Simulate blockchain data loss

You are going to delete the blockchain data from `restored` as if the disk had corrupted or been wiped, then restore it from `lightning`.

```bash
# RESTORED terminal — stop bitcoind cleanly first
sudo systemctl stop bitcoind

# Verify it stopped
sudo systemctl status bitcoind

# Delete blocks and chainstate (simulates disk failure or corruption)
sudo rm -rf /var/lib/bitcoind/signet/blocks/
sudo rm -rf /var/lib/bitcoind/signet/chainstate/

# Verify they are gone
ls /var/lib/bitcoind/signet/
# Should show: .cookie  settings.json  wallets/
# blocks/ and chainstate/ are gone

# Try starting bitcoind — it will fail to find its data
sudo systemctl start bitcoind
sleep 5
sudo journalctl -u bitcoind -n 20
# Expected: errors about missing blocks or reindex required
sudo systemctl stop bitcoind
```

### 1.3 — Restore blockchain from the healthy node

Two methods. Method A is faster because it bypasses SSH encryption; method B is what you would use from inside a container or from a remote location.

#### Method A: Direct host filesystem copy (fastest)

From the host, both containers' filesystems are directly accessible under `/var/lib/nixos-containers/`. No SSH, no encryption overhead — just a local copy at disk speed.

```bash
# HOST terminal — rsync blockchain from lightning to restored
# This uses the rsync pattern from baby-rabbit-holes.md, adapted for containers.
# --partial --inplace --append: safe for append-only blockchain data; survives interruption
# --exclude '*.lock': skip lock files that bitcoind holds while running

sudo rsync -av \
  --partial --inplace --append --progress \
  --exclude '*.lock' \
  /var/lib/nixos-containers/lightning/var/lib/bitcoind/signet/blocks \
  /var/lib/nixos-containers/lightning/var/lib/bitcoind/signet/chainstate \
  /var/lib/nixos-containers/restored/var/lib/bitcoind/signet/

# Fix ownership — files must belong to the 'bitcoin' user inside the container
# The UID/GID for 'bitcoin' is consistent across nix-bitcoin containers
sudo chown -R $(sudo nixos-container run restored -- id -u bitcoin):$(sudo nixos-container run restored -- id -g bitcoin) \
  /var/lib/nixos-containers/restored/var/lib/bitcoind/signet/blocks \
  /var/lib/nixos-containers/restored/var/lib/bitcoind/signet/chainstate
```

**Expected timing on this machine** (same-host, no network):
- NVMe SSD: ~4–14 seconds for ~7 GB
- SATA SSD: ~14–30 seconds for ~7 GB
- HDD: ~60–90 seconds for ~7 GB

Compare: a fresh IBD from Mutinynet peers would take **5–20 minutes** (download + signature verification for 2.7 million blocks). rsync wins every time when a healthy peer is available.

#### Method B: rsync over SSH between containers

Use this when the host filesystem is not directly accessible (remote node, different machine):

```bash
# RESTORED terminal — pull blockchain data from lightning over SSH
# lightning is reachable by hostname on the shared bridge network

sudo rsync -avz \
  --partial --inplace --append --progress \
  --exclude '*.lock' \
  root@lightning:/var/lib/bitcoind/signet/blocks \
  root@lightning:/var/lib/bitcoind/signet/chainstate \
  /var/lib/bitcoind/signet/

# Fix ownership
sudo chown -R bitcoin:bitcoin /var/lib/bitcoind/signet/
```

**Expected timing:** 18–47 seconds for ~7 GB (SSH/AES overhead, same-host bridge at 150–400 MB/s).

### 1.4 — Verify the blockchain recovery

```bash
# RESTORED terminal — start bitcoind
sudo systemctl start bitcoind
sleep 15

# Check it loaded the restored data correctly
bitcoin-cli -signet getblockchaininfo | jq '{chain, blocks, headers, verificationprogress, initialblockdownload}'
```

A successful recovery looks like:
```json
{
  "chain": "signet",
  "blocks": 2710543,
  "headers": 2710543,
  "verificationprogress": 0.9999,
  "initialblockdownload": false
}
```

`blocks` and `headers` should match `lightning`'s values (or be very close — a few blocks may have arrived during the copy). If `initialblockdownload` is `false`, Bitcoin considers itself synced. If it is `true`, the node is catching up from where the copy left off.

```bash
# Cross-check: compare block counts on both containers
sudo nixos-container run lightning -- bitcoin-cli -signet getblockcount
sudo nixos-container run restored -- bitcoin-cli -signet getblockcount
# Difference should be < 10 (a few 30-second blocks at most)
```

### 1.5 — What about a second run?

Run the rsync command again immediately:

```bash
# HOST terminal — second rsync run
sudo rsync -av \
  --partial --inplace --append --progress \
  --exclude '*.lock' \
  /var/lib/nixos-containers/lightning/var/lib/bitcoind/signet/blocks \
  /var/lib/nixos-containers/lightning/var/lib/bitcoind/signet/chainstate \
  /var/lib/nixos-containers/restored/var/lib/bitcoind/signet/
```

The `--append` flag means rsync only transfers data that was *appended* to existing files since the first run. On a blockchain — which is append-only by design — this means only the new blocks arrive in the second pass. If 100 new blocks arrived (50 minutes of Mutinynet time), only those 100 blocks transfer. The second run completes in **< 1 second** for zero new blocks, or a few seconds for a handful of new ones.

This is the basis of an incremental backup strategy: run rsync on a schedule (cron, systemd timer) and it transfers only what changed.

---

## Part 2: Lightning Layer Recovery

Lightning recovery is more nuanced than Bitcoin recovery. The wrong recovery can make things *worse* — specifically, restoring an old database can cause CLN to broadcast a channel state that your peer already considers revoked, triggering a **penalty transaction** that hands all channel funds to your peer. Understanding the three recovery levels protects you from this trap.

### 2.1 — The Lightning data hierarchy

```
/var/lib/clightning/signet/
├── hsm_secret          (32 bytes)  ← CRITICAL: master key, never leave home without it
├── emergency.recover   (57 bytes)  ← CRITICAL: static channel backup
├── lightningd.sqlite3  (~1–50 MB)  ← IMPORTANT: full channel database
├── gossip_store        (~1–5 MB)   ← NOT critical: channel graph, rebuilt automatically
├── ca.pem, server.pem, ...         ← TLS certificates, regenerated on start
└── lightning-rpc                   ← Unix socket, not a file, ignore
```

**What each backup level recovers:**

| Backup available | What you get back | What you lose |
|-----------------|-------------------|---------------|
| `hsm_secret` only | On-chain funds (wallet UTXOs) | All channel funds (irrecoverable) |
| `hsm_secret` + `emergency.recover` | On-chain funds + channel funds (after force-close + timelock) | Recent in-flight payments, routing fees |
| `hsm_secret` + `lightningd.sqlite3` (current) | Full channel state | Nothing — full recovery |
| `hsm_secret` + `lightningd.sqlite3` (old) | **DANGER** — may broadcast revoked states → penalty | You lose channel funds to your peer |

The danger of an old database is real. If your database backup is from 3 days ago and you had 50 payments since then, CLN will try to enforce a channel state your peers no longer recognise as the latest — and they are entitled to claim all funds in the channel as a penalty. **Always use the most recent database backup, or use `emergency.recover` instead.**

### 2.2 — Backup procedure

Run this on `restored`. In production, run it on a schedule.

```bash
# HOST terminal — back up critical Lightning files from restored
BACKUP_DIR="/root/lightning-backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR/restored"

sudo cp /var/lib/nixos-containers/restored/var/lib/clightning/signet/hsm_secret \
  "$BACKUP_DIR/restored/"
sudo cp /var/lib/nixos-containers/restored/var/lib/clightning/signet/emergency.recover \
  "$BACKUP_DIR/restored/"
sudo cp /var/lib/nixos-containers/restored/var/lib/clightning/signet/lightningd.sqlite3 \
  "$BACKUP_DIR/restored/"

ls -lh "$BACKUP_DIR/restored/"
```

Expected output:
```
/root/lightning-backups/20260520-143000/restored/:
-r-------- 1 root root   32 May 20 14:30 hsm_secret
-r-------- 1 root root   57 May 20 14:30 emergency.recover
-rw-r--r-- 1 root root 864K May 20 14:30 lightningd.sqlite3
```

Total backup size: **< 2 MB** per node. These fit on any medium, encrypted or not.

> **Automation:** In production, use a systemd timer or cron job to copy `lightningd.sqlite3` to a remote location after every block (every 30 seconds on Mutinynet, every 10 minutes on mainnet). The database file can be safely copied while CLN is running — SQLite's WAL mode ensures you always get a consistent snapshot.

### 2.3 — Scenario B: Recover on-chain funds from hsm_secret only

This is the minimum viable recovery. You lost the container, you have only the `hsm_secret`. You get your on-chain wallet back; channel funds are gone.

```bash
# RESTORED terminal — stop clightning, wipe the Lightning data directory
sudo systemctl stop clightning
sudo rm -rf /var/lib/clightning/signet/

# Restore only the hsm_secret
sudo mkdir -p /var/lib/clightning/signet/
sudo cp $BACKUP_DIR/restored/hsm_secret /var/lib/clightning/signet/
sudo chown -R clightning:clightning /var/lib/clightning/
sudo chmod 400 /var/lib/clightning/signet/hsm_secret

# Start clightning — it will start fresh with no channels but correct keys
sudo systemctl start clightning
sleep 10

# Check CLN started with the same node ID as before
lightning-cli getinfo | jq '.id'
# This MUST match the node ID you noted before the wipe.
# Same hsm_secret → same node ID. Different hsm_secret → different identity.
```

```bash
# Check on-chain wallet — the address is derived from hsm_secret
lightning-cli newaddr | jq '.bech32'
# Sweep any on-chain funds to this address or a hardware wallet
```

**What you do NOT recover:** channels and their balances. From your peer's (`lightning`) perspective your node disappeared. If you reconnect, they will see you have no channel state and cannot resume the channel.

```bash
# RESTORED terminal — CLN reports no channels
lightning-cli listchannels | jq '.channels | length'
# 0
```

### 2.4 — Scenario C: Recover channels using emergency.recover

`emergency.recover` contains a compressed static channel backup: it lists every channel you had, with enough information to ask your peers to force-close. You do not get the channel state back — you trigger an *emergency force-close*, after which the funds return on-chain after the CSV timelock expires.

```bash
# RESTORED terminal — stop clightning, wipe, restore hsm_secret + emergency.recover
sudo systemctl stop clightning
sudo rm -rf /var/lib/clightning/signet/
sudo mkdir -p /var/lib/clightning/signet/

sudo cp $BACKUP_DIR/restored/hsm_secret /var/lib/clightning/signet/
sudo cp $BACKUP_DIR/restored/emergency.recover /var/lib/clightning/signet/

sudo chown -R clightning:clightning /var/lib/clightning/
sudo chmod 400 /var/lib/clightning/signet/hsm_secret
sudo chmod 400 /var/lib/clightning/signet/emergency.recover

# Start clightning
sudo systemctl start clightning
sleep 15

# Trigger emergency recovery — CLN reads emergency.recover and signals peers to force-close
lightning-cli emergencyrecover
```

Expected response:
```json
{
   "stubs": [
      "channel_id_hex_here"
   ]
}
```

CLN now contacts each peer listed in `emergency.recover` and requests a force-close. Each peer will broadcast their version of the closing transaction. Funds become available on-chain after the CSV delay (typically 144 blocks on mainnet).

**On Mutinynet, 144 blocks = 144 × 30 seconds = 72 minutes.**

On mainnet, 144 blocks = ~24 hours.

```bash
# RESTORED terminal — watch for force-close transactions arriving on-chain
watch -n 5 'lightning-cli listfunds | jq ".channels[] | {channel_id, state, our_amount_msat}"'
# State will transition: CHANNELD_NORMAL → ONCHAIN → spendable
```

```bash
# LIGHTNING terminal — from the peer's perspective, observe the force-close
watch -n 5 'lightning-cli listchannels | jq ".channels[] | {short_channel_id, active}"'
# Channel becomes inactive after force-close broadcast
```

### 2.5 — Scenario D: Full recovery from lightningd.sqlite3

This is the gold standard: CLN resumes exactly where it left off. Use this when the database backup is current (taken minutes or hours ago, not days).

```bash
# RESTORED terminal — stop clightning, wipe, restore all three files
sudo systemctl stop clightning
sudo rm -rf /var/lib/clightning/signet/
sudo mkdir -p /var/lib/clightning/signet/

sudo cp $BACKUP_DIR/restored/hsm_secret /var/lib/clightning/signet/
sudo cp $BACKUP_DIR/restored/emergency.recover /var/lib/clightning/signet/
sudo cp $BACKUP_DIR/restored/lightningd.sqlite3 /var/lib/clightning/signet/

sudo chown -R clightning:clightning /var/lib/clightning/
sudo chmod 400 /var/lib/clightning/signet/hsm_secret
sudo chmod 400 /var/lib/clightning/signet/emergency.recover

# Start clightning
sudo systemctl start clightning
sleep 20
```

```bash
# RESTORED terminal — verify channels came back
lightning-cli getinfo | jq '{id, alias, num_active_channels}'
lightning-cli listchannels | jq '.channels[] | {short_channel_id, active, our_amount_msat: .amount_msat}'
```

CLN reconnects to peers automatically and resumes channel operation. If the database was recent enough (no missed HTLCs), the channels go straight to `CHANNELD_NORMAL` without any on-chain transactions.

```bash
# LIGHTNING terminal — peer sees the reconnection
lightning-cli listpeers | jq '.peers[] | {id, connected, num_channels}'
# connected: true — restored reconnected
```

#### ⚠️ Why an old database is dangerous

To make this concrete: create a payment from `restored` to `lightning`, *then* restore the pre-payment database.

```bash
# RESTORED terminal — note channel state BEFORE payment
lightning-cli listfunds | jq '.channels[] | {channel_id, our_amount_msat}'

# Make a payment to lightning
INVOICE=$(ssh root@lightning lightning-cli invoice 100000 test-payment "recovery test" | jq -r '.bolt11')
lightning-cli pay "$INVOICE"

# Note channel state AFTER payment — our_amount_msat decreased
lightning-cli listfunds | jq '.channels[] | {channel_id, our_amount_msat}'

# Now restore the PRE-payment database (which CLN's peer considers revoked)
sudo systemctl stop clightning
sudo cp $BACKUP_DIR/restored/lightningd.sqlite3 /var/lib/clightning/signet/
sudo chown clightning:clightning /var/lib/clightning/signet/lightningd.sqlite3
sudo systemctl start clightning
```

What happens next depends on the implementation. A production CLN node would detect the revoked state attempt and either refuse to broadcast it, or if it does broadcast it, the peer (`lightning`) would respond with a **penalty transaction** (also called a **justice transaction**) claiming the entire channel balance. In this workshop both ends are yours so no real funds are lost — but the lesson is clear.

**In production: never restore a database backup that is older than your last payment. Use `emergency.recover` if in doubt.**

---

## Verification checklist

After each recovery scenario, run this checklist before declaring success.

```bash
# RESTORED terminal

# 1. Node ID is unchanged
lightning-cli getinfo | jq '.id'
# Must match original node ID

# 2. Chain tip matches the healthy peer
lightning-cli getchaininfo | jq '{headercount, blockcount}'
sudo nixos-container run lightning -- lightning-cli getchaininfo | jq '{headercount, blockcount}'
# Both must report the same block height (within ~2 blocks)

# 3. Bitcoin RPC is working
bitcoin-cli -signet getblockcount

# 4. Channels in expected state
lightning-cli listchannels | jq '[.channels[] | {short_channel_id, active, state}]'

# 5. Funds visible
lightning-cli listfunds | jq '{onchain: [.outputs[] | {amount_msat}], channels: [.channels[] | {our_amount_msat}]}'
```

---

## Troubleshooting

**CLN starts but reports wrong node ID after restore:**
The `hsm_secret` you restored does not match the original. Check that the file was copied byte-for-byte:
```bash
# HOST terminal — compare hsm_secret checksums
sha256sum /root/lightning-backups/*/restored/hsm_secret
sha256sum /var/lib/nixos-containers/restored/var/lib/clightning/signet/hsm_secret
# Must match
```

**bitcoind fails to start after rsync restore:**
The ownership of restored files may be wrong. Fix it:
```bash
# HOST terminal
sudo chown -R $(sudo nixos-container run restored -- id -u bitcoin):$(sudo nixos-container run restored -- id -g bitcoin) \
  /var/lib/nixos-containers/restored/var/lib/bitcoind/
```

**emergencyrecover returns empty stubs:**
The `emergency.recover` file is from before any channels were opened. Back it up again now that channels exist, then retry.

**rsync is slow between containers:**
If throughput is below 50 MB/s over SSH, try the host filesystem method (Method A in Part 1) which bypasses SSH entirely and runs at disk speed.

**restored channel stuck in CLOSING after emergencyrecover:**
The CSV timelock is running. On Mutinynet (30-second blocks) a 144-block timelock expires in 72 minutes. Watch the channel state:
```bash
watch -n 30 'lightning-cli listfunds | jq ".channels[] | {state, our_amount_msat}"'
```

---

## Summary

| Layer | Backup target | Size | Method | Recovery time (Mutinynet) |
|-------|--------------|------|--------|--------------------------|
| Bitcoin blockchain | `blocks/` + `chainstate/` | ~7 GB | rsync from peer | 10–50 seconds |
| Bitcoin wallet | `bitcoin-hdmaster-seed` | < 1 KB | offline copy | immediate |
| Lightning key | `hsm_secret` | 32 bytes | offline copy | immediate |
| Lightning channels (minimal) | `emergency.recover` | 57 bytes | offline copy | 72 min (CSV timelock) |
| Lightning channels (full) | `lightningd.sqlite3` | 1–50 MB | frequent automated copy | < 30 seconds |

**The hierarchy to remember:**
1. `hsm_secret` is your identity and your on-chain key. Lose it, lose everything. Back it up offline, once, and never touch it again.
2. `emergency.recover` is your channel emergency brake. It is tiny. Back it up every time you open a new channel.
3. `lightningd.sqlite3` is your full state. Back it up continuously. **Never restore an old copy — use `emergency.recover` instead if the database is stale.**

---

## References

- [Workshop 10: Bitcoin VM + Lightning Container](../workshop-10/) — source of the container configuration and `manage-containers.sh` used here
- [nix-bitcoin secrets management](https://github.com/fort-nix/nix-bitcoin/blob/master/docs/secrets.md)
- [Core Lightning — backup and recovery](https://docs.corelightning.org/docs/backup-and-recovery)
- [BOLT 2: Peer Protocol — force-close and penalty transactions](https://github.com/lightning/bolts/blob/master/02-peer-protocol.md)
- [baby-rabbit-holes.md](../baby-rabbit-holes.md) — rsync, scp, and SSH patterns used in this workshop
