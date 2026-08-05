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
  ## Stop ComfyUI when no client has been connected for 30 minutes, and let
  ## the activation socket start it again (~7s) on the next request.
  ## Measured 2026-08-02: idle for two days after its last render it still
  ## held 3.9GB of VRAM and 13GB of RAM — the CUDA context and its kernel
  ## images, which `/free` cannot reach and only process exit releases. On
  ## a box where both the card and RAM are contended (minimax alone wants
  ## ~65GB) that is worth a 7s wait. 30min is deliberately longer than any
  ## hand-started render, since idleness is measured by connections.
  services.genai-server.comfyui.idleStopMinutes = 30;
  ## The bulk media sets this box runs, DECLARED rather than fetched by
  ## hand. Everything else in mediaModels is downloaded because it is
  ## declared; these two are held back by comfyui.optInModelSets purely on
  ## size (`comfy` ~90GB: Wan 2.2, LTX 2.3, FLUX.2, ACE-Step; `h3` ~63GB:
  ## MiniMax H3, video with native audio), so a host that wants them says
  ## so here and the comfyui unit fetches them before it serves.
  ##
  ## The `comfy` weights were already on disk with nothing declaring them —
  ## i.e. this machine's store was not a function of its config, and a
  ## rebuild from scratch would have come up missing the models its
  ## workflow templates reference. Fetches are idempotent, so listing them
  ## costs nothing when the files are present.
  services.genai-server.comfyui.modelSets = [ "comfy" "h3" ];
  ## qwen-dense ships disabled: at 25744MiB it cannot coexist with the
  ## resident set (asr + embed + rerank), so it and voice/RAG/memory lock
  ## each other out — whichever loads second dies. Kept available here for
  ## its MTP speed (~80 vs ~47 tok/s), but nothing DEFAULTS to it any more:
  ## `qwen-dense-long` holds the `dense` alias and is what opencode and
  ## Claude Code point at. So this only loads when named explicitly — and
  ## when it does, transcription stops working until it ages out. Drop this
  ## line if that trade is not worth it.
  services.genai-server.llmModels.qwen-dense.serve.enable = true;
  ## Claude Code's background slot (titles, small classification calls) on
  ## the CPU instead of pinned to whatever the session is using. Two things
  ## come of it: that traffic stops queueing behind the conversation on
  ## llama-swap's single GPU slot, and it becomes distinguishable from the
  ## conversation, which is what makes a context readout stop jumping.
  ##
  ## Costs ~2.5GB of host RAM and no VRAM, and downloads nothing — it is the
  ## same GGUF `voice` serves. Measured on this box: tool calls work, a
  ## ~600-token prompt takes 3.8s, a 4000-token one takes 26s. That last
  ## number is the thing to watch: if Claude Code turns out to send long
  ## prompts to this slot, set claudeBackgroundModel back to "" and it
  ## returns to the main model.
  ## Claude Code defaults to the better coder rather than the bigger window.
  ## Safe now that the wrapper exports the model's REAL context: the reason
  ## coder-pro held this slot was that Claude Code assumed 200k for every
  ## model and a 128k one would overflow instead of compacting.
  ##
  ## Set it here rather than reaching for `/model` in a session: that only
  ## moves the main slot, leaving subagents on the old model, and two 25GB
  ## models alternating makes llama-swap thrash the card (observed
  ## 2026-08-03 — qwen-dense and qwen swapping every few seconds).
  hostParams.aiCoding.claudeModel = "qwen-dense-long";

  ## MEASURED INERT, 2026-08-03, and left off for that reason. Claude Code
  ## never called the slot: over three turns llama-swap logged exactly one
  ## line for fast-cpu, its startup health check, and every request the
  ## status line reported — including the small ones — was attributed to
  ## the MAIN model. So the background traffic this was meant to move does
  ## not go through ANTHROPIC_DEFAULT_HAIKU_MODEL at all, and enabling it
  ## only pinned 2.5GB of RAM for a model nothing talks to.
  ##
  ## The entry is still in the catalog and still works; re-enable both
  ## lines if a future Claude Code starts using that slot.
  # services.genai-server.llmModels.fast-cpu.serve.enable = true;
  # hostParams.aiCoding.claudeBackgroundModel = "fast-cpu";
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

  ## This box has a monitor on it, so let it use it: when a render or a
  ## model load starts and nobody has touched the desk for five minutes,
  ## the screen wakes and shows the 3D view until the work finishes.
  ## Touching the keyboard hands it straight back.
  ##
  ## Nothing to configure beyond `enable` here: presence comes from
  ## swayidle over ext-idle-notify-v1, and the daemon probes for niri's own
  ## CLI to drive DPMS — both of which this session provides. `inference`
  ## is deliberately not in the default activity set; with the whole house
  ## chatting to this machine the screen would never be off.
  services.genai-server.kiosk.enable = true;
  ## ...including when the box has locked itself. Nothing can be drawn over
  ## a Wayland session lock, so the only way a locked screen shows the view
  ## is to open the lock: with DMS as the locker (see host-params.nix) the
  ## daemon unlocks when work starts on a machine nobody is at, and re-locks
  ## the instant either the work stops or somebody touches the keyboard.
  ##
  ## THE TRADE: while a render runs unattended this box is unlocked. Anyone
  ## walking up gets the lock screen back on the first keypress, but they
  ## can see the screen until then. That is the right trade for a machine in
  ## a house and the wrong one for a laptop in a café.
  ## Below DMS's own lock timeout (300s), so the screen is claimed a minute
  ## before the shell would lock it: with work running the hold then stops
  ## the lock happening at all, and the unlock path is only needed for a job
  ## that starts after the box had already locked itself.
  services.genai-server.kiosk.idleSeconds = 240;
  services.genai-server.kiosk.unlockCommand = "dms ipc call lock unlock";
  services.genai-server.kiosk.relockCommand = "dms ipc call lock lock";
  services.genai-server.kiosk.lockedCommand =
    "test \"$(dms ipc call lock isLocked)\" = true";
  ## DMS's own idle inhibit rather than systemd's: DMS is the thing that
  ## locks now, and this is the switch it listens to. Measured earlier —
  ## it stops DMS locking without suppressing the compositor's idle
  ## notifications, so the daemon can still tell when somebody comes back.
  # DMS's inhibit is also its caffeine switch: enabling it wakes the display.
  # That is fine because genai-server only takes this hold while it has the
  # screen — but it is why the hold must never be taken merely because a job
  # is running. Disable on EXIT only; TERM re-raises into it, so trapping
  # both would call the disable twice.
  services.genai-server.kiosk.holdCommand =
    "sh -c 'dms ipc call inhibit enable; "
    + "trap \"dms ipc call inhibit disable\" EXIT; "
    + "trap \"exit 0\" TERM INT; "
    + "sleep infinity & wait'";

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
    ## asserts this identity itself. Must match what the gate sends —
    ## which is the directory's email — and must be an admin.
    seedIdentity = config.hostParams.user.email;
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
  ## Where each service is actually published now that the stack is fronted
  ## by HomeFree. Without this the portal links to
  ## `http://<host you loaded the portal from>:<port>` — right on a LAN box,
  ## and wrong through the proxy, where it produces ai.homefree.host:3000:
  ## a port nothing listens on there, over a scheme the vhost does not speak.
  ##
  ## Three cases, and the difference is real rather than cosmetic:
  ##   * its own subdomain — the browser-facing UIs
  ##   * behind the portal at /svc/<name> — the stdlib APIs it proxies
  ## Links only. Health probes keep using the real local address, because
  ## "can I reach it" and "where do I send a browser" stop being the same
  ## question behind a proxy.
  services.genai-server.portal.serviceUrls =
    let
      sub = s: "https://${s}.homefree.host";
      svc = s: "https://ai.homefree.host/svc/${s}";
    in {
      "Open WebUI"      = sub "webui";
      "ComfyUI"         = sub "comfy";
      "SearXNG"         = sub "search";
      "Magentic-UI"     = sub "magentic";
      "Realtime voice"  = sub "voice";

      "Image server"    = svc "image";
      "Media tools"     = svc "media";
      "Search tool"     = svc "search";
      "MCP gateway"     = svc "mcp";
      "Knowledge (RAG)" = svc "rag";
      "Memory"          = svc "memory";
      "Code sandbox"    = svc "code";
      "TTS"             = svc "tts";
      "Segment server"  = svc "segment";

      ## The portal proxies neither the OpenAI-dialect endpoints nor
      ## Kokoro, so these get subdomains of their own rather than a LAN
      ## link the proxy cannot serve.
      "llama-swap"      = sub "swap";
      "LiteLLM"         = sub "litellm";
      "Ollama dialect"  = sub "ollama";
      "TTS-HQ"          = sub "ttshq";
    };

  ## Name that resolves for every LAN client (bare "logistikon" doesn't).
  ## Tool-returned images are embedded in chats as ABSOLUTE urls, so this
  ## value has to be fetchable by the browser — not merely by this box.
  ## Pointing it at http://logistikon.lan:8894 stopped working the moment
  ## the chat UI moved behind TLS: a browser refuses http subresources on
  ## an https page (mixed content), so every generated image silently
  ## vanished while uploads kept working, those being served same-origin
  ## through Open WebUI's own /api/v1/files.
  ##
  ## The portal already proxies media at /svc/media, so this is the same
  ## bytes over TLS on a name that resolves anywhere. Cross-subdomain from
  ## webui.homefree.host is fine: the SSO cookie is scoped to
  ## .homefree.host, so the image requests carry it.
  services.genai-server.mediaPublicUrl = "https://ai.homefree.host/svc/media";
  ## MagenticLite (:8895) rejects non-localhost Host headers unless listed
  ## (upstream DNS-rebinding defense; the launcher extends the allowlist).
  ## Behind the proxy the Host header is the public name, not this box's,
  ## and MagenticLite rejects anything unlisted with "bad host header".
  services.genai-server.magenticUi.allowedHosts = [
    "logistikon.lan"
    "magentic.homefree.host"
  ];
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

  ## The case power button must only ever power the machine ON. A press on a
  ## running system does nothing: niri hands the key back to logind (see
  ## niri.nix, input.power-key-handling), and logind drops it here rather than
  ## running its default poweroff. Both halves are required — disabling one
  ## just moves the shutdown/suspend to the other handler.
  ## Note this cannot disable the firmware's ~4s force-off override, which
  ## never reaches the OS; that one is a BIOS setting if it bothers you.
  ## The Telink wireless receiver exposes a System Control collection, so the
  ## keyboard can send KEY_POWER/KEY_SLEEP too — the same stray press could
  ## arrive as a suspend key and sail past HandlePowerKey. Drop those as well;
  ## deliberate suspends still go through the Mod+Shift+S dialog.
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandlePowerKeyLongPress = "ignore";
    HandleSuspendKey = "ignore";
    HandleHibernateKey = "ignore";
  };

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

