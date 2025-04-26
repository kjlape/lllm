#!/bin/bash

# Logs script for OpenWebUI deployment
# Shows logs from containers on the remote server

# Source the common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Default number of lines to show
DEFAULT_LINES=100

# Logs command
logs() {
    check_required_vars
    
    local service="$1"
    local lines="${2:-$DEFAULT_LINES}"
    local follow="$3"
    
    print_info "Showing logs from containers on $REMOTE_USER@$REMOTE_HOST..."
    
    # Check if compose directory exists
    if ! run_remote "[ -d $DEPLOY_DIR/compose ]"; then
        print_error "Compose directory not found on remote server"
        print_info "It appears the application has not been deployed yet."
        exit 1
    fi
    
    # Show logs
    if [ -n "$service" ]; then
        print_info "Showing logs for service: $service"
        
        if [ "$follow" = "follow" ]; then
            run_remote_interactive "cd $DEPLOY_DIR/compose && docker compose logs --tail=$lines -f $service"
        else
            run_remote "cd $DEPLOY_DIR/compose && docker compose logs --tail=$lines $service"
        fi
    else
        print_info "Showing logs for all services"
        
        if [ "$follow" = "follow" ]; then
            run_remote_interactive "cd $DEPLOY_DIR/compose && docker compose logs --tail=$lines -f"
        else
            run_remote "cd $DEPLOY_DIR/compose && docker compose logs --tail=$lines"
        fi
    fi
}

# Execute logs command with provided arguments
logs "$1" "$2" "$3"