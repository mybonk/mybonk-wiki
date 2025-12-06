#!/usr/bin/env bash
# Wrapper script to run Bitcoin VM with proper bridge networking
# This script must be run with sudo for bridge networking access

set -e

# Configuration
TAP_DEVICE="vmtap0"
BRIDGE="br-containers"  # Default bridge from workshop-9
VM_SCRIPT="./result/bin/run-bitcoin-vm"
PID_FILE="/var/run/bitcoin-vm.pid"
DAEMON_MODE=false
DATA_DISK="vm-data/bitcoin-vm.qcow2"
DATA_DISK_SIZE="50G"  # Adjust as needed for blockchain size

# Allow override via environment variable
BRIDGE="${BRIDGE:-br-containers}"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --daemon)
      DAEMON_MODE=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: sudo $0 [--daemon]"
      exit 1
      ;;
  esac
done

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run with sudo for bridge networking"
  echo "Usage: sudo $0 [--daemon]"
  exit 1
fi

# Check if bridge exists
if ! ip link show "$BRIDGE" &>/dev/null; then
  echo "Error: Bridge $BRIDGE does not exist"
  echo "Please set up the bridge network first (see workshop-9)"
  exit 1
fi

# Check if VM script exists
if [ ! -f "$VM_SCRIPT" ]; then
  echo "Error: VM script not found at $VM_SCRIPT"
  echo "Please run: nix build .#packages.x86_64-linux.bitcoin-vm"
  exit 1
fi

# Create persistent data disk if it doesn't exist
if [ ! -f "$DATA_DISK" ]; then
  echo "Creating persistent data disk: $DATA_DISK ($DATA_DISK_SIZE)"
  mkdir -p "$(dirname "$DATA_DISK")"

  # Use qemu-img to create disk (automatically use nix-shell if not in PATH)
  if command -v qemu-img &> /dev/null; then
    # qemu-img is in PATH, use it directly
    qemu-img create -f qcow2 "$DATA_DISK" "$DATA_DISK_SIZE"
  elif command -v nix-shell &> /dev/null; then
    # Use nix-shell to provide qemu-img
    echo "Using nix-shell to run qemu-img..."
    nix-shell -p qemu --run "qemu-img create -f qcow2 '$DATA_DISK' '$DATA_DISK_SIZE'"
  else
    echo "Error: Neither qemu-img nor nix-shell found"
    echo "Please install QEMU or Nix"
    exit 1
  fi

  echo "✓ Created persistent disk at $DATA_DISK"
  echo "  This disk will store Bitcoin blockchain data"
  echo "  Data persists across VM restarts"
else
  echo "Using existing persistent data disk: $DATA_DISK"
fi

# Cleanup function
cleanup() {
  # In daemon mode, don't cleanup (VM is still running)
  if [ "$DAEMON_MODE" = true ]; then
    return
  fi

  echo ""
  echo "Cleaning up network..."
  if ip link show "$TAP_DEVICE" &>/dev/null; then
    ip link set "$TAP_DEVICE" down
    ip link delete "$TAP_DEVICE"
    echo "Removed tap device $TAP_DEVICE"
  fi
}

# Set trap to cleanup on exit (only in foreground mode)
if [ "$DAEMON_MODE" = false ]; then
  trap cleanup EXIT INT TERM
fi

# Create tap device
echo "Setting up bridge networking..."
if ! ip link show "$TAP_DEVICE" &>/dev/null; then
  ip tuntap add dev "$TAP_DEVICE" mode tap user root
  echo "Created tap device $TAP_DEVICE"
fi

# Attach tap to bridge
ip link set "$TAP_DEVICE" master "$BRIDGE"
ip link set "$TAP_DEVICE" up
echo "Attached $TAP_DEVICE to bridge $BRIDGE"

# Convert DATA_DISK to absolute path
DATA_DISK_ABS="$(cd "$(dirname "$DATA_DISK")" && pwd)/$(basename "$DATA_DISK")"

# QEMU arguments for persistent data disk
# This will be attached as /dev/vdb in the VM
QEMU_DATA_DISK_ARGS="-drive file=$DATA_DISK_ABS,if=virtio,format=qcow2"

echo ""
if [ "$DAEMON_MODE" = true ]; then
  echo "Starting Bitcoin VM in daemon mode..."
  echo "VM will get IP via DHCP from host (10.233.0.x)"
  echo "Persistent data disk: $DATA_DISK"
  echo ""

  # Run the VM in background with persistent disk
  QEMU_OPTS="$QEMU_DATA_DISK_ARGS" $VM_SCRIPT &
  VM_PID=$!

  # Save PID
  echo $VM_PID > "$PID_FILE"

  echo "✓ Bitcoin VM started in background"
  echo "  PID: $VM_PID"
  echo "  PID file: $PID_FILE"
  echo "  Data disk: $DATA_DISK_ABS"
  echo ""
  echo "To stop the VM:"
  echo "  sudo ./stop-bitcoin-vm.sh"
  echo ""
  echo "To check if VM is running:"
  echo "  ps -p \$(cat $PID_FILE)"
  echo "  ping bitcoin"
  echo ""
else
  echo "Starting Bitcoin VM..."
  echo "VM will get IP via DHCP from host (10.233.0.x)"
  echo "Persistent data disk: $DATA_DISK"
  echo "Press Ctrl-A then X to exit QEMU console"
  echo ""

  # Run the VM in foreground with persistent disk
  QEMU_OPTS="$QEMU_DATA_DISK_ARGS" $VM_SCRIPT
fi
