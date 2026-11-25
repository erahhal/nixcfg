{ config, inputs, pkgs, lib, ... }:
let
  userParams = config.hostParams.user;
  home-monitor-left-sway = "LG Electronics LG Ultra HD 0x00003EAD";
  home-monitor-right-sway = "LG Electronics LG HDR 4K 0x00000F5B";
  home-monitor-left-hyprland = "LG Electronics LG Ultra HD 0x00043EAD";
  home-monitor-right-hyprland = "LG Electronics LG HDR 4K 0x00020F5B";
  portable-monitor = "LG Electronics 16MQ70 204NZKZ005285";
  hyprctl="${pkgs.hyprland}/bin/hyprctl";

  # Scale fix-up for screens that no explicit profile covers.
  #
  # niri already guesses a scale for unconfigured outputs, but purely from
  # DPI (135 DPI target under 20", 110 DPI above). That is right for desk
  # monitors and always wrong for TVs: any 4K panel of 40" or more is under
  # 110 DPI, so it lands on scale 1 even though it is viewed from much
  # further away. EDID carries no viewing distance, so this assumes it:
  #
  #   - short edge >= 480 mm (16:9 from ~39"; a 40" ultrawide is 392 mm)
  #     is treated as a TV, and
  #   - an external output whose EDID size is missing or nonsense (diagonal
  #     under 10": projectors, TVs that report only an aspect ratio) is
  #     treated the same way,
  #
  # and both get the usual 10-foot-UI layout of ~1080 logical lines
  # (4K -> 2, 1440p -> 1.25, 1080p -> 1). Everything else keeps niri's guess.
  auto-scale-tv = pkgs.writeShellApplication {
    name = "kanshi-auto-scale-tv";
    runtimeInputs = [ pkgs.jq config.programs.niri.package ];
    text = ''
      niri msg --json outputs | jq -r '
        def round25: (. * 4 | round) / 4;
        to_entries[] | .value
        | select(.current_mode != null and .logical != null)
        | select(.name | test("^(eDP|LVDS|DSI)") | not)
        | .modes[.current_mode] as $m
        | (.physical_size // [0, 0]) as [$wmm, $hmm]
        | (($wmm * $wmm + $hmm * $hmm) | sqrt / 25.4) as $diag
        | select($diag < 10 or ([$wmm, $hmm] | min) >= 480)
        | ([([$m.width, $m.height] | min) / 1080 | round25, 1] | max) as $scale
        | select((.logical.scale - $scale) | fabs > 0.01)
        | "\(.name) \($scale)"
      ' | while read -r name scale; do
        niri msg output "$name" scale "$scale"
      done
    '';
  };

  # Catch-all profile for any set of outputs. Written as a raw included file
  # because it needs the variadic "...output *": a plain "*" matches exactly
  # one output, kanshi refuses to parse two "*" in one profile (and then the
  # whole daemon fails to start), and the home-manager module can only emit
  # plain "output" lines.
  auto-profile = pkgs.writeText "kanshi-auto-profile" ''
    profile auto {
      ...output *
      exec ${auto-scale-tv}/bin/kanshi-auto-scale-tv
    }
  '';
in
{
  home-manager.users.${userParams.username} = {
    # Override home-manager's Restart=always to prevent blocking graphical-session.target stop
    systemd.user.services.kanshi.Service.Restart = lib.mkForce "on-failure";

    services.kanshi = {
      enable = true;
      systemdTarget = "graphical-session.target";
      settings = [
        {
          profile = {
            name = "undocked";
            outputs = [
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "2880x1800@120";
                position = "0,0";
                scale = 1.8;
              }
            ];
            exec = [
              "${hyprctl} dispatch dpms on"
            ];
          };
        }
        {
          profile = {
            name = "desk-sway";
            outputs = [
              {
                criteria = "LG Electronics LG Ultra HD 0x00003EAD";
                status = "enable";
                mode = "3840x2160";
                position = "0,0";
                # transform = "90";
                scale = 1.5;
              }
              {
                criteria = "LG Electronics LG HDR 4K 0x00000F5B";
                status = "enable";
                mode = "3840x2160";
                position = "2560,0";
                scale = 1.5;
              }
              {
                criteria = "eDP-1";
                status = "disable";
                # status = "enable";
                mode = "2880x1800@120";
                position = "3985,1440";
                scale = 1.8;
              }
            ];
          };
        }
        {
          profile = {
            name = "desk-hyprland-thinkvision";
            outputs = [
              {
                criteria = "Lenovo Group Limited P40w-20 V90DFGMV";
                status = "enable";
                mode = "5120x2160@60.000"; # Don't use 74.97899 rate as it requires negotation and sometimes hangs for 20 seconds before displaying anything
                position = "0,0";
                scale = 1.333333;
              }
              {
                # Keep enabled but off-screen to avoid slow DRM modeset cycle
                # Disabling causes ~20s delay on AMD GPU through MST dock
                criteria = "eDP-1";
                status = "disable";
                # status = "enable";
                mode = "2880x1800@120";
                # position = "-3000,0";
                position = "6249,1440";
                scale = 1.8;
              }
            ];
          };
        }
        {
          profile = {
            name = "desk-hyprland";
            outputs = [
              {
                criteria = "LG Electronics LG Ultra HD 0x00043EAD";
                status = "enable";
                mode = "3840x2160";
                position = "0,0";
                # transform = "90";
                scale = 1.5;
              }
              {
                criteria = "LG Electronics LG HDR 4K 0x00020F5B";
                status = "enable";
                mode = "3840x2160";
                position = "2560,0";
                scale = 1.5;
              }
              {
                criteria = "eDP-1";
                status = "disable";
                # status = "enable";
                mode = "2880x1800@120";
                position = "6249,1440";
                scale = 1.8;
              }
            ];
            exec = [
              "${hyprctl} dispatch moveworkspacetomonitor 1 desc:${home-monitor-left-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 2 desc:${home-monitor-right-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 3 desc:${home-monitor-right-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 4 desc:${home-monitor-left-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 5 desc:${home-monitor-left-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 6 desc:${home-monitor-left-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 7 desc:${home-monitor-left-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 8 desc:${home-monitor-left-hyprland}"
              "${hyprctl} dispatch moveworkspacetomonitor 9 desc:${home-monitor-left-hyprland}"
              "${hyprctl} dispatch dpms on"
            ];
          };
        }
        {
          profile = {
            name = "desk-left";
            outputs = [
              {
                criteria = "LG Electronics LG Ultra HD 0x00003EAD";
                status = "enable";
                mode = "3840x2160";
                position = "0,0";
                # transform = "90";
                scale = 1.5;
              }
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "2880x1800@120";
                position = "1678,1440";
                scale = 1.75;
              }
            ];
          };
        }
        {
          profile = {
            name = "desk-right";
            outputs = [
              {
                criteria = "LG Electronics LG HDR 4K 0x00000F5B";
                status = "enable";
                mode = "3840x2160";
                position = "0,0";
                # transform = "90";
                scale = 1.5;
              }
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "2880x1800@120";
                position = "1678,1440";
                scale = 1.75;
              }
            ];
          };
        }
        # {
        #   profile = {
        #     name = "desk-portable-right";
        #     outputs = [
        #       {
        #         criteria = "eDP-1";
        #         status = "enable";
        #         mode = "2880x1800@90.000999";
        #         position = "0,67";
        #         scale = 1.8;
        #       }
        #       {
        #         criteria = "LG Electronics 16MQ70 204NZKZ005285";
        #         status = "enable";
        #         mode = "2560x1600@59.972000Hz";
        #         position = "1599,0";
        #         scale = 1.6;
        #       }
        #     ];
        #     exec = [
        #       "swaymsg workspace 1, move workspace to output right"
        #       "swaymsg workspace 2, move workspace to eDP-1"
        #       "swaymsg workspace 3, move workspace to eDP-1"
        #       "swaymsg workspace 4, move workspace to output right"
        #       "swaymsg workspace 5, move workspace to output right"
        #       "swaymsg workspace 6, move workspace to output right"
        #       "swaymsg workspace 7, move workspace to output right"
        #       "swaymsg workspace 8, move workspace to output right"
        #       "swaymsg workspace 9, move workspace to output right"
        #     ];
        #   };
        # }
        {
          profile = {
            name = "desk-portable-right-hyprland";
            outputs = [
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "2880x1800@120";
                position = "0,67";
                # Resolution must be integer divisible by scale
                scale = 1.8;
              }
              {
                criteria = "LG Electronics 16MQ70 204NZKZ005285";
                status = "enable";
                mode = "2560x1600@59.972000Hz";
                position = "1599,0";
                # Resolution must be integer divisible by scale
                scale = 1.6;
              }
            ];
            exec = [
              "${hyprctl} dispatch moveworkspacetomonitor 1 desc:${portable-monitor}"
              "${hyprctl} dispatch moveworkspacetomonitor 2 eDP-1"
              "${hyprctl} dispatch moveworkspacetomonitor 3 eDP-1"
              "${hyprctl} dispatch moveworkspacetomonitor 4 desc:${portable-monitor}"
              "${hyprctl} dispatch moveworkspacetomonitor 5 desc:${portable-monitor}"
              "${hyprctl} dispatch moveworkspacetomonitor 6 desc:${portable-monitor}"
              "${hyprctl} dispatch moveworkspacetomonitor 7 desc:${portable-monitor}"
              "${hyprctl} dispatch moveworkspacetomonitor 8 desc:${portable-monitor}"
              "${hyprctl} dispatch moveworkspacetomonitor 9 desc:${portable-monitor}"
            ];
          };
        }
        # {
        #   profile = {
        #     name = "desk-portable-left";
        #     outputs = [
        #       {
        #         criteria = "LG Electronics 16MQ70 204NZKZ005285";
        #         status = "enable";
        #         mode = "2560x1600@59.972000Hz";
        #         position = "0,0";
        #         scale = 1.5;
        #       }
        #       {
        #         criteria = "eDP-1";
        #         status = "enable";
        #         mode = "2880x1800@90.000999";
        #         position = "1706,100";
        #         scale = 1.75;
        #       }
        #     ];
        #     exec = [
        #       "swaymsg workspace 1, move workspace to output left"
        #       "swaymsg workspace 2, move workspace to eDP-1"
        #       "swaymsg workspace 3, move workspace to eDP-1"
        #       "swaymsg workspace 4, move workspace to output left"
        #       "swaymsg workspace 5, move workspace to output left"
        #       "swaymsg workspace 6, move workspace to output left"
        #       "swaymsg workspace 7, move workspace to output left"
        #       "swaymsg workspace 8, move workspace to output left"
        #       "swaymsg workspace 9, move workspace to output left"
        #     ];
        #   };
        # }
        {
          profile = {
            name = "desk-netflix-viewsonic-dual";
            outputs = [
              {
                # criteria = "ViewSonic Corporation VP3481a";
                criteria = "ViewSonic Corporation VP3481a WAG204600294";
                status = "enable";
                mode = "3440x1440@59.973000Hz";
                position = "0,0";
                scale = 1.0;
              }
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "2880x1800@120";
                position = "1287,1440";
                scale = 1.75;
              }
            ];
          };
        }
        {
          profile = {
            name = "desk-netflix-viewsonic-triple";
            outputs = [
              {

                criteria = "ViewSonic Corporation VP3481a";
                status = "enable";
                mode = "3440x1440@59.973000Hz";
                position = "0,0";
                scale = 1.0;
              }
              {
                criteria = "Goldstar Company Ltd 16MQ70";
                status = "enable";
                mode = "2560x1600@59.972000Hz";
                position = "3847,2149";
                scale = 1.5;
              }
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "2880x1800@120";
                position = "1287,2149";
                scale = 1.75;
              }
            ];
          };
        }
        {
          profile = {
            name = "desk-netflix-samsung-dual";
            outputs = [
              {

                # criteria = "Samsung Electric Company C34H89x HCPR500197";
                criteria = "Samsung Electric Company C34H89x HCPR501154";
                status = "enable";
                mode = "3440x1440@59.973000Hz";
                position = "0,0";
                scale = 1.0;
              }
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "2880x1800@120";
                position = "900,1440";
                scale = 1.75;
              }
            ];
          };
        }
        {
          profile = {
            name = "desk-netflix-samsung-triple";
            outputs = [
              {
                criteria = "Samsung Electric Company C34H89x";
                status = "enable";
                mode = "3440x1440@59.973000Hz";
                position = "0,0";
                scale = 1.0;
              }
              {
                criteria = "Goldstar Company Ltd 16MQ70";
                status = "enable";
                mode = "2560x1600@59.972000Hz";
                position = "3847,2149";
                scale = 1.5;
              }
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "2880x1800@120";
                position = "1287,2149";
                scale = 1.75;
              }
            ];
            exec = [
              "swaymsg workspace 1, move workspace to output up"
              "swaymsg workspace 2, move workspace to eDP-1"
              "swaymsg workspace 3, move workspace to output right"
              "swaymsg workspace 4, move workspace to eDP-1"
              "swaymsg workspace 5, move workspace to eDP-1"
              "swaymsg workspace 6, move workspace to eDP-1"
            ];
          };
        }
        {
          profile = {
            name = "desk-netflix-lg-dual";
            outputs = [
              {
                # criteria = "LG Electronics LG ULTRAWIDE 0x0000FAF6";
                # criteria = "LG Electronics LG ULTRAWIDE 0x0000DD5F";
                criteria = "LG Electronics LG ULTRAWIDE 0x00006B78";
                status = "enable";
                mode = "3440x1440@49.987000Hz";
                position = "420,709";
                scale = 1.0;
              }
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "2880x1800@120";
                position = "1287,2149";
                scale = 1.75;
              }
            ];
            exec = [
              "swaymsg workspace 1, move workspace to output up"
              "swaymsg workspace 2, move workspace to eDP-1"
              "swaymsg workspace 3, move workspace to eDP-1"
              "swaymsg workspace 4, move workspace to eDP-1"
              "swaymsg workspace 5, move workspace to eDP-1"
              "swaymsg workspace 6, move workspace to eDP-1"
            ];
          };
        }
        {
          profile = {
            name = "desk-netflix-lg-triple";
            outputs = [
              {
                criteria = "LG Electronics LG ULTRAWIDE 0x0000FAF6";
                status = "enable";
                mode = "3440x1440@59.973000Hz";
                position = "420,709";
                scale = 1.0;
              }
              {
                criteria = "eDP-1";
                status = "enable";
                mode = "2880x1800@120";
                position = "1287,2149";
                scale = 1.75;
              }
              {
                criteria = "LG Electronics 16MQ70 204NZKZ005285";
                status = "enable";
                mode = "2560x1600@59.972000Hz";
                position = "2993,2149";
                scale = 1.5;
              }
            ];
            exec = [
              "swaymsg workspace 1, move workspace to output up"
              "swaymsg workspace 2, move workspace to eDP-1"
              "swaymsg workspace 3, move workspace to output right"
              "swaymsg workspace 4, move workspace to eDP-1"
              "swaymsg workspace 5, move workspace to eDP-1"
              "swaymsg workspace 6, move workspace to output right"
              "swaymsg workspace 7, move workspace to output right"
            ];
          };
        }
        # Catch-all for screens with no profile above. This MUST stay last:
        # kanshi applies the first profile that matches, in file order. It
        # sets nothing itself (niri keeps its own mode/position/scale
        # guess); the exec only corrects the scale of TV-class screens.
        { include = "${auto-profile}"; }
      ];
    };
  };
}
