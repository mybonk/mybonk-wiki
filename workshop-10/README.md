# Workshop 10: VM-Based Automated Testing with Mutinynet

## Overview

This workshop combines concepts from workshop-9 (automated testing) and workshop-3 (Bitcoin fork override) to create **VM-based automated tests** using a **Mutinynet Bitcoin fork**.

**Key Differences from Workshop-9:**
- Uses NixOS VM test framework (not containers)
- Tests run in isolated VMs with `boot.isContainer = false`
- Uses Mutinynet signet (30-second blocks) instead of regtest
- Bitcoin Core is overridden with benthecarman's fork

**Prerequisites:**
- [workshop-9](../workshop-9/) - Container-based testing and configuration
- [workshop-3](../workshop-3/) - Bitcoin fork override with Mutinynet

---

## What's Different

### 1. VM Configuration vs Container Configuration

The flake.nix provides two configurations:

```nix
nixosConfigurations = {
  default = ...       # Container config (boot.isContainer = true)
  default-vm = ...    # VM config (boot.isContainer = false)
};
```

**Why this matters:**
- NixOS tests require `boot.isContainer = false`
- VMs need full boot configuration (kernel, bootloader, etc.)
- Containers are lightweight, VMs are isolated
- Tests use `default-vm` configuration

### 2. Mutinynet Fork Override

See [workshop-3](../workshop-3/) for detailed explanation.

**Quick summary:**
- Uses `fetchFromGitHub` to get benthecarman's Bitcoin fork
- Overrides Bitcoin package with Mutinynet source
- Adds 30-second block support via `signetblocktime` parameter
- Signet configuration requires specific challenge and infrastructure nodes

### 3. Test Framework: test.nix vs test.sh

**Workshop-9 approach (test.sh):**
- Bash script creating actual containers
- Uses `nixos-container` commands
- Runs on host system
- Manual cleanup with `--keep` flag

**Workshop-10 approach (test.nix):**
- NixOS test framework with VMs
- Declarative Python test script
- Isolated VM environment
- Automatic cleanup

---

## File Structure

```
workshop-10/
├── flake.nix              # Defines default (container) and default-vm (VM) configs
├── configuration.nix      # Shared config for Bitcoin/Lightning with Mutinynet
├── test.nix              # VM-based automated tests
└── README.md             # This file
```

---

## Running the Tests

### Option 1: Build Test (recommended)

```bash
nix build .#checks.x86_64-linux.bitcoin-lightning-mutinynet
```

This builds and runs the test, showing output on success.

### Option 2: Flake Check

```bash
nix flake check
```

Runs all checks defined in the flake. Quieter output.

### Option 3: Interactive Test

```bash
nix build .#checks.x86_64-linux.bitcoin-lightning-mutinynet.driverInteractive
./result/bin/nixos-test-driver
```

Opens an interactive test environment where you can:
- Run tests manually
- Inspect VM state
- Debug failures
- Explore the environment

---

## What the Tests Validate

The test suite validates the same scenarios as workshop-9:

1. **System Setup**
   - VMs boot successfully
   - Root privileges available

2. **Network Connectivity**
   - VM-to-VM communication
   - Internet access
   - DNS resolution

3. **Bitcoin Core**
   - Service starts correctly
   - RPC responds
   - Wallet operations (create, generate address)
   - Balance queries
   - Peer connections between nodes

4. **Core Lightning**
   - Service starts correctly
   - RPC responds and syncs
   - Wallet operations (generate address)
   - Fund queries
   - Node information

5. **Multi-Node Setup**
   - Two nodes running simultaneously
   - Bitcoin peer connections
   - Lightning node discovery

6. **Mutinynet Verification**
   - Fork version check
   - Signet mode confirmation
   - 30-second block configuration

---

## Configuration Details

### Mutinynet Signet Configuration

See `configuration.nix` for full details. Key settings:

```nix
services.bitcoind = {
  enable = true;
  extraConfig = ''
    # Enable signet mode
    signet=1

    # Mutinynet-specific challenge
    signetchallenge=512102f7561d208dd9ae99bf497273e16f389bdbd6c4742ddb8e6b216e64fa2928ad8f51ae

    # Connect to Mutinynet infrastructure
    addnode=45.79.52.207:38333

    # 30-second blocks (fork feature)
    signetblocktime=30

    # Other settings...
    txindex=1
    fallbackfee=0.00001
  '';
};
```

**Important:** These parameters are required for Mutinynet. See [workshop-3](../workshop-3/) for explanation.

---

## Mutinynet vs Regtest

| Feature | Regtest (workshop-9) | Mutinynet (workshop-10) |
|---------|---------------------|------------------------|
| Network Type | Private local | Live signet |
| Block Time | Instant (manual) | 30 seconds (automatic) |
| Blockchain Sync | None needed | Required (but fast!) |
| External Peers | No | Yes |
| Free Coins | Generate locally | Faucet: https://faucet.mutinynet.com/ |
| Best For | Isolated testing | Realistic testing |
| RPC Port | 18443 | 38332 |
| P2P Port | 18444 | 38333 |

