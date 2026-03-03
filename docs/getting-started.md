# Getting Started

This guide walks you through setting up and using the NewPush Labs Workbench.

## Prerequisites

Before starting, ensure you have the following installed on your host machine:
- **Docker**: The core container engine.
- **Docker Compose**: For managing the multi-container stack (or a single container with complex configurations).

## Installation

1. **Clone the repository:**
   Start by cloning the Workbench repository to your local machine.

2. **Configure Environment Variables:**
   Copy the example environment file to configure your authentication and autoinstall packages:
   ```bash
   cp .env.example .env
   ```
   *Tip: Review the `.env` file to customize your global NPM, PIP, APT, and Bun packages, or adjust the default credentials (`admin`/`admin`).*

3. **Build the Image:**
   It is highly recommended to build the image without using the cache on the first run. This ensures that the base Debian image and all dependencies (like Node, Python, and CLI tools) are completely up-to-date:
   ```bash
   docker compose build --no-cache
   ```

4. **Start the Environment:**
   Bring up the Docker stack in detached mode:
   ```bash
   docker compose up -d
   ```

## Accessing the Workbench

The Workbench uses Caddy to route traffic through a single port, simplifying access and firewall rules.

- **Terminal Environment (Zellij via ttyd):**
  Navigate to `http://localhost:8080/`
- **IDE (Code-Server):**
  Navigate to `http://localhost:8080/ide/`

When prompted, enter your configured credentials (default: `admin` / `admin`).

## First Initialization

Upon the first startup, if the mapped `/workspace` directory lacks shell configurations (like `.oh-my-zsh`), the `entrypoint.sh` script will automatically populate your workspace with a pre-configured template. This bootstrap process includes your `.zshrc`, Zellij layouts, and toolchain configurations (NVM, Bun). Subsequent restarts will recognize the populated directory and skip this step, preserving your customizations.
