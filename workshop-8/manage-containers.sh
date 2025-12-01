#!/usr/bin/env bash
# NixOS Container Management Script
# Provides easy CLI interface for creating, managing, and destroying containers
#
# Usage: Run with --help for detailed information
#   sudo ./manage-containers.sh --help

set -e  # Exit on any error

# ============================================================================
# CONFIGURATION
# ============================================================================

# Get the directory where this script is located (where flake.nix lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================================
# RANDOM NAME GENERATOR
# ============================================================================

# Generate a random container name using 4-digit hexadecimal
generate_container_name() {
    printf '%04x' $RANDOM
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Error: This script must be run as root (use sudo)"
        exit 1
    fi
}

# Check if container exists
container_exists() {
    local name=$1
    nixos-container list | grep -q "^${name}$"
}

# Get container IP address
get_container_ip() {
    local name=$1
    nixos-container run "$name" -- ip -4 addr show eth0 2>/dev/null | grep inet | awk '{print $2}' | cut -d'/' -f1 || echo "No IP assigned"
}

# Get container status
get_container_status() {
    local name=$1
    nixos-container status "$name" 2>/dev/null || echo "unknown"
}

# ============================================================================
# COMMAND: CREATE CONTAINER
# ============================================================================

cmd_create() {
    local num_containers=1
    local container_name=""

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n)
                num_containers="$2"
                shift 2
                ;;
            -*)
                echo "Error: Unknown option: $1"
                exit 1
                ;;
            *)
                container_name="$1"
                shift
                ;;
        esac
    done

    # If -n option is used, create multiple containers with random names
    if [ "$num_containers" -gt 1 ]; then
        if [ -n "$container_name" ]; then
            echo "Error: Cannot specify both -n option and container name"
            exit 1
        fi

        echo "Creating $num_containers containers with random names..."
        echo

        for i in $(seq 1 "$num_containers"); do
            local random_name=$(generate_container_name)
            echo "[$i/$num_containers] Creating container: $random_name"
            cmd_create_single "$random_name"
            echo
        done

        echo "================================"
        echo "All $num_containers containers created successfully!"
        echo "================================"
        return
    fi

    # Single container creation
    cmd_create_single "$container_name"
}

cmd_create_single() {
    local container_name="$1"

    # If no name provided, generate one automatically
    if [ -z "$container_name" ]; then
        container_name=$(generate_container_name)
        echo "No name provided - auto-generating random name: $container_name"
    fi

    echo "================================"
    echo "Creating NixOS Container"
    echo "================================"
    echo "Container Name: $container_name"
    echo "Flake Path:     $SCRIPT_DIR"
    echo "================================"
    echo

    # Step 1: Create temporary configuration file
    echo "[1/3] Generating container configuration..."

    local temp_config=$(mktemp --suffix=.nix)
    cat > "$temp_config" << EOF
{ config, pkgs, lib, ... }:
{
  imports = [ $SCRIPT_DIR/configuration.nix ];

  _module.args.containerConfig = {
    hostname = "$container_name";
  };

  boot.isContainer = true;
  systemd.network.enable = true;
}
EOF

    # Step 2: Create container using nixos-container command
    # CRITICAL: --bridge br-containers connects the container to our bridge network
    # Without this flag, the container gets isolated networking and cannot:
    #   - Reach other containers
    #   - Reach the DHCP server (dnsmasq)
    #   - Get an IP from our DHCP range (10.233.0.50-150)
    echo "[2/3] Creating container from configuration..."
    nixos-container create "$container_name" --config-file "$temp_config" --bridge br-containers

    rm -f "$temp_config"

    echo "✓ Container created"
    echo

    # Step 3: Start the container
    echo "[3/3] Starting container..."
    nixos-container start "$container_name"

    echo "✓ Container started"
    echo

    # Wait a moment for DHCP to assign IP
    echo "Waiting for DHCP to assign IP address..."
    sleep 2

    # Display final status
    echo "================================"
    echo "Container Setup Complete!"
    echo "================================"
    echo
    echo "Container: $container_name"
    echo "Status:    $(get_container_status "$container_name")"
    echo "IP Address: $(get_container_ip "$container_name")"
    echo
    echo "Quick Commands:"
    echo "  Access shell:      sudo nixos-container root-login $container_name"
    echo "  Check IP:          sudo ./manage-containers.sh ip $container_name"
    echo "  Stop container:    sudo ./manage-containers.sh stop $container_name"
    echo "  Destroy container: sudo ./manage-containers.sh destroy $container_name"
    echo
    echo "Test connectivity from inside container:"
    echo "  sudo nixos-container root-login $container_name"
    echo "  Then run: ping -c 4 10.233.0.1    # Ping host"
    echo "  Then run: ping -c 4 8.8.8.8       # Ping internet"
    echo
}

