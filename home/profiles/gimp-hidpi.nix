{ lib, ... }:
{
  # Add high dpi theme for FIMP
  home.activation.gimpSettings = lib.hm.dag.entryAfter [ "installPackages" ]
    ''
      CONFIG_FILE="~/.config/zoomus.conf"

      mkdir -p ~/.config
      touch ~/.config/zoomus.conf

      local temp_file=$(mktemp)
      local general_found=false
      local scale_factor_set=false

      # Read the file line by line
      while IFS= read -r line || [[ -n "$line" ]]; do
          # Check if we're in the [General] section
          if [[ "$line" =~ ^\[General\]$ ]]; then
              general_found=true
              echo "$line" >> "$temp_file"
          # Check if we hit another section after [General]
          elif [[ "$line" =~ ^\[.*\]$ ]] && [[ "$general_found" == true ]]; then
              # Add scaleFactor if we haven't set it yet
              if [[ "$scale_factor_set" == false ]]; then
                  echo "scaleFactor=2" >> "$temp_file"
                  scale_factor_set=true
              fi
              general_found=false
              echo "$line" >> "$temp_file"
          # Check if this is the scaleFactor line in [General] section
          elif [[ "$general_found" == true ]] && [[ "$line" =~ ^scaleFactor= ]]; then
              echo "scaleFactor=2" >> "$temp_file"
              scale_factor_set=true
          else
              echo "$line" >> "$temp_file"
          fi
      done < "$CONFIG_FILE"

      # If we found [General] but never set scaleFactor, add it at the end
      if [[ "$general_found" == true ]] && [[ "$scale_factor_set" == false ]]; then
          echo "scaleFactor=2" >> "$temp_file"
      fi

      # If we never found [General] section, add it
      if [[ "$general_found" == false ]]; then
          echo "" >> "$temp_file"  # Add blank line for readability
          echo "[General]" >> "$temp_file"
          echo "scaleFactor=2" >> "$temp_file"
      fi

      # Replace original file with modified version
      mv "$temp_file" "$CONFIG_FILE"
    '';
}
