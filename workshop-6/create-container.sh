#!/usr/bin/env bash
# NixOS Container Creation Helper Script
# Usage: sudo ./create-container.sh <container-name>
# Example: sudo ./create-container.sh container1
#
# Note: Container configuration (IP address, hostname, etc.) is defined in flake.nix

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)"
    exit 1
fi

# Check arguments
if [ $# -ne 1 ]; then
    echo "Usage: $0 <container-name>"
    echo "Example: $0 container1"
    echo ""
    echo "Available containers defined in flake.nix:"
    echo "  - container1 (10.100.0.10)"
    echo "  - container2 (10.100.0.20)"
    exit 1
fi

CONTAINER_NAME="$1"

# Get script directory (where flake.nix is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================"
echo "NixOS Container Creation"
echo "================================"
echo "Container Name: $CONTAINER_NAME"
echo "Flake Path:     $SCRIPT_DIR"
echo "Configuration:  Defined in flake.nix"
echo "================================"
echo

# Step 1: Create container with network configuration
echo "[1/2] Creating container from flake with network configuration..."
nixos-container create "$CONTAINER_NAME" \
    --flake "$SCRIPT_DIR#$CONTAINER_NAME"

echo "✓ Container created"
echo

# Step 2: Start container
echo "[2/2] Starting container..."
nixos-container start "$CONTAINER_NAME"

echo "✓ Container started"
echo


# Final status
echo "================================"
echo "Container Setup Complete!"
echo "================================"
echo
echo "Container Status:"
nixos-container status "$CONTAINER_NAME"
echo
echo "Container IP:"
nixos-container run "$CONTAINER_NAME" -- ip -4 addr show enp1s0 2>/dev/null | grep inet || echo "Network not yet configured"
echo

echo "Quick Commands:"
echo "  Access container:  sudo nixos-container root-login $CONTAINER_NAME"
echo "  Stop container:    sudo nixos-container stop $CONTAINER_NAME"
echo "  Start container:   sudo nixos-container start $CONTAINER_NAME"
echo "  Update container:  sudo nixos-container update $CONTAINER_NAME --flake $SCRIPT_DIR#$CONTAINER_NAME"
echo "  Destroy container: sudo nixos-container destroy $CONTAINER_NAME"
echo
echo "Test connectivity:"
echo "  sudo nixos-container run $CONTAINER_NAME -- ping -c 4 google.com"
echo
