#!/bin/bash

# Setup script for OpenWebUI deployment
# Handles initial configuration and server preparation

# Source the common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Setup command
setup() {
    print_info "Setting up deployment configuration..."
    
    # Interactive configuration if file doesn't exist
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Creating new configuration file..."
        
        # Get configuration from user
        read -p "Remote hostname or IP: " input_host
        read -p "Remote SSH user: " input_user
        read -p "SSH port [22]: " input_port
        input_port=${input_port:-22}
        read -p "Deployment directory on remote server: " input_dir
        
        # Create configuration file
        cat > "$CONFIG_FILE" << EOL
# OpenWebUI Deployment Configuration
REMOTE_HOST="$input_host"
REMOTE_USER="$input_user"
SSH_PORT="$input_port"
DEPLOY_DIR="$input_dir"
EOL
        
        print_success "Configuration saved to $CONFIG_FILE"
    else
        print_info "Configuration file already exists. Edit $CONFIG_FILE to change settings."
    fi
    
    # Load the configuration
    source "$CONFIG_FILE"
    
    # Test SSH connection
    print_info "Testing SSH connection to $REMOTE_USER@$REMOTE_HOST..."
    if ssh -p ${SSH_PORT:-22} -o ConnectTimeout=5 -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" echo "SSH connection successful" 2>/dev/null; then
        print_success "SSH connection successful!"
    else
        print_error "Failed to connect to $REMOTE_USER@$REMOTE_HOST"
        print_info "Ensure you have SSH access to the server and that your SSH key is properly configured."
        exit 1
    fi
    
    # Prepare remote server
    prepare_server
}

# Function to prepare the remote server
prepare_server() {
    print_info "Preparing remote server..."
    
    # Create remote deployment directory
    print_info "Creating deployment directory on remote server..."
    ssh -p ${SSH_PORT:-22} "$REMOTE_USER@$REMOTE_HOST" "sudo mkdir -p $DEPLOY_DIR"
    
    # Copy installation script to remote server
    print_info "Copying installation script to remote server..."
    
    # Make script executable
    chmod +x "$SCRIPT_DIR/install_docker_nvidia.sh"
    
    # Copy script to remote server
    scp -P ${SSH_PORT:-22} "$SCRIPT_DIR/install_docker_nvidia.sh" "$REMOTE_USER@$REMOTE_HOST:$DEPLOY_DIR/"
    
    # Execute installation script on remote server
    print_info "Installing Docker and NVIDIA Container Toolkit on remote server..."
    print_info "This may take a while..."
    print_warning "You may be prompted for the sudo password on the remote server."
    
    # Execute the script
    ssh -t -p ${SSH_PORT:-22} "$REMOTE_USER@$REMOTE_HOST" "cd $DEPLOY_DIR && sudo ./install_docker_nvidia.sh"
    
    print_success "Remote server prepared successfully!"
}

# Execute setup process
setup
