#!/usr/bin/env python3
import os
import sys
import json
import subprocess
import hashlib
from pathlib import Path

HOME = Path(os.environ.get('HOME', '/workspace'))
HASH_FILE = HOME / '.autoinstall.hash'

def run_cmd(cmd):
    print(f"Running: {cmd}", flush=True)
    subprocess.run(cmd, shell=True, check=False)

def get_config():
    # Check for config files
    config_paths = [
        Path('/workspace/autoinstall.json'),
        HOME / 'autoinstall.json',
        Path('/etc/workbench/autoinstall.json')
    ]
    
    config = {"npm": [], "pip": [], "bun": [], "apt": []}
    for p in config_paths:
        if p.exists():
            try:
                with open(p, 'r') as f:
                    file_config = json.load(f)
                    for key in config:
                        if key in file_config:
                            config[key].extend(file_config[key])
                    print(f"Loaded config from {p}", flush=True)
                    break
            except Exception as e:
                print(f"Failed to load config from {p}: {e}", flush=True)
                
    # Parse env vars and merge
    npm_env = os.environ.get('AUTOINSTALL_NPM', '')
    pip_env = os.environ.get('AUTOINSTALL_PIP', '')
    bun_env = os.environ.get('AUTOINSTALL_BUN', '')
    apt_env = os.environ.get('AUTOINSTALL_APT', '')
    
    if npm_env: config["npm"].extend(npm_env.split())
    if pip_env: config["pip"].extend(pip_env.split())
    if bun_env: config["bun"].extend(bun_env.split())
    if apt_env: config["apt"].extend(apt_env.split())
    
    # Sort for stable hashing
    for key in config:
        config[key] = sorted(list(set(config[key])))
        
    return config

def main():
    config = get_config()
    
    # Calculate hash of the configuration
    config_str = json.dumps(config, sort_keys=True)
    current_hash = hashlib.sha256(config_str.encode()).hexdigest()
    
    # Check if we need to install
    if HASH_FILE.exists():
        try:
            with open(HASH_FILE, 'r') as f:
                saved_hash = f.read().strip()
            if saved_hash == current_hash:
                print("Configuration unchanged. Skipping autoinstall.", flush=True)
                sys.exit(0)
        except Exception:
            pass
            
    print("Configuration change detected or first startup. Running autoinstall...", flush=True)
    
    # Execute installations
    if config["apt"]:
        pkgs = " ".join(config["apt"])
        run_cmd(f"sudo apt-get update && sudo apt-get install -y {pkgs}")
        
    if config["npm"]:
        pkgs = " ".join(config["npm"])
        run_cmd(f"npm install -g {pkgs}")
        
    if config["pip"]:
        pkgs = " ".join(config["pip"])
        run_cmd(f"pip3 install --break-system-packages {pkgs}")
        
    if config["bun"]:
        pkgs = " ".join(config["bun"])
        run_cmd(f"bun add -g {pkgs}")
        
    # Save the new hash
    try:
        with open(HASH_FILE, 'w') as f:
            f.write(current_hash)
    except Exception as e:
        print(f"Failed to save hash: {e}", flush=True)
        
    print("Autoinstall complete.", flush=True)

if __name__ == '__main__':
    main()
