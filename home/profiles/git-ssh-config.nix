{ lib, ... }:

{
  home.activation.updateGitConfig = lib.hm.dag.entryAfter [ "installPackages" ] ''
      CONFIG_FILE="$HOME/.ssh/config"
      touch $CONFIG_FILE

      # Markers that define the boundaries of our managed configuration
      START_MARKER="## START: Extra Git config from Nix home-manager"
      END_MARKER="## END: Extra Git config from Nix home-manager"

      # The desired configuration content (without markers)
      DESIRED_CONTENT="Host erahhal-github
          HostName github.com
          User git
          IdentityFile ~/.ssh/id_rsa
      Host turingtesttwister-github
          HostName github.com
          User git
          IdentityFile ~/.ssh/id_rsa_turing_test_twister"

      # Check if both markers exist
      if grep -q "''${START_MARKER}" "$CONFIG_FILE" 2>/dev/null && grep -q "''${END_MARKER}" "$CONFIG_FILE" 2>/dev/null; then
          echo "Found existing managed section in $CONFIG_FILE, checking for changes..."

          # Extract current content between markers
          CURRENT_CONTENT=$(sed -n "/''${START_MARKER}/,/''${END_MARKER}/p" "$CONFIG_FILE" | sed '1d;$d')

          # Compare current content with desired content
          if [ "$CURRENT_CONTENT" != "$DESIRED_CONTENT" ]; then
              echo "Configuration has changed, updating managed section..."

              # Create a temporary file with the updated content
              TEMP_FILE=$(mktemp)

              # Copy everything before the start marker
              sed "/''${START_MARKER}/,/''${END_MARKER}/d" "$CONFIG_FILE" > "$TEMP_FILE"

              # Add the new managed section
              cat <<EOF >> "$TEMP_FILE"
      ''${START_MARKER}
      $DESIRED_CONTENT
      ''${END_MARKER}
      EOF

              # Replace the original file
              mv "$TEMP_FILE" "$CONFIG_FILE"
              echo "Updated managed configuration in $CONFIG_FILE"
          else
              echo "Configuration is up to date in $CONFIG_FILE"
          fi

      elif grep -q "''${START_MARKER}" "$CONFIG_FILE" 2>/dev/null || grep -q "''${END_MARKER}" "$CONFIG_FILE" 2>/dev/null; then
          echo "Warning: Found incomplete markers in $CONFIG_FILE, cleaning up and re-adding..."

          # Remove any existing partial markers and content
          TEMP_FILE=$(mktemp)
          grep -v "''${START_MARKER}" "$CONFIG_FILE" | grep -v "''${END_MARKER}" > "$TEMP_FILE"

          # Add the complete managed section
          cat <<EOF >> "$TEMP_FILE"
      ''${START_MARKER}
      $DESIRED_CONTENT
      ''${END_MARKER}
      EOF

          mv "$TEMP_FILE" "$CONFIG_FILE"
          echo "Cleaned up and added managed configuration to $CONFIG_FILE"

      else
          echo "No existing managed section found, adding configuration to $CONFIG_FILE"
          cat <<EOF >> "$CONFIG_FILE"
      ''${START_MARKER}
      $DESIRED_CONTENT
      ''${END_MARKER}
      EOF
      fi
    '';
}
