#!/bin/bash

#########################################################
# Docker and NVIDIA Container Toolkit Installation Script
# For OpenWebUI Deployment
#
# This script installs and configures:
# - Docker
# - Docker Compose
# - NVIDIA Container Toolkit
#
# It performs proper verification at each step and
# includes GPU passthrough testing.
#########################################################

set -e

# Script version
SCRIPT_VERSION="1.0.0"

# Default options
VERBOSE=false
FORCE_REINSTALL=false
SKIP_TESTS=false
LOG_FILE="/tmp/docker_nvidia_install.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

# File for capturing output
exec > >(tee -a ${LOG_FILE}) 2>&1

# Detect OS information
OS_NAME=$(. /etc/os-release && echo "$ID")
OS_VERSION=$(. /etc/os-release && echo "$VERSION_ID")
OS_CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")

# Utility functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    if [ "$VERBOSE" = true ]; then
        echo -e "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: $1" >> "$LOG_FILE"
    fi
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    if [ "$VERBOSE" = true ]; then
        echo -e "[$(date +"%Y-%m-%d %H:%M:%S")] SUCCESS: $1" >> "$LOG_FILE"
    fi
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    if [ "$VERBOSE" = true ]; then
        echo -e "[$(date +"%Y-%m-%d %H:%M:%S")] WARNING: $1" >> "$LOG_FILE"
    fi
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo -e "[$(date +"%Y-%m-%d %H:%M:%S")] ERROR: $1" >> "$LOG_FILE"
}

log_cmd() {
    if [ "$VERBOSE" = true ]; then
        echo -e "\n[$(date +"%Y-%m-%d %H:%M:%S")] Executing: $*" >> "$LOG_FILE"
        eval "$*" 2>&1 | tee -a "$LOG_FILE"
        return ${PIPESTATUS[0]}
    else
        eval "$*" >> "$LOG_FILE" 2>&1
        return $?
    fi
}

print_horizontal_line() {
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' '-'
}

print_header() {
    print_horizontal_line
    echo -e "${GREEN}$1${NC}"
    print_horizontal_line
}

# Usage information
usage() {
    echo "Docker and NVIDIA Container Toolkit Installation Script"
    echo "Version: $SCRIPT_VERSION"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -f, --force       Force reinstallation even if components are detected"
    echo "  -v, --verbose     Enable verbose output"
    echo "  -s, --skip-tests  Skip final verification tests"
    echo "  -h, --help        Display this help message"
    echo ""
    echo "Example:"
    echo "  $0 --verbose"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force)
                FORCE_REINSTALL=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -s|--skip-tests)
                SKIP_TESTS=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root"
        print_info "Try running with sudo: sudo $0"
        exit 1
    fi
}

# Check OS compatibility
check_os_compatibility() {
    print_info "Checking OS compatibility..."
    
    if [ "$OS_NAME" != "ubuntu" ]; then
        print_error "This script is designed for Ubuntu, but detected: $OS_NAME"
        print_info "The script may not work correctly on this system."
        read -p "Do you want to continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Installation aborted"
            exit 1
        fi
    else
        print_success "Ubuntu detected: version $OS_VERSION ($OS_CODENAME)"
    fi
    
    # Check if systemd is available
    if ! command -v systemctl &> /dev/null; then
        print_error "Systemd is required but not detected"
        exit 1
    fi
}

# Check hardware compatibility for NVIDIA
check_nvidia_hardware() {
    print_info "Checking for NVIDIA hardware..."
    
    if lspci | grep -i nvidia &> /dev/null; then
        NVIDIA_GPU=$(lspci | grep -i nvidia | head -n 1)
        print_success "NVIDIA GPU detected: $NVIDIA_GPU"
    else
        print_warning "No NVIDIA GPU detected in this system"
        print_info "The NVIDIA Container Toolkit will still be installed, but GPU passthrough will not work."
        read -p "Do you want to continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Installation aborted"
            exit 1
        fi
    fi
}

# Check if Docker is already installed
check_docker() {
    print_info "Checking if Docker is already installed..."
    
    if command -v docker &> /dev/null && [ "$FORCE_REINSTALL" = false ]; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}' | tr -d ',')
        print_success "Docker is already installed (version $DOCKER_VERSION)"
        
        # Check if Docker service is running
        if systemctl is-active --quiet docker; then
            print_success "Docker service is running"
            DOCKER_NEEDS_INSTALL=false
        else
            print_warning "Docker is installed but the service is not running"
            if systemctl start docker; then
                print_success "Docker service started successfully"
                DOCKER_NEEDS_INSTALL=false
            else
                print_error "Failed to start Docker service"
                print_info "Will attempt to reinstall Docker"
                DOCKER_NEEDS_INSTALL=true
            fi
        fi
    else
        if [ "$FORCE_REINSTALL" = true ]; then
            print_info "Force reinstall flag set, will reinstall Docker"
        else
            print_info "Docker not found, will install it"
        fi
        DOCKER_NEEDS_INSTALL=true
    fi
}

