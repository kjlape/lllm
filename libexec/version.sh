#!/bin/bash

# Version script for OpenWebUI deployment
# Shows the current version of the deployment tool

# Source the common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Version information
VERSION="0.1.0"
RELEASE_DATE="2025-04-25"

# Version command
version() {
    echo "OpenWebUI Deployment Tool"
    echo "Version: $VERSION"
    echo "Release Date: $RELEASE_DATE"
    echo ""
    echo "Repository: https://github.com/yourusername/openwebui-deploy"
}

# Execute version command
version