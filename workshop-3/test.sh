#!/usr/bin/env bash
# Automated Test Suite for nginx Version Override Workshop
# Tests validate that different nixpkgs versions provide different nginx versions
#
# Usage: sudo ./test.sh
#        sudo ./test.sh --keep  # Keep containers after tests for inspection

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
KEEP_CONTAINERS=false
CONTAINER_OLD="nginx-old"
CONTAINER_NEW="nginx-new"
TESTS_PASSED=0
TESTS_FAILED=0

# Parse arguments
if [ "$1" = "--keep" ]; then
  KEEP_CONTAINERS=true
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
  if [ "$KEEP_CONTAINERS" = false ]; then
    log_info "Cleaning up test containers..."

    for container in "$CONTAINER_OLD" "$CONTAINER_NEW"; do
      if sudo nixos-container list | grep -q "^${container}$"; then
        log_info "Destroying $container..."
        if sudo nixos-container destroy "$container" >/dev/null 2>&1; then
          log_success "$container destroyed"
        else
          log_error "Failed to destroy $container"
        fi
      fi
    done
  else
    log_info "Keeping containers for inspection (use --keep flag)"
    log_info "To destroy: sudo nixos-container destroy $CONTAINER_OLD $CONTAINER_NEW"
  fi
}

trap cleanup EXIT

# Helper function to run commands in container
run_in_container() {
  local container=$1
  shift
  sudo nixos-container run "$container" -- "$@"
}

echo "========================================"
echo "nginx Version Override Test Suite"
echo "Using: NixOS Containers with Multiple nixpkgs Inputs"
echo "========================================"
echo ""

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  log_error "This script must be run as root"
  exit 1
fi

# ============================================================================
# Test 1: Verify workshop directory and flake
# ============================================================================
log_test 1 "Verify workshop directory and flake"

if [ ! -f "flake.nix" ]; then
  log_error "flake.nix not found. Run this script from workshop-3 directory"
  exit 1
fi

if [ ! -f "container-configuration.nix" ]; then
  log_error "container-configuration.nix not found"
  exit 1
fi

log_success "Workshop files present"

# ============================================================================
# Test 2: Check for existing containers
# ============================================================================
log_test 2 "Check for existing test containers"

for container in "$CONTAINER_OLD" "$CONTAINER_NEW"; do
  if sudo nixos-container list | grep -q "^${container}$"; then
    log_info "Cleaning up existing $container..."
    sudo nixos-container destroy "$container" >/dev/null 2>&1 || true
  fi
done

log_success "No conflicting containers"

# ============================================================================
# Test 3: Create OLD nginx container (nixos-23.05)
# ============================================================================
log_test 3 "Create OLD nginx container (nixos-23.05)"

if sudo nixos-container create "$CONTAINER_OLD" --flake .#nginx-old 2>&1 | tee /tmp/create-old.txt; then
  log_success "OLD container created successfully"
else
  log_error "Failed to create OLD container"
  cat /tmp/create-old.txt
  exit 1
fi

# ============================================================================
# Test 4: Create NEW nginx container (nixos-24.11)
# ============================================================================
log_test 4 "Create NEW nginx container (nixos-24.11)"

if sudo nixos-container create "$CONTAINER_NEW" --flake .#nginx-new 2>&1 | tee /tmp/create-new.txt; then
  log_success "NEW container created successfully"
else
  log_error "Failed to create NEW container"
  cat /tmp/create-new.txt
  exit 1
fi

# ============================================================================
# Test 5: Start both containers
# ============================================================================
log_test 5 "Start both containers"

if sudo nixos-container start "$CONTAINER_OLD"; then
  log_success "OLD container started"
else
  log_error "Failed to start OLD container"
  exit 1
fi

if sudo nixos-container start "$CONTAINER_NEW"; then
  log_success "NEW container started"
else
  log_error "Failed to start NEW container"
  exit 1
fi

# Wait for containers to fully boot
sleep 5

# ============================================================================
# Test 6: Verify nginx service running in both containers
# ============================================================================
log_test 6 "Verify nginx service running"

for container in "$CONTAINER_OLD" "$CONTAINER_NEW"; do
  if run_in_container "$container" systemctl is-active nginx.service | grep -q "active"; then
    log_success "nginx.service is active in $container"
  else
    log_error "nginx.service is not active in $container"
    run_in_container "$container" journalctl -u nginx.service -n 20 --no-pager
  fi
done

# ============================================================================
# Test 7: Get nginx versions from both containers
# ============================================================================
log_test 7 "Compare nginx versions"

version_old=$(run_in_container "$CONTAINER_OLD" nginx -v 2>&1 | cut -d'/' -f2 | tr -d '\r\n')
version_new=$(run_in_container "$CONTAINER_NEW" nginx -v 2>&1 | cut -d'/' -f2 | tr -d '\r\n')

log_info "OLD container (nixos-23.05): nginx version $version_old"
log_info "NEW container (nixos-24.11): nginx version $version_new"

if [ "$version_old" != "$version_new" ]; then
  log_success "Versions are different - package override working!"
else
  log_error "Versions are the same - something went wrong"
fi

# ============================================================================
# Test 8: Test web server responses
# ============================================================================
log_test 8 "Test web server responses"

IP_OLD=$(sudo nixos-container show-ip "$CONTAINER_OLD")
IP_NEW=$(sudo nixos-container show-ip "$CONTAINER_NEW")

log_info "OLD container IP: $IP_OLD"
log_info "NEW container IP: $IP_NEW"

# Test OLD container
if curl -s "http://$IP_OLD" | grep -q "Welcome to nginx"; then
  log_success "OLD container web server responding"
else
  log_error "OLD container web server not responding"
fi

# Test NEW container
if curl -s "http://$IP_NEW" | grep -q "Welcome to nginx"; then
  log_success "NEW container web server responding"
else
  log_error "NEW container web server not responding"
fi

# ============================================================================
# Test 9: Verify version displayed in web pages
# ============================================================================
log_test 9 "Verify nginx versions displayed in web pages"

page_old=$(curl -s "http://$IP_OLD")
page_new=$(curl -s "http://$IP_NEW")

if echo "$page_old" | grep -q "$version_old"; then
  log_success "OLD container page shows correct version: $version_old"
else
  log_error "OLD container page doesn't show version correctly"
fi

if echo "$page_new" | grep -q "$version_new"; then
  log_success "NEW container page shows correct version: $version_new"
else
  log_error "NEW container page doesn't show version correctly"
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
  echo "Package version override validated:"
  echo "  ✓ OLD container using nixos-23.05: nginx $version_old"
  echo "  ✓ NEW container using nixos-24.11: nginx $version_new"
  echo "  ✓ Both containers created instantly (no compilation!)"
  echo "  ✓ Both web servers serving pages correctly"
  echo ""
  echo "To interact:"
  echo "  OLD: curl http://$IP_OLD"
  echo "  NEW: curl http://$IP_NEW"
  echo "  Login: sudo nixos-container root-login $CONTAINER_OLD"
  exit 0
else
  echo -e "${RED}❌ Some tests failed${NC}"
  exit 1
fi
