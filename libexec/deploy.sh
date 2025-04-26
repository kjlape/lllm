#!/bin/bash

# Deployment script for OpenWebUI
# Handles Docker Compose deployment to remote server

# Source the common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Deploy command
deploy() {
    check_required_vars
    
    print_info "Deploying OpenWebUI to $REMOTE_USER@$REMOTE_HOST:$DEPLOY_DIR..."
    
    # Check if compose directory exists locally
    if [ ! -d "$REPO_ROOT/compose" ]; then
        print_error "Compose directory not found at $REPO_ROOT/compose"
        print_info "Please create the Docker Compose configuration first."
        exit 1
    fi
    
    # Create compose directory on remote server
    print_info "Creating compose directory on remote server..."
    ssh -p ${SSH_PORT:-22} "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $DEPLOY_DIR/compose"
    
    # Copy compose files to remote server
    print_info "Copying Docker Compose configuration to remote server..."
    scp -P ${SSH_PORT:-22} -r "$REPO_ROOT/compose/"* "$REMOTE_USER@$REMOTE_HOST:$DEPLOY_DIR/compose/"
    
    # Deploy with Docker Compose
    print_info "Deploying containers with Docker Compose..."
    ssh -t -p ${SSH_PORT:-22} "$REMOTE_USER@$REMOTE_HOST" "cd $DEPLOY_DIR/compose && docker compose up -d"
    
    # Check deployment status
    print_info "Checking deployment status..."
    ssh -p ${SSH_PORT:-22} "$REMOTE_USER@$REMOTE_HOST" "cd $DEPLOY_DIR/compose && docker compose ps"
    
    print_success "Deployment completed successfully!"
    print_info "OpenWebUI should now be accessible at http://$REMOTE_HOST:${OPENWEBUI_PORT:-3000}"
}

# Function to handle container rollback
rollback() {
    check_required_vars
    
    print_info "Rolling back to previous version..."
    
    # Check if there's a previous deployment
    if ssh -p ${SSH_PORT:-22} "$REMOTE_USER@$REMOTE_HOST" "[ -d $DEPLOY_DIR/compose.bak ]"; then
        # Stop current containers
        print_info "Stopping current containers..."
        ssh -p ${SSH_PORT:-22} "$REMOTE_USER@$REMOTE_HOST" "cd $DEPLOY_DIR/compose && docker compose down"
        
        # Restore backup
        print_info "Restoring backup..."
        ssh -p ${SSH_PORT:-22} "$REMOTE_USER@$REMOTE_HOST" "rm -rf $DEPLOY_DIR/compose.tmp && \
            mv $DEPLOY_DIR/compose $DEPLOY_DIR/compose.tmp && \
            mv $DEPLOY_DIR/compose.bak $DEPLOY_DIR/compose && \
            mv $DEPLOY_DIR/compose.tmp $DEPLOY_DIR/compose.bak"
        
        # Start containers from backup
        print_info "Starting containers from backup..."
        ssh -p ${SSH_PORT:-22} "$REMOTE_USER@$REMOTE_HOST" "cd $DEPLOY_DIR/compose && docker compose up -d"
        
        print_success "Rollback completed successfully!"
    else
        print_error "No backup found for rollback"
        exit 1
    fi
}

# Check if we're rolling back or deploying
if [ "$1" == "rollback" ]; then
    rollback
else
    # Create backup of current deployment if it exists
    check_required_vars
    if ssh -p ${SSH_PORT:-22} "$REMOTE_USER@$REMOTE_HOST" "[ -d $DEPLOY_DIR/compose ]"; then
        print_info "Creating backup of current deployment..."
        ssh -p ${SSH_PORT:-22} "$REMOTE_USER@$REMOTE_HOST" "rm -rf $DEPLOY_DIR/compose.bak && \
            cp -a $DEPLOY_DIR/compose $DEPLOY_DIR/compose.bak"
    fi
    
    # Proceed with deployment
    deploy
fi