{ lib, pkgs, userParams, ... }:

let
  mcreator = pkgs.callPackage ../../pkgs/mcreator {};
in
{
  environment.systemPackages = [
  ];

  home-manager.users.${userParams.username} = {
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
        left = {
          hostname = "antikythera.lan";
          activate_on_startup = true;
        };
      };
    };

    # Deskflow server configuration
    xdg.configFile."Deskflow/Deskflow.conf".text = ''
      [core]
      screenName=nflx-erahhal-p16
      serverMode=true
      port=24800

      [gui]
      enableUpdateCheck=false
    '';

    xdg.configFile."Deskflow/deskflow-server.conf".text = ''
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
    '';

    home = {
      extraOutputsToInstall = [ "man" ]; # Additionally installs the manpages for each pkg

      packages = with pkgs; [
        awscli
        blender

        ## genai (requires CUDA/NVIDIA)
        vllm

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
