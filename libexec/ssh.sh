#!/bin/bash

# SSH script for OpenWebUI deployment
# Opens an SSH session to the remote server

# Source the common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# SSH command
ssh_connect() {
    check_required_vars
    
    local command="$1"
    
    print_info "Connecting to $REMOTE_USER@$REMOTE_HOST..."
    
    if [ -n "$command" ]; then
        # Execute specific command
        run_remote_interactive "$command"
    else
        # Open interactive session
        ssh -t -p ${SSH_PORT:-22} "$REMOTE_USER@$REMOTE_HOST"
    fi
}

# Execute SSH command with provided argument
ssh_connect "$1"