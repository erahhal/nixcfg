# Desktop responsiveness under CPU/IO load.
#
# Prevents background tasks (Vulkan shader compilation, builds, indexing)
# from starving the compositor and interactive applications.
#
# Key mechanisms:
#   - ananicy-cpp with CachyOS rules — automatic per-process nice/ionice/sched
#     (e.g. fossilize_replay → nice 16 + ioclass idle; niri → nice -12)
#   - GameMode service — on-demand game-process renicing via gamemoderun
#   - irqbalance — distributes hardware interrupts across cores
#   - CFS autogroup + low swappiness — session-level fairness, keep pages in RAM
#   - BFQ I/O scheduler on rotational disks — per-process I/O bandwidth fairness
#   - "none" (passthrough) on NVMe — hardware queues handle fairness natively
{ pkgs, ... }:
{
  # ── Process priority daemon ─────────────────────────────────────────
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
    # Override: CachyOS LowLatency_RT type lacks a "sched" field, so it never
    # overrides the SCHED_IDLE that niri (and its children) start with.
    # We add explicit sched:"other" to promote them to normal CFS scheduling.
    extraRules = [
      { name = "niri"; nice = -12; ioclass = "best-effort"; sched = "other"; }
      { name = "niri-session"; nice = -12; ioclass = "best-effort"; sched = "other"; }
      { name = "foot"; nice = -4; ioclass = "best-effort"; sched = "other"; }
      { name = "footclient"; nice = -4; ioclass = "best-effort"; sched = "other"; }
      # yt-dlp: CachyOS classifies as BG_CPUIO (nice 16, ioclass idle, sched idle).
      # Stream recording is time-critical — must keep up with real-time network data.
      { name = "yt-dlp"; nice = 0; ioclass = "best-effort"; sched = "other"; }
      # ffmpeg: CachyOS classifies as Heavy_CPU (nice 9, ionice 7).
      # When recording live streams, needs enough priority to avoid stalling.
      { name = "ffmpeg"; nice = 0; ioclass = "best-effort"; sched = "other"; }
    ];
  };

  # ── GameMode (Feral) — proper service, not just the package ─────────
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
      };
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
      };
    };
  };

  # ── Hardware interrupt balancing ────────────────────────────────────
  services.irqbalance.enable = true;

  # ── Scheduler and VM tuning ─────────────────────────────────────────
  boot.kernel.sysctl = {
    "kernel.sched_autogroup_enabled" = 1;
    "vm.swappiness" = 10;
  };

  # ── I/O scheduler ────────────────────────────────────────────────────
  # BFQ on rotational disks: per-process I/O bandwidth fairness.
  # "none" on NVMe: passthrough to hardware multi-queue — adding a software
  # scheduler only increases per-request latency on fast devices.
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
  '';

  # ── Per-user systemd manager limits ─────────────────────────────────
  # Upstream systemd ships DefaultLimitNOFILE=1024:524288 (soft:hard).
  # The 1024 soft is a select(2) backward-compat decision; modern session
  # daemons (dbus-broker, pipewire) don't bump their own soft limit and
  # eventually hit it.  When user dbus-broker hits EMFILE, every GUI app
  # holding a session-bus connection (chromium, electron, etc.) aborts.
  systemd.user.extraConfig = ''
    DefaultLimitNOFILE=524288:524288
  '';

  # ── Btrfs maintenance ──────────────────────────────────────────────
  # Weekly balance reclaims unallocated device space from partially-used
  # data chunks.  Without this, a COW filesystem gradually reaches 100%
  # device-allocated even with free space inside chunks, causing write
  # stalls under concurrent load.
  systemd.services.btrfs-balance = {
    description = "Btrfs balance - reclaim unallocated space from underused data chunks";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.btrfs-progs}/bin/btrfs balance start -dusage=50 -musage=50 /";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };

  systemd.timers.btrfs-balance = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "2h";
    };
  };

  # Monthly scrub verifies data integrity (checksums).
  systemd.services.btrfs-scrub = {
    description = "Btrfs scrub - verify data integrity";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.btrfs-progs}/bin/btrfs scrub start -B /";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };

  systemd.timers.btrfs-scrub = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "monthly";
      Persistent = true;
      RandomizedDelaySec = "6h";
    };
  };
}
