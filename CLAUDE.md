# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
- Deployment project for OpenWebUI with Ollama and GPU support
- Uses Kamal for containerized deployment management
- Includes Docker configurations for services

## Commands
- `kamal setup` - Prepare the target server environment
- `kamal deploy` - Deploy the application
- `kamal logs` - View deployment logs
- `kamal app status` - Check container status
- `kamal setup check` - Validate configuration
- `kamal validate` - Validate deployment.yml syntax

## Code Style Guidelines
- Follow Docker best practices for containerization
- Use YAML indentation of 2 spaces for Kamal configuration files
- Bash scripts should be executable (chmod +x) with proper shebang
- Use volumes for persistent data storage
- Include appropriate error handling in hook scripts

## Dependencies
- Kamal deployment tool (Ruby gem)
- Docker for containerization
- NVIDIA GPU with proper drivers for Ollama GPU support