# Check if Docker Compose is already installed
check_docker_compose() {
    print_info "Checking if Docker Compose is already installed..."
    
    # Check for docker-compose standalone
    if command -v docker-compose &> /dev/null && [ "$FORCE_REINSTALL" = false ]; then
        COMPOSE_VERSION=$(docker-compose --version | awk '{print $3}')
        print_success "Docker Compose (standalone) is already installed (version $COMPOSE_VERSION)"
        COMPOSE_NEEDS_INSTALL=false
        return
    fi
    
    # Check for docker compose plugin
    if docker compose version &> /dev/null && [ "$FORCE_REINSTALL" = false ]; then
        COMPOSE_VERSION=$(docker compose version --short)
        print_success "Docker Compose (plugin) is already installed (version $COMPOSE_VERSION)"
        COMPOSE_NEEDS_INSTALL=false
        return
    fi
    
    if [ "$FORCE_REINSTALL" = true ]; then
        print_info "Force reinstall flag set, will reinstall Docker Compose"
    else
        print_info "Docker Compose not found, will install it"
    fi
    COMPOSE_NEEDS_INSTALL=true
}

# Check if NVIDIA drivers are installed
check_nvidia_drivers() {
    print_info "Checking if NVIDIA drivers are installed..."
    
    if command -v nvidia-smi &> /dev/null; then
        NVIDIA_DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null)
        if [ -n "$NVIDIA_DRIVER_VERSION" ]; then
            print_success "NVIDIA drivers are installed (version $NVIDIA_DRIVER_VERSION)"
            
            # Get GPU information
            GPU_INFO=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null)
            print_info "GPU detected: $GPU_INFO"
            
            NVIDIA_DRIVERS_INSTALLED=true
        else
            print_warning "NVIDIA drivers appear to be installed but not functioning properly"
            NVIDIA_DRIVERS_INSTALLED=false
        fi
    else
        print_warning "NVIDIA drivers are not installed"
        NVIDIA_DRIVERS_INSTALLED=false
    fi
}

# Check if NVIDIA Container Toolkit is installed
check_nvidia_container_toolkit() {
    print_info "Checking if NVIDIA Container Toolkit is already installed..."
    
    if dpkg -l | grep -q nvidia-container-toolkit && [ "$FORCE_REINSTALL" = false ]; then
        TOOLKIT_VERSION=$(dpkg -l | grep nvidia-container-toolkit | awk '{print $3}')
        print_success "NVIDIA Container Toolkit is already installed (version $TOOLKIT_VERSION)"
        
        # Check if Docker is configured for NVIDIA runtime
        if grep -q "nvidia-container-runtime" /etc/docker/daemon.json 2>/dev/null; then
            print_success "Docker is configured for NVIDIA runtime"
            TOOLKIT_NEEDS_INSTALL=false
        else
            print_warning "NVIDIA Container Toolkit is installed but Docker is not configured properly"
            print_info "Will reconfigure NVIDIA Container Toolkit"
            TOOLKIT_NEEDS_INSTALL=true
        fi
    else
        if [ "$FORCE_REINSTALL" = true ]; then
            print_info "Force reinstall flag set, will reinstall NVIDIA Container Toolkit"
        else
            print_info "NVIDIA Container Toolkit not found, will install it"
        fi
        TOOLKIT_NEEDS_INSTALL=true
    fi
}

# Install prerequisites
install_prerequisites() {
    print_header "Installing Prerequisites"
    
    print_info "Updating package index..."
    log_cmd apt-get update -y || {
        print_error "Failed to update package index"
        exit 1
    }
    
    print_info "Installing required packages..."
    local PACKAGES="apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release"
    log_cmd apt-get install -y $PACKAGES || {
        print_error "Failed to install prerequisites"
        exit 1
    }
    
    print_success "Prerequisites installed successfully"
}