# ============================================================================
# COMMAND: START CONTAINER
# ============================================================================

cmd_start() {
    local name=$1

    # If no name provided, start all containers
    if [ -z "$name" ]; then
        echo "No container name provided - starting ALL containers..."
        echo

        local containers=$(nixos-container list)
        if [ -z "$containers" ]; then
            echo "No containers found"
            return
        fi

        for container in $containers; do
            local status=$(get_container_status "$container")
            if [ "$status" = "up" ]; then
                echo "✓ $container - already running"
            else
                echo "Starting: $container"
                nixos-container start "$container"
                echo "✓ $container - started"
            fi
        done

        echo
        echo "All containers started"
        return
    fi

    # Single container start
    if ! container_exists "$name"; then
        echo "Error: Container '$name' does not exist"
        echo "Use 'list' command to see existing containers"
        exit 1
    fi

    echo "Starting container: $name"
    nixos-container start "$name"
    echo "✓ Container started"
    echo "Status: $(get_container_status "$name")"
}

# ============================================================================
# COMMAND: STOP CONTAINER
# ============================================================================

cmd_stop() {
    local name=$1

    # If no name provided, stop all containers
    if [ -z "$name" ]; then
        echo "No container name provided - stopping ALL containers..."
        echo

        local containers=$(nixos-container list)
        if [ -z "$containers" ]; then
            echo "No containers found"
            return
        fi

        for container in $containers; do
            local status=$(get_container_status "$container")
            if [ "$status" = "up" ]; then
                echo "Stopping: $container"
                nixos-container stop "$container"
                echo "✓ $container - stopped"
            else
                echo "✓ $container - already stopped"
            fi
        done

        echo
        echo "All containers stopped"
        return
    fi

    # Single container stop
    if ! container_exists "$name"; then
        echo "Error: Container '$name' does not exist"
        exit 1
    fi

    echo "Stopping container: $name"
    nixos-container stop "$name"
    echo "✓ Container stopped"
}

# ============================================================================
# COMMAND: DESTROY CONTAINER
# ============================================================================

cmd_destroy() {
    local name=$1

    # If no name provided, destroy all containers
    if [ -z "$name" ]; then
        echo "WARNING: This will permanently delete ALL containers and their data"
        read -p "Are you sure? (yes/no): " confirm

        if [ "$confirm" != "yes" ]; then
            echo "Cancelled"
            exit 0
        fi

        echo "Destroying ALL containers..."
        echo

        local containers=$(nixos-container list)
        if [ -z "$containers" ]; then
            echo "No containers found"
            return
        fi

        for container in $containers; do
            echo "Destroying: $container"
            nixos-container destroy "$container"
            echo "✓ $container - destroyed"
        done

        echo
        echo "All containers destroyed"
        return
    fi

    # Single container destroy
    if ! container_exists "$name"; then
        echo "Error: Container '$name' does not exist"
        exit 1
    fi

    echo "WARNING: This will permanently delete container '$name' and all its data"
    read -p "Are you sure? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        echo "Cancelled"
        exit 0
    fi

    echo "Destroying container: $name"
    nixos-container destroy "$name"
    echo "✓ Container destroyed"
}

# ============================================================================
# COMMAND: LIST CONTAINERS
# ============================================================================

cmd_list() {
    echo "================================"
    echo "NixOS Containers"
    echo "================================"
    echo

    local containers=$(nixos-container list)

    if [ -z "$containers" ]; then
        echo "No containers found"
        echo
        echo "Create one with: sudo ./manage-containers.sh create [name]"
        return
    fi

    printf "%-20s %-12s %-18s %s\n" "Name" "Status" "IP Address" "Created"
    printf "%-20s %-12s %-18s %s\n" "----" "------" "----------" "-------"

    for container in $containers; do
        local status=$(get_container_status "$container")
        local ip=$(get_container_ip "$container")

        # Get creation date from container directory
        local container_dir="/var/lib/nixos-containers/$container"
        if [ -d "$container_dir" ]; then
            # Use stat to get creation time (birth time on macOS, change time on Linux)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS
                local created=$(stat -f "%SB" -t "%Y-%m-%d %H:%M" "$container_dir" 2>/dev/null || echo "Unknown")
            else
                # Linux
                local created=$(stat -c "%w" "$container_dir" 2>/dev/null)
                if [ "$created" = "-" ] || [ -z "$created" ]; then
                    # Birth time not available, use modification time
                    created=$(stat -c "%y" "$container_dir" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1 || echo "Unknown")
                else
                    created=$(echo "$created" | cut -d' ' -f1,2 | cut -d'.' -f1)
                fi
            fi
        else
            local created="Unknown"
        fi

        printf "%-20s %-12s %-18s %s\n" "$container" "$status" "$ip" "$created"
    done

    echo
    echo "Total containers: $(echo "$containers" | wc -l)"
}

