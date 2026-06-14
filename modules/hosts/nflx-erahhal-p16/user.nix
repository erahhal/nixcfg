{ broken, config, pkgs, ... }:

let
  userParams = config.hostParams.user;
  mcreator = pkgs.callPackage ../../../pkgs/mcreator {};
in
{
  environment.systemPackages = [
  ];

  home-manager.users.${userParams.username} = { lib, pkgs, ... }: {
    imports = [
      ../../services/protonmail-bridge
      ../../programs/thunderbird
      ./hyprland.nix
      ## Needed to create .desktop entry which is currently broken
      ## Also used to register mime types
      ../../programs/jetbrains-toolbox
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

    # Mutagen synchronization daemon
    systemd.user.services.mutagen-daemon = {
      Unit = {
        Description = "Mutagen synchronization daemon";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Install.WantedBy = [ "default.target" ];
      Service = {
        Type = "simple";
        Environment = [ "PATH=${lib.makeBinPath [ pkgs.openssh pkgs.mutagen ]}" ];
        ExecStart = "${pkgs.mutagen}/bin/mutagen daemon run";
        Restart = "on-failure";
        RestartSec = 3;
      };
    };

    # Reconcile the ~/Code/homefree <-> 10.0.0.1:~/homefree sync session to
    # match this Nix config. Re-runs on every activation where the script
    # derivation changes (i.e. when any of the values below change), and
    # terminates+recreates the session whenever its actual alpha/beta URLs
    # drift from what's declared here. Idempotent when already in sync.
    systemd.user.services.mutagen-homefree = let
      alpha = "/home/${userParams.username}/Code/homefree";
      beta  = "erahhal@10.0.0.1:/home/erahhal/homefree";
    in {
      Unit = {
        Description = "Mutagen sync session: ${alpha} <-> ${beta}";
        After = [ "mutagen-daemon.service" ];
        Requires = [ "mutagen-daemon.service" ];
      };
      Install.WantedBy = [ "default.target" ];
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        Environment = [ "PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.gawk pkgs.openssh pkgs.mutagen ]}" ];
        ExecStart = pkgs.writeShellScript "mutagen-homefree-reconcile" ''
          set -eu
          DESIRED_ALPHA=${lib.escapeShellArg alpha}
          DESIRED_BETA=${lib.escapeShellArg beta}

          mkdir -p "$DESIRED_ALPHA"

          # wait for the daemon socket to come up
          for _ in $(seq 1 30); do
            mutagen sync list >/dev/null 2>&1 && break
            sleep 0.5
          done

          # If a session named "homefree" exists, read its current endpoints;
          # otherwise treat as empty so the create branch runs.
          if current=$(mutagen sync list homefree 2>/dev/null); then
            current_alpha=$(printf '%s\n' "$current" | awk '/^Alpha:/{a=1;next} /^Beta:/{a=0} a && $1=="URL:"{print $2; exit}')
            current_beta=$(printf  '%s\n' "$current" | awk '/^Beta:/{a=1;next}  a && $1=="URL:"{print $2; exit}')
          else
            current_alpha=""
            current_beta=""
          fi

          if [ "$current_alpha" != "$DESIRED_ALPHA" ] || [ "$current_beta" != "$DESIRED_BETA" ]; then
            mutagen sync terminate homefree >/dev/null 2>&1 || true
            mutagen sync create --name=homefree \
              --sync-mode=two-way-resolved \
              --ignore='/result' --ignore='/result-*' \
              "$DESIRED_ALPHA" \
              "$DESIRED_BETA"
          fi
        '';
      };
    };

    home = {
      extraOutputsToInstall = [ "man" ]; # Additionally installs the manpages for each pkg

      packages = with pkgs; [
        (pkgs.callPackage ../../../pkgs/airport-utility {}) # Wayland driver scales via compositor
        (pkgs.callPackage ../../../pkgs/hyperbackup-explorer {})
        awscli
        blender

        ## genai (requires CUDA/NVIDIA)
        (broken vllm)

        chromium

        # lutris
        mcreator
        postgresql
        # nodejs-16_x
        transmission_4-gtk

        # AI
        # streamlit

        # Games
        prismlauncher

        ## unstable
        trunk.bitwig-studio

        ## arduino
        arduino
        arduino-ide
        # platformio

        ## Mutagen: two-way sync of ~/Code/homefree <-> 10.0.0.1:~/homefree
        mutagen
      ];
    };
  };
}
