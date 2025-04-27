#!/bin/bash

# Installation script for Docker and NVIDIA Container Toolkit
# For use with OpenWebUI deployment

set -e

USER=${REMOTE_USER:-$USER}
USER=${USER:-$(whoami)}

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

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root"
    print_info "Try running with sudo: sudo $0"
    exit 1
fi

# Check if Docker is already installed
check_docker() {
    if command -v docker &> /dev/null; then
        print_info "Docker is already installed"
        docker_version=$(docker --version)
        print_info "Version: $docker_version"
        return 0
    else
        return 1
    fi
}

# Check if Docker Compose is already installed
check_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        print_info "Docker Compose is already installed"
        compose_version=$(docker-compose --version)
        print_info "Version: $compose_version"
        return 0
    else
        return 1
    fi
}

# Check if NVIDIA drivers are installed
check_nvidia_drivers() {
    if command -v nvidia-smi &> /dev/null; then
        print_info "NVIDIA drivers are installed"
        nvidia_smi_output=$(nvidia-smi --query-gpu=name,driver_version --format=csv,noheader)
        print_info "GPU: $nvidia_smi_output"
        return 0
    else
        print_warning "NVIDIA drivers are not installed"
        return 1
    fi
}

# Check if NVIDIA Container Toolkit is installed
check_nvidia_container_toolkit() {
    if dpkg -l | grep -q nvidia-container-toolkit; then
        print_info "NVIDIA Container Toolkit is already installed"
        return 0
    else
        return 1
    fi
}

# Install Docker
install_docker() {
    print_info "Installing Docker..."
    
    curl -fsSL https://get.docker.com | sh
    sudo systemctl --now enable docker
    
    print_success "Docker installed successfully"
}

# Install Docker Compose
install_docker_compose() {
    print_info "Installing Docker Compose..."
    
    # Docker Compose is now included as a docker plugin in newer Docker installations
    if command -v docker-compose &> /dev/null; then
        print_success "Docker Compose is already available"
    elif command -v docker compose &> /dev/null; then
        print_success "Docker Compose plugin is available"
    else
        print_warning "Docker Compose plugin not found, installing standalone version"
        
        # Install Docker Compose standalone
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
        curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        
        print_success "Docker Compose installed successfully"
    fi
}

# Install NVIDIA Container Toolkit
install_nvidia_container_toolkit() {
    print_info "Installing NVIDIA Container Toolkit..."
    
    # Install prerequisites
    apt install -y curl
    
    # Add NVIDIA Container Toolkit GPG key
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
      sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
      tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    # Experimental features are not enabled by default
    sed -i -e '/experimental/ s/^#//g' /etc/apt/sources.list.d/nvidia-container-toolkit.list
    
    apt update
    apt install -y nvidia-container-toolkit
    
    # Configure Docker to use NVIDIA Container Runtime
    nvidia-ctk runtime configure --runtime=docker
    
    # Restart Docker daemon
    systemctl restart docker
    
    print_success "NVIDIA Container Toolkit installed successfully"
}

# Add user to docker group
add_user_to_docker_group() {
    # Get the user who invoked sudo
    SUDO_USER=${SUDO_USER:-$USER}
    
    if [ "$SUDO_USER" = "root" ]; then
        print_warning "Running as root user, skipping user addition to docker group"
        return
    fi
    
    print_info "Adding user $SUDO_USER to docker group..."
    usermod -aG docker $SUDO_USER
    print_success "User $SUDO_USER added to docker group"
    print_info "You may need to log out and log back in for this to take effect"
}

# Verify Docker installation
verify_docker() {
    print_info "Verifying Docker installation..."
    
    # Run hello-world container
    if docker run --rm hello-world > /dev/null 2>&1; then
        print_success "Docker verification passed"
        return 0
    else
        print_error "Docker verification failed"
        return 1
    fi
}

# Verify NVIDIA Container Toolkit
verify_nvidia_container_toolkit() {
    print_info "Verifying NVIDIA Container Toolkit..."
    
    # Run NVIDIA Container Toolkit test
    if docker run --rm --gpus all nvidia/cuda:12.8.1-cudnn-runtime-ubuntu20.04 nvidia-smi > /dev/null 2>&1; then
        print_success "NVIDIA Container Toolkit verification passed"
        return 0
    else
        print_error "NVIDIA Container Toolkit verification failed"
        return 1
    fi
}

# Main installation process
main() {
    print_info "Starting installation of Docker and NVIDIA Container Toolkit..."
    
    # Check and install Docker if needed
    if ! check_docker; then
        install_docker
    fi
    
    # Check and install Docker Compose if needed
    if ! check_docker_compose; then
        install_docker_compose
    fi
    
    # Check NVIDIA drivers
    if ! check_nvidia_drivers; then
        print_warning "NVIDIA drivers are not installed. You need to install them manually before continuing."
        print_info "You can install NVIDIA drivers using: sudo apt install nvidia-driver-XXX"
        print_info "Where XXX is the driver version compatible with your GPU."
        read -p "Do you want to continue with the installation? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Installation aborted"
            exit 1
        fi
    fi
    
    # Check and install NVIDIA Container Toolkit if needed
    if ! check_nvidia_container_toolkit; then
        install_nvidia_container_toolkit
    fi
    
    # Add user to docker group
    add_user_to_docker_group
    
    # Verify installations
    verify_docker
    
    if check_nvidia_drivers; then
        verify_nvidia_container_toolkit
    else
        print_warning "Skipping NVIDIA Container Toolkit verification as drivers are not installed"
    fi
    
    print_success "Installation completed successfully"
}

# Run the main function
main
