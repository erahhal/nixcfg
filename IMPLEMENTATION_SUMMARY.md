# Hermes AI Agent - Declarative Installation Summary

## Overview
Successfully added and configured the Hermes AI coding agent from Nous Research to be installed and configured declaratively by this Nix configuration repository.

## Implementation Details

### 1. Package Derivation (`pkgs/hermes/default.nix`)
- **Format**: Python wheel from PyPI (hermes_agent v0.19.0)
- **Dependencies**: 
  - System tools: git, ffmpeg, ripgrep, gnused, grep, findutils, jq, curl, coreutils
  - Python: python-dotenv
  - Build: uv, nodejs
- **Entry Point**: `hermes` CLI command
- **License**: MIT
- **Platforms**: Linux and Darwin

### 2. Module Integration (`modules/programs/ai-coding/default.nix`)

#### Added Packages:
- `hermes`: Base Hermes CLI from PyPI
- `hermes-logistikon`: Wrapper script pre-configured for local genai-server

#### Configuration Management:
- Creates declarative config at `~/.hermes/config.yaml`
- Points to local genai-server provider (LiteLLM bridge at `logistikon.lan:4000`)
- Includes models: coder-pro, qwen-dense, glm-flash, qwen, research

#### Wrapper Script (`hermes-logistikon`):
- Sets `HERMES_CONFIG_DIR` and `HERMES_DATA_DIR` to isolated directories
- Automatically starts hermes with pre-configured settings
- Similar to `claude-logistikon` pattern

### 3. Files Created/Modified

**Created:**
- `pkgs/hermes/default.nix` - Package derivation
- `pkgs/hermes/README.md` - Package documentation
- `HERMES_IMPLEMENTATION.md` - Implementation summary

**Modified:**
- `modules/programs/ai-coding/default.nix` - Added hermes integration
  - Lines 14-18: Updated header comment
  - Lines 104-111: Added hermes package derivation
  - Lines 203-212: Added hermes-logistikon wrapper
  - Lines 214-261: Added hermesConfig and hermesConfigFile
  - Lines 269-276: Added hermes to home.packages
  - Lines 289-294: Added xdg.configFile for hermes config

## How to Use

### With Local Genai-Server (Recommended)
```bash
hermes-logistikon
```

### With Default Configuration
```bash
hermes
```

## Configuration Location
- Config file: `~/.hermes/config.yaml` (managed by Nix)
- Data directory: `~/.hermes/data/`
- Config dir for logistikon: `~/.hermes-logistikon/`

## Key Features

1. **Declarative Installation**: Hermes is installed via home-manager like other packages
2. **Pre-configured for Local Models**: Uses the same genai-server configuration as opencode
3. **Isolated Environments**: Wrapper scripts provide separate config directories
4. **Consistent Models**: Uses the same model set as opencode for consistency
5. **No Manual Setup**: Fully automated installation and configuration

## Notes

- Hermes is NOT installed on Netflix hosts (nflxHost) - they use nflx-nixcfg's version
- The package uses PyPI wheel format for faster installation
- Hermes manages its own Python environment via `uv` internally
- System dependencies are propagated to ensure all tools are available
- Config is regenerated on each nixos-rebuild for consistency
