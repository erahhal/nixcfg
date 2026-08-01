{ config, pkgs, ... }:
{
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

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
      mullvad.enable = true;
      kdeconnect.enable = true;
      connection-sharing.enable = true;
    };
    hardware = {
      gfx-nvidia.enable = true;
      gfx-amd.enable = true;
      udev-rules.enable = true;
      openrgb = {
        enable = true;
        motherboard = "amd";
        profile = ./Red.orp;
      };
      keyboard-debounce.enable = true;
      spacenavd.enable = true;
    };
    programs = {
      android.enable = true;
      flatpak.enable = true;
      flox.enable = true;
      switchyard.enable = true;
    };
    services = {
      nfs-mounts.enable = true;
    };
  };

  ## AI model-serving stack (external flake: ~/Code/genai-server)
  services.genai-server.enable = true;
  ## genai group: write access to the shared model store
  ## (/var/lib/genai-models), LoRA store, and training jobs — no sudo needed
  ## for lora-train / lora-add / genai-fetch-media.
  users.users.${config.hostParams.user.username}.extraGroups = [ "genai" ];
  ## Serve on all interfaces (WiFi now, Ethernet later). NOTE: the APIs are
  ## unauthenticated — the whole LAN gets full access. Open WebUI is the
  ## exception since it went up on webui.homefree.host (see webui.auth
  ## below): its port is withheld from this blanket opening and admitted
  ## only from the router.
  services.genai-server.openFirewallGlobally = true;

  ## Open WebUI identifies users by the header the router's oauth2-proxy
  ## injects, so each SSO account gets its own chats. Before this it ran
  ## WEBUI_AUTH=False — one implicit `admin@localhost` that every visitor
  ## landed in, which was fine while only this LAN could reach it and
  ## stopped being fine the moment it was published behind SSO.
  ##
  ## trustedProxies is the security boundary, not a nicety: the header is a
  ## bearer token, so this list is exactly who may claim to be anyone. Both
  ## router addresses, because which one Caddy sources from depends on
  ## whether logistikon.lan resolves over the LAN or the tailnet.
  services.genai-server.webui.auth = {
    mode = "trusted-header";
    trustedProxies = [ "10.0.0.1" "100.64.0.2" ];
    ## Role comes from Zitadel on every sign-in: the router's gate calls
    ## admin-api's /api/auth/role and copies the verdict onto the request,
    ## so holding homefree-admin grants the Open WebUI admin panel and
    ## losing it takes the panel away at the next login.
    roleHeader = "X-Homefree-Role";
    ## Identity and display name come from the directory, not from
    ## oauth2-proxy. Its X-Auth-Request-Email carries whatever
    ## USER_ID_CLAIM picked — `preferred_username` here, so the header
    ## named "email" holds a login handle — and it has no display-name
    ## header at all. admin-api reports both from Zitadel alongside the
    ## role, so accounts here are keyed on a real address and show a real
    ## name.
    emailHeader = "X-Homefree-Email";
    nameHeader = "X-Homefree-Name";
    ## The seeder signs in over loopback with no proxy to label it, so it
    ## asserts this identity itself. Must match what the gate sends, and
    ## must be an admin.
    seedIdentity = "ellis@rahh.al";
  };
  ## Resolve our own LAN name to loopback, so nothing on this box depends on
  ## the network to reach services running on this box. Unpinned,
  ## "logistikon.lan" is answered only by the router's DNS and resolves to the
  ## wlan0 address — so a Wi-Fi drop, or a VPN that hijacks DNS and blocks LAN
  ## traffic (Mullvad switched on unconfigured, 2026-07-31), cuts the machine
  ## off from its own portal and models. Same trick the homefree module uses
  ## for *.homefree.lan. Local-only: this file is /etc/hosts on logistikon, so
  ## LAN clients (and the mediaPublicUrl links below) are unaffected.
  ## The CLI harnesses do not rely on this — they address :4000 as 127.0.0.1
  ## directly on this host (modules/programs/ai-coding), which survives even a
  ## wedged resolver, since nsswitch consults systemd-resolved before `files`.
  networking.extraHosts = ''
    127.0.0.1 logistikon.lan
  '';
  ## Name that resolves for every LAN client (bare "logistikon" doesn't).
  services.genai-server.mediaPublicUrl = "http://logistikon.lan:8894";
  ## MagenticLite (:8895) rejects non-localhost Host headers unless listed
  ## (upstream DNS-rebinding defense; the launcher extends the allowlist).
  services.genai-server.magenticUi.allowedHosts = [ "logistikon.lan" ];
  ## LAN access in addition to the (not-yet-enabled) tailnet. NOTE: the
  ## other services are still unauthenticated — every device on the LAN
  ## gets full access to them. Open WebUI no longer is (webui.auth above).
  services.genai-server.firewallInterfaces = [ "tailscale0" "wlan0" ];
  ## Civitai API token (shared agenix secret): lets image-server download
  ## the token-gated flux_nsfw checkpoint at startup. Without it those
  ## requests 503 ("checkpoint not downloaded").
  services.genai-server.civitaiTokenFile = config.age.secrets."civitai-token".path;
  ## Hugging Face read token (shared agenix secret): unlocks the
  ## license-gated SAM 3 weights (segment-server / smart_edit). The
  ## token's account must have accepted the license at
  ## huggingface.co/facebook/sam3, or the fetch 403s and skips.
  services.genai-server.hfTokenFile = config.age.secrets."hf-token".path;
  ## Build llama-swap from upstream (v245) instead of the nixpkgs v240.
  ## Stage 2 of the roadmap needs >= v242 for selectors (virtual model IDs
  ## that flip a champion/challenger A/B without touching clients),
  ## SQLite-persisted activity metrics and static apiKeys. Config
  ## compatibility was checked against v245's schema and the built binary
  ## starts on this host's config unchanged. The flake warns when nixpkgs
  ## catches up, at which point delete this line.
  services.genai-server.llamaSwap.useNewerBuild = true;
  ## Realtime voice on :8901 (portal page at :8897/voice). The chat model
  ## runs on the CPU, so this costs system RAM rather than VRAM and does not
  ## compete with the card. Transcription still uses the GPU-resident `asr`.
  ## NOTE: the browser only grants microphone access in a secure context —
  ## use http://localhost:8897/voice on this box, not the LAN name.
  services.genai-server.voice.enable = true;

  ## Model choices themselves live in the genai-server-private flake, which
  ## genai-server imports — nothing about them is host-specific, so nothing
  ## about them belongs here.

  ## GPU-inference box: the desktop stack enables power-profiles-daemon,
  ## which defaulted to "balanced" — community-measured ~15% llama.cpp
  ## throughput loss vs performance (found set to balanced 2026-07-20).
  ## ppd persists the profile in /var/lib, but pin it at boot so a fresh
  ## state dir or DE change can't silently regress inference speed.
  systemd.services.power-profile-performance = {
    description = "Pin power-profiles-daemon profile to performance";
    wantedBy = [ "multi-user.target" ];
    after = [ "power-profiles-daemon.service" ];
    requires = [ "power-profiles-daemon.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance";
    };
  };

  imports =
    [
      ./disk-config-btrfs.nix
      ./steam-fix.nix

      # user specific
      ./user.nix

      # display
      ./kanshi.nix
      ../../desktop/niri/user-window-rules.nix
      ../../desktop/niri/user-overrides.nix
    ];

  networking = {
    networkmanager = {
      enable = true;
    };
  };

  # --------------------------------------------------------------------------------------
  # Boot
  # --------------------------------------------------------------------------------------

  boot.loader = {
    timeout = 5;

    systemd-boot = {
      enable = true;
      configurationLimit = 4;
      consoleMode = "max";
    };

    efi = {
      canTouchEfiVariables = true;
      # assuming /boot is the mount point of the  EFI partition in NixOS (as the installation section recommends).
      efiSysMountPoint = "/boot";
    };

    # grub = {
    #   # despite what the configuration.nix manpage seems to indicate,
    #   # as of release 17.09, setting device to "nodev" will still call
    #   # `grub-install` if efiSupport is true
    #   # (the devices list is not used by the EFI grub install,
    #   # but must be set to some value in order to pass an assert in grub.nix)
    #   devices = [ "nodev" ];
    #   efiSupport = true;
    #   enable = true;
    #   # set $FS_UUID to the UUID of the EFI partition
    #   extraEntries = ''
    #     menuentry "Windows" {
    #       insmod part_gpt
    #       insmod fat
    #       insmod search_fs_uuid
    #       insmod chain
    #       search --fs-uuid --set=root $FS_UUID
    #       chainloader /EFI/Microsoft/Boot/bootmgfw.efi
    #     }
    #   '';
    #   useOSProber = true;
    # };
  };

  ## Settings that supposedly increase gaming perf and prevent HDMI audio dropouts during gaming
  boot.kernelParams = [
    "preempt=full"    # Realitime latency
    "nohz_full=all"   # Reduce latency for realtime apps
    "threadirqs"      # forces most interrupt handlers to run in a threaded context, thus reducing input latency.
    # "video=3840x2160@60"
    # "video=efifb"
  ];

  # boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

  # --------------------------------------------------------------------------------------
  # Hardware specific
  # --------------------------------------------------------------------------------------

  boot.kernelModules = [ "snd-hda-intel" "kvm-amd" ];

  ## Onboard Bluetooth and ASMedia ASM4242 USB4 (previously provided by the laptop module)
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.hardware.bolt.enable = true;

  ## Experimental

  nix.settings.extra-platforms = [ "i686-linux" ];
  nix.settings.sandbox = true;
  boot.binfmt.emulatedSystems = [ "i686-linux" ];
  # boot.kernel.sysctl."abi.vsyscall32" = 1;
}

