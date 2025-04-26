#!/bin/bash

# Status script for OpenWebUI deployment
# Shows the status of containers on the remote server

# Source the common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Status command
status() {
    check_required_vars
    
    print_info "Checking status of containers on $REMOTE_USER@$REMOTE_HOST..."
    
    # Check if compose directory exists
    if ! run_remote "[ -d $DEPLOY_DIR/compose ]"; then
        print_error "Compose directory not found on remote server"
        print_info "It appears the application has not been deployed yet."
        exit 1
    fi
    
    # Show container status
    print_info "Container status:"
    run_remote "cd $DEPLOY_DIR/compose && docker compose ps"
    
    # Show container resources
    print_info "Container resources:"
    run_remote "docker stats --no-stream"
    
    # If nvidia-smi is available, show GPU status
    if run_remote "command -v nvidia-smi > /dev/null"; then
        print_info "GPU status:"
        run_remote "nvidia-smi"
    fi
}

# Execute status command
status