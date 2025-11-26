# Build Your NixOS Installer ISO in 5 Minutes

## Overview

This workshop demonstrates how to build a custom NixOS installer ISO image that's pre-configured with SSH access and your public key. This enables remote installation over your local network, which is particularly useful when installing NixOS on headless servers, remote machines, or when you want to perform the installation from the comfort of your main workstation.

**What you'll create:**

A bootable USB installer that:
- Automatically starts SSH on boot
- Accepts connections using your SSH key
- Allows you to install NixOS remotely over your network
- Includes essential diagnostic and installation tools

**Why a custom installer ISO?**

The standard NixOS installer requires:
- Physical access to the target machine
- Keyboard and monitor attached
- Manual configuration of network and SSH each time

A custom installer ISO:
- Boots directly to SSH-enabled state
- Works headless (no monitor/keyboard needed)
- Pre-configured with your SSH keys
- Consistent, reproducible installation environment
- Perfect for remote installations

**What you'll learn:**

- Generate SSH key pairs using `ssh-keygen`
- Configure SSH daemon for secure remote access
- Build NixOS installer ISO images using Nix flakes
- Write bootable images to USB drives (GUI and CLI methods)
- Discover target machine IP addresses on local network
- Connect remotely via SSH to perform NixOS installation

**Prerequisites:**

- **Nix package manager** installed (on any Linux distribution or macOS)
- Basic understanding of Nix flakes
- Familiarity with SSH concepts
- USB drive (4GB minimum) for testing

**Remarkable fact:** You don't need NixOS to build a NixOS system! As long as you have the Nix package manager installed, you can build complete NixOS installer ISOs from Ubuntu, Arch, Fedora, macOS, or any other system. This is one of Nix's most powerful features - reproducible system images can be built anywhere Nix runs.

**Time:** ~5 minutes to build + time to burn to USB

**Reality check:**

The "5 minutes" refers to configuration time. Actual build time depends on:
- **First build:** 10-20 minutes (fetches packages, builds ISO)
- **Subsequent builds:** 2-5 minutes (uses Nix cache)
- **USB burning:** 2-5 minutes depending on drive speed

---

## Step 1: Understanding SSH Keys

Before building our custom installer, we need to set up SSH authentication. SSH keys provide secure, passwordless authentication that's more secure than password-based logins.

### What are SSH Keys?

SSH (Secure Shell) uses public-key cryptography:
- **Private key**: Kept secret on your local machine (never share this!)
- **Public key**: Placed on servers you want to access (safe to share)

When you connect, the server challenges you to prove you own the private key corresponding to a public key it knows about. Only your private key can solve this challenge.

### SSH Key Types

Modern SSH supports several key types:

| Algorithm | Security | Compatibility | Recommendation |
|-----------|----------|---------------|----------------|
| **ed25519** | Excellent | Modern systems | **Recommended** (fast, secure, small) |
| **rsa (4096-bit)** | Very good | Universal | Good fallback for legacy systems |
| **ecdsa** | Good | Wide | Less common, potential concerns |
| **dsa** | Poor | Legacy only | **Deprecated** - avoid |

We'll use **Ed25519** for this workshop - it's the modern standard with excellent security and performance.

---

## Step 2: Generate Your SSH Key Pair

If you already have an SSH key you want to use, you can skip to Step 3. Otherwise, let's generate a new key pair.

### Generate an Ed25519 Key

On your NixOS system (or any Linux/macOS machine), run:

```bash
# Generate a new Ed25519 SSH key
ssh-keygen -t ed25519 -C "your-email@example.com"
```

**What the flags mean:**
- `-t ed25519`: Use the Ed25519 algorithm
- `-C "your-email@example.com"`: Add a comment (helps identify the key later)

### Key Generation Process

You'll see prompts like this:

```
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/yourusername/.ssh/id_ed25519):
```

**Press Enter** to accept the default location (`~/.ssh/id_ed25519`).

```
Enter passphrase (empty for no passphrase):
```

**Choose a passphrase** (recommended for security) or press Enter for no passphrase.

**Best practice:** Use a passphrase! It protects your private key if your machine is compromised. Use `ssh-agent` to avoid typing it repeatedly.

```
Enter same passphrase again:
```

