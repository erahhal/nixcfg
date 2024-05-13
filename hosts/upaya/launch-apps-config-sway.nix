{ lib, ... }:
let
  left = "LG Electronics LG Ultra HD 0x00003EAD";
  right = "LG Electronics LG HDR 4K 0x00000F5B";
in
{
  options = {
    launchAppsConfigSway = lib.mkOption {
      type = lib.types.lines;
      default = ''
        # Discord reloads after startup, so it jumps to the
        # current workspace, so force it onto 7
        assign      [class="discord"]         7

        workspace 2 output right
        workspace 2
        exec kitty tmux a -dt code

        workspace 3 output left
        workspace 3
        # exec joplin-desktop

        workspace 4 output left
        workspace 4
        exec spotify
        exec brave

        workspace 5 output left
        workspace 5
        # exec thunderbird

        workspace 6 output left
        workspace 6
        exec signal-desktop
        exec telegram-desktop

        workspace 7 output left
        workspace 7
        exec discord
        exec element-desktop; sleep 1; element-desktop

        workspace 8 output left
        workspace 8
        # exec waydroid session start

        workspace 1 output left
        workspace 1
        exec firefox
      '';
    };
  };
}
