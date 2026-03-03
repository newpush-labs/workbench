# NewPush Labs Workbench

A professional, containerized, single-mount development environment integrating Zellij, Caddy, Code-Server, and an automated toolchain management system. Designed by NewPush Labs to provide a consistent, ephemeral-yet-persistent workspace for modern software engineering.

**[📚 View the Full Documentation](/docs/index.md)**

## Architecture

The Workbench relies on two core architectural concepts to provide a seamless developer experience:

### Single Mount Architecture
Unlike traditional Docker environments that separate volumes for configurations and bind mounts for source code, the Workbench maps the host's `./workspace` directory directly to `/workspace` inside the container, and sets this as the user's `$HOME` directory. 

This ensures that all environment configurations (such as `.zshrc`, global NPM packages, NVM, and Bun installations) persist natively on your host filesystem alongside your project code. When the container is destroyed or rebuilt, your tools and configurations remain intact.

### Unified Access Routing
The environment utilizes Caddy as a reverse proxy, exposing both the IDE (Code-Server) and the Terminal environment (ttyd running Zellij) over a single port (`8080`). This simplifies network management, firewall rules, and provides a unified entry point protected by basic authentication.

## Setup Guide

### Prerequisites
- Docker
- Docker Compose

### Initial Setup

1. **Clone the repository:**
   Ensure you have cloned the Workbench repository to your local machine.

2. **Configure Environment Variables:**
   Copy the example environment file to configure your authentication and autoinstall packages:
   ```bash
   cp .env.example .env
   ```

3. **Build the Image:**
   It is recommended to build the image without using the cache on the first run to ensure all base dependencies are up to date:
   ```bash
   docker compose build --no-cache
   ```

4. **Start the Environment:**
   Bring up the Docker stack in detached mode:
   ```bash
   docker compose up -d
   ```

### Accessing the Workbench
Once the container is running, access the environment via your web browser:
- **Terminal (Zellij):** `http://localhost:8080/`
- **IDE (Code-Server):** `http://localhost:8080/ide/`

*Default credentials (if not modified in `.env`): Username: `admin`, Password: `admin`*

## Configuration

The environment is highly configurable via the `.env` file.

### Authentication
Caddy handles the basic authentication for the entire workspace. The `setup-auth.py` script applies these settings on startup.
- `AUTH_SKIP`: Set to `true` to completely disable authentication.
- `AUTH_USERNAME`: The username required to access the Workbench.
- `AUTH_PASSWORD`: The password required to access the Workbench.

### Autoinstall System
The Workbench features an automated initialization script (`autoinstall.py`) that ensures required system packages and language-specific tools are installed whenever the container starts. Define space-separated lists of packages in your `.env`:
- `AUTOINSTALL_NPM`: Global NPM packages (e.g., `@google/gemini-cli`).
- `AUTOINSTALL_PIP`: Global Python packages via pip.
- `AUTOINSTALL_BUN`: Global Bun packages.
- `AUTOINSTALL_APT`: Debian system packages via apt-get.

## Directory Structure

The repository follows a clean, industry-standard structure:

- `configs/`: Central location for application-level configurations (Caddyfile, supervisord.conf, zellij.kdl).
- `scripts/`: System initialization and automation scripts (entrypoint, auth setup, autoinstall logic, execution wrappers).
- `workspace/`: The persistent bind mount point. This directory will contain your project files as well as your dotfiles (`.zshrc`, `.nvm`, etc.) after the first initialization.

## Development Guidelines

### Persistence Rules
- **Ephemeral System:** Changes made to the container's root filesystem (e.g., manually installing packages via `apt` without updating `.env`) will be lost if the container is recreated.
- **Persistent Data:** Anything written to the `/workspace` directory is persistent. This includes source code, git repositories, and tools installed via NVM or global NPM, as the `HOME` directory is mapped here.

### Terminal Experience
The Workbench utilizes Zellij inside a web-based terminal emulator (ttyd).
- **Clipboard Integration:** Zellij is configured with `mouse_mode false` and native clipboard support. You can select text using your standard mouse cursor and copy/paste using your browser's native right-click menu or standard keyboard shortcuts.
- **Layouts:** The default Zellij layout provides a compact status bar and opens a new bash/zsh session immediately. 

## License

This project is distributed under the MIT License. See the `LICENSE` file for more information.