{ broken, pkgs, lib, userParams, ... }:
let
  steam-gamescope-runtime-paths = lib.makeBinPath [
    pkgs.steam
    pkgs.gamescope
  ];

  steam-gamescope-script = pkgs.writeShellScriptBin "steam-gamescope-script" ''
    set -xeuo pipefail

    export LIBSEAT_BACKEND=logind

    gamescopeArgs=(
        --adaptive-sync # VRR support
        --hdr-enabled
        --mangoapp # performance overlay
        --rt
        --steam
    )
    steamArgs=(
        -pipewire-dmabuf
        -tenfoot
    )
    mangoConfig=(
        cpu_temp
        gpu_temp
        ram
        vram
    )
    mangoVars=(
        MANGOHUD=1
        MANGOHUD_CONFIG="$(IFS=,; echo "''${mangoConfig[*]}")"
    )

    export "''${mangoVars[@]}"
    exec gamescope "''${gamescopeArgs[@]}" -- steam "''${steamArgs[@]}"
  '';
  steam-gs = pkgs.stdenv.mkDerivation {
    name = "steam-gs";

    dontUnpack = true;

    nativeBuildInputs = [
      pkgs.makeWrapper
    ];

    installPhase = ''
      install -Dm755 ${steam-gamescope-script}/bin/steam-gamescope-script $out/bin/steam-gs

      wrapProgram $out/bin/steam-gs \
        --suffix PATH : ${steam-gamescope-runtime-paths}
    '';
  };
in
{
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    gamescopeSession.enable = true;
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;
    env = {
      __NV_PRIME_RENDER_OFFLOAD = "1";
      __VK_LAYER_NV_optimus = "NVIDIA_only";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };
  };

  hardware.xone.enable = true;
  services.getty.autologinUser = userParams.username;
  environment.loginShellInit = ''
    [[ "$(tty)" = "/dev/tty1" ]] && ${steam-gs}
  '';

  environment.systemPackages = with pkgs; [
    gamemode
    gamescope
    (broken mangohud) # Has issues with i686 builds
    protonup-ng
    steam-tui
    steamcmd
    steam-gs
  ];
}
