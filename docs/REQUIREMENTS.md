# Requirements — NewPush Labs Workbench

> Canonical specification for the Workbench project. This document is the primary source of truth for what needs to be built, validated, and maintained. All PRs and implementation plans should reference requirements defined here.

---

## 1. Project Overview

The NewPush Labs Workbench is a containerized, single-mount development environment that provides a consistent, ephemeral-yet-persistent workspace for modern software engineering. It integrates a terminal multiplexer (Zellij), a reverse proxy (Caddy), a web-based IDE (Code-Server), and an automated toolchain management system into a single Docker container accessible through a unified port.

### 1.1 Target Users

- Software developers requiring a portable, reproducible development environment.
- Teams needing consistent tooling across heterogeneous host operating systems.
- Remote developers who need browser-based access to a full development workspace.
- DevOps engineers evaluating or prototyping containerized developer workflows.

### 1.2 Design Principles

- **Single mount simplicity**: One volume mount (`/workspace`) serves as both the user home directory and the persistent data layer.
- **Ephemeral OS, persistent configuration**: The container image is disposable; user state lives entirely on the host filesystem.
- **Unified access**: All services are reachable through a single port (8080) via path-based routing.
- **Zero-setup experience**: A developer should be productive within minutes of cloning the repository and running `docker compose up`.

---

## 2. Functional Requirements

### FR-1: Single Mount Architecture

| ID | Requirement | Status |
|----|-------------|--------|
| FR-1.1 | The container MUST map a single host directory to `/workspace` inside the container. | Implemented |
| FR-1.2 | `/workspace` MUST be set as the `$HOME` directory for the container user (`superuser`). | Implemented |
| FR-1.3 | All user-facing configuration files (`.zshrc`, `.gitconfig`, `.nvm`, etc.) MUST reside within `/workspace` so they persist across container rebuilds. | Implemented |
| FR-1.4 | Destroying and recreating the container MUST NOT result in loss of user configurations, shell history, installed Node versions, or global packages installed into `$HOME`. | Implemented |

### FR-2: Home Directory Bootstrap

| ID | Requirement | Status |
|----|-------------|--------|
| FR-2.1 | The Docker image MUST include a pre-built bootstrap archive (`home_bootstrap.tar.gz`) containing a fully configured home directory. | Implemented |
| FR-2.2 | On first startup (detected by absence of `.oh-my-zsh` in `/workspace`), the entrypoint MUST extract the bootstrap archive into `/workspace`. | Implemented |
| FR-2.3 | On subsequent startups where `/workspace` is already populated, the entrypoint MUST skip extraction and preserve the user's customizations. | Implemented |
| FR-2.4 | The bootstrap archive MUST include: Oh-My-Zsh, `.zshrc` with NVM/Bun path configuration, Zellij config, and a welcome message source. | Implemented |

### FR-3: Unified Access Routing (Caddy)

| ID | Requirement | Status |
|----|-------------|--------|
| FR-3.1 | Caddy MUST listen on port 8080 and serve as the sole external entry point. | Implemented |
| FR-3.2 | Requests to `/ide/*` MUST be proxied to Code-Server (internal port 8081). | Implemented |
| FR-3.3 | Requests to `/*` (all other paths) MUST be proxied to ttyd/Zellij (internal port 8082). | Implemented |
| FR-3.4 | A request to `/ide` (without trailing slash) MUST redirect to `/ide/`. | Implemented |

### FR-4: Authentication

| ID | Requirement | Status |
|----|-------------|--------|
| FR-4.1 | The entire Workbench (all routes on port 8080) MUST be protected by HTTP Basic Authentication by default. | Implemented |
| FR-4.2 | Username and password MUST be configurable via `AUTH_USERNAME` and `AUTH_PASSWORD` environment variables. | Implemented |
| FR-4.3 | The `setup-auth.py` script MUST hash the plaintext password using `caddy hash-password` and inject credentials into the Caddyfile at startup. | Implemented |
| FR-4.4 | Setting `AUTH_SKIP=true` MUST completely remove the `basic_auth` block from the Caddyfile, allowing unauthenticated access. | Implemented |
| FR-4.5 | Default credentials MUST be `admin` / `admin` when no environment variables are provided. | Implemented |

### FR-5: Terminal Environment

