# Leap Motion / Ultraleap hand tracking (original controller, USB f182:0003).
#
# Packaging comes from the ultraleap-nix input (see flake.nix); nixpkgs has
# none (NixOS/nixpkgs#292624, #310138 both closed). It repackages Ultraleap's
# last Linux release, Gemini 5.17.1, from their Ubuntu .debs.
#
# Ultraleap's hand-tracking business was sold off in 2025 and
# repo.ultraleap.com, which the input's fetchurl URLs point at, no longer
# resolves. So the overlay below re-points each src at its Wayback Machine
# capture, keeping the input's pinned hash, which still guards the content.
# A verified copy of each .deb is also kept at
# /mnt/storage/Software-archive/ultraleap. If the Wayback copies ever vanish,
# `nix-store --add-fixed sha256 /mnt/storage/Software-archive/ultraleap/*.deb`
# seeds the store so the build succeeds without network. The file names there
# match the `name`s set below, which is what --add-fixed requires.
#
# Beyond the src swap, the overlay and config below fix gaps found by
# reading the .deb's maintainer scripts and leapd itself: broken udev rules,
# the model-file path, the log directory, and the default config, plus the
# control panel's Unity launcher (lock file, library path, .desktop entry).
#
# After the first switch, the service won't track until the EULA is
# accepted once: `leapctl eula`. The .deb's postinst does that via debconf.
#
# The service does NOT start at boot: run `leap-on` before using the
# controller and `leap-off` afterwards (see below for why, including why
# leap-off needs a helper to get the IR LEDs to switch off).
{ config, inputs, lib, pkgs, ... }:
let
  cfg = config.nixcfg.hardware.leap-motion;

  # Measured on antikythera (USB interrupts/s on the Leap's xhci controller):
  # leapd lights the IR LEDs as soon as it opens the device (~16/s, no
  # stream). Both cameras start streaming once a client first connects
  # (~2,200/s), and they keep streaming after it disconnects. Neither
  # `leapctl config tracking pause` nor USB autosuspend stops that; only
  # stopping leapd does (0/s, uvcvideo takes the device back). That's why
  # the controller ran hot, and why the service is on demand only.
  #
  # But leapd only switches the LEDs off on shutdown if a stream ran, so
  # a leap-on/leap-off with no app in between left them lit. leap-off
  # therefore connects briefly first (leap-kick.c) to make sure one did.
  systemctl = "${pkgs.systemd}/bin/systemctl";
  unit = "ultraleap-hand-tracking-service.service";
  servicePkg = config.services.ultraleap.servicePackage;
  leap-kick = pkgs.stdenv.mkDerivation {
    name = "leap-kick";
    src = ./leap-kick.c;
    dontUnpack = true;
    buildInputs = [ (lib.getDev servicePkg) (lib.getLib servicePkg) ];
    buildPhase = "$CC -O2 -Wall -o leap-kick $src -lLeapC";
    installPhase = "install -Dm755 leap-kick $out/bin/leap-kick";
  };
  leap-on = pkgs.writeShellScriptBin "leap-on" ''
    set -e
    ${systemctl} start ${unit}
    echo "Leap tracking on. The IR LEDs stay lit until you run leap-off."
  '';
  leap-off = pkgs.writeShellScriptBin "leap-off" ''
    set -e
    echo "Stopping Leap tracking (takes ~6 s)..."
    if ${systemctl} is-active --quiet ${unit}; then
      ${leap-kick}/bin/leap-kick >/dev/null || true
    fi
    ${systemctl} stop ${unit}
    echo "Leap tracking off."
  '';

  # Re-fetch a package's .deb from the Wayback Machine. `id_` asks for the
  # raw captured bytes rather than the archive's HTML-wrapped replay.
  # %2B is decoded to "+" because "%" is not a legal store-path character.
  fromWayback = final: timestamp: pkg:
    pkg.overrideAttrs (old: {
      src = final.fetchurl {
        name = lib.replaceStrings [ "%2B" ] [ "+" ] (baseNameOf (lib.head old.src.urls));
        url = "https://web.archive.org/web/${timestamp}id_/${lib.head old.src.urls}";
        hash = old.src.outputHash;
      };
    });
