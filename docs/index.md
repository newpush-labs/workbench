# NewPush Labs Workbench Documentation

Welcome to the documentation for the NewPush Labs Workbench. This guide provides comprehensive details on the architecture, setup, and components that make up this containerized development environment.

## Table of Contents

- **[Getting Started](getting-started.md)**: Prerequisites, installation, and basic usage.
- **Architecture**
  - [Single Mount Architecture](architecture/single-mount.md): How we persist your configurations while keeping the system ephemeral.
  - [Routing & Authentication](architecture/routing-and-auth.md): The unified port 8080 access model via Caddy.
- **Components**
  - [Initialization](components/initialization.md): The container lifecycle and bootstrapping.
  - [Autoinstall System](components/autoinstall-system.md): Dynamic package management.
  - [Developer Experience](components/developer-experience.md): Terminal, IDE, and pre-installed tools.

## Introduction

The Workbench is designed to provide a consistent, zero-setup, and fully equipped development environment that integrates Zellij, Caddy, Code-Server, and automated toolchain management. It maps your local workspace to act as the container's home directory, ensuring that your dotfiles, Node modules, and Python packages persist across container rebuilds.
