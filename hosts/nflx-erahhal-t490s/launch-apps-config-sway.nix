{ lib, ... }:
{
  options = {
    launchAppsConfigSway = lib.mkOption {
      type = lib.types.lines;
      default = ''
        set $homeLeft "LG Electronics LG Ultra HD 0x00003EAD"
        set $homeRight "LG Electronics LG HDR 4K 0x00000F5B"
        set $laptop "eDP-1"
        set $portableLg "Goldstar Company Ltd 16MQ70"
        set $officeSamsung "Samsung Electric Company C34H89x"
        set $officeLg "Goldstar Company Ltd LG ULTRAWIDE"
        set $officeViewsonic "ViewSonic Corporation VP3481a"

        workspace 2 output $homeRight $laptop
        workspace 2
        exec kitty tmux a -dt code
        workspace 3 output $portableLg $laptop
        workspace 3
        exec slack
        workspace 4 output $homeLeft $laptop
        workspace 4
        exec spotify
        exec brave
        workspace 5 output $homeLeft $laptop
        workspace 5
        exec firefox
        workspace 6 output $portableLg $laptop
        workspace 6
        exec signal-desktop
        exec telegram-desktop
        workspace 7 output $homeRight $laptop
        workspace 7
        exec discord
        workspace 8 output $laptop
        workspace 8
        exec waydroid session start
        workspace 1 output $homeLeft
        workspace 1
        exec chromium
      '';
    };
  };
}
