{ config, lib, pkgs, ... }:
let
  cfg = config.nixcfg.hardware.keyboard-unwedge;

  stateFile = "/var/lib/keyboard-unwedge/state.json";

  monitor = pkgs.writeText "keyboard-unwedge.py" ''
    """Detect and recover a wedged i8042 keyboard controller.

    Failure mode: the keyboard controller latches and continuously re-transmits a
    single make scancode without ever sending the matching break. The kernel then
    believes that key is held forever, and because the controller stops scanning
    the matrix no other key is ever reported -- the whole keyboard goes dead,
    including Ctrl+Alt+Fn VT switching.

    Detection: a key stays held while no press or release happens for longer than
    --hold-seconds. Kernel autorepeat (EV_KEY value 2) deliberately does not count
    as a transition, so a genuine wedge trips the timer while ordinary typing --
    which always produces presses and releases -- keeps resetting it.

    Recovery: unbind and rebind atkbd on the i8042 KBD serio port, which issues a
    keyboard reset and re-initialises the controller. Each reset bumps a counter in
    --state-file and, if --notify-send is given, raises a desktop notification in
    every active graphical session so recurrences are visible.
    """

    import argparse
    import fcntl
    import json
    import os
    import pwd
    import select
    import struct
    import subprocess
    import time

    EV_KEY = 0x01
    KEY_MAX = 0x2ff
    KEY_BYTES = KEY_MAX // 8 + 1
    EVENT_FMT = "llHHi"  # x86_64 struct input_event
    EVENT_SIZE = struct.calcsize(EVENT_FMT)
    ATKBD_DRIVER = "/sys/bus/serio/drivers/atkbd"
    SERIO_DEVICES = "/sys/bus/serio/devices"
    RUN_USER = "/run/user"

    # Enough to name the plausible culprits; anything else prints its raw code.
    KEY_NAMES = {
        1: "Esc", 14: "Backspace", 15: "Tab", 28: "Enter", 29: "LeftCtrl",
        42: "LeftShift", 54: "RightShift", 56: "LeftAlt", 57: "Space",
        58: "CapsLock", 97: "RightCtrl", 100: "RightAlt", 125: "LeftMeta",
        103: "Up", 105: "Left", 106: "Right", 108: "Down",
    }


    def log(message):
        print(message, flush=True)


    def _ioc(direction, typ, nr, size):
        return (direction << 30) | (size << 16) | (typ << 8) | nr


    EVIOCGKEY = _ioc(2, ord("E"), 0x18, KEY_BYTES)


    def key_label(codes):
        return ", ".join(
            KEY_NAMES.get(c, "keycode {}".format(c)) for c in sorted(codes)
        )


    def held_keys(fd):
        """Keycodes the kernel currently considers held on this device."""
        buf = bytearray(KEY_BYTES)
        fcntl.ioctl(fd, EVIOCGKEY, buf)
        return {c for c in range(KEY_MAX) if buf[c >> 3] >> (c & 7) & 1}


    def kbd_serio_port():
        """Name of the serio port for the i8042 keyboard, e.g. "serio0"."""
        try:
            ports = sorted(os.listdir(SERIO_DEVICES))
        except OSError:
            return None
        for port in ports:
            try:
                with open(os.path.join(SERIO_DEVICES, port, "description")) as f:
                    if f.read().strip() == "i8042 KBD port":
                        return port
            except OSError:
                continue
        return None


    def reset_keyboard(settle):
        port = kbd_serio_port()
        if port is None:
            log("ERROR: no i8042 KBD serio port found, cannot reset")
            return False
        for action in ("unbind", "bind"):
            try:
                with open(os.path.join(ATKBD_DRIVER, action), "w") as f:
                    f.write(port)
            except OSError as err:
                log("ERROR: atkbd {} of {} failed: {}".format(action, port, err))
                return False
            time.sleep(settle)
        log("reset atkbd on {}".format(port))
        return True


    def record_reset(state_file, ok):
        """Bump the persistent reset counter. Returns (count, since)."""
        state = {"count": 0, "failures": 0, "since": ""}
        try:
            with open(state_file) as f:
                state.update(json.load(f))
        except (OSError, ValueError):
            pass
        state["count"] = state.get("count", 0) + 1
        if not ok:
            state["failures"] = state.get("failures", 0) + 1
        stamp = time.strftime("%Y-%m-%d %H:%M")
        if not state.get("since"):
            state["since"] = stamp
        state["last"] = stamp
        try:
            os.makedirs(os.path.dirname(state_file), exist_ok=True)
            tmp = state_file + ".new"
            with open(tmp, "w") as f:
                json.dump(state, f)
            os.replace(tmp, state_file)
        except OSError as err:
            log("WARNING: could not write {}: {}".format(state_file, err))
        return state["count"], state["since"]


    def session_uids():
        """UIDs that currently have a D-Bus session bus we can talk to."""
        found = []
        try:
            entries = os.listdir(RUN_USER)
        except OSError:
            return found
        for entry in entries:
            if entry.isdigit() and os.path.exists(
                os.path.join(RUN_USER, entry, "bus")
            ):
                found.append(int(entry))
        return found


    def notify(notify_send, summary, body):
        """Notify every active graphical session.

        The service runs as root in the system context, so it has to drop to the
        session owner and point at their bus explicitly; a plain notify-send from
        root never reaches the user's notification daemon.
        """
        if not notify_send:
            return
        for uid in session_uids():
            try:
                pw = pwd.getpwuid(uid)
            except KeyError:
                continue
            runtime = os.path.join(RUN_USER, str(uid))
            try:
                result = subprocess.run(
                    [
                        notify_send,
                        "--app-name=keyboard-unwedge",
                        "--urgency=critical",
                        "--icon=input-keyboard",
                        summary,
                        body,
                    ],
                    user=uid,
                    group=pw.pw_gid,
                    extra_groups=[],
                    env={
                        "DBUS_SESSION_BUS_ADDRESS": "unix:path={}/bus".format(runtime),
                        "XDG_RUNTIME_DIR": runtime,
                        "HOME": pw.pw_dir,
                        "PATH": "/run/current-system/sw/bin",
                    },
                    capture_output=True,
                    text=True,
                    timeout=10,
                    check=False,
                )
            except (OSError, subprocess.SubprocessError) as err:
                log("WARNING: notify for uid {} failed: {}".format(uid, err))
                continue
            if result.returncode != 0:
                log(
                    "WARNING: notify-send for uid {} exited {}: {}".format(
                        uid, result.returncode, result.stderr.strip()
                    )
                )


    def open_device(path, timeout):
        """Open path, waiting for udev to (re)create it. None on timeout."""
        deadline = time.monotonic() + timeout
        warned = False
        while True:
            try:
                return os.open(path, os.O_RDONLY | os.O_NONBLOCK)
            except OSError:
                if time.monotonic() >= deadline:
                    return None
                if not warned:
                    log("waiting for {}".format(path))
                    warned = True
                time.sleep(0.2)


    def watch(fd, hold_seconds):
        """Watch an open device.

        Returns the set of stuck keycodes if wedged, or None if the device went
        away (which is expected right after a reset recreates the node).
        """
        poller = select.poll()
        poller.register(fd, select.POLLIN)
        last_transition = time.monotonic()
        while True:
            if poller.poll(1000):
                try:
                    data = os.read(fd, EVENT_SIZE * 256)
                except BlockingIOError:
                    data = b""
                except OSError:
                    return None
                if data == b"":
                    return None
                for off in range(0, len(data) - EVENT_SIZE + 1, EVENT_SIZE):
                    _, _, etype, _, value = struct.unpack(
                        EVENT_FMT, data[off:off + EVENT_SIZE]
                    )
                    # Only real presses and releases count; autorepeat is exactly
                    # what a wedged controller produces forever.
                    if etype == EV_KEY and value in (0, 1):
                        last_transition = time.monotonic()
            try:
                held = held_keys(fd)
            except OSError:
                return None
            if not held:
                last_transition = time.monotonic()
                continue
            if time.monotonic() - last_transition >= hold_seconds:
                log(
                    "{} held with no press or release for {:.0f}s: "
                    "keyboard is wedged".format(key_label(held), hold_seconds)
                )
                return held


    def main():
        parser = argparse.ArgumentParser()
        parser.add_argument("--device", required=True)
        parser.add_argument("--hold-seconds", type=float, default=20.0)
        parser.add_argument("--cooldown-seconds", type=float, default=60.0)
        parser.add_argument("--settle-seconds", type=float, default=0.3)
        parser.add_argument("--max-backoff-seconds", type=float, default=900.0)
        parser.add_argument("--state-file", default="/var/lib/keyboard-unwedge/state.json")
        parser.add_argument("--notify-send", default="")
        args = parser.parse_args()

        last_reset = None
        consecutive = 0
        while True:
            fd = open_device(args.device, timeout=60.0)
            if fd is None:
                continue
            try:
                stuck = watch(fd, args.hold_seconds)
            finally:
                os.close(fd)
            if stuck is None:
                continue

            now = time.monotonic()
            # A wedge recurring soon after a reset means the reset did not take,
            # so back off. One appearing much later is a fresh incident.
            if last_reset is not None and now - last_reset < args.cooldown_seconds * 4:
                consecutive += 1
                backoff = min(
                    args.cooldown_seconds * (2 ** (consecutive - 1)),
                    args.max_backoff_seconds,
                )
                log("reset did not hold, waiting {:.0f}s".format(backoff))
                time.sleep(backoff)
            else:
                consecutive = 0

            ok = reset_keyboard(args.settle_seconds)
            last_reset = time.monotonic()
            count, since = record_reset(args.state_file, ok)
            label = key_label(stuck)
            if ok:
                notify(
                    args.notify_send,
                    "Keyboard unwedged",
                    "{} was stuck, so the keyboard controller was reset.\n"
                    "Occurrence {} since {}.".format(label, count, since),
                )
            else:
                notify(
                    args.notify_send,
                    "Keyboard wedged, reset failed",
                    "{} is stuck and resetting the controller did not help.\n"
                    "Occurrence {} since {}.".format(label, count, since),
                )


    if __name__ == "__main__":
        main()
  '';