# ============================================================================
# COMMAND: SHOW IP ADDRESS
# ============================================================================

cmd_ip() {
    local name=$1

    if [ -z "$name" ]; then
        echo "Error: Container name required"
        echo "Usage: $0 ip <container-name>"
        exit 1
    fi

    if ! container_exists "$name"; then
        echo "Error: Container '$name' does not exist"
        exit 1
    fi

    local ip=$(get_container_ip "$name")
    echo "Container: $name"
    echo "IP Address: $ip"

    if [ "$ip" = "No IP assigned" ]; then
        echo
        echo "Container may not be running or DHCP hasn't assigned an IP yet"
        echo "Try: sudo nixos-container start $name"
    fi
}

# ============================================================================
# COMMAND: SHELL ACCESS
# ============================================================================

cmd_shell() {
    local name=$1

    if [ -z "$name" ]; then
        echo "Error: Container name required"
        echo "Usage: $0 shell <container-name>"
        exit 1
    fi

    if ! container_exists "$name"; then
        echo "Error: Container '$name' does not exist"
        exit 1
    fi

    local status=$(get_container_status "$name")
    if [ "$status" != "up" ]; then
        echo "Warning: Container is not running (status: $status)"
        echo "Starting container..."
        nixos-container start "$name"
        sleep 1
    fi

    echo "Opening root shell in container: $name"
    echo "(Type 'exit' to return to host)"
    echo
    nixos-container root-login "$name"
}

# ============================================================================
# MAIN COMMAND DISPATCHER
# ============================================================================

# Display help if no arguments or --help
if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    cat << EOF
NixOS Container Management Script
==================================

A convenient wrapper for managing NixOS containers with dynamic CLI tools.
Create, manage, and destroy containers on-the-fly without editing host configs.

USAGE:
  sudo $0 COMMAND [OPTIONS] [ARGUMENTS]

COMMANDS:
  create [name]           Create and start a new container
                          - If no name provided, auto-generates a random name
                          - Options:
                            -n <count>  Create multiple containers with random names

  start [name]            Start container(s)
                          - With name: Start specific container
                          - Without name: Start ALL containers

  stop [name]             Stop container(s)
                          - With name: Stop specific container
                          - Without name: Stop ALL containers

  destroy [name]          Permanently delete container(s)
                          - With name: Delete specific container
                          - Without name: Delete ALL containers (with confirmation)

  list                    Show all containers with status, IP, and creation date

  ip <name>               Show IP address of a specific container

  shell <name>            Open root shell in container

EXAMPLES:
  # Create containers
  sudo $0 create                    # Auto-generated name (e.g., "a3f2")
  sudo $0 create mycont             # Named "mycont"
  sudo $0 create -n 5               # Create 5 containers with random names

  # List and inspect
  sudo $0 list                      # Show all containers
  sudo $0 ip mycont                 # Get IP of "mycont"

  # Access containers
  sudo $0 shell mycont              # Open shell in "mycont"

  # Lifecycle management
  sudo $0 start mycont              # Start specific container
  sudo $0 start                     # Start ALL containers
  sudo $0 stop mycont               # Stop specific container
  sudo $0 stop                      # Stop ALL containers
  sudo $0 destroy mycont            # Delete specific container
  sudo $0 destroy                   # Delete ALL containers (with confirmation)

NETWORKING:
  All containers share a private network:
  - Network: 10.233.0.0/24
  - Host bridge IP: 10.233.0.1
  - Container IPs: 10.233.0.50-150 (assigned via DHCP)
  - Containers can ping each other, the host, and the internet

CONTAINER NAMING:
  If you don't specify a name, the script generates random 4-digit hexadecimal
  names (e.g., "a3f2", "7d91", "2b4c")

USER ACCOUNTS:
  Each container has two pre-configured users:
  - root (password: "nixos")
  - operator (password: "operator", has sudo access)

ACCESS:
  You can access containers via:
  - Direct shell: sudo $0 shell <name>
  - SSH: ssh root@<container-ip>
  - nixos-container: sudo nixos-container root-login <name>

EOF
    exit 0
fi

# Check root privileges
check_root

# Dispatch to appropriate command
COMMAND=$1
shift  # Remove command from arguments

case "$COMMAND" in
    create)
        cmd_create "$@"
        ;;
    start)
        cmd_start "$@"
        ;;
    stop)
        cmd_stop "$@"
        ;;
    destroy)
        cmd_destroy "$@"
        ;;
    list)
        cmd_list "$@"
        ;;
    ip)
        cmd_ip "$@"
        ;;
    shell)
        cmd_shell "$@"
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'"
        echo "Run '$0' without arguments to see usage"
        exit 1
        ;;
esac
