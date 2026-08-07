{ config, lib, pkgs, ... }:
let
  userParams = config.hostParams.user;
  cfg = config.nixcfg.hardware.openrgb;
  srv = config.services.hardware.openrgb;
  profileName = lib.removeSuffix ".orp" (baseNameOf cfg.profile);

  hsvType = lib.types.submodule {
    options = {
      hue = lib.mkOption {
        type = lib.types.numbers.between 0 360;
        description = "Hue in degrees: 0 red, 60 yellow, 120 green, 240 blue.";
      };
      saturation = lib.mkOption {
        type = lib.types.numbers.between 0 1;
        description = "0 is white, 1 is the fully saturated hue.";
      };
      value = lib.mkOption {
        type = lib.types.numbers.between 0 1;
        description = "0 is off, 1 is full brightness.";
      };
    };
  };
  hsvArg = c: "${toString c.hue},${toString c.saturation},${toString c.value}";
in {
  options.nixcfg.hardware.openrgb = {
    enable = lib.mkEnableOption "OpenRGB LED controller";

    motherboard = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "amd" "intel" ]);
      default = null;
      description = "Motherboard vendor, selects the SMBus kernel driver used for RGB detection.";
    };

    profile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ".orp profile the server applies at startup. Its filename (minus extension) is the profile name.";
    };

    usage = {
      enable = lib.mkEnableOption ''
        colouring the LEDs from live utilisation. GPU controllers follow GPU
        utilisation and every other controller follows CPU, so on a desktop
        the card lights up with its own load and the case lights with the
        CPU's. This owns the LEDs outright: it rewrites them every tick, so a
        static `profile` alongside it only decides what they look like in the
        moment before the first update lands
      '';

      interval = lib.mkOption {
        type = lib.types.numbers.positive;
        default = 0.25;
        description = "Seconds between LED updates.";
      };

      idle = lib.mkOption {
        type = hsvType;
        default = { hue = 0; saturation = 1.0; value = 0.0; };
        description = ''
          Colour at idle. Defaults to red at zero brightness, i.e. off.
        '';
      };

      busy = lib.mkOption {
        type = hsvType;
        default = { hue = 0; saturation = 1.0; value = 1.0; };
        description = ''
          Colour at full utilisation. Every component is interpolated
          independently between `idle` and `busy`, which is the whole of the
          configuration: leave the two hues equal and ramp `value` and the
          lights are a brightness meter in a fixed colour, or separate the
          hues and they sweep between them instead. Hue travels in degrees
          rather than around the shortest arc, so 120 -> 0 crosses the
          spectrum through yellow and orange rather than jumping the short
          way through magenta.

          Note that a diffused strip needs a fair amount of saturation before
          it reads as any colour at all: below about 0.5 it just looks white,
          so pull intensity out of `value` rather than out of `saturation`.
        '';
      };

      floor = lib.mkOption {
        type = lib.types.numbers.between 0 1;
        default = 0.0;
        description = ''
          Utilisation at or below this reads as fully idle. Raise it to a
          host's background load so the lights actually rest at the idle
          colour instead of sitting permanently a little way up the ramp.
        '';
      };

      ceiling = lib.mkOption {
        type = lib.types.numbers.between 0 1;
        default = 1.0;
        description = ''
          Utilisation at or above this reads as fully busy. Worth dropping
          below 1: a GPU under sustained load reports utilisation that
          flickers around the high nineties, so a ramp that only tops out at
          a literal 100% never quite gets there.
        '';
      };

      gamma = lib.mkOption {
        type = lib.types.numbers.positive;
        default = 1.0;
        description = ''
          Shapes the ramp between floor and ceiling. Above 1 holds the idle
          colour over more of the range. Prefer `floor` and `ceiling` for
          making the endpoints reachable and leave this alone unless the
          travel between them wants reshaping.
        '';
      };

      brightnessGamma = lib.mkOption {
        type = lib.types.numbers.positive;
        default = 2.2;
        description = ''
          LED gamma correction, which is what makes `value` mean *perceived*
          brightness rather than raw duty cycle. An LED's light output is
          linear in its duty cycle and the eye's response is not, so without
          this the dim end of the range is unusable: a strip driven at 5%
          duty still looks about a quarter as bright as full, and a
          utilisation meter spends most of its time looking uniformly lit.

          2.2 is the usual display gamma and a good starting point. Raise it
          if the lights still don't get dim enough at low load, or set it to
          1.0 for the uncorrected duty cycle.
        '';
      };

      nvidiaSmi = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default =
          if lib.elem "nvidia" config.services.xserver.videoDrivers
          then "${config.hardware.nvidia.package.bin}/bin/nvidia-smi"
          else null;
        defaultText = lib.literalMD
          "`nvidia-smi` from `hardware.nvidia.package` when the nvidia driver is in use, otherwise `null`";
        description = ''
          Where to read GPU utilisation from. When null, GPU controllers are
          left at whatever else set them and only the CPU-driven ones move.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.udev.packages = [ pkgs.openrgb ];

    environment.systemPackages = with pkgs; [ openrgb-with-all-plugins ];

    hardware.i2c.enable = true;

    services.hardware.openrgb = {
      enable = true;
      server.port = 6742;
      motherboard = cfg.motherboard;
    };

    systemd.tmpfiles.rules = lib.mkIf (cfg.profile != null) [
      "L+ /var/lib/OpenRGB/${profileName}.orp - - - - ${cfg.profile}"
    ];

    systemd.services.openrgb.serviceConfig.ExecStart =
      lib.mkIf (cfg.profile != null) (lib.mkForce
        "${srv.package}/bin/openrgb --server --server-port ${toString srv.server.port} --profile ${profileName}");

    ## The controllers lose their state across S3 and come back at their
    ## firmware default (dark), but the server keeps running, so the profile
    ## it applied at startup is never re-pushed. Send it again through the
    ## SDK port instead of restarting the server: a restart re-detects every
    ## device and drops the tray applet's connection.
    systemd.services.openrgb-resume = lib.mkIf (cfg.profile != null) {
      description = "Reapply the OpenRGB profile after resume";
      after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target" ];
      wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target" ];
      serviceConfig = {
        Type = "oneshot";
        ## OpenRGB resolves its config directory from $HOME and falls back to
        ## the working directory when that is unset, which is how the profile
        ## ends up read from /var/lib/OpenRGB. Match the server exactly: set
        ## no User= (systemd would then set HOME=/root) and the same WorkingDirectory,
        ## or the client looks in /root/.config/OpenRGB and finds no profile.
        WorkingDirectory = "/var/lib/OpenRGB";
        ExecStart = pkgs.writeShellScript "openrgb-reapply-profile" ''
          ## The client exits 0 whether or not the profile applied, so its
          ## output is the only success signal. Retry: the bus may need a
          ## moment after resume.
          for _ in $(seq 1 10); do
            if ${srv.package}/bin/openrgb --client 127.0.0.1:${toString srv.server.port} \
                 --profile ${profileName} 2>&1 | grep -q 'Profile loaded successfully'; then
              exit 0
            fi
            sleep 1
          done
          echo "openrgb: profile ${profileName} did not apply after resume" >&2
          exit 1
        '';
      };
    };

    ## Rewrites every controller on every tick rather than only when the
    ## colour changes. That costs one small I2C and one HID write per tick and
    ## buys back the resume problem for free: whatever the controllers came up
    ## as, they are corrected within `interval` without anyone noticing.
    systemd.services.openrgb-usage = lib.mkIf cfg.usage.enable {
      description = "Colour the OpenRGB devices by CPU and GPU utilisation";
      after = [ "openrgb.service" ];
      wants = [ "openrgb.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = lib.concatStringsSep " " ([
          "${pkgs.python3}/bin/python3"
          "${./usage-leds.py}"
          "--port ${toString srv.server.port}"
          "--interval ${toString cfg.usage.interval}"
          "--idle ${hsvArg cfg.usage.idle}"
          "--busy ${hsvArg cfg.usage.busy}"
          "--floor ${toString cfg.usage.floor}"
          "--ceiling ${toString cfg.usage.ceiling}"
          "--gamma ${toString cfg.usage.gamma}"
          "--brightness-gamma ${toString cfg.usage.brightnessGamma}"
        ] ++ lib.optional (cfg.usage.nvidiaSmi != null)
          "--nvidia-smi ${cfg.usage.nvidiaSmi}");
        ## It only needs a loopback socket, /proc/stat and the nvidia char
        ## devices, all of which survive everything below. PrivateDevices is
        ## the one that would hurt: it would hide /dev/nvidiactl from
        ## nvidia-smi.
        DynamicUser = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        LockPersonality = true;
        RestrictNamespaces = true;
        RestrictSUIDSGID = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_UNIX" ];
        SystemCallFilter = [ "@system-service" ];
        SystemCallErrorNumber = "EPERM";
        Restart = "always";
        RestartSec = 5;
      };
    };

    home-manager.users.${userParams.username} = {
      systemd.user.services."openrgb" = {
        Unit = {
          Description = "OpenRGB tray applet";
          PartOf = [ "graphical-session.target" ];
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
        Service = {
          Restart = "always";
          RestartSec = 2;
          ExecStart = "${pkgs.openrgb-with-all-plugins}/bin/openrgb --startminimized --nodetect --client 127.0.0.1:6742";
          PassEnvironment = [
            "HOME" "XDG_DATA_HOME" "XDG_CONFIG_HOME" "XDG_CACHE_HOME"
            "XDG_RUNTIME_DIR" "DISPLAY" "WAYLAND_DISPLAY"
          ];
          Environment = [ "HOME=%h" ];
        };
      };
    };
  };
}