| ID | Requirement | Status |
|----|-------------|--------|
| FR-5.1 | The terminal MUST be served via ttyd as a web-accessible interface at the root path (`/`). | Implemented |
| FR-5.2 | ttyd MUST launch Zellij as the terminal multiplexer (not a raw shell). | Implemented |
| FR-5.3 | Zellij MUST be configured with `mouse_mode false` to allow native browser text selection and clipboard operations. | Implemented |
| FR-5.4 | Zellij MUST use a custom layout (`zellij-layout.kdl`) that provides a compact status bar and immediate shell access. | Implemented |
| FR-5.5 | Zellij sessions MUST persist across browser refreshes (session name: `Workbench`). | Implemented |

### FR-6: IDE Environment

| ID | Requirement | Status |
|----|-------------|--------|
| FR-6.1 | Code-Server MUST be accessible at `/ide/` and share the `/workspace` filesystem with the terminal. | Implemented |
| FR-6.2 | Code-Server MUST run with `--auth none` (authentication is handled by Caddy). | Implemented |

### FR-7: Autoinstall System

| ID | Requirement | Status |
|----|-------------|--------|
| FR-7.1 | The `autoinstall.py` script MUST support installing packages from four managers: APT, NPM, PIP, and Bun. | Implemented |
| FR-7.2 | Package lists MUST be configurable via environment variables (`AUTOINSTALL_APT`, `AUTOINSTALL_NPM`, `AUTOINSTALL_PIP`, `AUTOINSTALL_BUN`). | Implemented |
| FR-7.3 | Package lists MUST also be loadable from an `autoinstall.json` file, with `/workspace/autoinstall.json` taking priority. | Implemented |
| FR-7.4 | Environment variable packages and JSON file packages MUST be merged (union). | Implemented |
| FR-7.5 | The script MUST compute a SHA-256 hash of the merged, sorted configuration and compare it against a saved hash (`/workspace/.autoinstall.hash`). | Implemented |
| FR-7.6 | If the hash matches (no configuration change), the script MUST skip all installations and exit immediately. | Implemented |
| FR-7.7 | If the hash differs or is absent, the script MUST execute installations for all configured managers and save the new hash. | Implemented |
| FR-7.8 | The autoinstall process MUST run as a one-shot supervisord program on every container start. | Implemented |

### FR-8: Process Management

| ID | Requirement | Status |
|----|-------------|--------|
| FR-8.1 | `supervisord` MUST manage four services: Caddy, Code-Server, ttyd, and autoinstall. | Implemented |
| FR-8.2 | Caddy, Code-Server, and ttyd MUST be configured with `autorestart=true` for crash resilience. | Implemented |
| FR-8.3 | The autoinstall program MUST be configured with `autorestart=false` and `startretries=0` (one-shot execution). | Implemented |

### FR-9: Pre-installed Toolchains

| ID | Requirement | Status |
|----|-------------|--------|
| FR-9.1 | The image MUST include Zsh with Oh-My-Zsh as the default shell. | Implemented |
| FR-9.2 | The image MUST include NVM with the latest Node.js LTS version and pnpm pre-installed. | Implemented |
| FR-9.3 | The image MUST include Bun as an alternative JavaScript runtime. | Implemented |
| FR-9.4 | The image MUST include Git and the GitHub CLI (`gh`). | Implemented |
| FR-9.5 | The image MUST include Python 3 and pip. | Implemented |
| FR-9.6 | The image MUST include standard build tools (`build-essential`). | Implemented |

---

## 3. Non-Functional Requirements

### NFR-1: Performance

| ID | Requirement | Status |
|----|-------------|--------|
| NFR-1.1 | Container startup (from `docker compose up` to accessible IDE) MUST complete within 30 seconds when the autoinstall hash matches (no package changes). | Not verified |
| NFR-1.2 | The autoinstall hash check MUST add no more than 1 second to startup when configuration is unchanged. | Implemented |
| NFR-1.3 | The bootstrap extraction (first-time initialization) SHOULD complete within 10 seconds on modern hardware. | Not verified |

### NFR-2: Security

| ID | Requirement | Status |
|----|-------------|--------|
| NFR-2.1 | Plaintext passwords MUST NOT appear in the running Caddyfile; only bcrypt hashes are permitted. | Implemented |
| NFR-2.2 | The container user (`superuser`) MUST have passwordless sudo access for system-level operations (APT installs, ownership changes). | Implemented |
| NFR-2.3 | Code-Server internal authentication MUST be disabled (`--auth none`) since Caddy handles auth at the gateway. | Implemented |
| NFR-2.4 | No secrets or credentials SHOULD be committed to the repository. The `.env` file MUST be gitignored. | Implemented |

### NFR-3: Portability

