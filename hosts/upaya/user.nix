{ pkgs, hostParams, userParams, ... }:
let
  dpiStr = toString hostParams.dpi;
  dpiLaptopStr = toString hostParams.dpiLaptop;
  mcreator = pkgs.callPackage ../../pkgs/mcreator {};
  phockup = pkgs.callPackage ../../pkgs/phockup {};
  # prismlauncher-nvidia = pkgs.callPackage ../../pkgs/prismlauncher-nvidia {};
  teensy-loader-gui = pkgs.callPackage ../../pkgs/teensy-loader-gui {};
  vdhcoapp = pkgs.callPackage ../../pkgs/vdhcoapp {};
in
{
  home-manager.users.${userParams.username} = {
    _module.args.hostParams = hostParams;
    _module.args.userParams = userParams;

    # ---------------------------------------------------------------------------
    # Host-specific user packages
    # ---------------------------------------------------------------------------

    imports = [
      # ../../home/profiles/gimp-hidpi.nix
      ../../home/profiles/protonmail-bridge.nix
    ];

    xresources = if hostParams.defaultSession == "none+i3" then {
      properties = {
        "Xft.dpi" = hostParams.dpiLaptop;
      };
    } else {};

    home = {
      extraOutputsToInstall = [ "man" ]; # Additionally installs the manpages for each pkg

      packages = with pkgs; [
        ## Audio
        jack2Full
        qjackctl

        ## terminal apps
        exercism

        ## apps
        cool-retro-term
        blender
        phockup
        simple-scan
        thunderbird
        transmission-gtk
        trunk.tdesktop
        vdhcoapp
        unstable.chromium

        ## games
        lutris
        steamtinkerlaunch
        mcreator
        unstable.prismlauncher
        unstable.atlauncher
        unstable.minecraft
        unstable.glfw-wayland-minecraft
        unstable.hmcl
        wesnoth

        ## dev
        android-studio

        ## arduino
        platformio
        unstable.teensy-loader-cli
        udev
        libudev0-shim
        gcc-arm-embedded
        teensy-loader-gui
        teensyduino

        ## unstable
        trunk.bitwig-studio
      ];

      # Xorg only
      file.".xprofile".text = ''
        #!/usr/bin/env bash

        export EDITOR = "vim";

        # Paths
        export PATH=$HOME/Scripts:$PATH
        export PATH=$HOME/.yarn/bin:$PATH
        export PATH=$HOME/.local/bin:$PATH
        export NODE_PATH=~/.local/share/yarn/global/node_modules

        ## chromium
        # base scale: Xft.dpi & floor(GDK_SCALE)
        # fractional scaling of everything: GDK_DPI_SCALE

        ## gnome-calculator
        # base scale: Xft.dpi & floor(GDK_SCALE)
        # fractional scaling of fonts: GDK_DPI_SCALE

        # Should be an integer. It gets FLOORed anyway.
        export GDK_SCALE=2

        # Would be nice to make this less than 0.5, but then chromium, discord, etc
        # will be too small on the 4k laptop screen. Next time get a
        # 14" QHD 2560x1440 screen which should roughly match the
        # DPI of a 27" 4k monitor. Or a higher resolution monitor to match
        # a 4k laptop screen.
        export GDK_DPI_SCALE=0.5

        # This appears to be correlated with Xft.dpi
        export QT_SCALE_FACTOR=2

        # This needs to be at 96. Fonts get clipped if higher
        export QT_FONT_DPI=96

        # This is unset at it is supposedly unreliable
        export QT_AUTO_SCREEN_SCALE_FACTOR=0

        # Make sure input box shows up
        export XMODIFIERS=@im=fcitx
        export GTK_IM_MODULE=fcitx
        export QT_IM_MODULE=fcitx
        export SDL_IM_MODULE=fcitx
        export INPUT_METHOD=fcitx
        export XIM_SERVERS=fcitx
        export GLFW_IM_MODULE=ibus
      '';
    };

    programs.autorandr = {
      enable = if hostParams.defaultSession == "none+i3" then true else false;
      profiles = {
        "home" = {
          fingerprint = {
            # Laptop
            eDP-1 = "00ffffffffffff004d10761400000000311a0104a52313780e06d3a75434ba250b4a51000000010101010101010101010101010101014dd000a0f0703e80302035005ac210000018000000000000000000000000000000000000000000fe005932584e44804c513135364431000000000002410328001200000b010a202000b6";
            # LG UHD IPS
            LG-UHD-IPS = "00ffffffffffff001e6d095bad3e0400071b0104b53c22789e3035a7554ea3260f50542108007140818081c0a9c0d1c08100010101014dd000a0f0703e803020650c58542100001a286800a0f0703e800890650c58542100001a000000fd00383d1e8738000a202020202020000000fc004c4720556c7472612048440a2001aa0203117144900403012309070783010000023a801871382d40582c450058542100001e565e00a0a0a029503020350058542100001a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c8";
            # LG HDR 4K
            LG-HDR-4K = "00ffffffffffff001e6d07775b0f0200011e0104b53c22789e3e31ae5047ac270c50542108007140818081c0a9c0d1c08100010101014dd000a0f0703e803020650c58542100001a286800a0f0703e800890650c58542100001a000000fd00383d1e8738000a202020202020000000fc004c472048445220344b0a20202001010203197144900403012309070783010000e305c000e3060501023a801871382d40582c450058542100001e565e00a0a0a029503020350058542100001a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000029";
          };
          config = {
            eDP-1 = {
              enable = true;
              crtc = 0;
              primary = false;
              position = "0x1100";
              mode = "3840x2160";
              gamma = "1.0:0.909:0.833";
              rate = "60.00";
              rotate = "normal";
            };
            LG-UHD-IPS = {
              enable = true;
              crtc = 0;
              primary = false;
              position = "3840x0";
              mode = "3840x2160";
              gamma = "1.0:0.909:0.833";
              rate = "60.00";
              rotate = "normal";
            };
            LG-HDR-4K = {
              enable = true;
              crtc = 0;
              primary = true;
              position = "7680x0";
              mode = "3840x2160";
              gamma = "1.0:0.909:0.833";
              rate = "60.00";
              rotate = "normal";
            };
          };
        };
        "left" = {
          fingerprint = {
            eDP-1 = "00ffffffffffff004d10761400000000311a0104a52313780e06d3a75434ba250b4a51000000010101010101010101010101010101014dd000a0f0703e80302035005ac210000018000000000000000000000000000000000000000000fe005932584e44804c513135364431000000000002410328001200000b010a202000b6";
            LG-UHD-IPS = "00ffffffffffff001e6d095bad3e0400071b0104b53c22789e3035a7554ea3260f50542108007140818081c0a9c0d1c08100010101014dd000a0f0703e803020650c58542100001a286800a0f0703e800890650c58542100001a000000fd00383d1e8738000a202020202020000000fc004c4720556c7472612048440a2001aa0203117144900403012309070783010000023a801871382d40582c450058542100001e565e00a0a0a029503020350058542100001a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c8";
          };
          config = {
            eDP-1 = {
              enable = true;
              crtc = 0;
              primary = false;
              position = "0x1100";
              mode = "3840x2160";
              gamma = "1.0:0.909:0.833";
              rate = "60.00";
              rotate = "normal";
            };
            LG-UHD-IPS = {
              enable = true;
              crtc = 0;
              primary = true;
              position = "3840x0";
              mode = "3840x2160";
              gamma = "1.0:0.909:0.833";
              rate = "60.00";
              rotate = "normal";
            };
          };
        };
        "right" = {
          fingerprint = {
            eDP-1 = "00ffffffffffff004d10761400000000311a0104a52313780e06d3a75434ba250b4a51000000010101010101010101010101010101014dd000a0f0703e80302035005ac210000018000000000000000000000000000000000000000000fe005932584e44804c513135364431000000000002410328001200000b010a202000b6";
            LG-HDR-4K = "00ffffffffffff001e6d07775b0f0200011e0104b53c22789e3e31ae5047ac270c50542108007140818081c0a9c0d1c08100010101014dd000a0f0703e803020650c58542100001a286800a0f0703e800890650c58542100001a000000fd00383d1e8738000a202020202020000000fc004c472048445220344b0a20202001010203197144900403012309070783010000e305c000e3060501023a801871382d40582c450058542100001e565e00a0a0a029503020350058542100001a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000029";
          };
          config = {
            eDP-1 = {
              enable = true;
              crtc = 0;
              primary = false;
              position = "0x1100";
              mode = "3840x2160";
              gamma = "1.0:0.909:0.833";
              rate = "60.00";
              rotate = "normal";
            };
            LG-HDR-4K = {
              enable = true;
              crtc = 0;
              primary = true;
              position = "3840x0";
              mode = "3840x2160";
              gamma = "1.0:0.909:0.833";
              rate = "60.00";
              rotate = "normal";
            };
          };
        };
        "laptop" = {
          fingerprint = {
            eDP-1 = "00ffffffffffff004d10761400000000311a0104a52313780e06d3a75434ba250b4a51000000010101010101010101010101010101014dd000a0f0703e80302035005ac210000018000000000000000000000000000000000000000000fe005932584e44804c513135364431000000000002410328001200000b010a202000b6";
          };
          config = {
            eDP-1 = {
              enable = true;
              crtc = 0;
              primary = true;
              position = "0x0";
              mode = "3840x2160";
              gamma = "1.0:0.909:0.833";
              rate = "60.00";
              rotate = "normal";
            };
          };
        };
      };
      hooks = {
        predetect = {
          "update" = ''
            xset s off
          '';
        };
        preswitch = {
          "update" = ''
            pkill polybar
            sleep 2
          '';
        };
        postswitch = {
          # "notify-i3" = "${pkgs.i3}/bin/i3-msg restart";
          # "change-background" = readFile ./change-background.sh;
          "update" = ''
            case "$AUTORANDR_CURRENT_PROFILE" in
              laptop)
                DPI=${dpiLaptopStr}
                ;;
              home)
                DPI=${dpiStr}
                ;;
              left)
                DPI=${dpiStr}
                ;;
              right)
                DPI=${dpiStr}
                ;;
              *)
                echo "Unknown profle: $AUTORANDR_CURRENT_PROFILE"
                exit 1
            esac

            # @TODO: Move this to another script
            #        Perhaps monitor-config-or-dpi-changed?
            CURR_DPI=$(xrdb -get Xft.dpi)
            echo "Xft.dpi: $DPI" | ${pkgs.xorg.xrdb}/bin/xrdb -merge

            # Might be holding onto an old i3 socket, get the latest
            export I3SOCK=$(find /run/user/$(id -u)/i3 -name "ipc-socket.*")
            ${pkgs.i3}/bin/i3-msg restart

            if [ $CURR_DPI != $DPI ]; then
              # Unfortunately firefox and brave don't detect DPI change, so
              # kill and restart them if they are  running

              if pgrep -f firefox &> /dev/null 2>&1; then
                pkill firefox
                firefox
              fi
              if pgrep -f brave &> /dev/null 2>&1; then
                pkill brave
                brave
              fi
            fi
          '';
        };
      };
    };
  };
}
