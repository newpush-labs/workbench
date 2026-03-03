#!/bin/bash
# Always use /workspace as HOME
export HOME="/workspace"
export USER="superuser"

# Load nvm and node from HOME
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Run the autoinstall logic
python3 /usr/local/bin/workbench/autoinstall.py