# Install Docker
install_docker() {
    if [ "$DOCKER_NEEDS_INSTALL" = true ]; then
        print_header "Installing Docker"
        
        # Remove old versions if they exist
        print_info "Removing old Docker versions if they exist..."
        log_cmd apt-get remove -y docker docker-engine docker.io containerd runc || true
        
        # Add Docker's official GPG key
        print_info "Adding Docker's official GPG key..."
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        if [ ! -f /usr/share/keyrings/docker-archive-keyring.gpg ]; then
            print_error "Failed to add Docker's GPG key"
            exit 1
        fi
        
        # Set up the stable repository
        print_info "Setting up Docker repository..."
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Update package index again with new repository
        print_info "Updating package index with Docker repository..."
        log_cmd apt-get update -y || {
            print_error "Failed to update package index after adding Docker repository"
            exit 1
        }
        
        # Install Docker Engine
        print_info "Installing Docker Engine..."
        log_cmd apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || {
            print_error "Failed to install Docker"
            exit 1
        }
        
        # Enable and start Docker service
        print_info "Enabling and starting Docker service..."
        log_cmd systemctl enable docker
        log_cmd systemctl start docker
        
        # Verify Docker installation
        print_info "Verifying Docker installation..."
        if docker --version > /dev/null 2>&1; then
            DOCKER_VERSION=$(docker --version | awk '{print $3}' | tr -d ',')
            print_success "Docker installed successfully (version $DOCKER_VERSION)"
        else
            print_error "Docker installation verification failed"
            exit 1
        fi
    else
        print_info "Skipping Docker installation as it's already installed and running"
    fi
}

# Add user to docker group
add_user_to_docker_group() {
    print_header "Configuring User Permissions"
    
    # Get the user who invoked sudo
    SUDO_USER=${SUDO_USER:-$USER}
    
    if [ "$SUDO_USER" = "root" ]; then
        print_warning "Running as root user, skipping user addition to docker group"
        return
    fi
    
    print_info "Adding user $SUDO_USER to docker group..."
    if groups "$SUDO_USER" | grep -q docker; then
        print_success "User $SUDO_USER is already in the docker group"
    else
        log_cmd usermod -aG docker "$SUDO_USER"
        print_success "User $SUDO_USER added to docker group"
        print_info "You may need to log out and log back in for this to take effect"
    fi
}

# Install Docker Compose
install_docker_compose() {
    if [ "$COMPOSE_NEEDS_INSTALL" = true ]; then
        print_header "Installing Docker Compose"
        
        # Docker Compose is now included as a docker plugin in newer Docker installations
        if command -v docker &> /dev/null && docker compose version &> /dev/null; then
            print_success "Docker Compose plugin is already available"
            COMPOSE_VERSION=$(docker compose version --short)
            print_info "Docker Compose plugin version: $COMPOSE_VERSION"
        else
            print_info "Installing Docker Compose standalone version..."
            
            # Get latest Docker Compose version
            COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
            if [ -z "$COMPOSE_VERSION" ]; then
                print_warning "Could not determine latest Docker Compose version, using default"
                COMPOSE_VERSION="v2.23.0"
            fi
            
            print_info "Installing Docker Compose version $COMPOSE_VERSION..."
            log_cmd curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || {
                print_error "Failed to download Docker Compose"
                exit 1
            }
            
            log_cmd chmod +x /usr/local/bin/docker-compose || {
                print_error "Failed to set permissions for Docker Compose"
                exit 1
            }
            
            # Create symlink for command completion
            log_cmd ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose 2>/dev/null || true
            
            # Verify Docker Compose installation
            if docker-compose --version > /dev/null 2>&1; then
                COMPOSE_VERSION=$(docker-compose --version | awk '{print $3}')
                print_success "Docker Compose installed successfully (version $COMPOSE_VERSION)"
            else
                print_error "Docker Compose installation verification failed"
                exit 1
            fi
        fi
    else
        print_info "Skipping Docker Compose installation as it's already installed"
    fi
}

