{ pkgs, lib, hostParams, ... }:
{
  options = {
    launchAppsConfig = lib.mkOption {
      type = lib.types.lines;
      default =
        ''
          workspace 3 output eDP-1
          workspace 1 output DP-2
          workspace 4 output DP-2
          workspace 5 output DP-2
          workspace 2 output DP-1

          ## [Assign apps to workspaces]
          assign      [class="Spotify"]         4
          for_window  [class="Spotify"]         move to workspace 4
          assign      [class="Brave-browser"]   4
          assign      [class="discord"]         3
          assign      [class="Signal"]          3
          assign      [class="kitty"]           2
          assign      [class="Navigator"]       1
          assign      [class="firefox"]         1

          exec --no-startup-id firefox
          exec --no-startup-id kitty tmux a -dt code
          exec --no-startup-id exec discord
          # exec --no-startup-id element-desktop
          exec --no-startup-id spotify
          exec --no-startup-id brave
        '';
    };
  };
}
