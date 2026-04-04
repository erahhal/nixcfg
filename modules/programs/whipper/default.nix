{ pkgs, lib, config, ... }:
let
  # Pre-defined config values for whipper
  # Section names are drive identifiers in URL-encoded format
  # Keys within each section are updated to these values; unknown keys are preserved
  whipperConfig = {
    "drive:TSSTcorp%3ADVD%2B-RW%20TS-L633C%3AD300" = {
      vendor = "TSSTcorp";
      model = "DVD+-RW TS-L633C";
      release = "D300";
      defeats_cache = "True";
      read_offset = "+6";
    };
  };

  # Convert Nix config to JSON for Python script
  configJson = builtins.toJSON whipperConfig;

  # Python script to merge INI config
  # - Creates config file if it doesn't exist
  # - Adds missing sections from pre-defined config
  # - Updates existing keys to pre-defined values
  # - Preserves user-added keys not in pre-defined config
  mergeScript = pkgs.writeScript "merge-whipper-config" ''
    #!${pkgs.python3}/bin/python3
    import configparser
    import json
    import os
    import sys

    def merge_config(config_path, defaults_json):
        # Parse the pre-defined config from JSON
        defaults = json.loads(defaults_json)

        # Create config directory if needed
        config_dir = os.path.dirname(config_path)
        if config_dir and not os.path.exists(config_dir):
            os.makedirs(config_dir)

        # Read existing config or create empty one
        config = configparser.ConfigParser()
        # Preserve case of keys
        config.optionxform = str

        if os.path.exists(config_path):
            config.read(config_path)

        # Merge pre-defined values
        for section, keys in defaults.items():
            # Create section if it doesn't exist
            if not config.has_section(section):
                config.add_section(section)

            # Update/add keys from pre-defined config
            for key, value in keys.items():
                config.set(section, key, value)

        # Write the merged config
        with open(config_path, 'w') as f:
            config.write(f)

    if __name__ == "__main__":
        if len(sys.argv) != 2:
            print(f"Usage: {sys.argv[0]} <config_path>", file=sys.stderr)
            sys.exit(1)

        config_path = sys.argv[1]
        defaults_json = '${lib.escape ["'" "\\"] configJson}'

        merge_config(config_path, defaults_json)
  '';
in
{
  home.activation.whipperConfig = lib.hm.dag.entryAfter ["linkGeneration"] ''
    ${mergeScript} "${config.xdg.configHome}/whipper/whipper.conf"
  '';
}
