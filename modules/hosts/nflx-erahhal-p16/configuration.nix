# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:
{
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

  # --------------------------------------------------------------------------
  # Feature modules (nixcfg.* — auto-included, toggled here)
  # --------------------------------------------------------------------------
  nixcfg = {
    desktop = {
      enable = true;
      niri.enable = true;
      dms.enable = true;
      pipewire.enable = true;
      fonts.enable = true;
      chromium-based-apps.enable = true;
    };
    networking = {
      tailscale.enable = true;
      mullvad.enable = true;
      kdeconnect.enable = true;
      wireless.enable = true;
      wifi-qos.enable = true;
      homefree.enable = true;
      captive-portal.enable = true;
      exclusive-lan.enable = true;
      connection-sharing.enable = true;
    };
    hardware = {
      gfx-nvidia.enable = true;
      gfx-intel.enable = true;
      laptop.enable = true;
      udev-rules.enable = true;
      spacenavd.enable = true;
    };
    programs = {
      appimage.enable = true;
      android.enable = true;
      totp.enable = true;
      # steam.enable = true;
      flatpak.enable = true;
      flox.enable = true;
      switchyard = {
        enable = true;
        rules = [
          {
            name = "Chromium (work)";
            browser = "chromium-browser.desktop";
            logic = "any";
            conditions = lib.concatMap (d: [
              { type = "glob"; pattern = d; }
              { type = "glob"; pattern = "*.${d}"; }
            ]) [
              "netflix.com"
              "netflix.net"
              "netflixstudios.com"
              "nflxvideo.net"
              "braintrust.dev"
              "flxvpn.net"
              "google.com"
            ];
          }
        ];
      };
      whisper-dictation = {
        enable = true;
        # Toggle-style -- bind `whisper-dictate` to a compositor hotkey.
        # See modules/hosts/nflx-erahhal-p16/niri.nix (Mod+Period).
      };
      nerd-dictation = {
        enable = true;
        # Full 1.8 GB US English model -- most accurate non-gigaspeech option,
        # still realtime on this CPU. See models.nix for smaller alternatives:
        #   small-en-us-0_15     (≈40 MB, fastest)
        #   en-us-0_22-lgraph    (≈130 MB, balanced)
        #   en-us-0_22           (≈1.8 GB, this one)
        model = "en-us-0_22";
      };
      # moonshine dropped (2026-04): even on the largest streaming model
      # (MEDIUM_STREAMING) it clipped first words and hallucinated on
      # short utterances. Replaced by the combination of nerd-dictation
      # (streaming, Mod+Comma, en-us-0_22) + whisper-dictate (batch,
      # Mod+Period, large-v3-turbo Vulkan). Packaging kept in pkgs/ if
      # we want to revisit.
    };
    services = {
      waydroid.enable = true;
      snapcast.enable = true;
      printers-scanners.enable = true;
      # nfs-mounts.enable = true;
    };
  };

  # --------------------------------------------------------------------------
  # Remaining imports (not yet converted to nixcfg.* modules)
  # --------------------------------------------------------------------------
  imports = [
    # device specific
    ./disk-config-btrfs.nix
    ./hardware-configuration.nix

    # host specific
    ./virtualization.nix

    # user specific
    ./user.nix

    # Display config
    ./kanshi.nix
    ./niri.nix
    ../../desktop/niri/user-window-rules.nix
    ../../desktop/niri/user-overrides.nix
  ];

  nixpkgs.config.packageOverrides = pkgs: {
    vmware-workstation = pkgs.symlinkJoin {
      name = "vmware-workstation-wrapped";
      paths = [ pkgs.vmware-workstation.unwrapped or pkgs.vmware-workstation ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        # Find all executables in the VMware package
        find $out/bin -type f -executable 2>/dev/null | while read -r exe; do
          if [ -f "$exe" ] && [ -x "$exe" ] && [ ! -L "$exe" ]; then
            # Move the original executable
            mv "$exe" "$exe.unwrapped"

            # Create a wrapper that sets GDK_DPI_SCALE
            makeWrapper "$exe.unwrapped" "$exe" \
              --set GDK_DPI_SCALE "0.75"
          fi
        done

        # Also handle any executables in libexec or other locations
        if [ -d "$out/libexec" ]; then
          find "$out/libexec" -type f -executable 2>/dev/null | while read -r exe; do
            if [ -f "$exe" ] && [ -x "$exe" ] && [ ! -L "$exe" ]; then
              mv "$exe" "$exe.unwrapped"
              makeWrapper "$exe.unwrapped" "$exe" \
                --set GDK_DPI_SCALE "0.75"
            fi
          done
        fi

        # Handle any other potential executable locations
        for dir in lib share; do
          if [ -d "$out/$dir" ]; then
            find "$out/$dir" -name "vmware*" -o -name "vmplayer*" | while read -r file; do
              # Only process if it's a regular file, executable, and not a symlink
              if [ -f "$file" ] && [ -x "$file" ] && [ ! -L "$file" ]; then
                # Check if it's actually an executable (has shebang or is binary)
                if file "$file" | grep -q -E "(executable|script)"; then
                  mv "$file" "$file.unwrapped"
                  makeWrapper "$file.unwrapped" "$file" \
                    --set GDK_DPI_SCALE "0.75"
                fi
              fi
            done
          fi
        done
      '';
    };
  };


  # --------------------------------------------------------------------------------------
  # Boot
  # --------------------------------------------------------------------------------------

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
    # Set font size early
    efi = {
      canTouchEfiVariables = true;
    };
  };

  # boot.kernelPackages = pkgs.linuxPackages_6_18;
  # boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernel.sysctl = {
    ## attempt to get rid of "rpfilter drop" messages in dmesg, which may be causing intermittent connectivity issues
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
  };

  # --------------------------------------------------------------------------------------
  # Device specific
  # --------------------------------------------------------------------------------------

  ## Fixes microphone
  ## See: https://askubuntu.com/questions/1283440/how-to-fix-ubuntu-incorrectly-seeing-the-internal-microphone-as-an-unplugged-h
  # boot.blacklistedKernelModules = [ "snd-soc-dmic" "snd-acp3x-rn" "snd-acp3x-pdm-dma" ];

  ## Change mac randomly on connection
  sec.macchanger = {
    enable = false;
    devices = [
      ## Real: E4:60:17:0F:28:C3
      "wlan0"
    ];
  };

  ## Attempt to address wifi connectivity issues
  # boot.extraModprobeConfig = ''
  #   options iwlwifi power_save=0
  #   options iwlmvm power_scheme=1
  # '';

  networking = {
    networkmanager = {
      enable = true;
      # Wifi power settings - do not remove
      #   - Either disabling wifi powersave here, or adding
      #     the kernel modules and params below fixed an intermittent
      #     hard freeze when on battery.
      wifi = {
        # Use iwd backend for better roaming behavior and auto-connect
        backend = "iwd";
        powersave = false;
        scanRandMacAddress = false;
      };
      ## When NtworkManager-wait-online.service is enabled, having wg0
      ## as a managed interface may interfere with the service coming up.
      # unmanaged = [
      #   "wg0"
      # ];
    };
    wireless = {
      # Disable wpa_supplicant (using iwd instead)
      enable = false;
      # iwd = {
      #   enable = true;
      #   settings = {
      #     General = {
      #       # Enable network configuration through iwd
      #       EnableNetworkConfiguration = false;
      #     };
      #     Settings = {
      #       # Auto-connect to known networks
      #       AutoConnect = true;
      #     };
      #   };
      # };
    };
    ## Don't include this line - it will add an additional default route.
    ## It's not necessary.
    # interfaces."wlan0".useDHCP = true;
  };

  # WiFi QoS now managed via nixcfg.networking.wifi-qos (see above)

  programs.captive-browser = {
    enable = true;
    interface = "wlan0";
  };

    # Enable the fprintd daemon
  services.fprintd.enable = false;

  # Enable fingerprint auth for specific PAM services
  security.pam.services = {
    login.fprintAuth = false;
    sudo.fprintAuth = false;
    polkit-1.fprintAuth = false;
    xscreensaver.fprintAuth = false;
  };

  services.smokeping = {
    enable = false;
    hostName = "${config.hostParams.hostName}.lan";
    targetConfig = ''
      probe = FPing
      menu = Top
      title = Network Latency Grapher
      remark = Welcome to SmokePing
      + google
      menu = Google
      title = google Network
      ++ googlesite
      host = google.com
      ++ googledns
      host = 8.8.8.8
      + netflix
      menu = Netflix
      title = Netlix Network
      ++ vpn
      host = lt.ovpn.netflix.net
      + home
      menu = Home
      title = Home Network
      ++ nasserver
      host = nas.lan
    '';
  };

  networking.firewall = {
    allowedUDPPorts = [
      4242  # lan-mouse
    ];
    allowedTCPPorts = [
      # Common docker development port
      80
      3000
      8080
      7002
      7001
      7101
      24800  # deskflow
    ];
    trustedInterfaces = [ "docker0" "br-+" ];
  };


  # --------------------------------------------------------------------------------------
  # Hardware specific
  # --------------------------------------------------------------------------------------

  # Despite the generic name, this is Lenovo specific
  ## Doesn't currently work with x1c CPU
  services.throttled.enable = false;

  # Thinkpad settings

  # Kernel settings - do not remove
  #   - Either adding these kernel modules and params,
  #     or turning off power saving on wifi fixed an intermittent
  #     hard freeze when on battery.
  # boot.extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];
  # boot.kernelModules = [ "thinkpad-acpi" "acpi_call" ];
  # boot.initrd.kernelModules = [ "thinkpad-acpi" "acpi_call" ];
  boot.kernelParams = [
    ## Seems to be needed for suspend to S0 (s2idle) without hanging
    ''acpi_osi="Windows 2022"''

    # Prevent spurious wakeups from a firmware bug where the EC or SMU generates spurious "heartbeat" interrupts during sleep
    "acpi.ec_no_wakeup=1"

    # NOTE: `usbcore.autosuspend=-1` was previously set here to "prevent the
    # dock from waking up the laptop right after suspend". It had a severe
    # side effect: this hardware only supports s2idle / Modern Standby (the
    # firmware does not expose S3 / `deep` in /sys/power/mem_sleep), and
    # globally disabling USB autosuspend kept the XHCI controllers (and
    # therefore the PCH) out of any low-power state during sleep. Result:
    # `slp_s0_residency_usec` was always 0 -- the SoC never entered S0ix
    # during "sleep", so the laptop drew ~1.5-2W with the lid closed and
    # a multi-hour sleep would chew through most of the battery. The
    # original wakeup concern is already addressed by the
    # `disable-wakeup-sources` systemd service below (which disables wakeup
    # on the Thunderbolt root port RP09 and the XHCI controller) plus
    # `acpi.ec_no_wakeup=1` above. If a *specific* dock device misbehaves
    # in the future, denylist just that device via TLP's USB_DENYLIST
    # rather than re-disabling autosuspend globally. To verify S0ix entry
    # after a suspend cycle:
    #   sudo cat /sys/kernel/debug/pmc_core/slp_s0_residency_usec
    # (should be > 0 and growing across suspends).

    ## Settings that supposedly increase gaming perf and prevent HDMI audio dropouts during gaming
    "preempt=full"    # Realitime latency
    "threadirqs"      # forces most interrupt handlers to run in a threaded context, thus reducing input latency.

    # Retry PCI resource assignment so the TB4 dock's downstream bridges get I/O space.
    # Without this, "bridge window [io size 0x5000]: can't assign; no space" errors on
    # the Goshen Ridge bridges leave the dock's USB 2.0 tunnel (Fresco Logic V1003,
    # 17ef:30ba) unenumerated, which breaks every HID device on the dock/monitor.
    "pci=realloc=on"

    # Don't reserve any I/O port window for hot-pluggable PCIe bridges. x86 has only
    # 64 KiB of legacy I/O port space total, and the TB4 dock's bridge tree alone
    # asks for ~74 KiB (0xe000 + 0xd000 + 0xd000 + several smaller windows behind
    # Maple Ridge and Goshen Ridge). With realloc on but no size cap, every plug-in
    # is a coin flip: some bridges win I/O windows, others get "can't assign; no
    # space" and their endpoints fail to enumerate. Empirically that surfaces as
    # "ethernet works but the external monitor doesn't" or vice-versa, flipping on
    # every replug.
    # All endpoints on this dock (Fresco Logic xHCI, RTL8156 USB ethernet via the
    # dock's USB hubs, DP mux) use MMIO; none need legacy I/O ports, so setting the
    # hot-plug I/O size to 0 lets realloc succeed without dropping any device.
    "pci=hpiosize=0"

    # IOMMU passthrough for trusted integrated devices. The Intel IOMMU on this
    # platform has a 39-bit MGAW; after pci=realloc=on, the integrated xHCI
    # (0000:00:14.0) was issued DMA addresses beyond that, producing
    # "DMAR: [DMA Read NO_PASID] ... Access beyond MGAW" and halting the
    # controller with "xhci_hcd: WARNING: Host System Error" ~25s after login —
    # taking every USB HID device with it. Passthrough bypasses IOMMU
    # translation for integrated PCIe devices; Thunderbolt peripherals still
    # get IOMMU isolation via bolt's iommu policy.
    "iommu=pt"

    # Hibernation: physical offset (in 4 KiB pages) of the first extent of
    # /swap/swapfile on /dev/mapper/cryptroot. Paired with boot.resumeDevice
    # below (search for "Hibernation resume target"). Recompute if the
    # swapfile is ever recreated, resized, defragmented, or restored from
    # btrfs send/recv:
    #   sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
    "resume_offset=533760"

    # ----- Hibernate-debug params (TEMPORARY -- remove once root cause found)
    # The hibernate-write path hangs at "PM: hibernation: hibernation entry"
    # with no further kernel output -- consistent with a driver suspend
    # callback (likely NVIDIA) that never returns. These params keep
    # diagnostic output visible/captured so the offending device shows up
    # in the previous-boot journal.
    #
    # no_console_suspend: keep the framebuffer console alive across the
    #   suspend-device phase so dpm_suspend() printk's reach the visible
    #   console instead of disappearing into a frozen FB driver.
    # pm_debug_messages: per-device suspend timing/result lines.
    # initcall_debug: every driver's suspend/resume callbacks; the LAST
    #   "calling <dev>+" line without a matching "... done" names the
    #   driver that hung.
    "no_console_suspend"
    "pm_debug_messages"
    "initcall_debug"
    # ----- end hibernate-debug params
  ];

  # ------------------------------------------------------------------------
  # Suspend / S0ix power-management knobs
  # ------------------------------------------------------------------------
  # Known BIOS limitation -- multi-hour standby battery drain:
  #
  # This laptop's firmware only advertises s2idle in /sys/power/mem_sleep
  # (Modern Standby) -- there is no S3 / `deep` option. For s2idle to be
  # low-power the SoC must reach S0ix. However, S0ix is completely blocked
  # by firmware limitations on this P16 Gen 2:
  #   1. The Lenovo BIOS actively disables ASPM on the TB4 root port
  #      (00:1d.0 / RP09) and hides L1 substates.
  #   2. The NVIDIA GPU GSP firmware times out during the PMC handshake
  #      (`PFM_REQ_HNDLR_STATE_SYNC_CALLBACK`).
  # As a result, `slp_s0_residency_usec` will always remain 0, and the
  # laptop will draw ~1.5-2W during sleep. Pure OS-level changes CANNOT
  # fix this.
  #
  # Solution: suspend-then-hibernate.
  # The machine will sleep normally (in s2idle) for 30 minutes, allowing
  # quick desk-to-desk roaming. After 30 minutes of sleep, it automatically
  # wakes up briefly to save the session to the SSD and fully powers off.
  services.logind = {
    # TEMPORARY for hibernate debug: leave lidSwitch at default so we can
    # test `systemctl hibernate` directly from a TTY without the chained
    # suspend-then-hibernate path interfering. Restore the line below
    # once a clean hibernate cycle works.
    # lidSwitch = lib.mkForce "suspend-then-hibernate";
    # Optional: also hibernate on external power so it doesn't cook in a bag
    # lidSwitchExternalPower = "suspend-then-hibernate";
  };

  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "30m";
  };

  # Hibernation resume target.
  #
  # Disko creates /swap/swapfile via `btrfs filesystem mkswapfile`
  # (NOCOW, contiguous extents, lock-protected) -- hibernation-safe by
  # construction. But disko does NOT wire boot.resumeDevice or
  # resume_offset, so without these two params the kernel boots fresh
  # after suspend-then-hibernate fires and the saved image is discarded.
  #
  # `resume=` is the LUKS-decrypted block device holding the btrfs FS
  # (already opened in initrd via FIDO2, so it exists at the moment the
  # kernel reads the resume image). `resume_offset=` lives next to the
  # other boot.kernelParams above.
  boot.resumeDevice = "/dev/mapper/cryptroot";

  # Keep the VeriMark fingerprint key (047d:8055) from pinning USB2 awake.
  # It defaults to `power/control=on` because it enumerates as an HID
  # device, and fprintd is disabled here anyway, so it is literally never
  # used -- but while it is powered the PMC's `USB2_SUS_PG_Sys_REQ_STS`
  # stays 0, which is one of the concrete S0ix blockers observed in
  # `substate_status_registers` on this machine.
  services.udev.extraRules = ''
    # Autosuspend unused USB HID fingerprint reader (ThinkPad P16)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="047d", ATTR{idProduct}=="8055", TEST=="power/control", ATTR{power/control}="auto"

    # Trigger PCI rescan when the ThinkPad TB4 Dock is authorized.
    # The dock's Goshen Ridge PCIe endpoint devices (ethernet, USB 3.x xHCI,
    # DisplayPort) need a few seconds to power up after Thunderbolt authorization;
    # pciehp has already initialized its slots by then and will miss them unless
    # we force a rescan.
    # UUID: ThinkPad Thunderbolt 4 Dock = 11328780-0035-7a6c-ffff-ffffffffffff
    ACTION=="change", SUBSYSTEM=="thunderbolt", ATTR{unique_id}=="11328780-0035-7a6c-ffff-ffffffffffff", ATTR{authorized}=="1", RUN+="${pkgs.systemd}/bin/systemctl start --no-block dock-pcie-rescan.service"
  '';

  # Disable wakeup sources that cause spurious wakes with Thunderbolt dock
  systemd.services.disable-wakeup-sources = {
    description = "Disable Thunderbolt/USB wakeup sources";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Disable Thunderbolt PCIe root port wakeup (RP09)
      echo disabled > /sys/devices/pci0000:00/0000:00:1d.0/power/wakeup || true

      # Disable USB XHCI controller wakeup
      echo disabled > /sys/devices/pci0000:00/0000:00:14.0/power/wakeup || true

      # Disable ACPI wakeup for XHCI and RP09 (toggle if enabled)
      grep -q "XHCI.*enabled" /proc/acpi/wakeup && echo XHCI > /proc/acpi/wakeup || true
      grep -q "RP09.*enabled" /proc/acpi/wakeup && echo RP09 > /proc/acpi/wakeup || true
    '';
  };

  # After the dock is authorized over Thunderbolt, its internal Goshen Ridge
  # PCIe endpoint devices (RTL8156 ethernet, Fresco Logic xHCI, DP mux) take
  # several seconds to power up.  By then pciehp has already initialized the
  # hot-plug slots in interrupt-wait mode and will never see a Card Present
  # transition.  Writing to the sysfs rescan knob forces pci_scan_slot() on
  # every Goshen Ridge downstream bridge so the endpoints finally enumerate.
  systemd.services.dock-pcie-rescan = {
    description = "PCI rescan after ThinkPad TB4 Dock PCIe endpoint power-up";
    # Chain the USB-3 controller rebind to fire after the PCI rescan completes;
    # see dock-usb-rebind.service below.
    wants = [ "dock-usb-rebind.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "dock-pcie-rescan" ''
        sleep 5
        # Rescan all Goshen Ridge PCIe bridges (dock's internal TB4 controller, PCI ID 8086:0b26).
        # Bus numbers can shift between boots, so we discover them dynamically.
        for bridge in $(${pkgs.pciutils}/bin/lspci -d 8086:0b26 -D | ${pkgs.gawk}/bin/awk '{print $1}'); do
          echo 1 > /sys/bus/pci/devices/"$bridge"/rescan 2>/dev/null || true
        done
        # Belt-and-suspenders full rescan for anything the targeted pass missed.
        echo 1 > /sys/bus/pci/rescan
      '';
    };
  };

  # On hot replug, the dock's TB-tunneled USB 2 devices come back fine on bus 1,
  # but the SuperSpeed (USB 3) link to the dock often fails to re-train -- bus 4
  # ends up empty and the dock's r8152 ethernet (17ef:30b6/30b8) plus anything
  # else that lives on USB 3 never enumerate. Cold boot works; only hot replug
  # is broken. boltctl-forget + replug doesn't reliably fix it, neither does a
  # plain replug -- which subsystem fails (ethernet vs DP) is roughly random.
  #
  # Rebinding the laptop-side TB4 USB controller (Maple Ridge, 8086:1138) forces
  # a fresh xHCI init, which re-runs port discovery on the TB-tunneled SuperSpeed
  # link and picks up the dock's bus-4 devices. The internal USB controller
  # (0000:00:14.0) is a SEPARATE device and is untouched -- internal camera,
  # Bluetooth, fingerprint reader stay up. Internal keyboard/trackpoint are
  # i8042/PS-2, not USB, so also unaffected.
  systemd.services.dock-usb-rebind = {
    description = "Rebind Maple Ridge TB4 USB controller after dock authorize (recover bus-4 SuperSpeed enum)";
    after = [ "dock-pcie-rescan.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "dock-usb-rebind" ''
        set -u
        # Discover by Vendor:Device ID rather than hard-coded BDF. 8086:1138 is
        # the Maple Ridge TB4 USB Controller; on this machine it lives at
        # 0000:48:00.0 today but discovery keeps us robust against future kernel
        # / firmware reshuffles.
        BDF=$(${pkgs.pciutils}/bin/lspci -d 8086:1138 -D 2>/dev/null | ${pkgs.gawk}/bin/awk '{print $1}' | head -1)
        if [ -z "$BDF" ]; then
          ${pkgs.util-linux}/bin/logger -t dock-usb-rebind "no Maple Ridge TB4 USB controller found; skipping"
          exit 0
        fi
        ${pkgs.util-linux}/bin/logger -t dock-usb-rebind "rebinding xhci_hcd on $BDF"
        echo "$BDF" > /sys/bus/pci/drivers/xhci_hcd/unbind 2>/dev/null || true
        sleep 2
        echo "$BDF" > /sys/bus/pci/drivers/xhci_hcd/bind 2>/dev/null || true
        ${pkgs.util-linux}/bin/logger -t dock-usb-rebind "rebind complete"
      '';
    };
  };

  # ------------------------------------------------------------------------
  # KNOWN ISSUE -- dock ethernet sometimes needs `systemctl restart
  # NetworkManager` after dock plug-in to get an IPv4 lease.
  # ------------------------------------------------------------------------
  # A working per-device `nmcli` nudge workaround (extending the rescan
  # service above + a sibling `dock-eth-nm-nudge.service` for resume) is
  # block-commented below. Left disabled because we don't have ground truth
  # on the failure mode -- enabling it would mask the broken state from
  # forensic capture, and the right long-term fix is almost certainly a
  # one-line NM config (autoconnect-retries / dhcp-timeout /
  # carrier-wait-time) once we know the REASON.
  #
  # NEXT TIME IT FIRES, BEFORE restarting NM, capture:
  #   nmcli device show <iface>          # state + STATE-REASON pins root cause
  #   nmcli connection show --active
  #   journalctl -u NetworkManager --since '-3 min' --no-pager
  #   ip -d link show <iface>; cat /sys/class/net/<iface>/carrier
  #   dmesg | tail -50
  # REASON values map to fixes:
  #   - autoconnect-retries exhausted -> raise `connection.autoconnect-retries`
  #   - DHCP timeout                  -> raise `ipv4.dhcp-timeout`, set `ipv4.may-fail`
  #   - no-carrier at probe           -> raise NM `[device].carrier-wait-time`
  #   - dispatcher race               -> fix exclusive-lan dispatcher
  /*
  systemd.services.dock-pcie-rescan = {
    description = "PCI rescan + NM nudge after ThinkPad TB4 Dock PCIe endpoint power-up";
    after = [ "NetworkManager.service" ];
    wants = [ "NetworkManager.service" ];
    serviceConfig = {
      Type = "oneshot";
      StartLimitIntervalSec = 30;
      StartLimitBurst = 3;
      ExecStart = pkgs.writeShellScript "dock-pcie-rescan" ''
        set -u
        export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.pciutils pkgs.gawk pkgs.networkmanager pkgs.util-linux pkgs.gnugrep pkgs.gnused ]}:$PATH

        exec 9>/run/dock-eth-nudge.lock
        flock -n 9 || exit 0
        log() { logger -t dock-pcie-rescan "$*"; }

        sleep 5
        for bridge in $(lspci -d 8086:0b26 -D | awk '{print $1}'); do
          echo 1 > /sys/bus/pci/devices/"$bridge"/rescan 2>/dev/null || true
        done
        echo 1 > /sys/bus/pci/rescan 2>/dev/null || true

        find_dock_iface() {
          local iface drv parent_pci goshen_pci_re
          goshen_pci_re=$(lspci -d 8086:0b26 -D | awk '{printf "%s|", $1}' | sed 's/|$//')
          [ -z "$goshen_pci_re" ] && return 1
          for iface_path in /sys/class/net/*; do
            iface=$(basename "$iface_path")
            [ "$iface" = "lo" ] && continue
            drv=$(basename "$(readlink -f "$iface_path/device/driver" 2>/dev/null)" 2>/dev/null)
            case "$drv" in r8169|r8152) ;; *) continue ;; esac
            parent_pci=$(readlink -f "$iface_path/device" 2>/dev/null)
            if echo "$parent_pci" | grep -Eq "$goshen_pci_re"; then
              echo "$iface"
              return 0
            fi
          done
          return 1
        }

        iface=""
        for _ in $(seq 1 50); do
          iface=$(find_dock_iface) && [ -n "$iface" ] && break
          sleep 0.5
        done
        if [ -z "$iface" ]; then
          log "no dock ethernet netdev appeared within 25s; bailing"
          exit 0
        fi
        log "found dock ethernet iface: $iface"

        for _ in $(seq 1 40); do
          [ "$(cat /sys/class/net/"$iface"/carrier 2>/dev/null || echo 0)" = "1" ] && break
          sleep 0.5
        done

        state=$(nmcli -t -g GENERAL.STATE device show "$iface" 2>/dev/null || echo "")
        log "iface $iface NM state before nudge: $state"
        case "$state" in
          *"100 (connected)"*) log "already connected; no nudge"; exit 0 ;;
        esac
        nmcli device set "$iface" managed yes 2>/dev/null || true
        prof=$(nmcli -t -g GENERAL.CONNECTION device show "$iface" 2>/dev/null || echo "")
        if [ -n "$prof" ] && [ "$prof" != "--" ]; then
          nmcli --wait 30 connection up "$prof" ifname "$iface" 2>&1 | logger -t dock-pcie-rescan \
            || nmcli --wait 30 device connect "$iface" 2>&1 | logger -t dock-pcie-rescan || true
        else
          nmcli --wait 30 device connect "$iface" 2>&1 | logger -t dock-pcie-rescan || true
        fi
        log "nudge complete; final state: $(nmcli -t -g GENERAL.STATE device show "$iface" 2>/dev/null)"
      '';
    };
  };

  systemd.services.dock-eth-nm-nudge = {
    description = "Nudge NetworkManager for dock ethernet after resume";
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" "NetworkManager.service" ];
    wants = [ "NetworkManager.service" ];
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "dock-eth-nm-nudge" ''
        set -u
        export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.pciutils pkgs.gawk pkgs.networkmanager pkgs.util-linux pkgs.gnugrep pkgs.gnused ]}:$PATH

        exec 9>/run/dock-eth-nudge.lock
        flock -n 9 || exit 0
        log() { logger -t dock-eth-nm-nudge "$*"; }

        find_dock_iface() {
          local iface drv parent_pci goshen_pci_re
          goshen_pci_re=$(lspci -d 8086:0b26 -D | awk '{printf "%s|", $1}' | sed 's/|$//')
          [ -z "$goshen_pci_re" ] && return 1
          for iface_path in /sys/class/net/*; do
            iface=$(basename "$iface_path")
            [ "$iface" = "lo" ] && continue
            drv=$(basename "$(readlink -f "$iface_path/device/driver" 2>/dev/null)" 2>/dev/null)
            case "$drv" in r8169|r8152) ;; *) continue ;; esac
            parent_pci=$(readlink -f "$iface_path/device" 2>/dev/null)
            if echo "$parent_pci" | grep -Eq "$goshen_pci_re"; then
              echo "$iface"
              return 0
            fi
          done
          return 1
        }

        iface=$(find_dock_iface) || true
        [ -z "$iface" ] && exit 0

        for _ in $(seq 1 40); do
          [ "$(cat /sys/class/net/"$iface"/carrier 2>/dev/null || echo 0)" = "1" ] && break
          sleep 0.5
        done

        state=$(nmcli -t -g GENERAL.STATE device show "$iface" 2>/dev/null || echo "")
        case "$state" in
          *"100 (connected)"*) exit 0 ;;
        esac
        nmcli device set "$iface" managed yes 2>/dev/null || true
        prof=$(nmcli -t -g GENERAL.CONNECTION device show "$iface" 2>/dev/null || echo "")
        if [ -n "$prof" ] && [ "$prof" != "--" ]; then
          nmcli --wait 30 connection up "$prof" ifname "$iface" 2>&1 | logger -t dock-eth-nm-nudge \
            || nmcli --wait 30 device connect "$iface" 2>&1 | logger -t dock-eth-nm-nudge || true
        else
          nmcli --wait 30 device connect "$iface" 2>&1 | logger -t dock-eth-nm-nudge || true
        fi
        log "post-resume nudge complete; final state: $(nmcli -t -g GENERAL.STATE device show "$iface" 2>/dev/null)"
      '';
    };
  };
  */

  # # Fix NVIDIA USB4 DP tunnel not resuming after suspend
  # # The NVIDIA driver's proprietary USB4 DP tunnel implementation doesn't properly
  # # re-establish the tunnel after suspend. We need to reload the modules.
  # systemd.services.nvidia-resume-fix = {
  #   description = "Fix NVIDIA USB4 DP tunnel after resume";
  #   after = [ "nvidia-resume.service" "systemd-suspend.service" "systemd-hibernate.service" ];
  #   wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";  # Wait for Thunderbolt link
  #   };
  #   script = ''
  #     # Check if DP outputs are disconnected (indicates failed resume)
  #     if grep -q "disconnected" /sys/class/drm/card0-DP-1/status 2>/dev/null; then
  #       echo "NVIDIA DP tunnel not restored, reloading modules..."
  #
  #       # Remove and reload NVIDIA modules to reset DP tunnel state
  #       ${pkgs.kmod}/bin/rmmod nvidia_drm nvidia_modeset nvidia_uvm nvidia 2>/dev/null || true
  #       sleep 1
  #       ${pkgs.kmod}/bin/modprobe nvidia
  #       ${pkgs.kmod}/bin/modprobe nvidia_modeset
  #       ${pkgs.kmod}/bin/modprobe nvidia_uvm
  #       ${pkgs.kmod}/bin/modprobe nvidia_drm
  #
  #       echo "NVIDIA modules reloaded"
  #     fi
  #   '';
  # };

  # Enable power management
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  services.upower = {
    enable = true;
    criticalPowerAction = "Hibernate";
  };

  # Thinkpad power and performance management
  services.power-profiles-daemon.enable = false; # conflicts with TLP
  services.tlp = {
    enable = true;
    settings = {
      # Control battery feature drivers:
      # NATACPI_ENABLE = 1;
      # TPACPI_ENABLE = 1;
      # TPSMAPI_ENABLE = 1;

      # # Sometimes dock doesn't unuspend, causing USB to stop working
      # USB_AUTOSUSPEND = 0;
      # USB_DENYLIST = "17ef:30b4 17ef:30b5 17ef:30b6 17ef:30b7 17ef:30b8 17ef:30b9 17ef:30ba 17ef:30bb";

      ## "performance" severely degrades IO performance on X1C. Leave as default ("powersave").
      ## Options are "performance" and "powersave" when intel_pstate is active
      ## cat /sys/devices/system/cpu/intel_pstate/status
      # CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      # CPU_HWP_ON_AC = "balance_performance";
      # CPU_HWP_ON_BAT = "balance_power";
      # ENERGY_PERF_POLICY_ON_AC = "performance";
      # ENERGY_PERF_POLICY_ON_BAT = "powersave";
      # SATA_LINKPWR_ON_AC = "max_performance";
      # SATA_LINKPWR_ON_BAT = "min_power";
      # PCIE_ASPM_ON_AC = "performance";
      # PCIE_ASPM_ON_BAT = "powersave";

      # 100 being the maximum, limit the speed of my CPU to reduce
      # heat and decrease battery usage:
      CPU_MAX_PERF_ON_AC = 100;
      CPU_BOOST_ON_AC = 1;

      CPU_MAX_PERF_ON_BAT = 50;
      # Only works if intel_pstate is active
      CPU_BOOST_ON_BAT = 0;

      ## High-perf battery settings
      # CPU_MAX_PERF_ON_BAT = 100;
      # CPU_BOOST_ON_BAT = 1;

      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 1;

      # Restore charge thresholds when AC is unplugged, ensuring any
      # temporary overrides (e.g. from `tlp fullcharge`) get reverted.
      RESTORE_THRESHOLDS_ON_BAT = 1;

      # The following prevents the battery from charging fully to
      # preserve lifetime. Run `tlp fullcharge` to temporarily force
      # full charge.
      # https://linrunner.de/tlp/faq/battery.html#how-to-choose-good-battery-charge-thresholds
    } // (if config.hostParams.system.thinkpad-battery-charge-to-full then {
      ## START can't be above 99
      START_CHARGE_THRESH_BAT0=99;
      STOP_CHARGE_THRESH_BAT0=100;
      START_CHARGE_THRESH_BAT1=99;
      STOP_CHARGE_THRESH_BAT1=100;
    } else {
      START_CHARGE_THRESH_BAT0 = 80;
      STOP_CHARGE_THRESH_BAT0 = 90;
      START_CHARGE_THRESH_BAT1 = 80;
      STOP_CHARGE_THRESH_BAT1 = 90;
    });
  };
}

