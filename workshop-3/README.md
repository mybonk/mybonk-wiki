# How to Run a Forked Version of Bitcoin on NixOS in 5 Minutes

## Overview

This workshop demonstrates how to run a custom Bitcoin fork on NixOS using Nix's powerful package override capabilities. We'll replace the standard Bitcoin Core with **Mutinynet** - a Bitcoin fork designed for faster, more practical testing.

**What is Mutinynet?**

Mutinynet is a custom signet (Bitcoin test network) with 30-second block times instead of the default 10 minutes, making it perfect for development and testing. Unlike testnet, which has irregular block production and a "graveyard of unkempt test nodes," Mutinynet provides a realistic network environment with consistent block production.

**Why Mutinynet over standard testnet?**

- **Faster feedback:** 30-second blocks vs 10-minute blocks means 20x faster confirmations
- **Active network:** Includes working mempool.space explorer, esplora instance, rapid gossip sync server, lightning nodes, and LSP infrastructure
- **Real activity:** Unlike testnet where there is little to no activity, Mutinynet is fun to interact with and test on.
- **Advanced features:** Includes experimental soft forks (CTV, Anyprevout, OP_CAT, CSFS, OP_INTERNALKEY)
- **Free coins:** Get testnet-like coins from the [Mutinynet faucet](https://faucet.mutinynet.com/)
- **Maintained infrastructure:** Block explorer at https://mutinynet.com/

**About pre-built binaries:**

This Bitcoin fork doesn't appear to provide pre-built binaries, so we'll have to build it ourselves from source. This is where Nix shines - it handles the entire build process reproducibly, ensuring everyone gets the same result.

**What you'll learn:**

- Pin a specific Bitcoin version using Nix's `fetchFromGitHub`
- Override NixOS service packages with custom builds
- Understand Nix's hash-based verification system
- Update existing container configurations
- Compare standard testnet vs custom signet behavior
- (Advanced) Use overlays for full package control

**Prerequisites:**

- Completed [workshop-2](../workshop-2/) (Bitcoin container running testnet)
- Understanding of NixOS containers
- Understanding of Nix flakes

**Time:** ~45 minutes including sync time (Mutinynet syncs fast!)

---

## Step 1: Check Your Current Bitcoin Configuration

Before making changes, let's verify what we're currently running. Make sure your bitcoin-container from [workshop-2](../workshop-2/) is running:

```bash
sudo nixos-container status demo-container
```

Get a root shell in the container:

```bash
sudo nixos-container root-login bitcoin-container
```

Inside the container, check the current setup:

```bash
# Check Bitcoin version
bitcoind --version

# Check network info - should show testnet
bitcoin-cli -testnet getnetworkinfo

# Check blockchain info
bitcoin-cli -testnet getblockchaininfo | grep chain
```

You should see `"chain": "test"` indicating testnet.

Exit the container for now:

```bash
exit
```

---

## Chapter A: Source Override with `fetchFromGitHub`

This is the **simplest approach** for using a custom fork. We fetch the source code from GitHub and override only the source of the existing package, keeping all the build configuration from nixpkgs.

### Understanding the Approach

**What `fetchFromGitHub` does:**
- Downloads source code from a specific GitHub repository and commit
- Verifies the download with a cryptographic hash
- Returns a Nix derivation that can be used as a package source

**What we're doing:**
- Fetching Mutinynet source from benthecarman's fork
- Using `overrideAttrs` to replace the `src` attribute of nixpkgs' bitcoin package
- Keeping the existing build recipe (dependencies, compilation flags, etc.)

**Why this approach:**
- Simple and straightforward
- Reuses existing nixpkgs build infrastructure
- Perfect for testing forks that don't need build changes
- Easy to understand for beginners

---

### Step 2: Update flake.nix for Mutinynet

Navigate to your workshop repository:

```bash
cd ~/workshops/workshop-3  # Or wherever you cloned it
```

Edit your `flake.nix` to override the bitcoin package with Mutinynet's:

```nix
{
  description = "Bitcoin NixOS Container - Workshop 3 (Mutinynet)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }: 
    let
      system = "x86_64-linux";
      
      # Fetch Mutinynet source from benthecarman's fork
      mutinynetSrc = nixpkgs.legacyPackages.${system}.fetchFromGitHub {
        owner = "benthecarman";
        repo = "bitcoin";
        rev = "v29.0";  # Mutinynet v29.0 release
        sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # We'll fix this
      };
      
      # Create custom package set with overridden bitcoin
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            bitcoin = prev.bitcoin.overrideAttrs (oldAttrs: {
              src = mutinynetSrc;
              version = "29.0-mutinynet";
            });
          })
        ];
      };
    in {
      nixosConfigurations.bitcoin-container = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          { nixpkgs.overlays = [ (final: prev: { inherit (pkgs) bitcoin; }) ]; }
          ./container-configuration.nix
        ];
      };
    };
}
```

**Code breakdown:**

1. **`fetchFromGitHub`**: Downloads Mutinynet source from GitHub at specific commit `v29.0`
2. **`sha256` hash**: Placeholder - Nix will tell us the correct hash when we try to build
3. **`overrideAttrs`**: Replaces only the source and version of the standard bitcoin package
4. **Overlay**: Applies our custom bitcoin package to the container's package set

---

### Step 3: Get the Correct Hash

The `sha256` hash in step 2 is a placeholder. Nix needs the correct hash to verify the download. Let's get it:

```bash
# Try to build - it will fail but show us the correct hash
sudo nixos-container update bitcoin-container --flake .#bitcoin-container
```

You'll see an error like:

```
error: hash mismatch in fixed-output derivation
specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
got:      sha256-XjkD8Fmn3h2Lk9P2mR5nQ8tY6vW4xA1bC2dE3fG4hJ5=
```

**This is expected!** Nix is telling us the real hash. Copy the "got:" hash and update your `flake.nix`:

```nix
sha256 = "sha256-XjkD8Fmn3h2Lk9P2mR5nQ8tY6vW4xA1bC2dE3fG4hJ5=";  # Use the real hash
```

**Why does Nix use hashes?**

Nix's hash verification ensures:
- **Reproducibility**: Same input hash = same output every time
- **Security**: Detects tampering or corrupted downloads
- **Caching**: Nix can cache builds based on input hashes
- **Determinism**: Your build matches everyone else's build exactly

The hash is calculated from the entire contents of the fetched source code. If even one byte changes in the repository, the hash will be different, alerting you to the change.

---

### Step 4: Update container-configuration.nix for Mutinynet

Edit `container-configuration.nix` to configure Mutinynet's signet.

**Important note:** These configuration parameters are **required** - they are not built into the fork by default. The fork only adds *support* for the custom signet parameters (e.x `signetblocktime`), but you must explicitly configure which signet to join (Mutinynet's) and how to connect to it.

```nix
{ config, pkgs, lib, ... }:

{
  boot.isContainer = true;
  networking.hostName = "demo-container";
  
  # Enable Bitcoin service with Mutinynet configuration
  services.bitcoind = {
    enable = true;
    
    # Mutinynet signet configuration
    extraConfig = ''
      # Enable signet mode (not testnet!)
      signet=1
      
      # Mutinynet-specific signet challenge
      # This identifies which signet network to join
      signetchallenge=512102f7561d208dd9ae99bf497273e16f389bdbd6c4742ddb8e6b216e64fa2928ad8f51ae
      
      # Connect to Mutinynet infrastructure node
      addnode=45.79.52.207:38333
      
      # Disable DNS seeding (use manual addnode instead)
      dnsseed=0
      
      # 30-second block time 
      # This parameter only works because we're using benthecarman's Mutinynet fork of bitcoin core
      signetblocktime=30
      
      # RPC settings
      rpcuser=nixos
      rpcpassword=workshop3demo
      
      # Network settings
      listen=1
      server=1
      
      # Transaction index
      txindex=1
    '';
    
    # RPC access
    rpc = {
      users = {
        nixos = {
          name = "nixos";
          passwordHMAC = "workshop3demo";
        };
      };
    };
  };

  # Useful utilities
  environment.systemPackages = with pkgs; [
    bitcoin
    vim
    btop
  ];

  # Allow container to access the internet
  networking.useHostResolvConf = lib.mkForce false;
  
  services.resolved.enable = true;

  system.stateVersion = "24.11";
}
```

**Configuration explained:**

- **`signet=1`**: Enables signet mode (custom signet network)
- **`signetchallenge`**: The cryptographic challenge that identifies Mutinynet specifically
- **`addnode`**: Direct connection to Mutinynet's infrastructure
- **`dnsseed=0`**: Disables automatic peer discovery (we use manual nodes)
- **`signetblocktime=30`**: Sets 30-second blocks (only possible with this fork)

---

### Step 5: Update the Container

Now update the running container with our new configuration:

```bash
# Update the container with new Mutinynet configuration
sudo nixos-container update demo --flake .#demo-container
```

This will:
1. Fetch the Mutinynet source from GitHub
2. Verify the hash matches
3. Build the custom Bitcoin package from source (takes 5-10 minutes)
4. Update the container configuration
5. Restart the bitcoind service

Watch the build process - you'll see Nix compiling the fork of Bitcoin from source. First-time builds take longer, but subsequent builds use Nix's cache.

---

### Step 6: Verify Mutinynet is Running

Get a shell in the updated container:

```bash
sudo nixos-container root-login demo
```

Check the Bitcoin version - should now show Mutinynet:

```bash
bitcoind --version
```

Check network info - should now show signet:

```bash
bitcoin-cli -signet getnetworkinfo
```

Check blockchain info:

```bash
bitcoin-cli -signet getblockchaininfo
```

You should see `"chain": "signet"` instead of `"chain": "test"`.

---

### Step 7: Watch the Fast Block Production

This is where Mutinynet shines! Watch the logs to see 30-second blocks:

```bash
journalctl -u bitcoind -f
```

You'll see blocks being downloaded much faster than testnet. Look for logs like:

```
UpdateTip: new best=00000... height=150000... log2_work=20.5
UpdateTip: new best=00000... height=150001... log2_work=20.5
```

Notice blocks are coming in every ~30 seconds instead of every 10 minutes!

Press `Ctrl+C` to stop.

Check sync progress:

```bash
bitcoin-cli -signet getblockchaininfo | grep -E "chain|blocks|headers"
```

The `blocks` count should be increasing rapidly.

Exit the container:

```bash
exit
```

---

## Chapter B: Full Overlay Approach (Advanced)

The `fetchFromGitHub` approach is simple and works well for most cases. However, sometimes you need **complete control** over how a package is built. This is where **overlays** shine.

### When to Use Overlays

Use overlays when you need to:
- Modify compilation flags or build options
- Add or change dependencies
- Apply custom patches to the source code
- Change the entire build process
- Override multiple related packages at once

For our Mutinynet example, the simple override is sufficient, but let's see what an overlay would look like.

### Understanding Overlays

**Overlays** are functions that take two arguments (`final` and `prev`) and return a set of package modifications:

- **`prev`**: The original package set before your changes
- **`final`**: The final package set after all overlays

Overlays give you access to the entire package definition, not just individual attributes.

### Alternative flake.nix with Full Overlay

Here is how you would write the same thing using a more powerful overlay approach:

```nix
{
  description = "Bitcoin NixOS Container - Workshop 3 (Mutinynet - Overlay)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.demo-container = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          nixpkgs.overlays = [
            (final: prev: {
              bitcoin = prev.bitcoin.overrideAttrs (oldAttrs: {
                # Fetch Mutinynet source
                src = final.fetchFromGitHub {
                  owner = "benthecarman";
                  repo = "bitcoin";
                  rev = "v29.0";
                  sha256 = "sha256-REAL_HASH_HERE";
                };
                
                version = "29.0-mutinynet";
                
                # You could add custom build modifications here:
                # configureFlags = oldAttrs.configureFlags ++ [ "--enable-custom-feature" ];
                # buildInputs = oldAttrs.buildInputs ++ [ final.someExtraLibrary ];
                # patches = [ ./custom-patch.patch ];
              });
            })
          ];
        }
        ./container-configuration.nix
      ];
    };
  };
}
```

**Key differences:**

1. **Overlay defined inline**: The overlay is part of the NixOS module directly
2. **Access to `final`**: Can reference other packages from the final package set
3. **More flexibility**: Easy to add build flags, patches, or dependencies
4. **Commented examples**: Shows how you could customize the build further

### When Each Approach Makes Sense

| Approach | Use When | Advantages |
|----------|----------|------------|
| `fetchFromGitHub` + `overrideAttrs` | Simple source swap | Quick, clear, minimal changes |
| Full Overlay | Need build customization | Complete control, can modify everything |

Most of the time the simple `fetchFromGitHub` approach is sufficient.

---

## Comparing Testnet vs Mutinynet

Let's summarize what we've learned:

| Feature | Testnet | Mutinynet (Signet) |
|---------|---------|-------------------|
| Block time | ~10 minutes | 30 seconds |
| Confirmations | Slow, irregular | Fast, consistent |
| Network activity | Sparse, dead nodes | Active infrastructure |
| Explorer | Limited | Full mempool.space |
| Lightning network | Graveyard | Active nodes + LSP |
| Free coins | Faucets exist | https://faucet.mutinynet.com/ |
| Use case | General testing | Active development |
| Configuration | Built-in | Requires custom params |

---

## What We Learned

✅ Used `fetchFromGitHub` to pin a specific version from a specific location
✅ Nix's hash verification system for security and reproducibility  
✅ Overrode a NixOS service package with a custom build  
✅ Updated an existing container configuration
✅ Configured a custom signet (Mutinynet) with required parameters
✅ Witnessed dramatically faster block production (30s vs 10min)  
✅ Learned the difference between simple overrides and full overlays

**The power of Nix:**

- **Pinning versions:** Exact control over what gets built and deployed
- **Hash verification:** Cryptographic guarantee of content integrity
- **Reproducibility:** Same configuration = same result everywhere
- **Easy updates:** Change a hash, rebuild, done
- **No pollution:** Custom packages don't affect the rest of your system
- **Build from source:** Even without pre-built binaries, Nix handles everything

---

## Cleanup (Optional)

If you want to go back to standard testnet or clean up:

```bash
# Stop the container
sudo nixos-container stop demo

# Destroy it
sudo nixos-container destroy demo

# Remove data
sudo rm -rf /var/lib/nixos-containers/demo-container
```

---

## Next Steps

You've learned how to run a custom build on NixOS! 

**Advanced techniques (not covered in this workshop):**

If you need even more control over package building, consider:

- **Using pre-built binaries**: Use `fetchurl` to download pre-compiled binaries instead of building from source (faster but less common for forks)
- **Complex overlays**: Override multiple packages at once, add custom patches, modify the entire dependency tree
- **Custom derivations**: Write completely custom build logic for unique requirements
- **Nix flake inputs**: Pin multiple repositories and coordinate versions across projects

These advanced techniques are useful for:
- Building complex infrastructures with interdependent components
- Creating reproducible research or development environments
- Testing experimental features requiring multiple coordinated package changes

**Coming next: Workshop 4 - "How to run a Bitcoin stack on NixOS in 5 minutes"**

Learn about nix-bitcoin - a complete solution for deploying production Bitcoin infrastructure with Lightning, web interfaces, and more, all configured declaratively.

---

## Resources

- [Mutinynet Blog Post](https://blog.mutinywallet.com/mutinynet/)
- [Mutinynet Faucet](https://faucet.mutinynet.com/)
- [Mutinynet Explorer](https://mutinynet.com/)
- [Bitcoin Inquisition](https://github.com/bitcoin-inquisition/bitcoin)
- [benthecarman's Bitcoin Fork](https://github.com/benthecarman/bitcoin)
- [Nix Pills - Chapter 17: Nixpkgs Overriding Packages](https://nixos.org/guides/nix-pills/nixpkgs-overriding-packages.html)

---

## Notes

- **Hash updates:** When updating to a new Mutinynet version, you'll need to get a new hash
- **Build time:** First build from source takes 5-10 minutes, subsequent builds use Nix cache
- **Soft forks:** Mutinynet v29.0 includes Anyprevout, CTV, OP_CAT, CSFS, and OP_INTERNALKEY
- **Network differences:** Mutinynet uses different ports and addresses than mainnet/testnet
- **Storage:** Mutinynet's blockchain is much smaller than mainnet and even testnet
- **Configuration required:** In the Mutinynet fork the signet parameters must be explicitly configured as in the example - they are re not built into the fork.

---

**Workshop Duration:** 45 minutes (configuration, build and sync time)
**Difficulty:** Intermediate  
**Prerequisites:** [workshop-2](../workshop-2/) required