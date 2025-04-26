# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
- Deployment project for OpenWebUI with Ollama and GPU support
- Uses Docker Compose with a Kamal-like deployment experience
- Custom local CLI tool for remote deployment
- Includes Docker configurations for services with GPU acceleration

## Commands
- `./deploy.sh setup` - Install Docker, NVIDIA toolkit, and set up initial configuration
- `./deploy.sh deploy` - Deploy or update the application
- `./deploy.sh status` - Check status of running containers
- `./deploy.sh logs` - View logs from containers
- `./deploy.sh ssh` - Open SSH session to the server

## Code Style Guidelines
- Follow Docker best practices for containerization
- Use YAML indentation of 2 spaces for Docker Compose configuration files
- Bash scripts should be executable (chmod +x) with proper shebang
- Use volumes for persistent data storage
- Include appropriate error handling in deployment scripts
- Maintain clear separation between installation and deployment logic

## Dependencies
- Docker and Docker Compose for containerization
- NVIDIA Container Toolkit for GPU passthrough
- SSH access from local development machine to target server
- NVIDIA RTX 3070 GPU with proper drivers for Ollama GPU support
- Ubuntu Linux on target server

## Models
- Llama3 7B Q4 KM: Primary model (~4GB VRAM)
- Phi3-mini: Lightweight alternative (~2GB VRAM)
- Deepseek (quantized): For complex reasoning tasks (5-7GB VRAM)