# Install NVIDIA Container Toolkit
install_nvidia_container_toolkit() {
    if [ "$TOOLKIT_NEEDS_INSTALL" = true ]; then
        print_header "Installing NVIDIA Container Toolkit"
        
        # Warning if NVIDIA drivers are not installed
        if [ "$NVIDIA_DRIVERS_INSTALLED" = false ]; then
            print_warning "NVIDIA drivers are not installed. Container toolkit will be installed, but GPU passthrough will not work."
            print_info "You can install NVIDIA drivers using: sudo apt install nvidia-driver-XXX"
            print_info "Where XXX is the driver version compatible with your GPU."
            read -p "Do you want to continue with the installation? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_error "Installation aborted"
                exit 1
            fi
        fi
        
        # Check if NVIDIA Container Toolkit repository is already configured
        print_info "Setting up NVIDIA Container Toolkit repository..."
        
        # Install prerequisites
        log_cmd apt-get install -y curl
        
        # Add NVIDIA Container Toolkit GPG key
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg || {
            print_error "Failed to add NVIDIA Container Toolkit GPG key"
            exit 1
        }
        
        # Setup apt repository
        curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            tee /etc/apt/sources.list.d/nvidia-container-toolkit.list || {
            print_error "Failed to add NVIDIA Container Toolkit repository"
            exit 1
        }
        
        # Update package index
        print_info "Updating package index with NVIDIA repository..."
        log_cmd apt-get update -y || {
            print_error "Failed to update package index after adding NVIDIA repository"
            exit 1
        }
        
        # Install NVIDIA Container Toolkit
        print_info "Installing NVIDIA Container Toolkit..."
        log_cmd apt-get install -y nvidia-container-toolkit || {
            print_error "Failed to install NVIDIA Container Toolkit"
            exit 1
        }
        
        # Configure Docker to use NVIDIA Container Runtime
        print_info "Configuring Docker to use NVIDIA Container Runtime..."
        log_cmd nvidia-ctk runtime configure --runtime=docker || {
            print_error "Failed to configure Docker for NVIDIA Container Runtime"
            exit 1
        }
        
        # Restart Docker daemon
        print_info "Restarting Docker daemon..."
        log_cmd systemctl restart docker || {
            print_error "Failed to restart Docker daemon"
            exit 1
        }
        
        # Verify NVIDIA Container Toolkit installation
        if dpkg -l | grep -q nvidia-container-toolkit; then
            TOOLKIT_VERSION=$(dpkg -l | grep nvidia-container-toolkit | awk '{print $3}')
            print_success "NVIDIA Container Toolkit installed successfully (version $TOOLKIT_VERSION)"
        else
            print_error "NVIDIA Container Toolkit installation verification failed"
            exit 1
        fi
    else
        print_info "Skipping NVIDIA Container Toolkit installation as it's already installed and configured"
    fi
}

# Verify Docker installation
verify_docker() {
    print_header "Verifying Docker Installation"
    
    print_info "Testing Docker with hello-world container..."
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
    print_header "Verifying GPU Passthrough"
    
    if [ "$NVIDIA_DRIVERS_INSTALLED" = false ]; then
        print_warning "Skipping GPU passthrough verification as NVIDIA drivers are not installed"
        return 0
    fi
    
    print_info "Testing NVIDIA Container Toolkit with CUDA container..."
    if docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi > /dev/null 2>&1; then
        print_success "NVIDIA Container Toolkit verification passed"
        
        # Show detailed GPU information from the container
        print_info "GPU Information from Container:"
        docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv
        
        return 0
    else
        print_error "NVIDIA Container Toolkit verification failed"
        return 1
    fi
}

# Main installation process
main() {
    print_header "Docker and NVIDIA Container Toolkit Installation"
    print_info "Script version: $SCRIPT_VERSION"
    print_info "Installation log is saved to: $LOG_FILE"
    
    # Parse command line arguments
    parse_args "$@"
    
    # Check if running as root
    check_root
    
    # Check OS compatibility
    check_os_compatibility
    
    # Check hardware compatibility
    check_nvidia_hardware
    
    # Check if components are already installed
    check_docker
    check_docker_compose
    check_nvidia_drivers
    check_nvidia_container_toolkit
    
    # Install prerequisites
    install_prerequisites
    
    # Install Docker
    install_docker
    
    # Add user to docker group
    add_user_to_docker_group
    
    # Install Docker Compose
    install_docker_compose
    
    # Install NVIDIA Container Toolkit
    install_nvidia_container_toolkit
    
    # Verify installations
    if [ "$SKIP_TESTS" = false ]; then
        verify_docker
        verify_nvidia_container_toolkit
    else
        print_info "Skipping verification tests as requested"
    fi
    
    print_header "Installation Summary"
    print_success "Docker: Installed and configured"
    print_success "Docker Compose: Installed and configured"
    print_success "NVIDIA Container Toolkit: Installed and configured"
    print_info "Installation completed successfully"
    
    # Print important notes
    print_info "Note: If you were added to the docker group, you may need to log out and log back in for the changes to take effect."
    print_info "You can use the following command to verify GPU passthrough: docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi"
}

install_nvidia_container_toolkit