| ID | Requirement | Status |
|----|-------------|--------|
| NFR-3.1 | The Docker image MUST support both `linux/amd64` and `linux/arm64` architectures. | Implemented |
| NFR-3.2 | All downloaded binaries (ttyd, Zellij, Bun) MUST be fetched for the correct target architecture at build time. | Implemented |
| NFR-3.3 | The Workbench MUST function on Docker Desktop for macOS, Linux, and Windows (via WSL2). | Partially verified |

### NFR-4: Maintainability

| ID | Requirement | Status |
|----|-------------|--------|
| NFR-4.1 | All external tool versions MUST be pinned via Dockerfile `ARG` declarations (ttyd, Zellij, Bun, Code-Server, NVM). | Implemented |
| NFR-4.2 | Version upgrades MUST be achievable by changing a single `ARG` value and rebuilding. | Implemented |
| NFR-4.3 | The Dockerfile MUST use multi-stage builds to separate download/build concerns from the runtime image. | Implemented |
| NFR-4.4 | Scripts MUST use `set -e` (or equivalent) for fail-fast behavior. | Implemented |

### NFR-5: Reproducibility

| ID | Requirement | Status |
|----|-------------|--------|
| NFR-5.1 | A developer cloning the repository MUST be able to build and run the Workbench with only Docker and Docker Compose installed on the host. | Implemented |
| NFR-5.2 | The `autoinstall.json` mechanism MUST allow teams to commit a shared tool manifest so all developers get the same global packages. | Implemented |

---

## 4. Integration Requirements

### IR-1: Docker Ecosystem

| ID | Requirement | Status |
|----|-------------|--------|
| IR-1.1 | The image MUST be publishable to `ghcr.io/newpush-labs/workbench`. | Implemented |
| IR-1.2 | The `docker-compose.yml` MUST reference the GHCR image for pre-built usage. | Implemented |
| IR-1.3 | The GitHub Actions CI workflow MUST support multi-platform builds and pushes. | Implemented |

### IR-2: External Tool Compatibility

| ID | Requirement | Status |
|----|-------------|--------|
| IR-2.1 | NVM-managed Node.js versions MUST persist in `/workspace/.nvm` across container restarts. | Implemented |
| IR-2.2 | Bun global packages MUST persist in `/workspace/.bun` across container restarts. | Implemented |
| IR-2.3 | Oh-My-Zsh plugins and themes MUST persist in `/workspace/.oh-my-zsh` across container restarts. | Implemented |

---

## 5. Current Status and Implementation Gaps

### 5.1 Implemented and Stable

All core functional requirements (FR-1 through FR-9) are implemented. The Workbench provides a fully functional containerized development environment with persistent state, unified access routing, basic authentication, and automated toolchain management.

### 5.2 Known Gaps and Future Considerations

| Area | Gap | Priority |
|------|-----|----------|
| Testing | No automated test suite exists. The DEV_AGENT_PROMPT recommends BATS for shell scripts and pytest for Python, but no `tests/` directory is present. | High |
| HTTPS/TLS | Caddy is configured for HTTP only. Production or remote-access deployments would benefit from automatic TLS via Caddy's built-in ACME support. | Medium |
| Multi-user | The environment supports only a single user (`superuser`). Shared or multi-tenant use cases are not addressed. | Low |
| Healthcheck | No Docker `HEALTHCHECK` instruction is defined, making it harder for orchestrators to determine container readiness. | Medium |
| `.env.example` | Referenced in documentation but not present in the repository. Should be committed as a template. | Medium |
| Graceful shutdown | No explicit signal handling in `entrypoint.sh` for clean Zellij/Code-Server termination on `docker stop`. | Low |
| Log management | Supervisord logs to `/tmp/supervisord.log` inside the ephemeral container filesystem. Logs are lost on container recreation. | Low |

---

## 6. Acceptance Criteria

A contribution or release is considered complete when:

1. All modified or newly added functional requirements pass manual verification.
2. No existing requirements regress (the Docker image builds successfully on both amd64 and arm64).
3. Documentation in `docs/` is updated to reflect any changes.
4. The `DEV_AGENT_PROMPT.md` workflow (plan, document, test, code, verify) has been followed.
5. Version-pinned dependencies have not been unpinned or set to floating versions.
6. The container starts, bootstraps (if needed), and serves both the terminal and IDE within the performance targets defined in NFR-1.

---

## Revision History

| Date | Author | Change |
|------|--------|--------|
| 2026-04-09 | Dev Agent | Initial creation based on repository analysis (closes #2) |
