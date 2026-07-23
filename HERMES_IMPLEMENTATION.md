# Hermes AI Agent Implementation Summary

This document summarizes the implementation of Hermes AI agent integration into the nixcfg repository.

## What Was Added

### 1. Package Derivation (`pkgs/hermes/default.nix`)
- Created a Nix package for Hermes AI agent (v0.19.0)
- Uses PyPI wheel format for installation
- Includes all necessary system dependencies (git, ffmpeg, ripgrep, etc.)
- Manages Hermes's own Python environment via `uv`

### 2. AI Coding Module Updates (`modules/programs/ai-coding/default.nix`)
- Added `hermes` package via `callPackage`
- Added `hermes-logistikon` wrapper script that:
  - Configures Hermes to use local genai-server at `logistikon.lan:4000`
  - Sets isolated config/data directories (`~/.hermes-logistikon`)
- Added declarative config management:
  - Creates `~/.hermes/config.yaml` with Nix
  - Points to local genai-server provider (LiteLLM)
  - Includes same models as opencode: coder-pro, qwen-dense, glm-flash, qwen, research

### 3. Documentation (`pkgs/hermes/README.md`)
- Comprehensive documentation of the package
- Integration details with local genai-server
- Usage examples and configuration guide

## Package Installation

The hermes CLI is installed to `~/.nix-profile/bin/hermes` via home-manager.

## Usage

### With Local Genai-Server (Pre-configured)
```bash
hermes-logistikon
```

### Default Hermes (Can be configured)
```bash
hermes
```

## Key Design Decisions

1. **Separate Wrapper Scripts**: Created `hermes-logistikon` wrapper that sets environment variables and isolated config directories, similar to how `claude-logistikon` and `opencode-openrouter` work.

2. **Declarative Config**: The Hermes config is managed by Nix at `xdg.configFile."hermes/config.yaml"`, ensuring consistent configuration across systems.

3. **Minimal Dependencies**: The package includes only what's necessary for the hermes CLI to function, leveraging hermes's own uv-managed Python environment for additional dependencies.

4. **Same Models as opencode**: The hermes config uses the same models as opencode (coder-pro, qwen-dense, etc.) for consistency.

## Files Modified/Created

### Created:
- `pkgs/hermes/default.nix` - Package derivation
- `pkgs/hermes/README.md` - Package documentation

### Modified:
- `modules/programs/ai-coding/default.nix` - Added hermes integration

## Testing

To test the implementation:

```bash
# Check if hermes is available
nix build .#hermes

# Test hermes-logistikon
hermes-logistikon --help
```

## Notes

- Hermes is not installed on Netflix hosts (nflxHost) as they use nflx-nixcfg's version
- The config file is declaratively managed and will be regenerated on each nixos-rebuild
- The wrapper scripts provide isolated environments for better configuration management
