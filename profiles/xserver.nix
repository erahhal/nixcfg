{ pkgs, enabled, hostParams, userParams, ... }:

{
  environment.systemPackages = with pkgs; [
    edid-decode
  ];

  services.libinput.enable = true;

  services.xserver = {
    enable = true;
    dpi = hostParams.dpi;
    # @TODO: move to variable that can be shared with sway and i3 config
    # 230/35 seems to be the same as 250/50 with xset/sway
    autoRepeatDelay = 230;
    autoRepeatInterval = 35;
    synaptics.palmDetect = true;
    inputClassSections = [
      ''
        Identifier      "system-keyboard"
        MatchIsKeyboard "on"
        Option          "AutoRepeat" "230 35"
      ''
      ''
        Identifier      "system-mouse"
        MatchDriver     "libinput"
        MatchIsPointer  "on"
        Option          "AccelSpeed"        "0.8"

        # Option          "AccelProfile"      "flat"

        # # set the following to 1 1 0 respectively to disable acceleration.
        # Option "AccelerationNumerator" "2"
        # Option "AccelerationDenominator" "1"
        # Option "AccelerationThreshold" "4"

      ''
    ];

    videoDrivers = [ "modesetting" ];

    deviceSection = ''
      # Driver "i915"
      Option "TearFree" "true"
      Option "AccelMethod" "uxa"
      Option "DRI" "2"
    '';

    # useGlamor = true;

    ## Handled in .Xresources
    # displayManager.sessionCommands = ''
    #   ${pkgs.xorg.xrdb}/bin/xrdb -merge <<EOF
    #     Xft.dpi: ${toString hostParams.dpi}
    #   EOF
    # '';
  };

  disabledModules = [ "services/misc/autorandr.nix" ];

  imports = [
    ../modules/autorandr.nix
  ];

  services.autorandr = if hostParams.defaultSession == "none+i3" then {
    defaultTarget = "home";
    enable = true;
  } else {};

  # NixOS base service doesn't support many options
  home-manager.users.${userParams.username} = {
    services.picom = if hostParams.defaultSession == "none+i3" then {
      enable = true;

      ## these two needed to get rid of tearing
      backend = "glx";
      vSync = true;

      ## Extra fancy stuff
      activeOpacity = "1.0";
      inactiveOpacity = "0.8";
      fade = true;
      fadeDelta = 5;
      shadow = true;
      shadowOpacity = "0.75";

      ## Home-manager-only options
      extraOptions = ''
        use-damage = true;
        xrender-sync-fence = true;
        mark-ovredir-focused = false;
        use-ewmh-active-win = true;

        wintypes:
        {
          dock          = { shadow = false; };
          dnd           = { shadow = false; };
          popup_menu    = { opacity = 1.0; };
          dropdown_menu = { opacity = 1.0; };
        };
      '';

      ## These rules need to be updated
      # opacityRule = [
      #   "100:name *= 'i3lock'"
      #   "99:fullscreen"
      #   "100:class_g = 'kitty' && focused"
      #   "50:class_g = 'kitty' && !focused"
      # ];
    } else {};
  };
}
