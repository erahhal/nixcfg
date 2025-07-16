{ lib, pkgs, userParams, ... }:

let
  mcreator = pkgs.callPackage ../../pkgs/mcreator {};
  chromium-p16-script = pkgs.writeShellScriptBin "chromium-p16-script" ''
    ${pkgs.chromium}/bin/chromium "$@"
  '';
  brave-p16-script = pkgs.writeShellScriptBin "brave-p16-script" ''
    ${pkgs.brave}/bin/brave "$@"
  '';
in
{
  environment.systemPackages = [
    (pkgs.stdenv.mkDerivation {
      name ="chrome-p16";
      pname = "chrome-p16";

      dontUnpack = true;

      nativeBuildInputs = [
        pkgs.makeWrapper
      ];

      installPhase = ''
        install -Dm755 ${chromium-p16-script}/bin/chromium-p16-script $out/bin/chromium-p16
        wrapProgram $out/bin/chromium-p16 \
          --add-flags "--force-device-scale-factor=2.0"
      '';
    })
    (pkgs.stdenv.mkDerivation {
      name ="brave-p16";
      pname = "brave-p16";

      dontUnpack = true;

      nativeBuildInputs = [
        pkgs.makeWrapper
      ];

      installPhase = ''
        install -Dm755 ${brave-p16-script}/bin/brave-p16-script $out/bin/brave-p16
        wrapProgram $out/bin/brave-p16 \
          --add-flags "--force-device-scale-factor=2.0"
      '';
    })
  ];

  home-manager.users.${userParams.username} = {
    imports = [
      ./launch-apps-config-hyprland.nix
      ## Needed to create .desktop entry which is currently broken
      ## Also used to register mime types
      ../../home/profiles/jetbrains-toolbox.nix
    ];

    home = {
      extraOutputsToInstall = [ "man" ]; # Additionally installs the manpages for each pkg

      packages = with pkgs; [
        awscli
        blender
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
