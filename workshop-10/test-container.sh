#!/usr/bin/env bash
# Automated Test Suite for Core Lightning Container
# Tests Core Lightning container connecting to external bitcoind
#
# PREREQUISITES:
#   - Bitcoin VM must be running with hostname "bitcoin"
#   - DNS resolution must be working (host provides DHCP/DNS)
#
# Usage: sudo ./test-container.sh
#        sudo ./test-container.sh --keep  # Keep container after tests

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
KEEP_CONTAINER=false
CONTAINER_NAME="tlightning"  # Test Lightning (max 11 chars for container names)
TESTS_PASSED=0
TESTS_FAILED=0

# Parse arguments
if [ "$1" = "--keep" ]; then
  KEEP_CONTAINER=true
fi

# Logging functions
log_info() {
  echo -e "${BLUE}ℹ $1${NC}"
}

log_success() {
  echo -e "${GREEN}✅ $1${NC}"
  ((TESTS_PASSED++)) || true
}

log_error() {
  echo -e "${RED}❌ $1${NC}"
  ((TESTS_FAILED++)) || true
}

log_test() {
  echo -e "\n${YELLOW}Test $1: $2${NC}"
}

# Cleanup function
cleanup() {
  if [ "$KEEP_CONTAINER" = false ]; then
    log_info "Cleaning up test container..."
    if sudo nixos-container list | grep -q "^${CONTAINER_NAME}$"; then
      log_info "Destroying $CONTAINER_NAME..."
      if sudo nixos-container destroy "$CONTAINER_NAME" >/dev/null 2>&1; then
        log_success "$CONTAINER_NAME destroyed"
      else
        log_error "Failed to destroy $CONTAINER_NAME"
      fi
    fi
  else
    log_info "Keeping container for inspection (--keep flag)"
    log_info "To destroy: sudo nixos-container destroy $CONTAINER_NAME"
  fi
}

trap cleanup EXIT

# Helper function to run commands in container
run_in_container() {
  sudo nixos-container run "$CONTAINER_NAME" -- "$@"
}

echo "========================================"
echo "Core Lightning Container Test Suite"
echo "Network: Mutinynet Signet"
echo "========================================"
echo ""

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  log_error "This script must be run as root"
  exit 1
fi

# ============================================================================
# Test 1: Verify workshop files
# ============================================================================
log_test 1 "Verify workshop files"

if [ ! -f "flake.nix" ]; then
  log_error "flake.nix not found. Run this script from workshop-10 directory"
  exit 1
fi

if [ ! -f "container-lightning.nix" ]; then
  log_error "container-lightning.nix not found"
  exit 1
fi

log_success "Workshop files present"

# ============================================================================
# Test 2: Check for existing container
# ============================================================================
log_test 2 "Check for existing test container"

if sudo nixos-container list | grep -q "^${CONTAINER_NAME}$"; then
  log_info "Cleaning up existing $CONTAINER_NAME..."
  sudo nixos-container destroy "$CONTAINER_NAME" >/dev/null 2>&1 || true
fi

log_success "No conflicting containers"

# ============================================================================
# Test 3: Verify bitcoind is accessible
# ============================================================================
log_test 3 "Verify bitcoind accessibility"

# Bitcoin VM hostname (configured in flake.nix)
BITCOIND_HOST="bitcoin"
log_info "Checking bitcoind at: ${BITCOIND_HOST}:38332"

# Verify DNS resolution works
if ping -c 2 "$BITCOIND_HOST" &> /dev/null; then
  log_success "DNS resolution working for hostname: $BITCOIND_HOST"
else
  log_error "Cannot resolve hostname: $BITCOIND_HOST"
  log_info "Make sure the Bitcoin VM is running and hostname is configured"
  exit 1
fi

# Try to connect to bitcoind RPC
if command -v curl &> /dev/null; then
  if curl -s --user bitcoin:bitcoin \
    --data-binary '{"jsonrpc": "1.0", "id":"test", "method": "getblockchaininfo", "params": [] }' \
    -H 'content-type: text/plain;' \
    http://${BITCOIND_HOST}:38332/ | grep -q "result"; then
    log_success "bitcoind RPC accessible at ${BITCOIND_HOST}:38332"
  else
    log_error "Cannot connect to bitcoind RPC at ${BITCOIND_HOST}:38332"
    log_info "Make sure Bitcoin VM is running and RPC is enabled"
    exit 1
  fi
else
  log_info "curl not found, skipping RPC connectivity check"
fi

# ============================================================================
# Test 4: Wait for Bitcoin IBD to complete
# ============================================================================
log_test 4 "Wait for Bitcoin Initial Block Download to complete"

