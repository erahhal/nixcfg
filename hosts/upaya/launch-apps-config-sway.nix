{ lib, ... }:
{
  options = {
    launchAppsConfigSway = lib.mkOption {
      type = lib.types.lines;
      default = ''
        # Discord reloads after startup, so it jumps to the
        # current workspace, so force it onto 3
        assign      [class="discord"]         3

        workspace 2 output "LG Electronics LG HDR 4K 0x00000F5B"
        workspace 2
        exec kitty tmux a -dt code
        workspace 3 output eDP-1
        workspace 3
        exec joplin-desktop
        workspace 4 output "LG Electronics LG Ultra HD 0x00003EAD"
        workspace 4
        exec spotify
        exec brave
        workspace 5 output "LG Electronics LG Ultra HD 0x00003EAD"
        workspace 5
        exec thunderbird
        workspace 6 output eDP-1
        workspace 6
        exec signal-desktop
        exec telegram-desktop
        workspace 7 output "LG Electronics LG HDR 4K 0x00000F5B"
        workspace 7
        exec discord
        workspace 8 output eDP-1
        workspace 8
        exec waydroid session start
        workspace 1 output "LG Electronics LG Ultra HD 0x00003EAD"
        workspace 1
        exec firefox
      '';
    };
  };
}
