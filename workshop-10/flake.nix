{
  description = "NixOS VM configuration with nix-bitcoin for Bitcoin and Lightning nodes using Mutinynet fork";

  inputs = {
    # nix-bitcoin: Bitcoin and Lightning node configurations
    nix-bitcoin.url = "github:fort-nix/nix-bitcoin/master";

    # Use nixpkgs from nix-bitcoin for consistency
    nixpkgs.follows = "nix-bitcoin/nixpkgs";
  };

  outputs = { self, nixpkgs, nix-bitcoin }:
  let
    system = "x86_64-linux";

    # Download pre-built Mutinynet binary from GitHub releases
    # Uses Bitcoin Inquisition with active soft forks (Anyprevout, CTV, OP_CAT, CSFS, OP_INTERNALKEY)
    mutinynetBinary = nixpkgs.legacyPackages.${system}.fetchurl {
      url = "https://github.com/benthecarman/bitcoin/releases/download/mutinynet-inq-29/bitcoin-38351585048e-x86_64-linux-gnu.tar.gz";
      sha256 = "sha256-DGH69F4s9Ez21RufJ5qnxnyxa7OFtHHSw2vYUoF8bwM=";
    };

    # Create custom package set with Mutinynet bitcoin binary
    pkgs = import nixpkgs {
      inherit system;
      overlays = [
        (final: prev: {
          bitcoin = prev.stdenv.mkDerivation {
            pname = "bitcoin";
            version = "29.0-mutinynet-inquisition";

            src = mutinynetBinary;

            nativeBuildInputs = [ prev.autoPatchelfHook ];

            buildInputs = with prev; [
              stdenv.cc.cc.lib
              boost
              libevent
              miniupnpc
              zeromq
              sqlite
            ];

            sourceRoot = ".";

            installPhase = ''
              mkdir -p $out/bin
              # Only copy the binaries we need (skip bitcoin-qt GUI which has extra dependencies)
              cp bitcoin-38351585048e/bin/bitcoind $out/bin/
              cp bitcoin-38351585048e/bin/bitcoin-cli $out/bin/
              cp bitcoin-38351585048e/bin/bitcoin-tx $out/bin/
              cp bitcoin-38351585048e/bin/bitcoin-util $out/bin/
              cp bitcoin-38351585048e/bin/bitcoin-wallet $out/bin/
              chmod +x $out/bin/*
            '';

            meta = {
              description = "Bitcoin Inquisition - Mutinynet signet fork (pre-built binary)";
              license = prev.lib.licenses.mit;
              platforms = [ "x86_64-linux" ];
            };
          };
        })
      ];
    };

    # Helper function to create a Bitcoin container configuration
    # Used for imperative container creation
    mkContainerConfig = { ... }: {
      imports = [
        ./configuration.nix
      ];

      # CONTAINER-SPECIFIC: Tell NixOS this is a container
      boot.isContainer = true;

      # Apply Mutinynet overlay
      nixpkgs.overlays = [ (final: prev: { inherit (pkgs) bitcoin; }) ];
    };

    # Note: VM configuration for tests is defined directly in test.nix
    # No helper function needed - test framework creates VMs with proper config
  in
  {
    # Container configurations (for imperative container creation)
    nixosConfigurations = {
      # Bitcoin container (Mutinynet signet)
      # Usage: sudo nixos-container create bitcoin --flake .#bitcoin
      bitcoin = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          (mkContainerConfig {})
        ];
      };

      # Core Lightning container (connects to external bitcoind)
      # Usage: sudo nixos-container create lightning --flake .#lightning
      lightning = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit nix-bitcoin; };  # Pass nix-bitcoin input to modules
        modules = [
          # CRITICAL: Apply Mutinynet overlay FIRST so nix-bitcoin sees Bitcoin Inquisition
          # This ensures the container runs the correct Bitcoin fork optimized for Mutinynet
          { nixpkgs.overlays = [ (final: prev: { inherit (pkgs) bitcoin; }) ]; }

          nix-bitcoin.nixosModules.default
          ./container-lightning.nix
        ];
      };

      # Note: VM configuration for tests is defined directly in test.nix
      # No separate VM config needed in nixosConfigurations
    };

    # Real VM for deployment (accessible on network)
    # Usage: nix build .#packages.x86_64-linux.bitcoin-vm
    #        ./result/bin/run-bitcoin-vm
    packages.x86_64-linux.bitcoin-vm =
      let
        vmConfig = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./configuration.nix

            # VM-specific configuration
            ({ config, modulesPath, ... }: {
              imports = [
                (modulesPath + "/virtualisation/qemu-vm.nix")
              ];

              # Basic VM settings
              boot.isContainer = false;

              # Hostname
              networking.hostName = "bitcoin";

              # VM filesystem
              fileSystems."/" = {
                device = "/dev/vda";
                fsType = "ext4";
              };

              boot.loader.grub.device = "/dev/vda";

              # Apply Mutinynet overlay
              nixpkgs.overlays = [ (final: prev: { inherit (pkgs) bitcoin; }) ];

              # Disable default VM networking settings that would conflict
              networking.useDHCP = pkgs.lib.mkForce false;
              systemd.network.enable = pkgs.lib.mkForce true;

              # Configure network interface for DHCP
              systemd.network.networks."10-eth" = {
                matchConfig.Name = "eth*";  # Match eth0, eth1, etc.
                networkConfig.DHCP = "yes";
                dhcpV4Config = {
                  UseDNS = false;
                  UseRoutes = true;
                };
              };

              # DNS from host
              networking.nameservers = [ "10.233.0.1" ];
              services.resolved.enable = false;

              # Disable default QEMU networking (we'll use our own tap device)
              virtualisation.qemu.networkingOptions = pkgs.lib.mkForce [];

              # VM QEMU settings - use tap device for bridge networking
              # Note: The actual tap setup is done by run-bitcoin-vm.sh wrapper script
              # The tap device (vmtap0) will be attached to br-containers bridge
              virtualisation.qemu.options = [
                # Run in headless mode (no graphical console)
                "-nographic"
                # Use tap device (created by wrapper script)
                "-netdev" "tap,id=net0,ifname=vmtap0,script=no,downscript=no"
                # Connect to VM's network device
                "-device" "virtio-net-pci,netdev=net0,mac=52:54:00:12:34:56"
              ];

              # Enable serial console for headless operation
              virtualisation.qemu.consoles = [ "ttyS0" ];

              # Auto-login as root on serial console
              #services.getty.autologinUser = "root";

              # Allocate more memory for Bitcoin
              virtualisation.memorySize = 4096;
              virtualisation.cores = 2;

              # Configure persistent disk size (this is still ephemeral by default)
              # We'll attach a separate persistent disk via run-bitcoin-vm.sh
              virtualisation.diskSize = 8192; # 8GB for system

              # Auto-mount persistent data disk (if present)
              # The persistent disk will be /dev/vdb (second virtio disk)
              fileSystems."/var/lib/bitcoind" = {
                device = "/dev/vdb";
                fsType = "ext4";
                options = [ "nofail" ]; # Don't fail boot if disk not attached
                autoFormat = true; # Auto-format on first use
              };

              # Ensure proper ownership and permissions on persistent disk
              systemd.tmpfiles.rules = [
                "d /var/lib/bitcoind 0750 bitcoin bitcoin -"
                "d /var/lib/bitcoind/signet 0750 bitcoin bitcoin -"
              ];

              # Create a systemd service to setup persistent disk (runs as root before bitcoind)
              systemd.services.bitcoind-setup-disk = {
                description = "Setup Bitcoin persistent disk";
                wantedBy = [ "bitcoind.service" ];
                before = [ "bitcoind.service" ];
                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                };
                script = ''
                  # Ensure /dev/vdb is formatted and mounted
                  if [ -b /dev/vdb ]; then
                    echo "Checking persistent disk /dev/vdb..."

                    # Format if not already formatted
                    if ! ${pkgs.util-linux}/bin/blkid /dev/vdb >/dev/null 2>&1; then
                      echo "Formatting /dev/vdb with ext4..."
                      ${pkgs.e2fsprogs}/bin/mkfs.ext4 -F /dev/vdb
                    fi

                    # Create mount point if it doesn't exist
                    mkdir -p /var/lib/bitcoind

                    # Mount if not already mounted
                    if ! ${pkgs.util-linux}/bin/mountpoint -q /var/lib/bitcoind; then
                      echo "Mounting /dev/vdb to /var/lib/bitcoind..."
                      ${pkgs.util-linux}/bin/mount /dev/vdb /var/lib/bitcoind
                    fi

                    # Ensure correct ownership
                    chown -R bitcoin:bitcoin /var/lib/bitcoind

                    echo "Persistent disk ready at /var/lib/bitcoind"
                    df -h /var/lib/bitcoind
                  else
                    echo "Warning: /dev/vdb not found - using root filesystem"
                  fi
                '';
              };

              # Clean up corrupted settings files before bitcoind starts
              systemd.services.bitcoind.preStart = ''
                # Clean up any corrupted settings files on startup
                if [ -f /var/lib/bitcoind/signet/settings.json ]; then
                  if ! ${pkgs.jq}/bin/jq empty /var/lib/bitcoind/signet/settings.json 2>/dev/null; then
                    echo "Removing corrupted settings.json..."
                    rm -f /var/lib/bitcoind/signet/settings.json
                  fi
                fi
              '';

              # Make bitcoind depend on disk setup
              systemd.services.bitcoind.requires = [ "bitcoind-setup-disk.service" ];
              systemd.services.bitcoind.after = [ "bitcoind-setup-disk.service" ];
            })
          ];
        };
      in
      vmConfig.config.system.build.vm;

    # Automated tests using NixOS VM test framework
    # Usage: nix build .#checks.x86_64-linux.bitcoin-lightning-mutinynet
    #        nix flake check
    checks.x86_64-linux = {
      bitcoin-lightning-mutinynet = import ./test.nix {
        inherit nixpkgs system;
        nix-bitcoin = nix-bitcoin;
        mutinynetOverlay = (final: prev: { inherit (pkgs) bitcoin; });
      };
    };
  };
}
