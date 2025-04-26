# OpenWebUI Deployment Tool

A Kamal-like deployment experience for OpenWebUI with Ollama and GPU support.

## Overview

This tool provides a simple command-line interface to deploy and manage OpenWebUI with Ollama on a remote server with GPU acceleration. It handles setting up the necessary dependencies, deploying the application, and managing its lifecycle.

## Requirements

- SSH access to a remote Ubuntu server
- NVIDIA GPU on the remote server (RTX 3070 recommended)
- Local bash environment (macOS or Linux)
- SSH key-based authentication to the remote server (recommended)

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/openwebui-deploy.git
   cd openwebui-deploy
   ```

2. Make the deployment script executable:
   ```bash
   chmod +x deploy.sh
   ```

3. (Optional) Set up command completion for bash:
   ```bash
   # For temporary use
   source completion.sh
   
   # For permanent use, add to your .bashrc or .zshrc
   echo "source $(pwd)/completion.sh" >> ~/.bashrc
   ```

## Commands

### Initial Setup

Configure the deployment settings and prepare the remote server:

```bash
./deploy.sh setup
```

This command will:
- Create a `.deploy.env` configuration file
- Prompt for remote server details
- Test the SSH connection
- Install Docker and NVIDIA Container Toolkit on the remote server
- Configure the remote environment for deployment

### Deployment

Deploy or update the application on the remote server:

```bash
./deploy.sh deploy
```

This command:
- Copies the Docker Compose configuration to the remote server
- Creates a backup of any existing deployment
- Starts the containers with Docker Compose
- Verifies the deployment status

### Rollback

Rollback to the previous deployment if something goes wrong:

```bash
./deploy.sh deploy rollback
```

This command:
- Stops the current containers
- Restores the previous deployment configuration
- Restarts the containers with the previous configuration

### Status Check

Check the status of the running containers:

```bash
./deploy.sh status
```

This shows:
- Running container status
- Resource usage (CPU, memory)
- GPU utilization (if applicable)

### View Logs

View logs from all application containers:

```bash
./deploy.sh logs
```

View logs from a specific container:

```bash
./deploy.sh logs ollama
```

Follow logs in real-time:

```bash
./deploy.sh logs ollama follow
```

### SSH Access

Open an SSH session to the remote server:

```bash
./deploy.sh ssh
```

Execute a specific command on the remote server:

```bash
./deploy.sh ssh "docker ps -a"
```

### Version Information

Display the version information:

```bash
./deploy.sh version
```

### Help

Display usage information:

```bash
./deploy.sh help
```

## Configuration

The configuration is stored in the `.deploy.env` file with the following variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `REMOTE_HOST` | Remote server hostname or IP | `example.com` or `192.168.1.100` |
| `REMOTE_USER` | SSH username for the remote server | `ubuntu` |
| `SSH_PORT` | SSH port (defaults to 22) | `22` |
| `DEPLOY_DIR` | Deployment directory on the remote server | `/home/ubuntu/openwebui` |
| `OPENWEBUI_PORT` | Port to expose OpenWebUI on (defaults to 3000) | `3000` |

You can modify these settings by editing the `.deploy.env` file directly or by running the setup command again.

## Docker Compose Configuration

The Docker Compose configuration is located in the `compose/docker-compose.yml` file. It includes:

- **Ollama service**: Runs the Ollama model server with GPU acceleration
- **OpenWebUI service**: Provides the web interface for interacting with Ollama

The configuration uses Docker volumes for persistent storage:

- `ollama_data`: Stores the Ollama models
- `openwebui_data`: Stores the OpenWebUI user data and SQLite database

## Models

The deployment supports the following models:

- **Llama3 7B Q4 KM**: Primary model (~4GB VRAM)
- **Phi3-mini**: Lightweight alternative (~2GB VRAM)
- **Deepseek (quantized)**: For complex reasoning tasks (5-7GB VRAM)

## Troubleshooting

### SSH Connection Issues

If you encounter SSH connection issues, check the following:

1. Ensure you have SSH access to the remote server
2. Verify that your SSH key is properly configured
3. Check if the SSH port is correct in your configuration

### Deployment Failures

If deployment fails, you can:

1. Check the logs: `./deploy.sh logs`
2. Rollback to the previous deployment: `./deploy.sh deploy rollback`
3. SSH into the server for manual inspection: `./deploy.sh ssh`

### GPU Acceleration Issues

If GPU acceleration is not working:

1. Check if NVIDIA drivers are installed: `./deploy.sh ssh "nvidia-smi"`
2. Verify NVIDIA Container Toolkit: `./deploy.sh ssh "docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi"`

## Directory Structure

```
.
├── deploy.sh                  # Main deployment script
├── completion.sh              # Command completion script
├── README.md                  # Documentation
├── .deploy.env                # Configuration file (created during setup)
├── compose/                   # Docker Compose configuration
│   └── docker-compose.yml     # Main Docker Compose file
└── libexec/                   # Command implementation scripts
    ├── deploy.sh              # Deployment implementation
    ├── install_docker_nvidia.sh  # Docker and NVIDIA toolkit installation
    ├── logs.sh                # Log viewing implementation
    ├── setup.sh               # Setup implementation
    ├── ssh.sh                 # SSH implementation
    ├── status.sh              # Status implementation
    ├── utils.sh               # Shared utility functions
    └── version.sh             # Version information
```

## License

[MIT License](LICENSE)