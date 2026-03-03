# Global ARGs for version pinning - these can be overridden via --build-arg
ARG TTYD_VERSION=1.7.7
ARG ZELLIJ_VERSION=v0.43.1
ARG BUN_VERSION=bun-v1.3.10
ARG CODE_SERVER_VERSION=4.109.5
ARG NVM_VERSION=v0.40.4

# --- Builder Stage ---
FROM debian:trixie-slim AS builder

RUN apt-get update && apt-get install -y wget curl unzip tar xz-utils

# Re-declare global ARGs in this stage to make them available
ARG TTYD_VERSION
ARG ZELLIJ_VERSION
ARG BUN_VERSION
ARG TARGETARCH

WORKDIR /downloads

# Download ttyd, zellij, and bun based on TARGETARCH
RUN case "${TARGETARCH}" in \
      "amd64") \
        TTYD_ARCH="x86_64" && \
        ZELLIJ_ARCH="x86_64-unknown-linux-musl" && \
        BUN_ARCH="x64" ;; \
      "arm64") \
        TTYD_ARCH="aarch64" && \
        ZELLIJ_ARCH="aarch64-unknown-linux-musl" && \
        BUN_ARCH="aarch64" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    # Download ttyd
    wget -q https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.${TTYD_ARCH} -O ttyd && \
    chmod +x ttyd && \
    # Download Zellij
    wget -q https://github.com/zellij-org/zellij/releases/download/${ZELLIJ_VERSION}/zellij-${ZELLIJ_ARCH}.tar.gz && \
    tar -xzf zellij-${ZELLIJ_ARCH}.tar.gz && \
    chmod +x zellij && \
    # Download Bun
    wget -q https://github.com/oven-sh/bun/releases/download/${BUN_VERSION}/bun-linux-${BUN_ARCH}.zip && \
    unzip bun-linux-${BUN_ARCH}.zip && \
    mv bun-linux-${BUN_ARCH}/bun bun && \
    chmod +x bun

# --- Final Stage ---
FROM debian:trixie-slim

# Avoid tzdata prompts
ENV DEBIAN_FRONTEND=noninteractive

# Re-declare global ARGs in this stage
ARG CODE_SERVER_VERSION
ARG NVM_VERSION

# Install all apt dependencies in one single RUN command to optimize layers
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    sudo \
    supervisor \
    python3 \
    python3-pip \
    git \
    build-essential \
    debian-keyring debian-archive-keyring apt-transport-https \
    ca-certificates \
    gnupg \
    unzip \
    zsh \
    # Download keyrings for gh, caddy, then update and install them
    && mkdir -p -m 755 /etc/apt/keyrings \
    # GitHub CLI
    && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    # Caddy
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg \
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list \
    # Update and install new repo packages
    && apt-get update \
    && apt-get install -y --no-install-recommends gh caddy \
    && rm -rf /var/lib/apt/lists/*

# Install code-server
RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- --version ${CODE_SERVER_VERSION}

# Copy binaries from builder
COPY --from=builder /downloads/ttyd /usr/local/bin/ttyd
COPY --from=builder /downloads/zellij /usr/local/bin/zellij
COPY --from=builder /downloads/bun /usr/local/bin/bun

# Create user with zsh as default shell (Home at /workspace)
RUN useradd -d /workspace -ms /usr/bin/zsh superuser && \
    echo "superuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up work directory
RUN mkdir -p /workspace && chown -R superuser:superuser /workspace
WORKDIR /workspace

# Copy configurations and scripts
COPY configs/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN chown superuser:superuser /etc/supervisor/conf.d/supervisord.conf
COPY configs/ /etc/workbench/
COPY scripts/ /usr/local/bin/workbench/

# Ensure scripts are owned by the user and executable
RUN chown -R superuser:superuser /etc/workbench /usr/local/bin/workbench && \
    chmod +x /usr/local/bin/workbench/*.sh /usr/local/bin/workbench/*.py

# Set up Zellij config (Template)
RUN mkdir -p /workspace/.config/zellij && \
    cp /etc/workbench/zellij.kdl /workspace/.config/zellij/config.kdl && \
    chown -R superuser:superuser /workspace/.config

# Install NVM, Node LTS, pnpm as superuser (into /workspace)
USER superuser
ENV NVM_DIR="/workspace/.nvm"
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install --lts && \
    nvm use --delete-prefix default && \
    npm install -g pnpm

# Install Oh My Zsh (into /workspace)
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Persist environment variables in the template home
RUN for file in .bashrc .zshrc; do \
    if [ "$file" = ".zshrc" ]; then \
        mkdir -p /workspace/.cache/zsh && \
        echo 'mkdir -p "$HOME/.cache/zsh"' > /tmp/zsh_header && \
        echo 'export ZSH_COMPDUMP="$HOME/.cache/zsh/zcompdump"' >> /tmp/zsh_header && \
        cat /workspace/.zshrc >> /tmp/zsh_header && \
        mv /tmp/zsh_header /workspace/.zshrc && \
        rm -f /workspace/.zcompdump* && \
        # Add welcome message
        echo 'source /usr/local/bin/workbench/show-welcome.sh' >> /workspace/.zshrc; \
    fi && \
    echo 'export NVM_DIR="$HOME/.nvm"' >> /workspace/$file && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /workspace/$file && \
    echo 'export BUN_INSTALL="$HOME/.bun"' >> /workspace/$file && \
    echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> /workspace/$file; \
    done

# Final Step: Create a bootstrap tarball of the HOME directory
USER root
RUN tar -czf /usr/src/home_bootstrap.tar.gz -C /workspace . && \
    chown superuser:superuser /usr/src/home_bootstrap.tar.gz

EXPOSE 8080

# Switch back to superuser
USER superuser
ENTRYPOINT ["/usr/local/bin/workbench/entrypoint.sh"]

# Start supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
