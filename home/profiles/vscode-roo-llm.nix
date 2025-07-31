{ lib, pkgs, ... }:

# VSCode Roo LLM Configuration Manager
#
# This module provides automatic management of VSCode Roo Code's LLM (Large Language Model)
# configurations stored in the VSCode SQLite database. It ensures that default LLM settings
# are available while preserving any user customizations.
#
# Features:
# - Automatically adds/updates default LLM configurations in SQLite database
# - Preserves existing user customizations and additional settings
# - Creates backups before making changes
# - Handles database corruption gracefully
# - Idempotent - safe to run multiple times
# - Only updates when changes are detected
#
# Configuration Location:
# ~/.config/VSCode/User/globalStorage/state.vscdb (SQLite database)
# Key: 'RooVeterinaryInc.roo-cline'
#
# Usage:
# Simply import this module in your home-manager configuration. The activation script
# will run automatically during home-manager switches and ensure your LLM configuration
# is up to date.

let
  # Default LLM configuration settings
  # These will be merged with any existing configuration, with user settings taking precedence
  defaultLlmConfig = {
    apiProvider = "anthropic";
    anthropicBaseUrl = "http://mgp.local.dev.netflix.net:9123/proxy/erahhaldevtools";
    apiModelId = "claude-sonnet-4-20250514";
    currentApiConfigName = "Netflix";
    listApiConfigMeta = [
      {
        name = "default";
        id = "ej8k08jgq4c";
        apiProvider = "openai";
      }
      {
        name = "Netflix";
        id = "rw12r18xlln";
        apiProvider = "anthropic";
      }
    ];
    telemetrySetting = "disabled";
    mcpEnabled = true;
    autoApprovalEnabled = true;
    mode = "code";
  };

  # Convert Nix attrset to JSON string
  defaultLlmJson = builtins.toJSON defaultLlmConfig;

  # Escape bash variables so they aren't interpolated by home-manager during activation
  activationScript = ''
    # VSCode Roo LLM Configuration Update Script
    echo "Updating VSCode Roo LLM configuration..."

    # Define paths
    VSCODE_GLOBAL_STORAGE="$HOME/.config/Code/User/globalStorage"
    STATE_DB="$VSCODE_GLOBAL_STORAGE/state.vscdb"
    BACKUP_DB="$STATE_DB.backup.$(date +%Y%m%d_%H%M%S)"
    ROO_CONFIG_KEY="RooVeterinaryInc.roo-cline"

    # Create directory if it doesn't exist
    mkdir -p "$VSCODE_GLOBAL_STORAGE"

    # Default configuration as JSON
    DEFAULT_CONFIG='${defaultLlmJson}'

    # Function to merge JSON configurations
    merge_llm_config() {
      local existing_config="$1"
      local default_config="$2"

      # Use jq to perform deep merge where defaults are added/updated but existing configs are preserved
      echo "$existing_config" | ${pkgs.jq}/bin/jq --argjson defaults "$default_config" '
        # Merge: existing first, then defaults (existing entries take precedence)
        . + $defaults |

        # Special handling for arrays that should be merged intelligently
        if .listApiConfigMeta and $defaults.listApiConfigMeta then
          .listApiConfigMeta = (
            # Create a map of existing configs by id for deduplication
            (.listApiConfigMeta | map({(.id): .}) | add) as $existing_map |
            # Create a map of default configs by id
            ($defaults.listApiConfigMeta | map({(.id): .}) | add) as $default_map |
            # Merge maps (existing takes precedence) and convert back to array
            ($existing_map + $default_map | to_entries | map(.value))
          )
        else . end
      '
    }

    # Function to initialize database if it doesn't exist
    init_database() {
      echo "Initializing new VSCode state database..."
      ${pkgs.sqlite}/bin/sqlite3 "$STATE_DB" "CREATE TABLE IF NOT EXISTS ItemTable (key TEXT PRIMARY KEY, value TEXT);"
    }

    # Function to get current config from database
    get_current_config() {
      ${pkgs.sqlite}/bin/sqlite3 "$STATE_DB" "SELECT value FROM ItemTable WHERE key = '$ROO_CONFIG_KEY';" 2>/dev/null || echo "{}"
    }

    # Function to update config in database
    update_config() {
      local new_config="$1"
      # Write JSON to temporary file to avoid quoting issues
      local temp_file=$(mktemp)
      echo "$new_config" > "$temp_file"
      # Use .import or a here-doc approach to safely insert the JSON
      ${pkgs.sqlite}/bin/sqlite3 "$STATE_DB" <<EOF
INSERT OR REPLACE INTO ItemTable (key, value) VALUES ('$ROO_CONFIG_KEY', readfile('$temp_file'));
EOF
      rm "$temp_file"
    }

    # Check if database exists
    if [ -f "$STATE_DB" ]; then
      echo "Found existing VSCode state database at $STATE_DB"

      # Test if database is accessible
      if ${pkgs.sqlite}/bin/sqlite3 "$STATE_DB" ".tables" >/dev/null 2>&1; then
        echo "Database is accessible"

        # Create backup
        cp "$STATE_DB" "$BACKUP_DB"
        echo "Created backup at $BACKUP_DB"

        # Get existing configuration
        EXISTING_CONFIG=$(get_current_config)

        if [ "$EXISTING_CONFIG" = "" ] || [ "$EXISTING_CONFIG" = "{}" ]; then
          echo "No existing Roo configuration found, creating with defaults"
          update_config "$DEFAULT_CONFIG"
          echo "Created new Roo LLM configuration in database"
        else
          echo "Found existing Roo configuration, merging with defaults"

          # Validate existing JSON
          if echo "$EXISTING_CONFIG" | ${pkgs.jq}/bin/jq empty 2>/dev/null; then
            echo "Existing configuration is valid JSON"

            # Merge configurations
            MERGED_CONFIG=$(merge_llm_config "$EXISTING_CONFIG" "$DEFAULT_CONFIG")

            # Check if configuration actually changed
            if [ "$EXISTING_CONFIG" != "$MERGED_CONFIG" ]; then
              echo "Configuration changes detected, updating..."
              update_config "$MERGED_CONFIG"
              echo "Roo LLM configuration updated successfully"
            else
              echo "No changes needed, configuration is already up to date"
              # Remove unnecessary backup
              rm "$BACKUP_DB"
            fi
          else
            echo "Warning: Existing configuration is not valid JSON, replacing with defaults"
            update_config "$DEFAULT_CONFIG"
            echo "Replaced with default Roo LLM configuration"
          fi
        fi
      else
        echo "Warning: Database exists but is not accessible, reinitializing"
        # Create backup of corrupted database
        cp "$STATE_DB" "$BACKUP_DB"
        echo "Created backup of corrupted database at $BACKUP_DB"

        # Reinitialize database
        rm "$STATE_DB"
        init_database
        update_config "$DEFAULT_CONFIG"
        echo "Reinitialized database with default Roo LLM configuration"
      fi
    else
      echo "No existing VSCode state database found, creating with defaults"
      init_database
      update_config "$DEFAULT_CONFIG"
      echo "Created new VSCode state database with Roo LLM configuration"
    fi

    # Set appropriate permissions
    chmod 644 "$STATE_DB"

    echo "VSCode Roo LLM configuration update completed"
  '';

in
{
  # Home activation script that runs after package installation
  home.activation.vsCodeRooLlm = lib.hm.dag.entryAfter [ "installPackages" ] activationScript;

  # Ensure required packages are available
  home.packages = with pkgs; [
    jq      # Required for JSON manipulation
    sqlite  # Required for SQLite database operations
  ];
}
