{ pkgs, ... }:
let
  debouncer-udevmon = pkgs.callPackage ../pkgs/debouncer-udevmon {};

  debouncerConfig = pkgs.writeText "debouncer.toml" ''
    # Keycodes for modifier keys (Ctrl, Shift, Alt, Super) - don't debounce these
    # 29=Left Ctrl, 42=Left Shift, 54=Right Shift, 56=Left Alt
    # 97=Right Ctrl, 100=Right Alt, 125=Left Super
    exceptions = [29, 42, 54, 56, 97, 100, 125]
    # Debounce time in milliseconds
    # 14ms is a good starting point; increase to 20-25ms if chatter persists
    debounce_time = 14
  '';
in
{
  # -------------------------------------------------------------------------
  # Software debounce for wireless keyboards (Linux only)
  # -------------------------------------------------------------------------
  services.interception-tools = {
    enable = true;
    plugins = [ debouncer-udevmon ];
    udevmonConfig = ''
      - JOB: "${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${debouncer-udevmon}/bin/debouncer-udevmon | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE"
        DEVICE:
          EVENTS:
            EV_KEY: [KEY_A]
          NAME: ".*[Kk]eychron.*"
    '';
  };

  environment.etc."debouncer.toml".source = debouncerConfig;

  # -------------------------------------------------------------------------
  # VIA keyboard configurator (for firmware-level debounce on QMK keyboards)
  # -------------------------------------------------------------------------
  # VIA allows adjusting keyboard firmware settings like debounce directly
  # on the keyboard, which works across all operating systems (Linux/Windows)
  environment.systemPackages = [ pkgs.via ];

  # Required for VIA to detect the keyboard without root
  services.udev.packages = [ pkgs.via ];
}