log_info "Checking Bitcoin sync status..."
while true; do
  if command -v curl &> /dev/null && command -v jq &> /dev/null; then
    IBD_STATUS=$(curl -s --user bitcoin:bitcoin \
      --data-binary '{"jsonrpc": "1.0", "id":"ibd", "method": "getblockchaininfo", "params": [] }' \
      -H 'content-type: text/plain;' \
      http://${BITCOIND_HOST}:38332/ | jq -r '.result.initialblockdownload')

    if [ "$IBD_STATUS" = "false" ]; then
      log_success "Bitcoin IBD complete, blockchain is synced"
      break
    else
      log_info "Bitcoin is still syncing (IBD in progress)..."
      log_info "Waiting 60 seconds before retry..."
      sleep 60
    fi
  else
    log_error "curl or jq not found, cannot check IBD status"
    log_info "Install: apt install curl jq (or nix-shell -p curl jq)"
    exit 1
  fi
done

# ============================================================================
# Test 5: Create Core Lightning container
# ============================================================================
log_test 5 "Create Core Lightning container"

if sudo nixos-container create "$CONTAINER_NAME" --flake .#lightning 2>&1 | tee /tmp/create-cln.txt; then
  log_success "Container created successfully"
else
  log_error "Failed to create container"
  cat /tmp/create-cln.txt
  exit 1
fi

# ============================================================================
# Test 6: Start container
# ============================================================================
log_test 6 "Start container"

if sudo nixos-container start "$CONTAINER_NAME"; then
  log_success "Container started"
else
  log_error "Failed to start container"
  exit 1
fi

# Wait for container to fully boot
log_info "Waiting for container to boot..."
sleep 10

# ============================================================================
# Test 7: Verify network connectivity
# ============================================================================
log_test 7 "Verify network connectivity"

# Get container IP
CONTAINER_IP=$(sudo nixos-container show-ip "$CONTAINER_NAME")
log_info "Container IP: $CONTAINER_IP"

# Ping container from host
if ping -c 2 "$CONTAINER_IP" > /dev/null 2>&1; then
  log_success "Container is reachable from host"
else
  log_error "Cannot ping container"
fi

# Check if container can reach bitcoind via hostname
if run_in_container ping -c 2 "$BITCOIND_HOST" > /dev/null 2>&1; then
  log_success "Container can reach bitcoind host: $BITCOIND_HOST"
else
  log_error "Container cannot reach bitcoind hostname: $BITCOIND_HOST"
fi

# ============================================================================
# Test 8: Verify clightning service is running
# ============================================================================
log_test 8 "Verify clightning service"

if run_in_container systemctl is-active clightning.service | grep -q "active"; then
  log_success "clightning.service is active"
else
  log_error "clightning.service is not active"
  run_in_container journalctl -u clightning.service -n 20 --no-pager
  exit 1
fi

# Wait for Lightning to initialize
log_info "Waiting for Lightning to initialize..."
sleep 5

# ============================================================================
# Test 9: Verify Lightning RPC socket
# ============================================================================
log_test 9 "Verify Lightning RPC socket"

if run_in_container test -S /var/lib/clightning/signet/lightning-rpc; then
  log_success "Lightning RPC socket exists"
else
  log_error "Lightning RPC socket not found"
  run_in_container ls -la /var/lib/clightning/
fi

# ============================================================================
# Test 10: Test Lightning RPC commands
# ============================================================================
log_test 10 "Test Lightning RPC commands"

# Get Lightning node info
if LN_INFO=$(run_in_container lightning-cli --network=signet getinfo 2>&1); then
  log_success "lightning-cli getinfo works"
  echo "$LN_INFO" | head -5
else
  log_error "lightning-cli getinfo failed"
  echo "$LN_INFO"
fi

# ============================================================================
# Test 11: Verify Bitcoin backend connection
# ============================================================================
log_test 11 "Verify Bitcoin backend connection"

# Check if Lightning sees the blockchain
BLOCK_HEIGHT=$(run_in_container lightning-cli --network=signet getinfo | grep -o '"blockheight":[0-9]*' | cut -d':' -f2)

if [ -n "$BLOCK_HEIGHT" ] && [ "$BLOCK_HEIGHT" -gt 0 ]; then
  log_success "Lightning synced to block height: $BLOCK_HEIGHT"
else
  log_error "Lightning not seeing blocks from bitcoind"
  log_info "Check clightning logs for connection errors:"
  run_in_container journalctl -u clightning.service -n 30 --no-pager
fi

# ============================================================================
# Test 12: Generate Lightning address
# ============================================================================
log_test 12 "Generate Lightning address"

if LN_ADDR=$(run_in_container lightning-cli --network=signet newaddr 2>&1); then
  log_success "Generated Lightning address"
  echo "$LN_ADDR" | grep -o 'tb1[a-z0-9]*' || true
else
  log_error "Failed to generate Lightning address"
  echo "$LN_ADDR"
fi

# ============================================================================
# Test 13: List funds
# ============================================================================
log_test 13 "List Lightning funds"

if FUNDS=$(run_in_container lightning-cli --network=signet listfunds 2>&1); then
  log_success "listfunds command works"
  echo "$FUNDS" | head -10
else
  log_error "listfunds command failed"
  echo "$FUNDS"
fi

# ============================================================================
# Test 14: Check service logs
# ============================================================================
log_test 14 "Check service logs"

if run_in_container journalctl -u clightning.service -n 10 --no-pager > /dev/null 2>&1; then
  log_success "Service logs accessible"
else
  log_error "Cannot access service logs"
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "========================================"
echo "Test Summary"
echo "========================================"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo "========================================"

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✅ All tests passed!${NC}"
  echo ""
  echo "Core Lightning container validated:"
  echo "  ✓ Container created and started"
  echo "  ✓ Network connectivity (DHCP from host)"
  echo "  ✓ clightning service running"
  echo "  ✓ Connected to bitcoind VM (hostname: $BITCOIND_HOST)"
  echo "  ✓ Lightning RPC working"
  echo "  ✓ Synced to blockchain (block $BLOCK_HEIGHT)"
  echo ""
  echo "To interact with Lightning:"
  echo "  sudo nixos-container run $CONTAINER_NAME -- lightning-cli --network=signet getinfo"
  echo "  sudo nixos-container root-login $CONTAINER_NAME"
  echo ""
  echo "Container IP: $CONTAINER_IP"
  exit 0
else
  echo -e "${RED}❌ Some tests failed${NC}"
  echo ""
  echo "Common issues:"
  echo "  - Bitcoin VM not running (hostname: $BITCOIND_HOST)"
  echo "  - DNS resolution not working"
  echo "  - RPC credentials mismatch"
  echo "  - Network routing issues"
  exit 1
fi
