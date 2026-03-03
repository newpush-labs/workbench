# Developer Experience

The Workbench is optimized for a seamless, immediate developer experience, combining powerful terminal multiplexing, a web-based IDE, and a pre-configured shell environment.

## The Terminal (Zellij + ttyd)

At the root path (`/`), the Workbench serves a terminal session via [ttyd](https://github.com/tsl0922/ttyd). ttyd translates standard terminal output into a web-accessible interface.

Instead of dropping you into a raw bash shell, ttyd is configured to launch [Zellij](https://zellij.dev/), a modern workspace and terminal multiplexer.

### Zellij Methodology
- **Pre-configured Layout**: The environment uses a custom layout (`configs/zellij-layout.kdl`) that immediately drops you into a prompt while providing a compact status bar. This maximizes screen real estate for your code.
- **Clipboard Integration**: One common pain point with web terminals is clipboard access. Zellij is configured with `mouse_mode false` (`configs/zellij.kdl`). This is a deliberate choice: it allows your browser's native text selection and right-click context menu to function normally, meaning you can copy and paste code directly from the web interface exactly as you would on a standard webpage.
- **Persistent Sessions**: Because Zellij manages the sessions, you can open multiple panes and tabs. If you refresh your browser, your terminal state remains exactly as you left it.

## The IDE (Code-Server)

At the `/ide/` path, the Workbench serves [Code-Server](https://github.com/coder/code-server), allowing you to run VS Code on any machine with a browser.
- Code-Server shares the exact same filesystem (`/workspace`) as the terminal. 
- You can seamlessly edit files in the IDE, and run compilers or dev servers in the Zellij terminal.

## Pre-Installed Toolchains

To provide a zero-setup experience, the underlying Docker image comes pre-installed with standard industry toolchains:

1. **Zsh and Oh-My-Zsh**: The default shell is `zsh` instead of `bash`. Oh-My-Zsh provides an enhanced prompt, better tab completion, and extensive plugin support. The `entrypoint.sh` bootstrap mechanism ensures these dotfiles are available in your persistent workspace.
2. **Node Version Manager (NVM)**: Provides the ability to easily install and switch between different Node.js versions.
3. **Bun**: An all-in-one JavaScript runtime and toolkit, pre-installed to speed up dependency resolution and script execution.
4. **Git and GitHub CLI (`gh`)**: For seamless version control and PR management directly from the terminal.
5. **Python 3**: For scripting and auxiliary tooling. 

By default, these tools are available immediately upon first boot, and any further global packages you install via the Autoinstall system (`.env`) will persist in your workspace.
