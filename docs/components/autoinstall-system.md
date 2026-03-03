# Autoinstall System

The Workbench includes a dynamic autoinstallation system designed to ensure that global dependencies, CLI tools, and system packages are automatically provisioned when the container starts.

## Methodology

Because the container's OS layer is ephemeral, any packages installed manually via `apt`, `npm -g`, or `pip` (outside of the `/workspace` directory) are lost when the container is recreated.

The `autoinstall.py` script bridges this gap by acting as a declarative package manager for the Workbench.

### Execution Flow
1. Upon container boot, `supervisord` triggers the `run-autoinstall.sh` script.
2. The script executes `/usr/local/bin/workbench/autoinstall.py`.
3. The Python script parses requested packages, checks for changes, and installs them if necessary.

## Configuration Sources

The system aggregates required packages from two primary sources, merging them together:

1. **Environment Variables**:
   Defined in the `.env` or `docker-compose.yml` file:
   - `AUTOINSTALL_APT`: Debian system packages.
   - `AUTOINSTALL_NPM`: Global Node.js packages.
   - `AUTOINSTALL_PIP`: Global Python 3 packages.
   - `AUTOINSTALL_BUN`: Global Bun packages.

2. **JSON Configuration**:
   The script looks for an `autoinstall.json` file in multiple locations (prioritizing `/workspace/autoinstall.json`). This allows a project repository to commit a standard set of required tools for all developers.
   ```json
   {
     "npm": ["typescript", "eslint"],
     "apt": ["jq", "tree"],
     "pip": ["requests"],
     "bun": []
   }
   ```

## State Management and Hashing

Running `apt-get install` or `npm install -g` on every single container restart would significantly slow down boot times.

To optimize this, `autoinstall.py` implements a hashing mechanism:
1. It aggregates and alphabetically sorts the final list of all requested packages across all managers.
2. It generates a SHA-256 hash of this configuration.
3. It compares this hash against the contents of `/workspace/.autoinstall.hash`.
4. **If the hash matches:** The configuration hasn't changed. The script exits immediately with a success code (`sys.exit(0)`), skipping all installations.
5. **If the hash differs (or doesn't exist):** It proceeds to sequentially execute the installation commands for APT, NPM, PIP, and Bun. Once completed, it saves the new hash to `/workspace/.autoinstall.hash`.

This ensures that dependencies are only resolved when you actually add or remove a tool from your configuration, making subsequent starts nearly instantaneous.
