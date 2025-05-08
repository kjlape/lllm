#!/bin/bash

# OpenWebUI Deployment Tool
# A Kamal-like deployment experience for OpenWebUI with Ollama and GPU support

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBEXEC_DIR="$SCRIPT_DIR/libexec"
source "$LIBEXEC_DIR/utils.sh"

# Command functions
cmd_help() {
    echo "OpenWebUI Deployment Tool"
    echo ""
    echo "Usage:"
    echo "  ./deploy.sh [command] [options]"
    echo ""
    echo "Commands:"
    echo "  setup               Configure deployment settings and prepare remote server"
    echo "  deploy              Deploy or update the application on the remote server"
    echo "  deploy rollback     Rollback to the previous deployment"
    echo "  status              Check status of running containers"
    echo "  logs [service]      View logs from containers (optionally for a specific service)"
    echo "  logs [service] follow    View logs and follow output"
    echo "  ssh [command]       Open SSH session to the server, optionally executing a command"
    echo "  version             Display the version information"
    echo "  help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh setup"
    echo "  ./deploy.sh deploy"
    echo "  ./deploy.sh logs"
    echo "  ./deploy.sh logs ollama follow"
    echo "  ./deploy.sh ssh"
    echo "  ./deploy.sh ssh \"ls -la\""
}

cmd_setup() {
    "$LIBEXEC_DIR/setup.sh"
}

cmd_deploy() {
    "$LIBEXEC_DIR/deploy.sh" "$1"
}

cmd_status() {
    "$LIBEXEC_DIR/status.sh"
}

cmd_logs() {
    "$LIBEXEC_DIR/logs.sh" "$2" "$3" "$4"
}

cmd_ssh() {
    "$LIBEXEC_DIR/ssh.sh" "$2"
}

cmd_version() {
    "$LIBEXEC_DIR/version.sh"
}

# Check if libexec directory exists
if [ ! -d "$LIBEXEC_DIR" ]; then
    print_error "Cannot find libexec directory at $LIBEXEC_DIR"
    exit 1
fi

# Check if utility scripts are executable
for script in "$LIBEXEC_DIR"/*.sh; do
    if [ ! -x "$script" ]; then
        chmod +x "$script"
    fi
done

# Main command router
case "$1" in
    setup)
        cmd_setup
        ;;
    deploy)
        cmd_deploy "$2"
        ;;
    status)
        cmd_status
        ;;
    logs)
        cmd_logs "$2" "$3" "$4"
        ;;
    ssh)
        cmd_ssh "$2"
        ;;
    version)
        cmd_version
        ;;
    help|'')
        cmd_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Run './deploy.sh help' for usage information."
        exit 1
        ;;
esac