in {
  options.nixcfg.hardware.keyboard-unwedge = {
    enable = lib.mkEnableOption "automatic recovery from a wedged i8042 keyboard controller";

    device = lib.mkOption {
      type = lib.types.str;
      default = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
      description = "Evdev node of the internal i8042 keyboard to watch.";
    };

    holdSeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 20;
      description = ''
        Reset once a key has been held this long with no press or release in
        between. Autorepeat does not count, so ordinary typing never trips it.
        Keep it above the longest single-key hold you expect, since holding one
        key this long while touching no other key looks the same as a wedge.
      '';
    };

    cooldownSeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 60;
      description = ''
        Minimum delay before another reset, doubling while resets fail to clear
        the wedge, so a genuinely broken keyboard is not reset in a tight loop.
      '';
    };

    notify = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Raise a desktop notification in every active graphical session when a
        reset fires, including a running count so recurrences are easy to spot.
        The journal and ${stateFile} keep the durable record either way.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.keyboard-unwedge = {
      description = "Recover the internal keyboard from a wedged i8042 controller";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = lib.concatStringsSep " " ([
          "${pkgs.python3}/bin/python3"
          "${monitor}"
          "--device" cfg.device
          "--hold-seconds" (toString cfg.holdSeconds)
          "--cooldown-seconds" (toString cfg.cooldownSeconds)
          "--state-file" stateFile
        ] ++ lib.optionals cfg.notify [
          "--notify-send" "${pkgs.libnotify}/bin/notify-send"
        ]);
        Restart = "always";
        RestartSec = 5;
        StateDirectory = "keyboard-unwedge";
        # Runs as root: reads /dev/input, writes atkbd's bind/unbind knobs, and
        # drops to each session owner to send notifications. Deliberately no
        # PrivateDevices (needs /dev/input) and no ProtectKernelTunables (needs
        # sysfs writes); ProtectHome stays readable so notify-send's GLib setup
        # cannot trip over a masked home.
        ProtectSystem = "full";
        ProtectHome = "read-only";
        PrivateNetwork = true;
        NoNewPrivileges = true;
        RestrictSUIDSGID = true;
        RestrictAddressFamilies = [ "AF_UNIX" ];
        SystemCallFilter = [ "@system-service" "@setuid" ];
      };
    };
  };
}