Confirm your passphrase.

### What Gets Created

After generation, you'll have two files:

```bash
# View your new keys
ls -la ~/.ssh/id_ed25519*
```

Output:
```
-rw-------  1 you  you   464 Nov 26 10:00 /home/you/.ssh/id_ed25519      # Private key
-rw-r--r--  1 you  you   103 Nov 26 10:00 /home/you/.ssh/id_ed25519.pub  # Public key
```

**Important notes:**
- **Private key** (`id_ed25519`): Permissions `600` (only you can read/write)
- **Public key** (`id_ed25519.pub`): Permissions `644` (readable by others)

**Never share your private key!** Only the public key (`.pub` file) should be placed on servers.

### Alternative: RSA Keys

If you need compatibility with older systems, generate an RSA key:

```bash
# Generate a 4096-bit RSA key (more compatible but larger)
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
```

This creates `~/.ssh/id_rsa` (private) and `~/.ssh/id_rsa.pub` (public).

---

## Step 3: View Your Public Key

Your public key is what you'll add to the installer ISO configuration. Let's view it:

```bash
# Display your public key
cat ~/.ssh/id_ed25519.pub
```

Output will look like:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG7x9K2vZ3qX4Jh8... your-email@example.com
```

**This entire line is your public key.** Copy it now - we'll need it in the next step.

**The format:**
- `ssh-ed25519`: Algorithm identifier
- `AAAAC3Nz...`: The actual public key data (base64 encoded)
- `your-email@example.com`: Comment (helps identify which key)

### If Using RSA

For RSA keys:

```bash
cat ~/.ssh/id_rsa.pub
```

Output:
```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD... your-email@example.com
```

---

## Step 4: Clone the Workshop Repository

Clone the repository to get started with the base configuration:

```bash
# Clone the repository with workshop files
git clone git@github.com:mybonk/mybonk-wiki.git
cd mybonk-wiki/workshop-5
```

The repository contains:
- `flake.nix` - Defines the ISO build configuration
- `configuration.nix` - System configuration for the installer (includes SSH setup)

Let's examine what we're about to customize.

---

## Step 5: Understanding the Configuration

### File: `flake.nix`

This file defines how to build the installer ISO:

```nix
{
  description = "Build Custom NixOS Installer ISO - Workshop 5";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.installer-iso = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ./configuration.nix
      ];
    };
  };
}
```

**What's happening:**

1. **`nixpkgs` input**: Uses NixOS 25.05 stable channel
2. **`installation-cd-minimal.nix`**: Base NixOS installer module (provides core installer functionality)
3. **`./configuration.nix`**: Our custom configuration (SSH, packages, keys)

The magic is in combining the official minimal installer with our custom settings.

### File: `configuration.nix`

This file customizes the installer environment:

```nix
{ config, pkgs, lib, modulesPath, ... }:

{
  # Enable SSH server for remote installation
  services.openssh = {
    enable = true;
    settings = {
      # Allow root login with public key authentication
      PermitRootLogin = "prohibit-password";
      # Disable password authentication for security
      PasswordAuthentication = false;
      # Only allow public key authentication
      PubkeyAuthentication = true;
    };
  };

  # Add your SSH public key here
  users.users.root.openssh.authorizedKeys.keys = [
    # Example: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG... your-email@example.com"
    # Add your public key here after running: ssh-keygen -t ed25519
  ];

  # Essential packages for installation and diagnostics
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    htop
    btop
    tmux
    parted
    gptfdisk
    cryptsetup
    rsync
  ];

  # Network configuration
  networking = {
    # Disable wireless (conflicts with NetworkManager)
    wireless.enable = lib.mkForce false;
    # Enable network manager for easy WiFi/Ethernet setup
    networkmanager.enable = true;
    # Use systemd-resolved for DNS
    useNetworkd = false;
    useDHCP = lib.mkDefault true;
    # Enable firewall but allow SSH
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  # Set a temporary root password for initial access
  users.users.root.initialPassword = "nixos";

  # Console configuration
  console = {
    font = "Lat2-Terminus16";
    keyMap = lib.mkDefault "us";
  };

  time.timeZone = lib.mkDefault "UTC";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  system.stateVersion = "25.05";
}
```

**Configuration breakdown:**

1. **`services.openssh`**: Enables SSH server on boot
2. **`PermitRootLogin = "prohibit-password"`**: Root can log in, but ONLY with SSH keys (not passwords)
3. **`PasswordAuthentication = false`**: Disables password auth completely (more secure)
4. **`authorizedKeys.keys`**: Where we'll add your public key
5. **`environment.systemPackages`**: Essential tools for installation
6. **`wireless.enable = lib.mkForce false`**: Disables wpa_supplicant (conflicts with NetworkManager)
7. **`networkmanager.enable = true`**: Enables NetworkManager for easy WiFi/Ethernet configuration
8. **`networking.firewall.allowedTCPPorts = [ 22 ]`**: Opens SSH port
9. **`initialPassword = "nixos"`**: Temporary password for console access (if needed)

**Security note:** The temporary password `nixos` is only for emergency console access. SSH still requires your key.

---

## Step 6: Add Your SSH Public Key

Now we customize the configuration with your SSH public key.

Edit `configuration.nix`:

```bash
vim configuration.nix
```

Find the section with `authorizedKeys.keys`:

```nix
  users.users.root.openssh.authorizedKeys.keys = [
    # Example: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG... your-email@example.com"
    # Add your public key here after running: ssh-keygen -t ed25519
  ];
