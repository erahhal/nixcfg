{ pkgs, ... }:
let
  # LG C1 over HDMI 2.1 (TV's "HDMI Ultra HD Deep Color" on): 4K@120 needs an FRL link. When
  # FRL is the first link after boot (e.g. coming from Windows), NVIDIA's link training fails
  # and the screen stays black; stepping up from an established 4K@60 TMDS link works. So the
  # output config below pins 60, and this guard steps up to 120 once the TV is up, falling back
  # to 60 whenever the kernel reports a failed FRL link training.
  tvName = "LG Electronics LG TV SSCR2 0x01010101";
  tv-hdmi-frl-guard = pkgs.writeShellScript "tv-hdmi-frl-guard" ''
    set -uo pipefail
    PATH="${pkgs.niri}/bin:${pkgs.jq}/bin:${pkgs.systemd}/bin:${pkgs.coreutils}/bin:$PATH"

    TV="${tvName}"
    SAFE="3840x2160@60.000"
    FAST="3840x2160@119.880"
    FAILURES="$XDG_RUNTIME_DIR/tv-hdmi-frl-failures"
    : > "$FAILURES"

    # Fallback: back to TMDS 4K@60 on any FRL link training failure.
    journalctl -k -f -n 0 -o cat --grep 'HDMI FRL link training failed' | while read -r _; do
      echo "FRL link training failed; falling back to $SAFE" >&2
      echo x >> "$FAILURES"
      niri msg output "$TV" mode "$SAFE" >/dev/null
    done &

    present=0
    settled=0
    while sleep 3; do
      state=$(niri msg --json outputs 2>/dev/null | jq -r --arg tv "$TV" '
        [.[] | select("\(.make) \(.model) \(.serial)" == $tv)][0] // empty
        | (if .current_mode == null then "off"
           else .modes[.current_mode] | "\(.width)x\(.height)@\(.refresh_rate)" end)
          + " " + (any(.modes[]; .width == 3840 and .height == 2160 and .refresh_rate == 119880) | tostring)')

      if [[ -z $state ]]; then
        if (( present )); then
          # Disconnected: make the next connection link up at 60 first, and reset the retry budget.
          niri msg output "$TV" mode "$SAFE" >/dev/null 2>&1
          : > "$FAILURES"
          present=0
        fi
        settled=0
        continue
      fi
      present=1

      read -r cur fast <<< "$state"
      if [[ $cur == "3840x2160@60000" && $fast == true && $(wc -l < "$FAILURES") -lt 2 ]]; then
        # Step up only after the 60 Hz link has been up for a full poll interval.
        if (( settled )); then
          echo "stepping up to $FAST" >&2
          niri msg output "$TV" mode "$FAST" >/dev/null
          settled=0
        else
          settled=1
        fi
      else
        settled=0
      fi
    done
  '';
in
{
  systemd.user.services.tv-hdmi-frl-guard = {
    Unit = {
      Description = "Step the LG TV up to 4K@120 after a 4K@60 link, fall back on FRL failure";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      # niri sessions only; Hyprland and others don't export NIRI_SOCKET.
      ConditionEnvironment = "NIRI_SOCKET";
    };
    Service = {
      Type = "simple";
      ExecStart = toString tv-hdmi-frl-guard;
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  programs.niri.settings = {
    outputs = {
      "eDP-1" = {
        mode = { width = 2880; height = 1800; refresh = 120.0; };
        scale = 1.8;
        variable-refresh-rate = true;
      };
      "Lenovo Group Limited P40w-20 V90DFGMV" = {
        mode = { width = 5120; height = 2160; refresh = 60.0; };
        scale = 1.333333;
        variable-refresh-rate = true;
      };
      "LG Electronics 16MQ70 20NKZ005285" = {
        mode = { width = 2560; height = 1600; refresh = 60.0; };
        scale = 1.6;
        variable-refresh-rate = true;
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
      # Pinned to 60 so the first link is TMDS; tv-hdmi-frl-guard steps up to 120. With the
      # TV's HDMI Deep Color off only 4K@30 exists and niri falls back to the preferred mode.
      ${tvName} = {
        mode = { width = 3840; height = 2160; refresh = 60.0; };
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
      __NV_PRIME_RENDER_OFFLOAD = "1";
      __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      __VK_LAYER_NV_optimus = "NVIDIA_only";
    };

    # Startup workspace and workspace output come from hostParams.desktop
    # (startupWorkspace / workspaceOutput).
    spawn-at-startup = [
      { argv = [ "foot" "tmux" "a" "-dt" "code" ]; }
    ];
  };
}
