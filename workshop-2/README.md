---
layout: default
title: Workshop 2
nav_order: 3
---

# Run Bitcoin as a service on NixOS in 2 Minutes

## Overview

This workshop demonstrates how to configure a service, here Bitcoin Core, on a NixOS system. This requires editing the `.nix` files (declarative configuration of the system) and the deployment of the configuration.
We'll use a NixOS container to efficiently demonstrate how this works - the same approach would work on full NixOS systems and VMs ([workshop-1](../workshop-1/README.md) showed you how to setup and interact with such a VM).

**Why testnet for this workshop?**

We'll run Bitcoin in testnet mode because mainnet is too heavy for quick experimentation:
- **Mainnet blockchain:** ~600GB (blocks only)
- **Mainnet with indexes:** ~750GB to 1TB+
- **Download time:** Days to weeks depending on connection and hardware

Compare this to testnet:
- **Testnet blockchain:** ~30GB
- **Testnet with indexes:** ~50GB
- **Download time:** Hours instead of days

For learning and testing, testnet provides the same functionality without the massive storage and time requirements of mainnet.

**What you'll learn:**
- Declaratively configure Bitcoin Core as a systemd service
- Use NixOS modules to manage Bitcoin configuration
- Inspect and verify the running Bitcoin node
- Understand container storage implications for blockchain data

**Prerequisites:**
- NixOS system (host machine)
- Basic understanding of Nix flakes
- Familiarity with NixOS containers (See [workshop-1](../workshop-1))

**Time:** ~2 minutes (setup) + hours (testnet sync)

---

## Step 1: Clone the Workshop Repository

Clone the workshop repository containing the configuration we prepared for you:

```bash
git clone git@github.com:mybonk/mybonk-wiki.git
cd mybonk-wiki/workshop-2
```

The repository contains two files:
- `flake.nix` - Defines the NixOS configuration for the container
- `container-configuration.nix` - Bitcoin system and services configuration

```nix
{
  description = "Bitcoin Core NixOS Container";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.bitcoin-container = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./container-configuration.nix
      ];
    };
  };
}
```

---

## Step 2: Configure Bitcoin Service

Edit `container-configuration.nix`:

```nix
{ config, pkgs, lib, ... }:

{
  boot.isContainer = true;
  networking.hostName = "demo-container";
  
  # Enable Bitcoin service
  services.bitcoind = {
    enable = true;
    
    # Bitcoin Core configuration
    extraConfig = ''
      # Run in testnet mode (for workshop purposes)
      testnet=1
      
      # RPC settings
      rpcuser=nixos
      rpcpassword=workshop2demo
      
      # Network settings
      listen=1
      server=1
      
      # Transaction index (enables full transaction queries)
      txindex=1
    '';
    
    # RPC access
    rpc = {
      users = {
        nixos = {
          name = "nixos";
          passwordHMAC = "workshop2demo";
        };
      };
    };
  };

  # Useful utilities
  environment.systemPackages = with pkgs; [
    bitcoin
    vim
    htop
  ];

  # Allow container to access the internet
  networking.useHostResolvConf = lib.mkForce false;
  
  services.resolved.enable = true;

  system.stateVersion = "24.11";
}
```

---

## Step 3: Build and Start the Container

Build the container configuration:

```bash
sudo nixos-container create demo --flake .#demo-container
```

Start the container:

```bash
sudo nixos-container start demo
```

Check container status:

```bash
sudo nixos-container status demo
```

---

## Step 4: Verify Bitcoin is Running

Get a root shell in the container:

```bash
sudo nixos-container root-login demo
```

Inside the container, verify the system:

```bash
# Check NixOS version
nixos-version

# Check running services
systemctl --type=service --state=running
systemctl status bitcoin*

# View Bitcoin logs
journalctl -f -u bitcoin*
```

Press `Ctrl+C` to stop following logs.

---

## Step 5: Watch Bitcoin Sync in Real-Time

Still inside the container, watch Bitcoin connect to the testnet and start downloading blocks:

```bash
# Watch the live sync logs - you'll see Bitcoin discovering peers and downloading blocks
journalctl -f -u bitcoin*
```

After a while you should start seeing many logs like:
```
UpdateTip: new best=000000000000000000... height=2500000...
Synchronizing blockheaders, height: 123456...
```

Press `Ctrl+C` when you've seen enough.

Check the current sync progress:

```bash
# View blockchain sync status
bitcoin-cli -testnet getblockchaininfo
```

Look for the `blocks` and `headers` fields - when they match, sync is complete.

---

## Step 6: Use Bitcoin CLI

Interact with your Bitcoin testnet node:

```bash
# Get network info
bitcoin-cli -testnet getnetworkinfo

# Check peer connections
bitcoin-cli -testnet getconnectioncount
bitcoin-cli -testnet getpeerinfo | head -20

# View current blockchain state
bitcoin-cli -testnet getblockchaininfo
```

Exit the container:

```bash
exit
```

---

## Step 7: Watch Storage Growth in Real-Time

From your host system, watch the Bitcoin data directory grow:

```bash
# Check initial size
sudo du -sh /var/lib/nixos-containers/demo-container/var/lib/bitcoind/

# Watch it grow in real-time (updates every 5 seconds)
watch -n 5 'sudo du -sh /var/lib/nixos-containers/demo-container/var/lib/bitcoind/'
```