```

Replace it with your actual public key:

```nix
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG7x9K2vZ3qX4Jh8... your-email@example.com"
  ];
```

**Important:**
- Paste the **entire line** from your `id_ed25519.pub` file
- Keep the quotes around the key
- You can add multiple keys (one per line)

**Example with multiple keys:**

```nix
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG7x9K2vZ3qX4Jh8... laptop@example.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF8p2Y3mW1nK5Lk9... desktop@example.com"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD... oldmachine@example.com"
  ];
```

Save and exit (`:wq` in vim).

---

## Step 7: Build the Custom ISO

Now we're ready to build the installer ISO!

From the `workshop-5` directory:

```bash
# Build the ISO image
nix build .#nixosConfigurations.installer-iso.config.system.build.isoImage
```

**What happens:**

1. **Nix fetches inputs**: Downloads nixpkgs if not cached
2. **Evaluates configuration**: Processes flake.nix and configuration.nix
3. **Builds packages**: Compiles any necessary packages
4. **Generates ISO**: Creates the bootable installer image
5. **Creates result symlink**: Links `./result` to the ISO in `/nix/store`

**Build time:**
- **First build:** 10-20 minutes (downloads and builds packages)
- **Subsequent builds:** 2-5 minutes (most things cached)

**Watch for errors:**
- **Syntax errors** in configuration.nix will fail immediately
- **Hash mismatches** shouldn't occur with stable nixpkgs
- **Out of disk space**: Make sure you have at least 10GB free in `/nix/store`

When build completes successfully:

```bash
# Find the ISO file
ls -lh result/iso/
```

Output:
```
nixos-25.05-x86_64-linux.iso
```

The ISO is typically 800MB-1.2GB.

---

## Step 8: Locate Your Custom ISO

The built ISO is in the Nix store, with a symlink at `./result`:

```bash
# Check the result
ls -lh result/iso/

