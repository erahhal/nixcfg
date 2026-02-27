{ broken, pkgs, userParams, ... }:

let
  mcreator = pkgs.callPackage ../../pkgs/mcreator {};
in
{
  environment.systemPackages = [
  ];

  home-manager.users.${userParams.username} = { lib, pkgs, ... }: {
    imports = [
      ./hyprland.nix
      ## Needed to create .desktop entry which is currently broken
      ## Also used to register mime types
      ../../home/profiles/jetbrains-toolbox.nix
    ];

    programs.lan-mouse = {
      enable = true;
      systemd = true;
      settings = {
        port = 4242;
        authorized_fingerprints = {
          "db:0c:20:f1:42:2b:24:2c:a7:e0:43:bf:72:be:28:a2:24:6d:7b:38:8e:7b:8f:ad:b9:ca:f1:6c:27:ed:06:48" = "antikythera";
        };
        clients = [
          {
            position = "left";
            hostname = "antikythera.lan";
            activate_on_startup = true;
          }
        ];
      };
    };

    # Deskflow server configuration (updates only managed values, preserves others)
    home.activation.deskflowConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.config/Deskflow"
      CONF="$HOME/.config/Deskflow/Deskflow.conf"
      SERVER_CONF="$HOME/.config/Deskflow/deskflow-server.conf"

      # Remove old symlinks from previous xdg.configFile approach
      [ -L "$CONF" ] && rm "$CONF"
      [ -L "$SERVER_CONF" ] && rm "$SERVER_CONF"

      # Create Deskflow.conf if missing
      if [ ! -f "$CONF" ]; then
        touch "$CONF"
      fi

      # Update only the specific values we manage (preserves other settings)
      ${pkgs.crudini}/bin/crudini --set "$CONF" core screenName nflx-erahhal-p16
      ${pkgs.crudini}/bin/crudini --set "$CONF" core serverMode true
      ${pkgs.crudini}/bin/crudini --set "$CONF" core port 24800
      ${pkgs.crudini}/bin/crudini --set "$CONF" gui enableUpdateCheck false

      # Server layout config - only create if missing (complex format, manual edits preserved)
      if [ ! -f "$SERVER_CONF" ]; then
        cat > "$SERVER_CONF" << 'EOF'
section: screens
    nflx-erahhal-p16:
    antikythera:
end

section: links
    nflx-erahhal-p16:
        left = antikythera
    antikythera:
        right = nflx-erahhal-p16
end

section: options
    clipboardSharing = true
    switchDelay = 250
end
EOF
      fi
    '';

    home = {
      extraOutputsToInstall = [ "man" ]; # Additionally installs the manpages for each pkg

      packages = with pkgs; [
        awscli
        blender

        ## genai (requires CUDA/NVIDIA)
        (broken vllm)

        chromium

        lutris
        mcreator
        postgresql
        # nodejs-16_x
        transmission_4-gtk

        # AI
        # streamlit
        # vespa-cli

        # Games
        prismlauncher

        ## unstable
        trunk.bitwig-studio

        ## arduino
        arduino
        arduino-ide
        # platformio
      ];
    };
  };
}
