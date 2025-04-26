#!/bin/bash

# Utility functions and common variables for OpenWebUI deployment

# Determine the repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$REPO_ROOT/.deploy.env"

# Default SSH port
DEFAULT_SSH_PORT=22

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

# Utility functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Load configuration if exists
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        return 0
    else
        return 1
    fi
}

# Check required variables
check_required_vars() {
    # Load configuration
    load_config
    
    if [ -z "$REMOTE_HOST" ]; then
        print_error "REMOTE_HOST is not set. Please set it in $CONFIG_FILE or use the setup command."
        exit 1
    fi
    
    if [ -z "$REMOTE_USER" ]; then
        print_error "REMOTE_USER is not set. Please set it in $CONFIG_FILE or use the setup command."
        exit 1
    fi
    
    if [ -z "$DEPLOY_DIR" ]; then
        print_error "DEPLOY_DIR is not set. Please set it in $CONFIG_FILE or use the setup command."
        exit 1
    fi
}

# Test SSH connection
test_ssh_connection() {
    check_required_vars
    
    print_info "Testing SSH connection to $REMOTE_USER@$REMOTE_HOST..."
    if ssh -p ${SSH_PORT:-22} -o ConnectTimeout=5 -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" echo "SSH connection successful" 2>/dev/null; then
        print_success "SSH connection successful!"
        return 0
    else
        print_error "Failed to connect to $REMOTE_USER@$REMOTE_HOST"
        print_info "Ensure you have SSH access to the server and that your SSH key is properly configured."
        return 1
    fi
}

# Run command on remote server
run_remote() {
    check_required_vars
    
    local command="$1"
    
    ssh -p ${SSH_PORT:-22} "$REMOTE_USER@$REMOTE_HOST" "$command"
    return $?
}

# Run interactive command on remote server
run_remote_interactive() {
    check_required_vars
    
    local command="$1"
    
    ssh -t -p ${SSH_PORT:-22} "$REMOTE_USER@$REMOTE_HOST" "$command"
    return $?
}

# Copy file to remote server
copy_to_remote() {
    check_required_vars
    
    local src="$1"
    local dest="$2"
    
    scp -P ${SSH_PORT:-22} "$src" "$REMOTE_USER@$REMOTE_HOST:$dest"
    return $?
}

# Copy directory to remote server recursively
copy_dir_to_remote() {
    check_required_vars
    
    local src="$1"
    local dest="$2"
    
    scp -P ${SSH_PORT:-22} -r "$src" "$REMOTE_USER@$REMOTE_HOST:$dest"
    return $?
}

# Try to load configuration, but don't exit if the file doesn't exist yet
if [ -f "$CONFIG_FILE" ]; then
    load_config
fi