# Get the full path
readlink -f result/iso/*.iso
```

Example output:
```
/nix/store/abc123.../nixos-25.05-x86_64-linux.iso
```

**For convenience, copy it somewhere accessible:**

```bash
# Copy to your home directory
cp result/iso/*.iso ~/nixos-custom-installer.iso

# Check the size
ls -lh ~/nixos-custom-installer.iso
```

You should see a file around 800MB-1.2GB.

---

## Step 9: Burn the ISO to USB (Two Methods)

Now we need to write this ISO to a USB drive to make it bootable.

**Warning:** This will ERASE ALL DATA on the USB drive! Make sure you select the correct device.

### Method 1: Balena Etcher (GUI - Easy)

Balena Etcher is a user-friendly graphical tool for burning ISO images to USB drives.

**Step 1: Install Balena Etcher**

On NixOS, add to your configuration:

```nix
environment.systemPackages = with pkgs; [
  etcher
];
```

Then rebuild:

```bash
sudo nixos-rebuild switch
```

Or install temporarily:

```bash
nix-shell -p etcher
```

On other Linux distributions:

```bash
# Download from https://www.balena.io/etcher/
# Or use your package manager
```

**Step 2: Use Balena Etcher**

1. Insert your USB drive
2. Launch Balena Etcher
3. **Select image**: Click "Flash from file" and choose `~/nixos-custom-installer.iso`
4. **Select target**: Click "Select target" and choose your USB drive
5. **Flash**: Click "Flash!" and wait for completion

Balena Etcher will:
- Verify the USB drive selection
- Write the ISO image
- Verify the written data
- Eject the drive when done

**Advantages:**
- User-friendly interface
- Built-in verification
- Hard to select wrong device accidentally
- Cross-platform (Linux, macOS, Windows)

### Method 2: dd Command (CLI - Advanced)

The `dd` (data duplicator) command is a powerful tool for writing raw data to devices.

**Step 1: Identify Your USB Drive**

Insert your USB drive, then:

```bash
# List all block devices
lsblk
```

Output example:
```
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda           8:0    0 238.5G  0 disk
├─sda1        8:1    0   512M  0 part /boot
└─sda2        8:2    0   238G  0 part /
sdb           8:16   1  14.9G  0 disk          <-- This is your USB drive
└─sdb1        8:17   1  14.9G  0 part
```

**Identify your USB drive** by:
- **Size**: Should match your USB drive capacity
- **RM (removable)**: Shows `1` for removable drives
- **Name**: Typically `/dev/sdb`, `/dev/sdc`, etc. (NOT `/dev/sda` which is usually your main disk!)

**CRITICAL:** Double-check the device name! Using the wrong device will erase your hard drive!

**Step 2: Unmount the USB Drive**

If the USB is auto-mounted, unmount it:

```bash
# Unmount all partitions on the USB (replace sdX with your device)
sudo umount /dev/sdb*
```

If you get "not mounted" errors, that's fine - proceed to the next step.

**Step 3: Write the ISO to USB**

Use `dd` to write the ISO:

```bash
# Write ISO to USB (replace /dev/sdX with your actual device!)
sudo dd if=~/nixos-custom-installer.iso of=/dev/sdb bs=4M status=progress conv=fsync
```

**Command breakdown:**
- **`if=`** (input file): The ISO image to read
- **`of=`** (output file): The USB device to write to
- **`bs=4M`**: Block size (4MB chunks for faster writing)
- **`status=progress`**: Show write progress
- **`conv=fsync`**: Sync data to disk before finishing (ensures complete write)

**Warning:** Make absolutely sure `of=/dev/sdX` points to your USB drive, NOT your system disk!

**Example output:**

```
862+1 records in
862+1 records out
905969664 bytes (906 MB, 864 MiB) copied, 45.2 s, 20.0 MB/s
```

**Step 4: Sync and Eject**

Ensure all data is written:

```bash
# Force sync
sudo sync

# Eject the USB drive
sudo eject /dev/sdb
```

Now your USB drive is ready!

**Advantages of dd:**
- Fast and lightweight
- No additional software needed
- Full control over the process
- Available on all Unix-like systems

**Disadvantages:**
- Risk of data loss if wrong device selected
- No built-in verification
- Requires command-line knowledge

---

## Step 10: Boot the Target Machine from USB

Now we'll boot the target machine (the one where you want to install NixOS) from the USB drive we just created.

### Insert USB and Boot

1. **Insert the USB drive** into the target machine
2. **Power on** the machine
3. **Enter boot menu**:
   - Usually: Press `F12`, `F11`, `F10`, `F8`, `Esc`, or `Del` during startup
   - The key varies by manufacturer (watch for "Boot Menu" message)
4. **Select the USB drive** from the boot menu
5. **Boot into NixOS installer**

The machine will boot into your custom NixOS installer environment.

### What Happens on Boot

When your custom installer boots:

1. **Linux kernel loads** with NixOS initrd
2. **Network detection**: DHCP attempts to configure network
3. **SSH daemon starts** automatically with your configuration
4. **Root user active** with your SSH key authorized

**You'll see a login prompt:**
```
<<< Welcome to NixOS 25.05 (x86_64) - ttyX >>>

nixos login:
```

You can log in at the console with:
- Username: `root`
- Password: `nixos` (the temporary password we set)

But we want to connect via SSH instead!

---

## Step 11: Find the Target Machine's IP Address

To connect via SSH, we need to know the target machine's IP address on your local network.

### Method 1: Check Router/DHCP Server

Most home routers show connected devices:

1. **Access your router's admin interface** (usually `http://192.168.1.1` or `http://192.168.0.1`)
2. **Navigate to DHCP clients** or "Connected Devices"
3. **Look for a new device** named "nixos" or showing NixOS in hostname
4. **Note the IP address** (e.g., `192.168.1.150`)

### Method 2: Console Login and Check

If you have physical access, log in at the console:

```bash
# At the NixOS installer console
# Login: root
# Password: nixos

# Check IP address
ip addr show
```

Look for the `inet` line under your network interface (usually `eth0` for wired or `wlan0` for wireless):

```
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP>
    inet 192.168.1.150/24 brd 192.168.1.255 scope global dynamic eth0
```

The IP is `192.168.1.150` in this example.

Alternative command:

```bash
# Simpler output
hostname -I
```

### Method 3: Network Scan from Your Workstation

From your main machine, scan the local network:

```bash
# Install nmap if needed
nix-shell -p nmap

# Scan your local network (adjust subnet to match your network)
sudo nmap -sn 192.168.1.0/24
```

Look for a host with port 22 (SSH) open that recently appeared.

Or use `arp-scan`:

```bash
# Install arp-scan
nix-shell -p arp-scan

# Scan local network
sudo arp-scan --localnet
```

Look for a new MAC address or hostname.

### Method 4: Check DHCP Logs (Advanced)

If running your own DHCP server:

```bash
# Check systemd journal for DHCP leases
sudo journalctl -u dhcpd -n 50
```

---

## Step 12: Connect via SSH

Now that you have the IP address, connect from your main workstation!

### SSH Connection

From your main machine (the one with the private key):

```bash
# Connect to the installer (replace IP with actual address)
ssh root@192.168.1.150
```

**First connection prompt:**

The first time you connect, you'll see:

```
The authenticity of host '192.168.1.150 (192.168.1.150)' can't be established.
ED25519 key fingerprint is SHA256:abc123...xyz789.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Type `yes` and press Enter.

**This is normal** - SSH is confirming you trust this host. The fingerprint will be saved in `~/.ssh/known_hosts`.

### Successful Connection

If everything is configured correctly, you'll connect without a password:

```
Warning: Permanently added '192.168.1.150' (ED25519) to the list of known hosts.

<<< Welcome to NixOS 25.05 (x86_64) - pts/0 >>>

[root@nixos:~]#
```

Congratulations! You're now remotely connected to your NixOS installer.

### Troubleshooting Connection Issues

**Connection refused:**

```bash
ssh: connect to host 192.168.1.150 port 22: Connection refused
```

Possible causes:
- SSH daemon not running (check `systemctl status sshd` on target)
- Firewall blocking port 22 (shouldn't happen with our config)
- Wrong IP address

**Permission denied (publickey):**

```bash
Permission denied (publickey).
```

Possible causes:
- **Public key not added** to configuration.nix (rebuild ISO with correct key)
- **Wrong private key** being used (specify with `ssh -i ~/.ssh/id_ed25519 root@...`)
- **Permissions wrong** on private key (should be `600`: `chmod 600 ~/.ssh/id_ed25519`)

**Timeout:**

```bash
ssh: connect to host 192.168.1.150 port 22: Operation timed out
```

Possible causes:
- Target machine not on network
- Wrong IP address
- Network routing issues
- Machine not booted from USB

---

## Step 13: Perform Remote NixOS Installation

You're now connected remotely to the installer! From here, you can perform a complete NixOS installation using standard installation procedures.

### Standard Installation Overview

The full NixOS installation process is beyond the scope of this workshop, but here's the general flow:

**1. Partition the disk:**

```bash
# List available disks
lsblk

# Partition with your preferred tool
parted /dev/sda
# or
gdisk /dev/sda
# or
fdisk /dev/sda
```

**2. Format partitions:**

```bash
# Example: Format boot partition as FAT32 (for UEFI)
mkfs.vfat -F 32 /dev/sda1

# Example: Format root partition as ext4
mkfs.ext4 /dev/sda2
```

**3. Mount partitions:**

```bash
# Mount root
mount /dev/sda2 /mnt

# Create and mount boot
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot
```

**4. Generate configuration:**

```bash
# Generate initial NixOS configuration
nixos-generate-config --root /mnt
```

**5. Edit configuration:**

```bash
# Edit the generated configuration
vim /mnt/etc/nixos/configuration.nix
```

Add your settings:
- Hostname
- Users
- SSH keys (same ones from this workshop!)
- Bootloader settings
- Network configuration
- Packages
- Services

**6. Install NixOS:**

```bash
# Perform installation
nixos-install
```

**7. Set root password:**

```bash
# Set root password when prompted
# Or skip if using SSH keys only
```

**8. Reboot:**

```bash
# Reboot into your new system
reboot
```

### Remote Installation Advantages

Installing via SSH from your main machine provides several benefits:

**Convenience:**
- Use your familiar terminal and editor
- Copy/paste configurations easily
- Access documentation in browser
- Multi-monitor setup for reference materials

**Efficiency:**
- No monitor/keyboard needed on target machine
- Install multiple machines from one workstation
- Scripting and automation possible
- Easy to transfer files between machines

**Reliability:**
- Terminal session persists (use `tmux` for extra safety)
- Can disconnect and reconnect
- Full scrollback and logging
- No physical console issues

### Advanced: Using Tmux for Safety

For long installations, use `tmux` to prevent disconnection issues:

```bash
# On the target machine (via SSH)
tmux new -s install

# Now perform installation inside tmux
# If disconnected, reconnect and run:
tmux attach -t install
```

This ensures your installation continues even if SSH disconnects.

---

## Going Further: Customizing Your Installer

The beauty of NixOS is that the installer is just another NixOS configuration. You can customize it extensively.

### Add More Packages

Edit `configuration.nix` to include tools you frequently use:

```nix
  environment.systemPackages = with pkgs; [
    # Editors
    vim
    neovim
    emacs

    # Network tools
    curl
    wget
    nmap
    tcpdump

    # Disk tools
    parted
    gptfdisk
    cryptsetup

    # System monitoring
    htop
    btop
    iotop

    # File management
    rsync
    tree

    # Your favorite tools
    tmux
    screen
    git
  ];
```

### Configure WiFi

For wireless installations, you can pre-configure WiFi networks:

```nix
  networking.wireless = {
    enable = true;
    networks = {
      "YourSSID" = {
        psk = "your-wifi-password";
      };
      "AnotherNetwork" = {
        psk = "another-password";
      };
    };
  };
```

Or use NetworkManager (already enabled in our config):

```bash
# On booted installer, connect to WiFi
nmcli device wifi connect "YourSSID" password "your-password"
```

### Custom ISO Name and Label

Customize the ISO appearance:

```nix
  isoImage = {
    isoName = "nixos-custom-installer-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
    volumeID = "NIXOS_CUSTOM";
  };
```

### Include Custom Scripts

Add your own installation scripts:

```nix
  environment.systemPackages = [
    (pkgs.writeScriptBin "auto-install" ''
      #!${pkgs.bash}/bin/bash
      echo "Starting automated NixOS installation..."
      # Your custom installation logic
    '')
  ];
```

After rebuilding the ISO, `auto-install` will be available as a command.

---

## Understanding How This Works

### NixOS Installer Architecture

The NixOS installer ISO is special - it's a fully functional NixOS system that:

1. **Boots entirely in RAM** (no persistent storage needed)
2. **Provides tools** for installing NixOS to disk
3. **Is itself configured declaratively** using standard NixOS modules

**This is Nix philosophy in action:** The installer is just another NixOS configuration. You configure it the same way you configure a permanent system.

### The Build Process

When you ran `nix build .#nixosConfigurations.installer-iso.config.system.build.isoImage`, Nix:

1. **Evaluated your flake**: Loaded `flake.nix` and `configuration.nix`
2. **Imported base installer**: Merged `installation-cd-minimal.nix` with your config
3. **Resolved dependencies**: Determined all packages needed
4. **Built packages**: Compiled or fetched from cache
5. **Generated filesystem**: Created the ISO filesystem structure
6. **Created bootable image**: Added bootloader and made it bootable
7. **Produced ISO file**: Final bootable ISO image

Everything is reproducible - the same configuration always produces the same ISO (bit-for-bit).

### Why This Approach is Powerful

**Reproducibility:**
- Same configuration = same ISO on any machine
- Team members can build identical installers
- Easy to version control installer configurations

**Declarative:**
- Entire installer defined in code
- No manual steps to create customized installer
- Easy to review and audit

**Composable:**
- Combine official modules with your customizations
- Reuse configurations across different installers
- Share modules between installer and installed system

**Maintainable:**
- Update base installer by changing nixpkgs version
- Security updates propagate automatically
- No installer "drift" over time

---

## What We Learned

You have successfully:

- ✅ Generated SSH key pairs using `ssh-keygen`
- ✅ Understood public key authentication
- ✅ Configured SSH daemon for secure remote access
- ✅ Built a custom NixOS installer ISO using Nix flakes
- ✅ Learned two methods for burning ISOs to USB (Balena Etcher and dd)
- ✅ Discovered target machine IP addresses on local network
- ✅ Connected remotely via SSH to perform installation
- ✅ Understood the NixOS installer architecture
- ✅ Explored ISO customization options

**The power of declarative infrastructure:**

- **Reproducible**: Same config = same ISO every time
- **Customizable**: Add any packages, users, or configurations
- **Maintainable**: Update by changing configuration and rebuilding
- **Shareable**: Version control and distribute installer configs
- **Secure**: Control exactly what's in your installer

---

## Next Steps

**Customize your installer:**

Experiment with:
- Adding your favorite packages
- Pre-configuring WiFi networks
- Creating custom installation scripts
- Building multi-architecture ISOs (ARM, etc.)

**Automate installations:**

Create fully automated installation scripts that:
- Partition disks automatically
- Generate configurations
- Install NixOS unattended

**Explore NixOS deployment:**

Now that you can install NixOS remotely, explore:
- **nixops**: Deploy NixOS to multiple machines
- **deploy-rs**: Flake-based deployment tool
- **colmena**: Simple, stateless NixOps alternative
- **morph**: Deployment tool for NixOS

**Build specialized installers:**

Create purpose-built installers for:
- Raspberry Pi and ARM devices
- Encrypted root filesystems
- Specific hardware (GPU drivers, WiFi, etc.)
- Rescue/recovery systems

---

## Resources

- [NixOS Manual - Building ISOs](https://nixos.org/manual/nixos/stable/#sec-building-image)
- [NixOS Wiki - Creating a NixOS live CD](https://nixos.wiki/wiki/Creating_a_NixOS_live_CD)
- [SSH Key Generation Guide](https://www.ssh.com/academy/ssh/keygen)
- [Balena Etcher](https://www.balena.io/etcher/)
- [NixOS Installation Guide](https://nixos.org/manual/nixos/stable/#sec-installation)

---

## Notes

- **Build time:** First build takes 10-20 minutes, subsequent builds use cache
- **USB size:** Minimum 4GB recommended, ISO is typically ~1GB
- **Network:** Target machine must be on same network as your workstation
- **Security:** The temporary password "nixos" is for console access only; SSH requires keys
- **Customization:** Installer is just another NixOS config - customize freely!
- **Updates:** Rebuild periodically with `nix flake update` for latest packages

---

**Workshop Duration:** 45 minutes (configuration + build + testing)
**Difficulty:** Beginner to Intermediate
**Prerequisites:** Basic NixOS knowledge, [workshop-1](../workshop-1/) recommended

Happy installing!

**Coming up:**

Continue exploring the NixOS ecosystem with previous workshops:
- **[Workshop 1](../workshop-1/)** - Run NixOS in a VM or Container
- **[Workshop 2](../workshop-2/)** - Run Bitcoin as a service on NixOS
- **[Workshop 3](../workshop-3/)** - Run a forked version of Bitcoin (Mutinynet)
- **[Workshop 4](../workshop-4/)** - Run a complete Bitcoin stack with nix-bitcoin
