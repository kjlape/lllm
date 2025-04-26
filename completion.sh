#!/bin/bash
# OpenWebUI Deployment Tool completion script

_deploy_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Main commands
    commands="setup deploy status logs ssh version help"
    
    # Options for specific commands
    case "$prev" in
        deploy)
            COMPREPLY=( $(compgen -W "rollback" -- "$cur") )
            return 0
            ;;
        logs)
            # Add container names if possible
            services="ollama openwebui"
            COMPREPLY=( $(compgen -W "$services follow" -- "$cur") )
            return 0
            ;;
        help|version|setup|status)
            COMPREPLY=()
            return 0
            ;;
        ssh)
            # No completion for ssh commands
            COMPREPLY=()
            return 0
            ;;
    esac
    
    # If we are on the first argument, complete with commands
    if [[ ${COMP_CWORD} -eq 1 ]] ; then
        COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
        return 0
    fi
}

# Register the completion function
complete -F _deploy_completion deploy.sh