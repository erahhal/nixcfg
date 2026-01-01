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
}