in
{
  key = "nixcfg/hardware/leap-motion";

  imports = [ inputs.ultraleap-nix.nixosModules.default ];

  options.nixcfg.hardware.leap-motion.enable =
    lib.mkEnableOption "Leap Motion (Ultraleap) hand tracking service";

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      inputs.ultraleap-nix.overlays.default
      (final: prev: {
        ultraleap-hand-tracking-service =
          (fromWayback final "20260124060130" prev.ultraleap-hand-tracking-service).overrideAttrs (old: {
            postInstall = (old.postInstall or "") + ''
              # The .deb's rules put the match and GROUP="plugdev" on
              # separate lines. udev reads every line as its own rule, so
              # the match line is dead (`udevadm verify`: "The line has no
              # effect") and the bare GROUP= line would re-group EVERY
              # device node (GPU, input, sound...) once plugdev exists.
              # Rewrite each as the single rule it was meant to be.
              rules=$out/lib/udev/rules.d
              echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="f182", ATTRS{idProduct}=="0003", GROUP="plugdev"' > $rules/99-LMC.rules
              echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="2936", ATTRS{idProduct}=="1206", GROUP="plugdev"' > $rules/99-LMC2.rules
              echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="2936", ATTRS{idProduct}=="1202", GROUP="plugdev"' > $rules/99-SIR170.rules

              # Default tracker config, which the .deb's postinst copies to
              # /etc/ultraleap; upstream's installPhase drops it.
              install -Dm644 usr/TrackingService/bin/hand_tracker_config.json \
                $out/share/ultraleap-hand-tracking-service/hand_tracker_config.json
            '';
          });
        # Upstream still takes the deprecated xorg.* names, each of which
        # now emits an evaluation warning; hand it the renamed packages.
        ultraleap-hand-tracking-control-panel = (fromWayback final "20260215021652"
          (prev.ultraleap-hand-tracking-control-panel.override {
            xorg = {
              libX11 = final.libx11;
              libXScrnSaver = final.libxscrnsaver;
              libXcursor = final.libxcursor;
              libXext = final.libxext;
              libXi = final.libxi;
              libXinerama = final.libxinerama;
              libXrandr = final.libxrandr;
              libXxf86vm = final.libxxf86vm;
            };
          })).overrideAttrs (old: {
            # Upstream lists sonames here ("libGL.so.1", ...), but the hook
            # wants packages, so the RUNPATH got literal relative entries
            # like "libGL.so.1/lib", resolved against the CWD. Those are
            # useless at best. Also, Unity dlopen()s from UnityPlayer.so and
            # Mono, which never consult the executable's RUNPATH anyway;
            # LD_LIBRARY_PATH in the launcher below is what works.
            runtimeDependencies = [ ];

            postInstall = (old.postInstall or "") + ''
              # The app is built with Unity's forceSingleInstance, which
              # creates unity.lock beside the executable (read-only in the
              # store) and quits if it can't. So run a copy of the 18 KB
              # launcher from a per-store-path cache dir, with
              # UnityPlayer.so and the _Data dir symlinked next to it.
              rm "$out/bin/ultraleap-hand-tracking-control-panel"
              cat > "$out/bin/ultraleap-hand-tracking-control-panel" <<'EOF'
              #!@shell@
              set -eu
              app=@app@
              cache="''${XDG_CACHE_HOME:-$HOME/.cache}/ultraleap-hand-tracking-control-panel"
              dir="$cache/@storeName@"
              if [ ! -e "$dir/ultraleap-hand-tracking-control-panel" ]; then
                rm -rf "$cache" # copies made for older store paths
                mkdir -p "$dir"
                cp "$app/ultraleap-hand-tracking-control-panel" "$dir/"
                ln -s "$app/UnityPlayer.so" "$app/ultraleap-hand-tracking-control-panel_Data" "$dir/"
              fi
              export LD_LIBRARY_PATH="@libPath@''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
              exec "$dir/ultraleap-hand-tracking-control-panel" "$@"
              EOF
              chmod +x "$out/bin/ultraleap-hand-tracking-control-panel"
              substituteInPlace "$out/bin/ultraleap-hand-tracking-control-panel" \
                --subst-var-by shell "${final.runtimeShell}" \
                --subst-var-by app "$out/opt/ultraleap-hand-tracking-control-panel" \
                --subst-var-by storeName "$(basename "$out")" \
                --subst-var-by libPath "${final.addDriverRunpath.driverLink}/lib:${lib.makeLibraryPath (with final; [
                  libGL libx11 libxcursor libxext libxi libxinerama libxrandr libxscrnsaver libxxf86vm
                  dbus udev vulkan-loader wayland libxkbcommon zlib ultraleap-hand-tracking-service
                ])}"

              # The .desktop entry points at Debian's /opt install path.
              substituteInPlace "$out/share/applications/ultraleap-hand-tracking-control-panel.desktop" \
                --replace-fail '"/opt/ultraleap-hand-tracking-control-panel/ultraleap-hand-tracking-control-panel"' \
                  "$out/bin/ultraleap-hand-tracking-control-panel"
            '';
          });
        openxr-ultraleap-layer =
          fromWayback final "20260124060130" prev.openxr-ultraleap-layer;
      })
    ];

    # Runs leapd as the `leap` system user, installs the service's udev
    # rules, and puts the (implicit) OpenXR API layer on the system profile.
    services.ultraleap.enable = true;

    # The udev rules (fixed above) hand the device to group plugdev, and the
    # upstream module adds `leap` to it, but NixOS doesn't create plugdev.
    users.groups.plugdev = { };

    systemd.services.ultraleap-hand-tracking-service = {
      # Not started at boot; see leap-on / leap-off above.
      wantedBy = lib.mkForce [ ];
      # leapd finds its tracking models (*.ldat) via this variable, falling
      # back to a hardcoded /usr/share/ultraleap; the package puts them in
      # the store. Check with: journalctl -u ultraleap-hand-tracking-service
      # | grep 'LDATS in'
      environment.LIBTRACK_LDAT_DIR = "${servicePkg}/share/ultraleap";
      # leapd hardcodes /var/log/ultraleap when LIBTRACK_IS_SERVICE=1
      # (the .deb's preinst creates exactly that); upstream says "leap".
      serviceConfig.LogsDirectory = lib.mkForce "ultraleap";
    };

    # Seed the default config if missing, as the .deb's postinst does,
    # including its deliberate world-writable mode (a+rw).
    systemd.tmpfiles.settings."10-ultraleap"."/etc/ultraleap/hand_tracker_config.json".C = {
      argument = "${servicePkg}/share/ultraleap-hand-tracking-service/hand_tracker_config.json";
      user = "leap";
      group = "leap";
      mode = "0666";
    };

    # Control panel: live view of the IR cameras and tracked hands, plus
    # tracking-mode settings (desktop / head-mounted / screentop).
    environment.systemPackages = [
      pkgs.ultraleap-hand-tracking-control-panel
      leap-on
      leap-off
    ];

    # leap-on/leap-off without a password prompt, for wheel users, scoped to
    # this one unit. Low stakes: leapd runs unprivileged as `leap`.
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            action.lookup("unit") == "${unit}" &&
            subject.isInGroup("wheel")) {
          var verb = action.lookup("verb");
          if (verb == "start" || verb == "stop" || verb == "restart") {
            return polkit.Result.YES;
          }
        }
      });
    '';
  };
}
