{ ... }:
{
  programs.niri.settings = {
    outputs = {
      "Lenovo Group Limited P40w-20 V90DFGMV" = {
        mode = { width = 5120; height = 2160; refresh = 60.0; };
        scale = 1.333333;
        variable-refresh-rate = true;
      };
      "LG Electronics 16MQ70 204NZKZ005285" = {
        mode = { width = 2560; height = 1600; refresh = 60.0; };
        scale = 1.6;
      };
      "LG Electronics LG Ultra HD 0x00043EAD" = {
        mode = { width = 3840; height = 2160; refresh = 60.0; };
        scale = 1.5;
        variable-refresh-rate = true;
      };
      "LG Electronics L33HD334K 0x00020F5B" = {
        mode = { width = 3840; height = 2160; refresh = 60.0; };
        scale = 1.5;
        variable-refresh-rate = true;
      };
      "LG Electronics LG TV SSCR2 0x01010101" = {
        mode = { width = 3840; height = 2160; };
        scale = 2.666667;
        variable-refresh-rate = true;
      };
      "Yamaha Corporation - RX-A2A" = {
        mode = { width = 3840; height = 2160; };
        scale = 2.666667;
        variable-refresh-rate = true;
      };
    };

    environment = {
      STEAM_FORCE_DESKTOPUI_SCALING = "2.0";
    };

    # niri takes an inhibitor on logind's handle-power-key and turns a short
    # press of the case button into a suspend -- which is how this box went to
    # sleep unattended on 2026-08-04. This is a server that should never
    # suspend from a bumped button, so hand the key back to logind, which
    # configuration.nix sets to ignore it. Powering ON is a firmware function
    # and is unaffected.
    input.power-key-handling.enable = false;

    # Startup workspace comes from hostParams.desktop.startupWorkspace; the ten
    # named workspaces are declared by nixcfg-niri.
    spawn-at-startup = [
      { argv = [ "foot" "tmux" "a" "-dt" "code" ]; }
    ];
  };
}
