# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a comprehensive personal NixOS configuration repository using Nix flakes for multiple machines and servers. It manages configurations for desktop environments (Wayland/Sway with HiDPI support), personal and work laptops, servers with container orchestration, and WSL environments.

## Common Development Commands

All commands should be run from the repository root using the provided Makefile:

### Primary Build Commands
- `make switch` - Apply configuration changes to current system (most common)
- `make boot` - Apply configuration for next boot only  
- `make test` - Test configuration without applying
- `make show-trace` - Debug build issues with full trace output
- `make offline` - Build without network access

### Update Commands
- `make update` - Update all flake inputs
- `make upgrade` - Update flake inputs and switch configuration
- `make update-local` - Update only local flake inputs (remarkable, dcc)
- `make update-nflx` - Update Netflix work-specific inputs
- `make update-secrets` - Update secrets flake input

### Maintenance Commands
- `make gc` - Garbage collect old generations and unused store entries
- `make get-new-packages` - Compare packages between current and stable nixpkgs
- `make clear-gpu-cache` - Clear browser GPU caches (fixes common issues)

### Prerequisites
- `nom` (nix-output-monitor) must be installed: `nix-shell -p nix-output-monitor`
- Run from repository root where flake.nix is located
- Hostname must match one of the configured hosts

## Architecture

### Host Configuration Structure
Five configured hosts in `hosts/` directory:
- `nflx-erahhal-x1c` - Netflix work laptop (ThinkPad X1 Carbon)
- `antikythera` - Personal laptop (ThinkPad P14s AMD Gen4)  
- `upaya` - Personal laptop (Dell XPS 15-9560)
- `sicmundus` - Server configuration
- `msi-desktop` - WSL configuration

Each host contains:
- `configuration.nix` - Main NixOS configuration
- `params.nix` - Host-specific parameters
- `kanshi.nix` - Display management configuration
- `launch-apps-config-*.nix` - Application launcher configs per window manager

### Modular Configuration System

**`profiles/`** - Feature-based configurations that can be mixed and matched:
- Hardware profiles: `gfx-nvidia.nix`, `gfx-intel.nix`, `laptop-hardware.nix`
- Software profiles: `desktop.nix`, `steam.nix`, `android.nix`
- Service profiles: `pipewire.nix`, `tailscale.nix`, `mullvad.nix`

**`home/`** - Home Manager configurations:
- `user.nix` - Base user configuration with ZSH setup
- `desktop.nix` - Desktop environment configuration
- `profiles/` - Application-specific home configs (nvim, waybar, sway, etc.)

**`modules/`** - Custom NixOS modules for services not in nixpkgs

**`overlays/`** - Package customizations (Wayland patches, HiDPI fixes, hardware-specific modifications)

**`pkgs/`** - Custom package derivations for software not available in nixpkgs

**`containers/`** - Docker/Podman service configurations for self-hosted applications

### Key Configuration Files
- `user-params.nix` - Global user settings (username: erahhal, shell: zsh, terminal: foot)
- `flake.nix` - Central flake with inputs from multiple nixpkgs channels (stable, unstable, trunk)
- Individual host `params.nix` files define machine-specific settings

## Development Workflow

### Making Configuration Changes
1. Edit relevant configuration files
2. Run `make switch` to apply changes
3. The build process automatically clears caches and updates permissions
4. Theme switching is handled automatically if system theme changes

### Testing Changes
- Use `make test` for non-persistent testing
- Use `make show-trace` when debugging build failures
- Check `make get-new-packages` to see what packages changed

### Common Issues Resolution
- GPU cache issues: Automatically cleared during switch
- SDDM cache issues: Automatically cleared during switch  
- Theme inconsistencies: Automatic theme restoration after builds
- Permission issues: GnuPG permissions automatically updated

### Secrets Management
- Uses both SOPS-nix and agenix for different types of secrets
- Private flakes handle work-specific and sensitive configurations
- Never commit sensitive information directly to the repository

## Multi-Channel Package Management

The configuration uses multiple nixpkgs channels:
- **nixpkgs** (unstable) - Primary channel for most packages
- **nixpkgs-trunk** - Latest packages from master (may be broken)
- **nixpkgs-erahhal** - Personal fork with custom package updates
- Package-specific channels for bleeding-edge software when needed

## Desktop Environment

- **Primary**: Sway (Wayland compositor)
- **Alternative**: Hyprland, i3 (X11 fallback)
- **HiDPI**: 2x scaling configured across all applications
- **Audio**: PipeWire with full multimedia stack
- **Display Management**: Kanshi for multi-monitor configurations per host

## Hardware Support

Extensive hardware support including:
- Multiple GPU vendors (Intel, AMD, NVIDIA) with proper switching
- Laptop-specific optimizations (TLP, fingerprint readers, dock support)
- Custom hardware modules for specific devices (ThinkPad docks, Dell tools)