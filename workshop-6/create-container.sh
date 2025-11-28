#!/usr/bin/env bash
# NixOS Container Creation Helper Script
# Usage: sudo ./create-container.sh <container-name> <ip-address>
# Example: sudo ./create-container.sh container1 10.100.0.10

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)"
    exit 1
fi

# Check arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <container-name> <ip-address>"
    echo "Example: $0 container1 10.100.0.10"
    exit 1
fi

CONTAINER_NAME="$1"
IP_ADDRESS="$2"
BRIDGE="br-containers"
SUBNET_PREFIX="24"

# Get script directory (where flake.nix is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================"
echo "NixOS Container Creation"
echo "================================"
echo "Container Name: $CONTAINER_NAME"
echo "IP Address:     $IP_ADDRESS/$SUBNET_PREFIX"
echo "Bridge:         $BRIDGE"
echo "Flake Path:     $SCRIPT_DIR"
echo "================================"
echo

# Step 1: Create container
echo "[1/4] Creating container from flake..."
nixos-container create "$CONTAINER_NAME" \
    --flake "$SCRIPT_DIR#$CONTAINER_NAME" \
    --config-file /dev/null

echo "✓ Container created"
echo

# Step 2: Configure networking
echo "[2/4] Configuring container networking..."
mkdir -p "/etc/nixos-containers/$CONTAINER_NAME"

cat > "/etc/nixos-containers/$CONTAINER_NAME.conf" <<EOF
PRIVATE_NETWORK=yes
HOST_BRIDGE=$BRIDGE
LOCAL_ADDRESS=$IP_ADDRESS/$SUBNET_PREFIX
EOF

echo "✓ Network configuration written"
echo

# Step 3: Start container
echo "[3/4] Starting container..."
nixos-container start "$CONTAINER_NAME"

echo "✓ Container started"
echo

# Step 4: Enable auto-start
echo "[4/4] Enabling auto-start on boot..."
systemctl enable "container@$CONTAINER_NAME"

echo "✓ Auto-start enabled"
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
nixos-container run "$CONTAINER_NAME" -- ip -4 addr show eth0 2>/dev/null | grep inet || echo "Network not yet configured"
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
