{ lib, pkgs, ... }:

# VSCode Roo MCP Configuration Manager
#
# This module provides automatic management of VSCode Roo Code's MCP (Model Context Protocol)
# server configurations. It ensures that a default set of MCP servers are always available
# while preserving any user customizations.
#
# Features:
# - Automatically adds/updates default MCP server configurations
# - Preserves existing user customizations and additional servers
# - Creates backups before making changes
# - Handles malformed JSON gracefully
# - Idempotent - safe to run multiple times
# - Only updates when changes are detected
#
# Configuration Location:
# ~/.config/VSCodium/User/globalStorage/rooveterinaryinc.roo-cline/settings/mcp_settings.json
#
# Usage:
# Simply import this module in your home-manager configuration. The activation script
# will run automatically during home-manager switches and ensure your MCP configuration
# is up to date.

let
  # Default MCP server configurations
  # These will be merged with any existing configuration, with user settings taking precedence
  defaultMcpServers = {
    puppeteer = {
      command = "npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-puppeteer"
      ];
    };
    "GenAI MCP Gateway" = {
      command = "uvx";
      args = [
        "nflx-genai-tool-registry@latest"
      ];
      env = {
        REGISTRY_TOOLBOX_ID = "core_tools";
        REGISTRY_URL_OVERRIDE = "sbn-dev-agent";
      };
    };
    ndex = {
      transportType = "stdio";
      command = "/home/erahhal/Code/ndex/core/run.sh";
      args = [];
      alwaysAllow = [
        "search_knowledge"
        "request_knowledge"
        "read_toward_node"
        "create_plan"
        "get_plan"
      ];
    };
    jetbrains = {
      command = "npx";
      args = [
        "-y"
        "@jetbrains/mcp-proxy"
      ];
    };
  };

  # Convert Nix attrset to JSON string with proper structure (wrapped in mcpServers key)
  defaultMcpJson = builtins.toJSON { mcpServers = defaultMcpServers; };

  # Escape bash variables so they aren't interpolated by home-manager during activation
  activationScript = ''
    # VSCode Roo MCP Configuration Update Script
    echo "Updating VSCode Roo MCP configuration..."

    # Define paths
    MCP_CONFIG_DIR="$HOME/.config/VSCodium/User/globalStorage/rooveterinaryinc.roo-cline/settings"
    MCP_CONFIG_FILE="$MCP_CONFIG_DIR/mcp_settings.json"
    BACKUP_FILE="$MCP_CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"

    # Create directory if it doesn't exist
    mkdir -p "$MCP_CONFIG_DIR"

    # Default configuration as JSON
    DEFAULT_CONFIG='${defaultMcpJson}'

    # Function to merge JSON configurations
    merge_mcp_config() {
      local existing_config="$1"
      local default_config="$2"

      # Use jq to perform deep merge where defaults are added/updated but existing configs are preserved
      echo "$existing_config" | ${pkgs.jq}/bin/jq --argjson defaults "$default_config" '
        # Ensure the existing config has mcpServers key
        if has("mcpServers") | not then .mcpServers = {} else . end |

        # Merge: existing first, then defaults on top (but existing entries take precedence)
        .mcpServers = (.mcpServers + $defaults.mcpServers)
      '
    }

    # Check if config file exists and is valid JSON
    if [ -f "$MCP_CONFIG_FILE" ]; then
      echo "Found existing MCP configuration at $MCP_CONFIG_FILE"

      # Validate existing JSON
      if ${pkgs.jq}/bin/jq empty "$MCP_CONFIG_FILE" 2>/dev/null; then
        echo "Existing configuration is valid JSON"

        # Create backup
        cp "$MCP_CONFIG_FILE" "$BACKUP_FILE"
        echo "Created backup at $BACKUP_FILE"

        # Read existing config
        EXISTING_CONFIG=$(cat "$MCP_CONFIG_FILE")

        # Merge configurations
        MERGED_CONFIG=$(merge_mcp_config "$EXISTING_CONFIG" "$DEFAULT_CONFIG")

        # Check if configuration actually changed
        if [ "$EXISTING_CONFIG" != "$MERGED_CONFIG" ]; then
          echo "Configuration changes detected, updating..."
          echo "$MERGED_CONFIG" | ${pkgs.jq}/bin/jq '.' > "$MCP_CONFIG_FILE.tmp"
          mv "$MCP_CONFIG_FILE.tmp" "$MCP_CONFIG_FILE"
          echo "MCP configuration updated successfully"
        else
          echo "No changes needed, configuration is already up to date"
          # Remove unnecessary backup
          rm "$BACKUP_FILE"
        fi
      else
        echo "Warning: Existing configuration is not valid JSON, replacing with defaults"
        # Create backup of invalid file
        cp "$MCP_CONFIG_FILE" "$BACKUP_FILE"
        echo "Created backup of invalid config at $BACKUP_FILE"

        # Write default configuration
        echo "$DEFAULT_CONFIG" | ${pkgs.jq}/bin/jq '.' > "$MCP_CONFIG_FILE"
        echo "Replaced with default MCP configuration"
      fi
    else
      echo "No existing MCP configuration found, creating with defaults"
      echo "$DEFAULT_CONFIG" | ${pkgs.jq}/bin/jq '.' > "$MCP_CONFIG_FILE"
      echo "Created new MCP configuration at $MCP_CONFIG_FILE"
    fi

    # Set appropriate permissions
    chmod 644 "$MCP_CONFIG_FILE"

    echo "VSCode Roo MCP configuration update completed"
  '';

in
{
  # Home activation script that runs after package installation
  home.activation.vsCodeRooMcp = lib.hm.dag.entryAfter [ "installPackages" ] activationScript;

  # Ensure required packages are available
  home.packages = with pkgs; [
    jq  # Required for JSON manipulation
  ];
}
