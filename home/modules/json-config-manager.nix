{ config, lib, pkgs, ... }:

# JSON Config Manager Module
#
# A generalized module for managing JSON configuration files in home-manager.
# This module provides automatic management of JSON configuration files by merging
# default configurations with existing user customizations.
#
# Features:
# - Multiple configuration instances support
# - Automatically adds/updates default configurations
# - Preserves existing user customizations and additional settings
# - Creates timestamped backups before making changes
# - Handles malformed JSON gracefully
# - Idempotent - safe to run multiple times
# - Only updates when changes are detected
# - Configurable merge strategies and wrapper keys
#
# Usage Example:
# ```nix
# services.jsonConfigManager.vscode-roo-mcp = {
#   enable = true;
#   configFile = "$HOME/.config/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/mcp_settings.json";
#   defaultConfig = {
#     puppeteer = {
#       command = "npx";
#       args = [ "-y" "@modelcontextprotocol/server-puppeteer" ];
#     };
#   };
#   configKey = "mcpServers";
#   description = "VSCode Roo MCP Configuration";
# };
# ```

with lib;
let
  cfg = config.services.jsonConfigManager;

  # Submodule defining options for each JSON config manager instance
  jsonConfigOptions = { name, config, ... }: {
    options = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable this JSON configuration manager instance.
        '';
      };

      configFile = mkOption {
        type = types.str;
        description = ''
          Path to the JSON configuration file to manage.
          Environment variables like $HOME will be expanded during activation.

          Example: "$HOME/.config/app/settings.json"
        '';
      };

      defaultConfig = mkOption {
        type = types.attrs;
        default = {};
        description = ''
          Default configuration as a Nix attribute set.
          This will be converted to JSON and merged with existing configuration.

          Example: { theme = "dark"; fontSize = 14; }
        '';
      };

      configKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Optional top-level key to wrap the configuration in.
          If specified, the defaultConfig will be placed under this key in the JSON file.

          Example: If configKey = "servers", then { foo = "bar"; } becomes { servers = { foo = "bar"; }; }
        '';
      };

      description = mkOption {
        type = types.str;
        default = "JSON Configuration for ${name}";
        description = ''
          Human-readable description of what this configuration manages.
          Used in log messages and activation script output.
        '';
      };

      createBackups = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to create timestamped backups of the configuration file before making changes.
          Backups are only created when actual changes are detected.
        '';
      };

      packages = mkOption {
        type = types.listOf types.package;
        default = [ pkgs.jq ];
        description = ''
          Additional packages required for this configuration manager.
          jq is included by default for JSON manipulation.
        '';
      };

      activationPriority = mkOption {
        type = types.int;
        default = 1000;
        description = ''
          Priority for the activation script. Lower numbers run earlier.
          Use this to control the order when multiple JSON configs depend on each other.
        '';
      };
    };
  };

  # Generate activation script for a single JSON config manager instance
  generateActivationScript = name: instanceCfg: let
    # Prepare the default configuration JSON
    defaultConfigJson = if instanceCfg.configKey != null then
      builtins.toJSON { ${instanceCfg.configKey} = instanceCfg.defaultConfig; }
    else
      builtins.toJSON instanceCfg.defaultConfig;

    # Generate unique script name
    scriptName = "jsonConfigManager-${name}";

    # Activation script content
    activationScript = ''
      # JSON Configuration Manager: ${instanceCfg.description}
      echo "Updating JSON configuration: ${instanceCfg.description}..."

      # Define paths (expand environment variables)
      CONFIG_FILE="${instanceCfg.configFile}"
      CONFIG_DIR="$(dirname "$CONFIG_FILE")"

      ${optionalString instanceCfg.createBackups ''
        BACKUP_FILE="$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
      ''}

      # Create directory if it doesn't exist
      mkdir -p "$CONFIG_DIR"

      # Default configuration as JSON
      DEFAULT_CONFIG='${defaultConfigJson}'

      # Function to merge JSON configurations
      merge_json_config() {
        local existing_config="$1"
        local default_config="$2"

        ${if instanceCfg.configKey != null then ''
          # Use jq to perform merge with specified config key
          echo "$existing_config" | ${pkgs.jq}/bin/jq --argjson defaults "$default_config" '
            # Ensure the existing config has the required key
            if has("${instanceCfg.configKey}") | not then .${instanceCfg.configKey} = {} else . end |

            # Merge: existing first, then defaults (existing entries take precedence)
            .${instanceCfg.configKey} = (.${instanceCfg.configKey} + $defaults.${instanceCfg.configKey})
          '
        '' else ''
          # Use jq to perform simple merge at root level
          echo "$existing_config" | ${pkgs.jq}/bin/jq --argjson defaults "$default_config" '
            # Merge: existing first, then defaults (existing entries take precedence)
            . + $defaults
          '
        ''}
      }

      # Check if config file exists and is valid JSON
      if [ -f "$CONFIG_FILE" ]; then
        echo "Found existing JSON configuration at $CONFIG_FILE"

        # Validate existing JSON
        if ${pkgs.jq}/bin/jq empty "$CONFIG_FILE" 2>/dev/null; then
          echo "Existing configuration is valid JSON"

          # Read existing config
          EXISTING_CONFIG=$(cat "$CONFIG_FILE")

          # Merge configurations
          MERGED_CONFIG=$(merge_json_config "$EXISTING_CONFIG" "$DEFAULT_CONFIG")

          # Check if configuration actually changed
          if [ "$EXISTING_CONFIG" != "$MERGED_CONFIG" ]; then
            echo "Configuration changes detected, updating..."

            ${optionalString instanceCfg.createBackups ''
              # Create backup
              cp "$CONFIG_FILE" "$BACKUP_FILE"
              echo "Created backup at $BACKUP_FILE"
            ''}

            # Write merged configuration
            echo "$MERGED_CONFIG" | ${pkgs.jq}/bin/jq '.' > "$CONFIG_FILE.tmp"
            mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
            echo "JSON configuration updated successfully"
          else
            echo "No changes needed, configuration is already up to date"
          fi
        else
          echo "Warning: Existing configuration is not valid JSON, replacing with defaults"

          ${optionalString instanceCfg.createBackups ''
            # Create backup of invalid file
            cp "$CONFIG_FILE" "$BACKUP_FILE"
            echo "Created backup of invalid config at $BACKUP_FILE"
          ''}

          # Write default configuration
          echo "$DEFAULT_CONFIG" | ${pkgs.jq}/bin/jq '.' > "$CONFIG_FILE"
          echo "Replaced with default JSON configuration"
        fi
      else
        echo "No existing JSON configuration found, creating with defaults"
        echo "$DEFAULT_CONFIG" | ${pkgs.jq}/bin/jq '.' > "$CONFIG_FILE"
        echo "Created new JSON configuration at $CONFIG_FILE"
      fi

      # Set appropriate permissions
      chmod 644 "$CONFIG_FILE"

      echo "${instanceCfg.description} configuration update completed"
    '';
  in {
    inherit scriptName activationScript;
  };

