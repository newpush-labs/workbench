# Single Mount Architecture

The most defining feature of the Workbench is its **Single Mount Architecture**. This methodology ensures that the environment is both ephemeral and persistent where it matters.

## The Concept

Traditionally, containerized development environments use complex volume mapping:
- One volume for database data.
- One volume for IDE configuration.
- A bind mount for the project source code.

The Workbench simplifies this by mapping exactly **one bind mount**:
```yaml
volumes:
  - ./workspace:/workspace
```

## How It Works

1. **Changing `$HOME`**: In the Dockerfile, the `superuser`'s home directory is explicitly set to `/workspace`. 
2. **Ephemeral OS**: The core operating system, system packages installed via `apt`, and the server binaries (Caddy, Code-Server, ttyd) are ephemeral. If you destroy the container and rebuild it, you start with a clean slate.
3. **Persistent Configuration**: Because `$HOME` is mapped to the bind mount on your host machine, all configuration files (`.zshrc`, `.gitconfig`), history files (`.zsh_history`), and toolchain installations (NVM, Bun, Global NPM packages) reside on your physical hard drive.

## The Bootstrap Process

When a fresh container starts, it mounts an empty or purely source-code directory to `/workspace`. The environment expects tools like Oh-My-Zsh to exist in the home directory.

To bridge this gap, the Dockerfile builds a `home_bootstrap.tar.gz` archive containing a fully configured `.zshrc`, Zellij layouts, NVM initialization scripts, and more. 

When the `entrypoint.sh` script runs, it checks for the existence of `.oh-my-zsh`. If it is missing, it assumes the directory needs initialization and extracts the bootstrap archive into `/workspace`. This provides you with an instantly usable terminal environment that immediately becomes persistent on your host.

## Benefits
- **Zero Configuration Loss**: Deleting the Docker container does not delete your CLI history, Git configuration, or installed Node versions.
- **Easy Backup**: Backing up your project folder inherently backs up your entire development environment state.
- **Portability**: Another developer cloning the repo and spinning up the container will have their own isolated workspace generated locally.