---

## Fork Hash Update

On first build, you'll see:

```
error: hash mismatch in fixed-output derivation
specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
got:      sha256-<REAL_HASH>
```

**This is expected!** Copy the "got:" hash and update `flake.nix`:

```nix
mutinynetSrc = nixpkgs.legacyPackages.${system}.fetchFromGitHub {
  owner = "benthecarman";
  repo = "bitcoin";
  rev = "v29.0";
  sha256 = "sha256-<REAL_HASH>";  # Update this line
};
```

See [workshop-3](../workshop-3/) for detailed explanation of hash verification.

---

## Creating Containers (Optional)

This workshop focuses on VM testing, but you can still create containers:

```bash
sudo nixos-container create mynode --flake .#default
sudo nixos-container start mynode
sudo nixos-container root-login mynode
```

Inside the container:

```bash
# Wait for sync (30-second blocks!)
bitcoin-cli -signet getblockchaininfo

# Get free coins from faucet
bitcoin-cli -signet getnewaddress
# Visit https://faucet.mutinynet.com/ and send coins to that address

# Check Lightning
lightning-cli --network=signet getinfo
```

---

## Debugging Test Failures

### View test output:

```bash
nix build .#checks.x86_64-linux.bitcoin-lightning-mutinynet --show-trace
```

### Interactive debugging:

```bash
nix build .#checks.x86_64-linux.bitcoin-lightning-mutinynet.driverInteractive
./result/bin/nixos-test-driver

# Inside the interactive environment:
>>> start_all()
>>> node1.succeed("bitcoin-cli -signet getblockchaininfo")
>>> node1.shell_interact()  # Get a shell in the VM
```

### Check logs in test output:

Test logs are saved to `result/` after build. Look for:
- VM boot logs
- Service journals
- Test failure details

---

## Test Output Example

Successful test output:

```
test script started
[INFO] VMs are running
[INFO] Network connectivity - node1
[INFO] Bitcoin service is running on node1
[INFO] Bitcoin RPC responds on node1
...
[INFO] All tests passed!
============================================================
Configuration validated:
  ✓ Mutinynet Bitcoin fork
  ✓ Bitcoin Core (signet mode)
  ✓ Core Lightning
  ✓ Network connectivity
  ✓ Multi-node setup
============================================================
```

---

## Common Issues

### Issue: Hash mismatch on first build

**Expected behavior.** Update the hash in flake.nix with the correct value from error message.

### Issue: Build takes a long time

First build compiles Bitcoin from source (~5-10 minutes). Subsequent builds use Nix cache.

### Issue: Tests fail with "connection refused"

Lightning binds to localhost by default. This is documented in test output. To enable peer connections, configure CLN to bind to `0.0.0.0` in configuration.nix.

### Issue: Signet sync is slow

Mutinynet has 30-second blocks, so sync is much faster than mainnet but not instant like regtest. Wait for sync to complete.

---

## Going Further

### Add more test scenarios:

Edit `test.nix` to add custom tests:

```python
with subtest("Custom test"):
    node1.succeed("bitcoin-cli -signet <command>")
```

### Test Lightning channels:

Requires more advanced setup:
1. Fund wallets from faucet
2. Open channels between nodes
3. Send payments
4. Close channels

### Test with real Mutinynet:

Containers can connect to live Mutinynet:
- Sync full blockchain (fast with 30s blocks!)
- Connect to other Mutinynet nodes
- Get coins from faucet
- Explore on https://mutinynet.com/

---

## Key Takeaways

✅ VM-based testing provides complete isolation
✅ NixOS test framework offers declarative test definitions
✅ Mutinynet fork override requires `fetchFromGitHub` and hash verification
✅ Same configuration works for both containers and VMs
✅ `boot.isContainer` determines container vs VM behavior
✅ Signet configuration requires specific parameters
✅ 30-second blocks make Mutinynet practical for testing

---

## Resources

- [workshop-9](../workshop-9/) - Container-based testing
- [workshop-3](../workshop-3/) - Bitcoin fork override details
- [Mutinynet](https://blog.mutinywallet.com/mutinynet/) - About Mutinynet
- [Mutinynet Faucet](https://faucet.mutinynet.com/) - Free testnet coins
- [Mutinynet Explorer](https://mutinynet.com/) - Block explorer
- [NixOS Test Framework](https://nixos.org/manual/nixos/stable/index.html#sec-nixos-tests) - Official documentation
- [nix-bitcoin](https://github.com/fort-nix/nix-bitcoin) - Bitcoin services for NixOS

---

**Workshop Duration:** 30-45 minutes (including build time)
**Difficulty:** Intermediate
**Prerequisites:** workshop-9, workshop-3
