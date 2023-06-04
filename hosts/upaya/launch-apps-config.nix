{ lib, hostParams, ... }:
{
  options = {
    launchAppsConfig = lib.mkOption {
      type = lib.types.lines;
      default = if hostParams.defaultSession == "none+i3" then
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
        ''
        else
        ''
          # Discord reloads after startup, so it jumps to the
          # current workspace, so force it onto 3
          assign      [class="discord"]         3

          workspace 2 output "LG Electronics LG HDR 4K 0x00000F5B"
          workspace 2
          exec kitty tmux a -dt code
          workspace 3 output eDP-1
          workspace 3
          exec signal-desktop
          workspace 4 output "LG Electronics LG Ultra HD 0x00003EAD"
          workspace 4
          exec spotify
          exec brave
          workspace 5 output "LG Electronics LG Ultra HD 0x00003EAD"
          workspace 5
          exec thunderbird
          workspace 6 output "LG Electronics LG Ultra HD 0x00003EAD"
          workspace 6
          exec joplin-desktop
          workspace 7 output "LG Electronics LG HDR 4K 0x00000F5B"
          workspace 7
          exec discord
          workspace 1 output "LG Electronics LG Ultra HD 0x00003EAD"
          workspace 1
          exec firefox
        '';
    };
  };
}