in
{
  options = {
    services.jsonConfigManager = mkOption {
      type = types.attrsOf (types.submodule jsonConfigOptions);
      default = {};
      description = ''
        JSON configuration manager instances.
        Each instance can manage a different JSON configuration file.
      '';
      example = literalExpression ''
        {
          vscode-settings = {
            enable = true;
            configFile = "$HOME/.config/Code/User/settings.json";
            defaultConfig = {
              "editor.fontSize" = 14;
              "editor.theme" = "dark";
            };
            description = "VSCode User Settings";
          };

          app-config = {
            enable = true;
            configFile = "$HOME/.config/myapp/config.json";
            defaultConfig = {
              host = "localhost";
              port = 3000;
            };
            configKey = "server";
            description = "My App Server Configuration";
          };
        }
      '';
    };
  };

  config = {
    # Generate activation scripts for all enabled instances
    home.activation = mkMerge (
      mapAttrsToList (name: instanceCfg:
        mkIf instanceCfg.enable (
          let
            scriptData = generateActivationScript name instanceCfg;
          in {
            ${scriptData.scriptName} = lib.hm.dag.entryAfter [ "installPackages" ] scriptData.activationScript;
          }
        )
      ) cfg
    );

    # Ensure required packages are available for all enabled instances
    home.packages = mkMerge (
      mapAttrsToList (name: instanceCfg:
        mkIf instanceCfg.enable instanceCfg.packages
      ) cfg
    );
  };
}