**You'll see the directory grow** as Bitcoin downloads the testnet blocks.

After some time, check the detailed breakdown:

```bash
# See what's taking up space
sudo du -h --max-depth=2 /var/lib/nixos-containers/demo-container/var/lib/bitcoind/

# Check testnet3 directory specifically
sudo du -sh /var/lib/nixos-containers/demo-container/var/lib/bitcoind/testnet3/
```

Even testnet will grow to **~30GB for the blockchain** and **~50GB+ with indexes enabled**.

---

## Understanding the Configuration

**Key points about our setup:**

1. **Declarative service:** `services.bitcoind.enable = true` is all you need
2. **Testnet mode:** Smaller blockchain (~30GB vs ~600GB mainnet) for practical testing
3. **Transaction index:** `txindex=1` enables full transaction queries
4. **RPC access:** Allows `bitcoin-cli` to communicate with `bitcoind`
5. **Container isolation:** Bitcoin runs isolated but shares host kernel
6. **Quick sync:** Testnet syncs in hours instead of days/weeks

---

## Storage Reality Check

As you've seen, the Bitcoin data directory grows continuously and possibly considerably, hence the use of TESTNET instead of MAINNET:

- **TESTNET storage requirements:**
  - Testnet blockchain: ~30GB
  - With txindex: ~50GB+

- **MAINNET storage requirements:**
  - Blockchain only: ~600GB (and growing every day)
  - With txindex: ~750GB
  - With full indexes: **>1TB**


Container storage is typically not ideal for:
- Large, persistent datasets
- High I/O workloads
- Production blockchain nodes
- Data that grows indefinitely

---

## The Real Challenge: Managing a Full Bitcoin Stack

While this workshop showed how to deploy Bitcoin Core declaratively, **running a production Bitcoin node involves much more than just bitcoind**. A complete Bitcoin stack typically includes:

- **Bitcoin Core** (bitcoind) - the base layer
- **Lightning Network** (LND, CLN, or Eclair) - for instant payments
- **Web interfaces** (RTL, ThunderHub) - for managing your node
- **Payment processors** (LNBits, BTCPay Server) - for accepting payments
- **Reverse proxy** (nginx) - for secure external access
- **Monitoring tools** - for tracking performance and health

Configuring all these components manually is **tedious and error-prone**:
- Each service needs its own configuration
- Services must communicate securely with each other
- Ports, authentication, and permissions need careful coordination
- Updates and maintenance become complex

**This is where nix-bitcoin comes in.**: It is a collection of NixOS modules designed to help to the deployment of Bitcoin stacks with minimal configuration. Instead of manually setting up 5-10 different services, nix-bitcoin provides pre-integrated, battle-tested configurations that work together. We will look at nix-bitcoin in [workshop-4](../workshop-4/) "How to run a Bitcoin stack on NixOS in 5 minutes".

---

## Cleanup (Optional)

Stop and remove the container:

```bash
sudo nixos-container stop demo
sudo nixos-container destroy demo
```

Remove the data directory:

```bash
sudo rm -rf /var/lib/nixos-containers/bitcoin-container
```

---

## What We Learned

✅ Declaratively configured Bitcoin Core as a NixOS service  
✅ Started Bitcoin testnet node and watched it connect to peers  
✅ Observed live block download logs with `journalctl`  
✅ Verified blockchain sync progress with `bitcoin-cli`  
✅ Witnessed the storage growth even on testnet  
✅ Understood why containers aren't suitable for full Bitcoin nodes  
✅ Realized that managing a full Bitcoin stack (Bitcoin + Lightning + web interfaces + more) manually is tedious  
✅ Learned why nix-bitcoin exists - to simplify deploying complete Bitcoin infrastructure  

---

## Next Steps

This workshop demonstrated how easy NixOS makes deploying Bitcoin. Even with testnet's smaller footprint, you saw how blockchain storage becomes significant over time. More importantly, you learned that a production Bitcoin setup requires many integrated services beyond just Bitcoin Core, a complete stack is required, which we cover in [workshop-4](../workshop-4/) "How to run a Bitcoin stack on NixOS in 5 minutes".

Happy hacking!

**Coming up:**

**[workshop-3](../workshop-3/) - "How to run a forked version of Bitcoin on NixOS in 5 minutes"** - where we'll show you how to run the Mutinynet fork of Bitcoin (signet with 30s block production).

**[workshop-4](../workshop-4/) - "How to run a Bitcoin stack on NixOS in 5 minutes"** - where we'll explore nix-bitcoin for managing complete Bitcoin infrastructure

---

## Notes

- **VM deployment:** The same configuration works on NixOS VMs - just use the configuration in your VM's `configuration.nix` (see [workshop-1](../workshop-1))
- **Sync time:** Testnet initial blockchain download takes several hours depending on your hardware and connection
- **Stopping early:** You can stop the container anytime with `sudo nixos-container stop demo` - progress is saved
- **Security:** The RPC password in this workshop is for demo only - use strong passwords in production

---

**Workshop Duration:** 45 minutes 
**Difficulty:** Beginner  
**Prerequisites:** [workshop-1](../workshop-1) recommended