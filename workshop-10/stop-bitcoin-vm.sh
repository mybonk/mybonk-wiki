#!/usr/bin/env bash
# Script to stop the Bitcoin VM running in daemon mode

set -e

TAP_DEVICE="vmtap0"
PID_FILE="/var/run/bitcoin-vm.pid"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run with sudo"
  echo "Usage: sudo $0"
  exit 1
fi

# Check if PID file exists
if [ ! -f "$PID_FILE" ]; then
  echo "Error: No PID file found at $PID_FILE"
  echo "VM may not be running or was started without --daemon"
  exit 1
fi

# Read PID
VM_PID=$(cat "$PID_FILE")

# Check if process is running
if ! ps -p "$VM_PID" > /dev/null 2>&1; then
  echo "Warning: Process $VM_PID is not running"
  echo "Cleaning up stale PID file and tap device..."
else
  echo "Stopping Bitcoin VM (PID: $VM_PID)..."
  kill "$VM_PID"
  sleep 2

  # Force kill if still running
  if ps -p "$VM_PID" > /dev/null 2>&1; then
    echo "Force stopping VM..."
    kill -9 "$VM_PID"
  fi

  echo "✓ VM stopped"
fi

# Remove PID file
rm -f "$PID_FILE"
echo "✓ Removed PID file"

# Remove tap device
if ip link show "$TAP_DEVICE" &>/dev/null; then
  ip link set "$TAP_DEVICE" down
  ip link delete "$TAP_DEVICE"
  echo "✓ Removed tap device $TAP_DEVICE"
fi

echo ""
echo "Bitcoin VM has been stopped and cleaned up"
