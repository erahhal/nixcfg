{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.hardware.power-clamp-notify;
  userParams = config.hostParams.user;

  monitor = pkgs.writeText "power-clamp-notify.py" ''
    """Warn when the firmware clamps every CPU core to minimum clocks.

    Failure mode: a USB-C dock occasionally fails PD negotiation (typically
    across a reboot) and leaves the laptop on the 5 V default contract. AC still
    reads "online", but the EC pins every core near its lowest P-state, so a
    normal desktop load saturates the machine.

    Detection is by symptom rather than by the charger's reported contract: the
    UCSI power_supply nodes are unreliable here (voltage_now reads 0 on a healthy
    20 V contract), whereas "busy, yet no core above --max-mhz" is unambiguous.
    The effective clock comes from /proc/cpuinfo, which the kernel derives from
    APERF/MPERF, so it reflects what the cores actually ran at.
    """

    import argparse
    import subprocess
    import time


    def log(message):
        print(message, flush=True)


    def cpu_times():
        with open("/proc/stat") as f:
            fields = [int(x) for x in f.readline().split()[1:]]
        idle = fields[3] + fields[4]  # idle + iowait
        return sum(fields), idle


    def max_core_mhz():
        best = 0.0
        with open("/proc/cpuinfo") as f:
            for line in f:
                if line.startswith("cpu MHz"):
                    best = max(best, float(line.split(":")[1]))
        return best


    def ac_online():
        try:
            with open("/sys/class/power_supply/AC/online") as f:
                return f.read().strip() == "1"
        except OSError:
            return None


    def notify(notify_send, urgency, summary, body):
        try:
            subprocess.run(
                [notify_send, "--app-name=power-clamp-notify",
                 "--urgency=" + urgency, "--icon=battery-caution",
                 summary, body],
                check=False, timeout=10,
            )
        except (OSError, subprocess.TimeoutExpired) as err:
            log("WARNING: notify-send failed: {}".format(err))


    def main():
        parser = argparse.ArgumentParser()
        parser.add_argument("--interval-seconds", type=float, default=5.0)
        parser.add_argument("--samples", type=int, default=6)
        parser.add_argument("--max-mhz", type=float, default=1000.0)
        parser.add_argument("--min-busy", type=float, default=0.5)
        parser.add_argument("--notify-send", required=True)
        args = parser.parse_args()

        clamped_streak = 0
        alerted = False
        prev_total, prev_idle = cpu_times()
        while True:
            time.sleep(args.interval_seconds)
            total, idle = cpu_times()
            delta = total - prev_total
            busy = 1.0 - (idle - prev_idle) / delta if delta else 0.0
            prev_total, prev_idle = total, idle
            mhz = max_core_mhz()

            if busy >= args.min_busy and mhz < args.max_mhz:
                clamped_streak += 1
            elif mhz >= args.max_mhz:
                clamped_streak = 0
                if alerted:
                    alerted = False
                    log("clamp cleared: fastest core at {:.0f} MHz".format(mhz))
                    notify(args.notify_send, "normal", "CPU clocks restored",
                           "Cores are running at full speed again.")

            if clamped_streak >= args.samples and not alerted:
                alerted = True
                window = args.samples * args.interval_seconds
                log("clamp detected: {:.0%} busy, fastest core {:.0f} MHz for {:.0f}s"
                    .format(busy, mhz, window))
                if ac_online():
                    hint = ("The charger or dock is probably supplying only "
                            "low USB-C power. Unplug and replug the dock.")
                else:
                    hint = "Running on battery; check the power profile."
                notify(args.notify_send, "critical", "CPU power clamped",
                       "Every core has been held under {:.0f} MHz for {:.0f}s "
                       "while the system is {:.0%} busy.\n{}"
                       .format(args.max_mhz, window, busy, hint))


    if __name__ == "__main__":
        main()
  '';
in {
  options.nixcfg.hardware.power-clamp-notify = {
    enable = lib.mkEnableOption "desktop notification when firmware clamps the CPU to minimum clocks (e.g. degraded USB-C power negotiation)";

    maxMhz = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1000;
      description = ''
        A sample counts as clamped when the fastest core is below this effective
        clock while the system is busy. A clamped AMD laptop sits near its lowest
        P-state (~400-550 MHz); a healthy busy core boosts well above 2 GHz.
      '';
    };

    seconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 30;
      description = "How long the clamp must persist before notifying.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Declared through Home Manager rather than NixOS systemd.user.services:
    # switch-to-configuration never starts new NixOS-level user units, whereas
    # Home Manager's startServices starts/restarts them on every switch.
    home-manager.users.${userParams.username} = {
      systemd.user.services.power-clamp-notify = {
        Unit = {
          Description = "Notify when the CPU is power-clamped to minimum clocks";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = lib.concatStringsSep " " [
            "${pkgs.python3}/bin/python3"
            "${monitor}"
            "--interval-seconds" "5"
            "--samples" (toString (lib.max 1 (cfg.seconds / 5)))
            "--max-mhz" (toString cfg.maxMhz)
            "--notify-send" "${pkgs.libnotify}/bin/notify-send"
          ];
          Restart = "always";
          RestartSec = 10;
        };
      };
    };
  };
}
