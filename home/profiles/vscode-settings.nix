{ lib, pkgs, ... }:

# VSCode Roo MCP Configuration Manager
#
# This module provides automatic management of VSCode Roo Code's MCP (Model Context Protocol)
# server configurations. It ensures that a default set of MCP servers are always available
# while preserving any user customizations.
#
# Now uses the generalized json-config-manager.nix module for robust JSON configuration management.
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
# ~/.config/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/mcp_settings.json
#
# Usage:
# Simply import this module in your home-manager configuration. The activation script
# will run automatically during home-manager switches and ensure your MCP configuration
# is up to date.

{
  # Import the generalized JSON config manager module
  imports = [
    ../modules/json-config-manager.nix
  ];

  # Configure VSCode Roo MCP using the generalized module
  services.jsonConfigManager.vscode-roo-mcp = {
    enable = true;

    configFile = "$HOME/.config/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/mcp_settings.json";

    # Default MCP server configurations
    # These will be merged with any existing configuration, with user settings taking precedence
    defaultConfig = {
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

    # The MCP configuration needs to be wrapped under the "mcpServers" key
    configKey = "mcpServers";

    description = "VSCode Roo MCP Server Configuration";

    # Enable backups for safety
    createBackups = true;

    # Ensure jq is available for JSON manipulation
    packages = with pkgs; [ jq ];
  };

  # Configure VSCode Roo MCP using the generalized module
  services.jsonConfigManager.vscode-settings = {
    enable = true;

    configFile = "$HOME/.config/Code/User/settings.json";

    # Default MCP server configurations
    # These will be merged with any existing configuration, with user settings taking precedence
    defaultConfig = {
      "workbench.colorTheme" = "Tokyo (Dark)";
      "extensions.experimental.affinity" = {
        "asvetliakov.vscode-neovim" = 1;
      };
      "telemetry.editStats.enabled" = false;
      "telemetry.feedback.enabled" = false;
      "telemetry.telemetryLevel" = "off";
    };

    description = "VSCode General Configuration";

    # Enable backups for safety
    createBackups = true;

    # Ensure jq is available for JSON manipulation
    packages = with pkgs; [ jq ];
  };
}
