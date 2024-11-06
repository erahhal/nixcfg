{ pkgs, inputs, lib }:
let
  hyprland = pkgs.hyprland;
  # hyprland = pkgs.trunk.hyprland;
  # hyprland = pkgs.unstable.hyprland-patched;
  # hyprland = inputs.hyprland.packages.${pkgs.system}.hyprland-debug;
  runtime-paths = lib.makeBinPath [
    hyprland
    pkgs.jq
    pkgs.gamescope
    pkgs.waybar
    pkgs.zenity
  ];
  run-script = pkgs.writeShellScriptBin "bambu-studio-script" ''
    CURR_MONITOR=$(hyprctl activeworkspace -j | jq '.monitorID')
    WIDTH=$(hyprctl monitors -j | jq ".[] | select(.id==$CURR_MONITOR) | .width")
    HEIGHT=$(hyprctl monitors -j | jq ".[] | select(.id==$CURR_MONITOR) | .height")

    WAYBAR_HEIGHT=52

    HEIGHT="$((HEIGHT-WAYBAR_HEIGHT))"

    ## Not needed with --force-windows-fullscreen
    # zenity --info --text="bambu-studio under gamescope runs with the last window size it ran at. run bambu-studio-original then maximize and exit before running this."

    echo "gamescope -W $WIDTH -w $WIDTH -H $HEIGHT -h $HEIGHT -r 60 --expose-wayland --backend wayland -- ${pkgs.bambu-studio}/bin/bambu-studio"
    gamescope -W $WIDTH -w $WIDTH -H $HEIGHT -h $HEIGHT -r 60 --expose-wayland --backend wayland --force-windows-fullscreen -- ${pkgs.bambu-studio}/bin/bambu-studio
  '';
in
  pkgs.stdenv.mkDerivation {
    name = "bambu-studio";

    dontUnpack = true;

    nativeBuildInputs = [
      pkgs.makeWrapper
    ];

    installPhase = ''
      install -Dm755 ${run-script}/bin/bambu-studio-script $out/bin/bambu-studio
      install -Dm755 ${pkgs.bambu-studio}/bin/bambu-studio $out/bin/bambu-studio-original
      cp -r ${pkgs.bambu-studio}/share $out/

      wrapProgram $out/bin/bambu-studio \
        --suffix PATH : ${runtime-paths}
    '';
  }
