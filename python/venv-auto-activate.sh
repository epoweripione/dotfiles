#!/usr/bin/env bash

# Virtual Environment Auto-Activation
# ===================================
# Automatically activates/deactivates Python virtual environments
# when changing directories
# See full write up at https://mkennedy.codes/posts/always-activate-the-venv-a-shell-script/

# Add to shell configuration file (e.g., ~/.bashrc or ~/.zshrc)
function venv_auto_activate_bash() {
    if ! grep -q 'venv-auto-activate.sh' "$HOME/.bashrc" 2>/dev/null; then
        tee -a "$HOME/.bashrc" >/dev/null <<-EOF

# Automatically activates/deactivates Python virtual environments
source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/python/venv-auto-activate.sh"

# Venv security whitelist/blocklist
alias venv-security='uv run -q --no-project ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/python/venv-security.py'
alias vnvsec='uv run -q --no-project ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/python/venv-security.py'
EOF
fi
}

function venv_auto_activate_zsh() {
    if ! grep -q 'venv-auto-activate.sh' "$HOME/.zshrc" 2>/dev/null; then
        tee -a "$HOME/.zshrc" >/dev/null <<-EOF

# Automatically activates/deactivates Python virtual environments
source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/python/venv-auto-activate.sh"

# Venv security whitelist/blocklist
alias venv-security='uv run -q --no-project ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/python/venv-security.py'
alias vnvsec='uv run -q --no-project ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/python/venv-security.py'
EOF
fi
}

# Function to find venv directory in current path or parent directories
# Prefers 'venv' over '.venv' if both exist
function find_venv() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/venv" && -f "$dir/venv/bin/activate" ]]; then
            echo "$dir/venv"
            return 0
        elif [[ -d "$dir/.venv" && -f "$dir/.venv/bin/activate" ]]; then
            echo "$dir/.venv"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

# Auto-activate virtual environment for any project with a venv directory
function chpwd() {
    local venv_path project_name
    venv_path=$(find_venv)
    
    if [[ -n "$venv_path" ]]; then
        # Normalize paths for comparison (handles symlinks and path differences)
        # Use zsh :A modifier to resolve paths without triggering chpwd recursively
        local normalized_venv_path="${venv_path:A}"
        local normalized_current_venv=""
        if [[ -n "${VIRTUAL_ENV:-}" ]]; then
            normalized_current_venv="${VIRTUAL_ENV:A}"
        fi
        
        # We found a venv, check if it's already active
        if [[ "$normalized_current_venv" != "$normalized_venv_path" ]]; then
            # Deactivate current venv if different
            if [[ -n "${VIRTUAL_ENV:-}" ]] && type deactivate >/dev/null 2>&1; then
                deactivate
            fi
            # Security check: only activate trusted venvs
            if uv run -q --no-project ~/scripts/venv-security.py check "$normalized_venv_path"; then
                source "$venv_path/bin/activate"
                project_name=$(basename "$(dirname "$venv_path")")
                colorEcho "${BLUE}🇵🇾 Activated virtual environment ${FUCHSIA}${project_name}${BLUE}."
            fi
        fi
    else
        # No venv found, deactivate if we have one active
        if [[ -n "${VIRTUAL_ENV:-}" ]] && type deactivate >/dev/null 2>&1; then
            project_name=$(basename "$(dirname "${VIRTUAL_ENV}")")
            deactivate
            colorEcho "${BLUE}🔒 Deactivated virtual environment ${FUCHSIA}${project_name}${BLUE}."
        elif [[ -n "${VIRTUAL_ENV:-}" ]]; then
            # VIRTUAL_ENV is set but deactivate function is not available
            # This can happen when opening a new shell with VIRTUAL_ENV from previous session
            unset VIRTUAL_ENV
        fi
    fi
}

# Run the chpwd function when the shell starts
chpwd
