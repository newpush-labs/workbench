#!/bin/bash
set -e

# Real HOME is /workspace
export HOME="/workspace"
export USER="superuser"

# Setup: If the home directory is missing critical shell configs,
# it means a bind-mount or new volume is masking the build-time files.
# We check for .oh-my-zsh as a reliable indicator of a populated home.
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "--- Workbench Initialization ---"
    echo "Detected empty or uninitialized home directory at $HOME"
    echo "Populating from bootstrap template..."
    
    # Ensure superuser owns the top-level $HOME (bind-mount)
    # We ignore errors because on some hosts (macOS) chown might not be allowed on the mount root
    sudo chown superuser:superuser "$HOME" || true
    
    # Extract as superuser. This ensures all files are owned by them from the start.
    # --no-same-owner is crucial when extracting as a non-root user.
    sudo -u superuser tar -xzf /usr/src/home_bootstrap.tar.gz -C "$HOME" --no-same-owner
    
    # Ensure workbench scripts remain executable after extraction/bind-mount
    sudo chmod +x /usr/local/bin/workbench/*.sh
    
    echo "Initialization complete."
    echo "--------------------------------"
fi

# Load nvm and node from HOME
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Configure Caddy Authentication (Fast)
python3 /usr/local/bin/workbench/setup-auth.py

# Execute original CMD (Starts supervisord)
exec "$@"
