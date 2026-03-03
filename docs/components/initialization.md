# Container Initialization Lifecycle

Understanding how the Workbench container boots is crucial for extending or debugging the environment. The lifecycle is strictly managed to handle the complexities of bind-mounting over the user's home directory.

## 1. The Entrypoint (`entrypoint.sh`)

When `docker compose up` is executed, the container does not immediately start the IDE or Terminal. It first runs `/usr/local/bin/workbench/entrypoint.sh` as the `superuser`.

### The Home Directory Problem
In Docker, if you copy files into a directory during the `docker build` phase, and then later bind-mount a host volume over that same directory during runtime, the host volume completely obscures the build-time files. 

Since the Workbench maps `./workspace` to `/workspace` (which is our `$HOME`), any `.zshrc`, `.nvm`, or default configurations we baked into the image are hidden the moment the container starts.

### The Bootstrap Solution
To solve this, the Dockerfile bundles a complete, pre-configured home directory into a tarball: `/usr/src/home_bootstrap.tar.gz` before the `EXPOSE` layer.

The `entrypoint.sh` performs the following logic:
1. It checks if `/workspace/.oh-my-zsh` exists. 
2. **If it does not exist:** It assumes this is a fresh bind mount (or an empty directory). It then runs `tar -xzf /usr/src/home_bootstrap.tar.gz -C "$HOME"`. This populates the host machine's directory with all the necessary dotfiles and scripts.
3. **If it does exist:** It skips extraction, preserving the user's customized files.

### Post-Bootstrap Initialization
After handling the directory state, the script:
- Sources NVM and Bun to ensure they are available in the current environment path.
- Executes `setup-auth.py` to configure Caddy's basic authentication.
- Finally, it uses `exec "$@"` to pass control over to the main command, which is `supervisord`.

## 2. Process Management (`supervisord`)

A Docker container is designed to run a single primary process. Because the Workbench requires Caddy, Code-Server, ttyd, and a background autoinstall script to run simultaneously, it utilizes `supervisord` as an init system.

The `/etc/supervisor/conf.d/supervisord.conf` file defines the following services:
- **caddy**: The reverse proxy routing traffic on port 8080.
- **code-server**: The VS Code environment running on internal port 8443.
- **ttyd**: The terminal emulator running on internal port 7681, configured to execute `zellij`.
- **autoinstall**: A one-shot script (`run-autoinstall.sh`) that executes the `autoinstall.py` logic once the container is up.

If any of these critical services crash, `supervisord` is responsible for restarting them automatically, ensuring a stable development experience.
