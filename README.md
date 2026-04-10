NixOS Config
============

Personal NixOS configuration for desktops, laptops, and a WSL host, using flake-parts.

## Hosts

| Host | Description | Window Manager |
|------|-------------|----------------|
| antikythera | Lenovo ThinkPad (AMD) | Niri / Hyprland |
| nflx-erahhal-p16 | ThinkPad P16 (NVIDIA + Intel) | Niri / Hyprland |
| msi-linux | MSI laptop | Niri / Hyprland |
| upaya | Dell XPS 9560 | Hyprland |
| msi-desktop | MSI desktop (WSL) | headless |

## Key Features

- Wayland desktop: Niri (default), Hyprland (available)
- Display manager: dms-shell
- Audio: PipeWire
- Terminal: foot
- Networking: NetworkManager with iwd
- Browsers: Brave, Firefox
- Theming: nix-colors
- Secrets: agenix + sops-nix (via nixcfg-secrets)
- Disk: disko (BTRFS + LUKS)
- Secure boot: lanzaboote
- VPN: Tailscale with Headscale

## Flake Apps

Run from the repo directory:

```
nix run .#switch            # Build and switch to new configuration
nix run .#debug             # Build with debug mode and --show-trace
nix run .#boot              # Build for next boot only
nix run .#show-trace        # Switch with --show-trace
nix run .#offline           # Switch offline (no downloads)
nix run .#nflx-local        # Override nflx-nixcfg with local checkout
nix run .#nflx-vpn          # Override nflx-nixcfg + openconnect with local
nix run .#nixvim-local      # Override nixvim-config with local checkout
nix run .#secrets-local     # Override secrets with local checkout
nix run .#update            # nix flake update
nix run .#update-nflx       # Update nflx-related inputs only
nix run .#update-secrets    # Update secrets input only
nix run .#upgrade           # Update flake + switch
nix run .#gc                # Garbage collect
nix run .#remote-install    # Install to remote host via nixos-anywhere
nix run .#get-new-packages  # Compare current system to new build with nvd
```

## Repo Layout

- `docs/` - Documentation (COOKBOOK, etc.)
- `flake-modules/` - Flake-parts modules: host configs, apps, home-manager, nixos module exports
- `lib/` - Shared helpers: host-params options, recursive-merge, shared module lists
- `modules/` - NixOS and home-manager modules, organized by concern:
  - `base-user/` - User account, shell, home-manager base config
  - `base-desktop/` - Common desktop packages and settings
  - `desktop/` - Window managers, terminals, theming, apps
  - `hardware/` - GPU drivers, peripherals, laptop support
  - `hosts/` - Per-host configuration and params
  - `networking/` - Tailscale, captive portal, etc.
  - `programs/` - Steam, Android, etc.
  - `services/` - VMs, Waydroid, Snapcast, etc.
  - `system/` - Boot, security, packages, overlays, networking
  - `overrides/` - Package overrides
- `nixos-anywhere/` - Remote installation script
- `overlays/` - Nixpkgs overlays
- `pkgs/` - Custom packages/derivations not in nixpkgs
- `scripts/` - Utility shell scripts (managed via home-manager)
- `wallpapers/` - Background images

## Setup Guides

- [ProtonMail Bridge + Thunderbird](docs/protonmail-bridge-setup.md)
