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
#   - user.slice memory ceiling + systemd-oomd — bound runaway memory without
#     creating a soft-throttle livelock (see the long note at the cap below)
#   - swap cap lifted for the duration of a sleep cycle — hibernation has to
#     swap the session out to build its image (see the note below the cap)
#   - BFQ I/O scheduler on rotational disks — per-process I/O bandwidth fairness
#   - "none" (passthrough) on NVMe — hardware queues handle fairness natively
{ config, lib, pkgs, ... }:
let
  # Shared by the slice definition and the post-resume restore below.
  userSliceSwapMax = "8G";
  systemctl = "${config.systemd.package}/bin/systemctl";
in
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
      # yt-dlp/ffmpeg: CachyOS defaults are too restrictive (nice 16, ioclass
      # idle) — they cause stream recording to stall under load.  But nice=0
      # is too aggressive: under high concurrency (9+ simultaneous recordings)
      # they compete with the compositor and tank UI latency.  nice=5 keeps
      # recording reliable while leaving headroom for niri/Firefox.
      { name = "yt-dlp"; nice = 5; ioclass = "best-effort"; ionice = 4; sched = "other"; }
      { name = "ffmpeg"; nice = 5; ioclass = "best-effort"; ionice = 4; sched = "other"; }
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
  systemd.user.settings.Manager = {
    DefaultLimitNOFILE = "524288:524288";
  };

  # ── User-slice memory ceiling ───────────────────────────────────────
  # MemorySwapMax IS LOAD-BEARING, and its absence inverted this block on
  # 2026-08-31: the box locked up hard (ping alive, sshd/console/journald
  # all blocked, hard reboot to recover) because a process asked for ~104GB
  # of ANONYMOUS memory inside this 54GB slice.  memory.max forces reclaim,
  # anonymous pages can only be reclaimed to swap, and memory.swap.max was
  # `max` — so instead of dying at the ceiling the slice swapped itself
  # through the 32GB swapfile and took the machine's IO with it.  The cap
  # made the failure WORSE than no cap would have.
  #
  # MemoryHigh WAS the next lockup, on 2026-09-01, and is now gone.  The
  # kernel caught it mid-livelock in an RCU stall: a task spun ~21s inside
  #   filemap_add_folio → try_charge_memcg → __mem_cgroup_handle_over_high
  #   → reclaim_high → shrink_lruvec → evict_folios
  # i.e. page-cache readahead on an ordinary page fault, blocked doing
  # synchronous reclaim because the slice sat above memory.high.  Three
  # properties combined into a trap:
  #
  #   1. memory.high THROTTLES BUT NEVER KILLS.  Past the limit every
  #      allocating task does its own reclaim plus an escalating penalty
  #      sleep (up to 2s per allocation), across all ~55 session processes.
  #      That was the "high CPU" — it was kernel reclaim, not userspace.
  #   2. memory.max WAS THEREFORE UNREACHABLE.  The 48G throttle held usage
  #      below the 54G ceiling, so the cgroup OOM killer that would have
  #      ended it cleanly never ran (memory.events: oom_kill 0).
  #   3. memory.current COUNTS PAGE CACHE.  25G of the 46G here is file
  #      cache and 4G is unswappable shmem_thp; with anon capped at 8G of
  #      swap, reclaim fell on the mapped working set — evict, fault back
  #      in, recharge, reclaim again.  A cap on a slice holding page cache
  #      is a thrash line by construction, and normal desktop use sits at
  #      46.6G of the 48G limit (2827 throttle events in one 6min boot).
  #
  # Note earlyoom would NOT have saved this and is the wrong tool: it
  # watches global MemAvailable, but this was a per-cgroup livelock with
  # the machine globally fine.  pgscan_kswapd was 0 against pgscan_direct
  # 471163 — kswapd never ran, proving global watermarks were never
  # breached while 100% of reclaim was synchronous in-task cgroup reclaim.
  # systemd-oomd is the right tool because it triggers on the actual
  # symptom, sustained memory PSI on this specific slice.
  #
  # So: no soft throttle.  MemoryMax + bounded swap stays as the runaway-
  # anon backstop (the 2026-08-31 case, which it handles correctly and can
  # now actually reach), and oomd below is the pressure-based safety net.
  systemd.slices."user".sliceConfig = {
    MemoryMax = "54G";
    MemorySwapMax = userSliceSwapMax;
  };

  # ── Lift the swap cap for the duration of a sleep cycle ────────────
  # The swap cap broke hibernation: on antikythera every attempt from
  # 2026-09-18 to 09-20 failed with "Image allocation is N pages short" or
  # "Normal pages needed X, available Y / Error -12 creating image", and on
  # 09-20 the fallback drained the battery overnight.
  #
  # Hibernation must shrink the resident set to under half of RAM before it
  # can snapshot, and anonymous memory can only shrink by going to swap.
  # Once user.slice sits at memory.swap.max, the kernel's global reclaim
  # skips every anon page in the slice (can_reclaim_anon_pages → memcg swap
  # limit), so a session larger than ~half of RAM minus kernel/GPU memory
  # can never be hibernated.  The journal showed swap use parked at the cap
  # (8191 MiB) from 2026-09-17 on; hibernation had worked until the session
  # outgrew the limit.
  #
  # Worse, systemd's suspend-then-hibernate handles a failed hibernate with
  # ONE plain suspend and no wake-up timer (sleep.c, execute_s2h), so the
  # box sat in s2idle for 22 h until the battery was empty.  upower's
  # criticalPowerAction = "Hibernate" fails the same way, so the safety net
  # only exists if hibernation actually works.
  #
  # sleep-actions.service runs powerDownCommands before sleep.target and
  # resumeCommands when the target is torn down after resume, bracketing
  # the whole suspend → hibernate → resume cycle.  Nothing in the session
  # runs while asleep, so the runaway-anon backstop loses nothing.
  # mkBefore puts the restore ahead of host resume hooks (the script runs
  # under set -e), and `|| true` keeps a failed restore from blocking them;
  # systemctl still logs the failure.  The restore writes the configured
  # value instead of `systemctl revert`, which would also delete NixOS's
  # own /etc drop-ins.  The runtime drop-in it leaves behind matches the
  # unit file and disappears at reboot.
  powerManagement.powerDownCommands = ''
    ${systemctl} set-property --runtime user.slice MemorySwapMax=infinity
  '';
  powerManagement.resumeCommands = lib.mkBefore ''
    ${systemctl} set-property --runtime user.slice MemorySwapMax=${userSliceSwapMax} || true
  '';

  # ── OOM enforcement ────────────────────────────────────────────────
  # Nothing enforced the ceiling during either lockup: earlyoom is not
  # enabled on most hosts, and oomd's ManagedOOM* default to "auto", which
  # means "inherit" — with nothing set to "kill" anywhere, oomd monitored
  # nothing and took no action across a 10-hour session.
  #
  # enableUserSlices sets ManagedOOMMemoryPressure=kill on user.slice.
  # The nixpkgs default limit is 80% sustained pressure, which only fires
  # once the box is already unusable; 60% over 20s is early enough to keep
  # the session interactive and still far past any legitimate I/O burst.
  systemd.oomd = {
    enable = true;
    enableUserSlices = true;
    settings.OOM.DefaultMemoryPressureDurationSec = "20s";
  };
  systemd.slices."user".sliceConfig.ManagedOOMMemoryPressureLimit = "60%";

  # ── Keep the recovery path resident ────────────────────────────────
  # The 2026-08-31 lockup left sshd, journald and the console blocked, so
  # there was no way in to diagnose it.  Capping user.slice was the wrong
  # lever for that (see above); protecting system.slice is the right one.
  # MemoryMin is never reclaimed, MemoryLow is reclaimed only as a last
  # resort.  system.slice idles at ~2.5G, so this costs nothing in practice
  # and guarantees a way in when the session is thrashing.
  systemd.slices."system".sliceConfig = {
    MemoryMin = "1G";
    MemoryLow = "3G";
  };

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
