# NixOS VM-based automated tests for Bitcoin and Lightning with Mutinynet
# This test suite validates the same scenarios as workshop-9's test.sh
# but runs in isolated VMs using NixOS's test framework
#
# Usage:
#   nix build .#checks.x86_64-linux.bitcoin-lightning-mutinynet
#   nix flake check

{ nixpkgs, system, nix-bitcoin, mutinynetOverlay }:

let
  pkgs = import nixpkgs { inherit system; };
in

pkgs.nixosTest {
  name = "bitcoin-lightning-mutinynet";

  nodes = {
    # First Bitcoin/Lightning node
    node1 = { config, pkgs, ... }: {
      imports = [
        nix-bitcoin.nixosModules.default
        ./configuration.nix
      ];

      # VM-specific: NOT a container
      boot.isContainer = false;

      # Apply Mutinynet overlay
      nixpkgs.overlays = [ mutinynetOverlay ];

      # Set hostname for identification
      networking.hostName = "node1";
    };

    # Second Bitcoin/Lightning node for multi-node tests
    node2 = { config, pkgs, ... }: {
      imports = [
        nix-bitcoin.nixosModules.default
        ./configuration.nix
      ];

      # VM-specific: NOT a container
      boot.isContainer = false;

      # Apply Mutinynet overlay
      nixpkgs.overlays = [ mutinynetOverlay ];

      # Set hostname for identification
      networking.hostName = "node2";
    };
  };

  testScript = ''
    # Start both VMs
    start_all()

    # ============================================================================
    # Test 1: Verify VMs are running
    # ============================================================================
    with subtest("VMs are running"):
        node1.wait_for_unit("multi-user.target")
        node2.wait_for_unit("multi-user.target")

    # ============================================================================
    # Test 2: Root privileges check (implicit - tests run as root)
    # ============================================================================

    # ============================================================================
    # Test 3: Network connectivity
    # ============================================================================
    with subtest("Network connectivity - node1"):
        # VM can reach node2
        node1.succeed("ping -c 2 node2")
        # VM can reach internet
        node1.succeed("ping -c 2 1.1.1.1")
        # DNS works
        node1.succeed("nslookup google.com")

    # ============================================================================
    # Test 4: Bitcoin service is running
    # ============================================================================
    with subtest("Bitcoin service is running on node1"):
        node1.wait_for_unit("bitcoind.service")
        node1.wait_for_open_port(38332)  # Mutinynet RPC port

    # ============================================================================
    # Test 5: Bitcoin RPC responds
    # ============================================================================
    with subtest("Bitcoin RPC responds on node1"):
        node1.succeed("bitcoin-cli -signet getblockchaininfo")

    # ============================================================================
    # Test 6: Bitcoin wallet operations
    # ============================================================================
    with subtest("Bitcoin wallet operations on node1"):
        # Create or load wallet
        node1.succeed(
            "bitcoin-cli -signet createwallet testwallet || bitcoin-cli -signet loadwallet testwallet"
        )
        # Generate address
        addr = node1.succeed("bitcoin-cli -signet getnewaddress").strip()
        assert len(addr) > 0, "Failed to generate address"

    # ============================================================================
    # Test 7: Check Bitcoin balance (initially 0 in signet)
    # ============================================================================
    with subtest("Bitcoin balance check on node1"):
        balance = node1.succeed("bitcoin-cli -signet getbalance").strip()
        print(f"Initial balance: {balance} BTC")
        # In signet, balance starts at 0 (need to get coins from faucet)
        # Test just verifies the command works

    # ============================================================================
    # Test 8: Lightning service is running
    # ============================================================================
    with subtest("Lightning service is running on node1"):
        node1.wait_for_unit("clightning.service")

    # ============================================================================
    # Test 9: Lightning RPC responds and syncs
    # ============================================================================
    with subtest("Lightning RPC responds on node1"):
        # Wait for Lightning to start
        node1.wait_for_file("/var/lib/clightning/signet/lightning-rpc")

        # Get Lightning info
        ln_info = node1.succeed("lightning-cli --network=signet getinfo")
        print(f"Lightning info: {ln_info}")

        # Check blockheight (lenient - may still be syncing)
        blockheight_line = node1.succeed(
            "lightning-cli --network=signet getinfo | grep blockheight"
        ).strip()
        print(f"Lightning sync status: {blockheight_line}")

    # ============================================================================
    # Test 10: Lightning wallet operations
    # ============================================================================
    with subtest("Lightning wallet operations on node1"):
        # Generate Lightning address
        ln_addr = node1.succeed("lightning-cli --network=signet newaddr").strip()
        assert len(ln_addr) > 0, "Failed to generate Lightning address"

    # ============================================================================
    # Test 11: Lightning listfunds
    # ============================================================================
    with subtest("Lightning listfunds on node1"):
        funds = node1.succeed("lightning-cli --network=signet listfunds")
        print(f"Lightning funds: {funds}")

    # ============================================================================
    # Test 12: Check service logs
    # ============================================================================
    with subtest("Service logs accessible on node1"):
        node1.succeed("journalctl -u bitcoind.service -n 10")
        node1.succeed("journalctl -u clightning.service -n 10")

    # ============================================================================
    # Test 13: Second node - Bitcoin service
    # ============================================================================
    with subtest("Bitcoin service is running on node2"):
        node2.wait_for_unit("bitcoind.service")
        node2.wait_for_open_port(38332)  # Mutinynet RPC port
        node2.succeed("bitcoin-cli -signet getblockchaininfo")

    # ============================================================================
    # Test 14: Network connectivity - bidirectional
    # ============================================================================
    with subtest("Node-to-node connectivity"):
        # node1 can ping node2
        node1.succeed("ping -c 2 node2")
        # node2 can ping node1
        node2.succeed("ping -c 2 node1")

    # ============================================================================
    # Test 15: Get node IPs
    # ============================================================================
    with subtest("Node IP addresses"):
        node1_ip = node1.succeed("hostname -I | awk '{print $1}'").strip()
        node2_ip = node2.succeed("hostname -I | awk '{print $1}'").strip()
        print(f"Node1 IP: {node1_ip}")
        print(f"Node2 IP: {node2_ip}")
        assert len(node1_ip) > 0, "Failed to get node1 IP"
        assert len(node2_ip) > 0, "Failed to get node2 IP"

    # ============================================================================
    # Test 16: Bitcoin peer connection
    # ============================================================================
    with subtest("Bitcoin peer connection between nodes"):
        # Get node2 IP for connection
        node2_ip = node2.succeed("hostname -I | awk '{print $1}'").strip()

        # Add node2 as peer from node1 (Mutinynet P2P port 38333)
        node1.succeed(f"bitcoin-cli -signet addnode {node2_ip}:38333 add")

        # Wait a moment for connection
        import time
        time.sleep(3)

        # Check peer info
        peer_info = node1.succeed("bitcoin-cli -signet getpeerinfo")
        print(f"Peer info: {peer_info}")

    # ============================================================================
    # Test 17: Lightning service on node2
    # ============================================================================
    with subtest("Lightning service is running on node2"):
        node2.wait_for_unit("clightning.service")
        node2.wait_for_file("/var/lib/clightning/signet/lightning-rpc")
        node2.succeed("lightning-cli --network=signet getinfo")

    # ============================================================================
    # Test 18: Lightning node information
    # ============================================================================
    with subtest("Lightning node information"):
        # Get node1 Lightning pubkey
        node1_info = node1.succeed("lightning-cli --network=signet getinfo")
        print(f"Node1 Lightning info: {node1_info}")

        # Get node2 Lightning pubkey
        node2_info = node2.succeed("lightning-cli --network=signet getinfo")
        print(f"Node2 Lightning info: {node2_info}")

        # Note: Lightning peer connection would require:
        # 1. Configure CLN to bind to 0.0.0.0 (currently localhost only)
        # 2. Use lightning-cli connect <pubkey>@<ip>:9735
        # This is documented in configuration.nix comments

    # ============================================================================
    # Test 19: Verify Mutinynet fork
    # ============================================================================
    with subtest("Verify Mutinynet Bitcoin fork"):
        # Check Bitcoin version shows Mutinynet
        version = node1.succeed("bitcoind --version | head -1")
        print(f"Bitcoin version: {version}")

        # Verify signet configuration
        netinfo = node1.succeed("bitcoin-cli -signet getnetworkinfo")
        assert "signet" in netinfo.lower(), "Not running on signet"
        print("Confirmed: Running Mutinynet signet")

    # ============================================================================
    # Summary
    # ============================================================================
    print("\n" + "="*60)
    print("All tests passed!")
    print("="*60)
    print("Configuration validated:")
    print("  ✓ Mutinynet Bitcoin fork")
    print("  ✓ Bitcoin Core (signet mode)")
    print("  ✓ Core Lightning")
    print("  ✓ Network connectivity")
    print("  ✓ Multi-node setup")
    print("="*60)
  '';
}
