# Routing & Authentication

The Workbench consolidates multiple services into a single, secure entry point using **Caddy** as a reverse proxy.

## Methodology

Running an IDE (Code-Server) and a Web Terminal (ttyd) typically requires mapping multiple ports to the host machine (e.g., `8080` for Code-Server, `7681` for ttyd). This complicates firewall configurations and requires the user to remember multiple addresses.

The Workbench uses Caddy internally to bind to port `8080` and route traffic based on the URL path.

### The Caddyfile Configuration

The internal Caddyfile is configured to route traffic as follows:

- **`/ide/*`** routes to the internal Code-Server running on port `8443`.
- **`/*`** (everything else) routes to ttyd (Zellij) running on port `7681`.

This means a single `localhost:8080` handles the entire developer experience.

## Authentication System

Security is paramount, even for local development containers, as exposing ports can sometimes expose services to the local network or internet.

1. **Basic Authentication**: The entire `8080` port is protected by Caddy's basic authentication mechanism. 
2. **Dynamic Configuration (`setup-auth.py`)**: 
   Because Caddy requires hashed passwords in its Caddyfile, we cannot easily pass raw text from Docker environment variables directly into the configuration.
   
   During the container initialization (`entrypoint.sh`), the `setup-auth.py` script executes. It reads the `AUTH_USERNAME` and `AUTH_PASSWORD` environment variables provided in your `.env` file.
   - It runs the `caddy hash-password` command to securely encrypt the plaintext password.
   - It modifies the `/etc/workbench/Caddyfile`, replacing the `basic_auth` block with the newly hashed credentials.
   - If `AUTH_SKIP=true` is set, the script completely strips the `basic_auth` block from the Caddyfile, allowing unauthenticated access (useful for heavily isolated environments).

Once `setup-auth.py` completes, `supervisord` takes over and starts Caddy with the newly secured configuration.
