{ pkgs, lib, hostParams, ... }:
let
  assignWorkspaces = pkgs.writeShellScript "hyprland-assign-workspaces.sh" ''
    ## Unfortunately the workspace keyword for Hyprland does not support the monitor "desc:" qualifier, so map them here

    until hyprctl monitors | grep eDP-1; do echo "waiting for monitors"; done

    sleep 5

    mapfile -t monitors < <(${pkgs.hyprland}/bin/hyprctl monitors | ${pkgs.gnugrep}/bin/grep "Monitor" | ${pkgs.gawk}/bin/awk '{print $2}')
    mapfile -t descriptions < <(${pkgs.hyprland}/bin/hyprctl monitors | ${pkgs.gnugrep}/bin/grep "description" | ${pkgs.gnused}/bin/sed 's/.*description: //' |  ${pkgs.gnused}/bin/sed 's/ (.*//')

    # until ${pkgs.wlr-randr}/bin/wlr-randr | ${pkgs.gnugrep}/bin/grep eDP-1; do echo "waiting for monitors"; done
    #
    # mapfile -t monitors < <(${pkgs.wlr-randr}/bin/wlr-randr | ${pkgs.gnugrep}/bin/grep -Ev "^(\s)+" | ${pkgs.gawk}/bin/awk '{print $1}')
    # mapfile -t descriptions < <(${pkgs.wlr-randr}/bin/wlr-randr | ${pkgs.gnugrep}/bin/grep -Ev "^(\s)+" | ${pkgs.gnused}/bin/sed 's/^[^\s]+ "//' | ${pkgs.gnused}/bin/sed -E 's/^.*"(.*)\(.*$/\1/g')

    # Laptop monitor name never changes
    LEFT=eDP-1

    # External monitor names are not deterministic, so find them using the description
    for index in "''${!monitors[@]}";
    do
      if [ "''${descriptions[$index]}" == "LG Electronics LG HDR 4K 0x00020F5B" ]; then
        RIGHT="''${monitors[$index]}"
      elif [ "''${descriptions[$index]}" == "LG Electronics LG Ultra HD 0x00043EAD" ]; then
        MIDDLE="''${monitors[$index]}"
      fi
    done

    ${pkgs.hyprland}/bin/hyprctl dispatch moveworkspacetomonitor 1 $MIDDLE
    ${pkgs.hyprland}/bin/hyprctl dispatch moveworkspacetomonitor 2 $RIGHT
    ${pkgs.hyprland}/bin/hyprctl dispatch moveworkspacetomonitor 3 $LEFT
    ${pkgs.hyprland}/bin/hyprctl dispatch moveworkspacetomonitor 4 $MIDDLE
    ${pkgs.hyprland}/bin/hyprctl dispatch moveworkspacetomonitor 5 $MIDDLE
    ${pkgs.hyprland}/bin/hyprctl dispatch moveworkspacetomonitor 6 $LEFT
    ${pkgs.hyprland}/bin/hyprctl dispatch moveworkspacetomonitor 7 $RIGHT
  '';
in
{
  options = {
    launchAppsConfigHyprland = lib.mkOption {
      type = lib.types.lines;
      default = ''
        exec = ${assignWorkspaces}

        # workspace 1
        windowrule = workspace 1, silent, class:^(firefox)$
        exec-once = [workspace l silent] firefox

        # workspace 2
        windowrule = workspace 2, silent, class:^(kitty)$
        exec-once = [workspace 2 silent] kitty tmux a -dt code

        # workspace 4
        windowrule = workspace 4 silent, title:^(Spotify)$
        exec-once = [workspace 4 silent] spotify
        windowrule = workspace 4 silent, class:^(brave-browser)$
        exec-once = [workspace 4 silent] brave

        # workspace 6
        windowrule = workspace 6, class:^(signal)$
        exec-once = [workspace 6 silent] signal-desktop

        # workspace 7
        windowrule = workspace 7, class:^(discord)$
        exec-once = [workspace 7 silent] discord
      '';
    };
  };
}
