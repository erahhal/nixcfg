#!/usr/bin/env python3
"""Drive OpenRGB devices from live CPU / GPU utilisation.

GPU controllers follow GPU utilisation, every other controller follows CPU.
Each device's colour is interpolated between two HSV endpoints, so at idle
they sit at a dim green-grey and at full load they burn red, sweeping
green -> yellow -> orange -> red on the way.

Talks the OpenRGB SDK protocol directly rather than through a client
library: we never send REQUEST_PROTOCOL_VERSION, so the server answers in
protocol 0, whose controller-data layout has been stable across every
OpenRGB release and carries none of the version-dependent fields.
"""

import argparse
import colorsys
import errno
import select
import socket
import struct
import subprocess
import sys
import time

MAGIC = b"ORGB"
PKT_REQUEST_CONTROLLER_COUNT = 0
PKT_REQUEST_CONTROLLER_DATA = 1
PKT_DEVICE_LIST_UPDATED = 100
PKT_SET_CLIENT_NAME = 50
PKT_UPDATE_LEDS = 1050
PKT_UPDATE_MODE = 1101

DEVICE_TYPE_GPU = 2


class ServerGone(Exception):
    """The SDK server dropped us or changed under us; reconnect."""


class ClockGone(Exception):
    """nvidia-smi died, so the loop has no clock left; let systemd restart us."""


class Reader:
    """Cursor over a protocol-0 controller-data blob."""

    def __init__(self, buf):
        self.buf = buf
        self.off = 0

    def u16(self):
        (v,) = struct.unpack_from("<H", self.buf, self.off)
        self.off += 2
        return v

    def u32(self):
        (v,) = struct.unpack_from("<I", self.buf, self.off)
        self.off += 4
        return v

    def i32(self):
        (v,) = struct.unpack_from("<i", self.buf, self.off)
        self.off += 4
        return v

    def string(self):
        n = self.u16()
        raw = self.buf[self.off:self.off + n]
        self.off += n
        return raw.rstrip(b"\0").decode("utf-8", "replace")


def parse_controller(blob):
    """Pull out what we need to address a controller, plus raw mode bytes.

    UPDATE_MODE echoes a mode back to the server in exactly the layout it
    arrived in, so keep each mode's slice verbatim rather than re-serialising
    fields we never inspect.
    """
    r = Reader(blob)
    size = r.u32()
    dev_type = r.u32()
    name = r.string()
    r.string()  # description
    r.string()  # version
    r.string()  # serial
    r.string()  # location

    modes = []
    n_modes = r.u16()
    active_mode = r.i32()
    for _ in range(n_modes):
        start = r.off
        mode_name = r.string()
        r.i32()  # value
        r.u32()  # flags
        r.u32()  # speed_min
        r.u32()  # speed_max
        r.u32()  # colors_min
        r.u32()  # colors_max
        r.u32()  # speed
        r.u32()  # direction
        r.u32()  # color_mode
        for _ in range(r.u16()):
            r.u32()  # mode colour
        modes.append((mode_name, blob[start:r.off]))

    for _ in range(r.u16()):  # zones
        r.string()
        r.i32()
        r.u32()  # leds_min
        r.u32()  # leds_max
        r.u32()  # leds_count
        matrix_len = r.u16()
        r.off += matrix_len

    n_leds = r.u16()
    for _ in range(n_leds):
        r.string()
        r.u32()

    if r.off > size:
        raise ValueError(f"overran controller data for {name!r}")
    return {
        "type": dev_type,
        "name": name,
        "leds": n_leds,
        "modes": modes,
        "active_mode": active_mode,
    }


class OpenRGB:
    def __init__(self, host, port, client_name):
        self.sock = socket.create_connection((host, port), timeout=10)
        self.sock.settimeout(10)
        self._send(0, PKT_SET_CLIENT_NAME, client_name.encode() + b"\0")

    def close(self):
        try:
            self.sock.close()
        except OSError:
            pass

    def _send(self, device, packet, data=b""):
        try:
            self.sock.sendall(
                MAGIC + struct.pack("<III", device, packet, len(data)) + data
            )
        except OSError as exc:
            raise ServerGone(str(exc)) from exc

    def _recv_exactly(self, n):
        buf = bytearray()
        while len(buf) < n:
            try:
                chunk = self.sock.recv(n - len(buf))
            except OSError as exc:
                raise ServerGone(str(exc)) from exc
            if not chunk:
                raise ServerGone("connection closed")
            buf += chunk
        return bytes(buf)

    def _recv(self):
        header = self._recv_exactly(16)
        if header[:4] != MAGIC:
            raise ServerGone(f"bad magic {header[:4]!r}")
        _, packet, size = struct.unpack("<III", header[4:])
        return packet, self._recv_exactly(size)

    def check_for_notifications(self):
        """Anything the server sends unprompted means our indices may be stale.

        We only ever read replies to our own requests, so unsolicited traffic
        is a device-list change (a rescan from the tray applet, say). Drop the
        session and re-enumerate rather than writing to controllers that have
        moved.
        """
        if not select.select([self.sock], [], [], 0)[0]:
            return
        packet, _ = self._recv()
        if packet == PKT_DEVICE_LIST_UPDATED:
            raise ServerGone("device list changed")
        raise ServerGone(f"unexpected packet {packet}")

    def controllers(self):
        self._send(0, PKT_REQUEST_CONTROLLER_COUNT)
        (count,) = struct.unpack("<I", self._recv()[1])
        out = []
        for index in range(count):
            self._send(index, PKT_REQUEST_CONTROLLER_DATA)
            ctrl = parse_controller(self._recv()[1])
            ctrl["index"] = index
            out.append(ctrl)
        return out

    def force_direct(self, ctrl):
        """Put a controller into per-LED mode so UPDATE_LEDS is honoured."""
        active = ctrl["active_mode"]
        if 0 <= active < len(ctrl["modes"]) and ctrl["modes"][active][0] == "Direct":
            return
        for index, (name, raw) in enumerate(ctrl["modes"]):
            if name == "Direct":
                payload = struct.pack("<I", index) + raw
                self._send(
                    ctrl["index"],
                    PKT_UPDATE_MODE,
                    struct.pack("<I", 4 + len(payload)) + payload,
                )
                return
        log(f"{ctrl['name']}: no Direct mode, leaving it alone")

    def set_all_leds(self, ctrl, rgb):
        payload = struct.pack("<H", ctrl["leds"]) + bytes(rgb + (0,)) * ctrl["leds"]
        self._send(
            ctrl["index"],
            PKT_UPDATE_LEDS,
            struct.pack("<I", 4 + len(payload)) + payload,
        )


class CpuUsage:
    """Busy fraction between successive reads of /proc/stat."""

    def __init__(self):
        self.prev = self._sample()

    @staticmethod
    def _sample():
        with open("/proc/stat", "r") as fh:
            fields = [int(x) for x in fh.readline().split()[1:]]
        # user nice system idle iowait irq softirq steal ...
        idle = fields[3] + fields[4]
        return sum(fields), idle

    def read(self):
        total, idle = self._sample()
        d_total = total - self.prev[0]
        d_idle = idle - self.prev[1]
        self.prev = (total, idle)
        if d_total <= 0:
            return 0.0
        return clamp01((d_total - d_idle) / d_total)


class GpuUsage:
    """Peak utilisation across the NVIDIA GPUs, streamed from nvidia-smi.

    One long-lived `nvidia-smi -lms` doubles as the loop clock: it flushes a
    line per GPU per interval, which is both cheaper and steadier than
    respawning the tool every tick.
    """

    def __init__(self, nvidia_smi, interval):
        query = [
            nvidia_smi,
            "--query-gpu=utilization.gpu",
            "--format=csv,noheader,nounits",
        ]
        listing = subprocess.run(query, capture_output=True, text=True, check=True)
        self.gpus = len([ln for ln in listing.stdout.splitlines() if ln.strip()])
        if not self.gpus:
            raise ClockGone("nvidia-smi reported no GPUs")
        self.proc = subprocess.Popen(
            query + ["-lms", str(int(interval * 1000))],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )

    def tick(self):
        """Block until the next sweep of every GPU, then return the peak."""
        peak = 0.0
        for _ in range(self.gpus):
            line = self.proc.stdout.readline() if self.proc.stdout else ""
            if not line:
                raise ClockGone("nvidia-smi exited")
            try:
                peak = max(peak, clamp01(float(line.strip()) / 100.0))
            except ValueError:
                # A transient "[N/A]" while the driver settles; treat as idle.
                pass
        return peak

    def close(self):
        self.proc.terminate()
        try:
            self.proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.proc.kill()


def clamp01(x):
    return 0.0 if x < 0.0 else 1.0 if x > 1.0 else x


def log(msg):
    print(msg, file=sys.stderr, flush=True)


class Ramp:
    """Utilisation -> RGB, with an asymmetric smoother in front of it."""

    def __init__(self, idle_hsv, busy_hsv, floor, ceiling, gamma,
                 brightness_gamma, attack, release):
        self.idle_hsv = idle_hsv
        self.busy_hsv = busy_hsv
        self.floor = floor
        self.ceiling = ceiling
        self.gamma = gamma
        self.brightness_gamma = brightness_gamma
        self.attack = attack
        self.release = release
        self.level = 0.0

    def feed(self, raw):
        # Rising load should show up at once; falling load looks better easing
        # out than snapping back the instant a job finishes.
        alpha = self.attack if raw > self.level else self.release
        self.level += alpha * (raw - self.level)
        return self.rgb(self.level)

    def rgb(self, level):
        # Both endpoints have to be reachable in practice, not just in
        # principle: a host that never drops below its background load would
        # otherwise never show the idle colour, and a GPU whose reported
        # utilisation flickers around the high 90s would never reach full red.
        t = clamp01((level - self.floor) / (self.ceiling - self.floor)) ** self.gamma
        h, s, v = (a + (b - a) * t for a, b in zip(self.idle_hsv, self.busy_hsv))
        # An LED's output is linear in its duty cycle but the eye's response is
        # not, so `value` means perceived brightness and is corrected on the way
        # out. Without this the bottom of the range is unusable: a strip driven
        # at 5% duty still reads as a quarter as bright as full, leaving
        # nowhere for "barely ticking over" to sit.
        v = clamp01(v) ** self.brightness_gamma
        # Hue is interpolated in degrees rather than by the short way round, so
        # 120 -> 0 sweeps green, yellow, orange, red.
        r, g, b = colorsys.hsv_to_rgb((h % 360.0) / 360.0, clamp01(s), v)
        return (round(r * 255), round(g * 255), round(b * 255))


def hsv(text):
    parts = text.split(",")
    if len(parts) != 3:
        raise argparse.ArgumentTypeError("expected hue,saturation,value")
    try:
        return tuple(float(p) for p in parts)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(str(exc)) from exc


def check_args(p, args):
    if not 0.0 <= args.floor < args.ceiling <= 1.0:
        p.error(f"need 0 <= floor < ceiling <= 1, got "
                f"floor={args.floor} ceiling={args.ceiling}")
    return args


def parse_args(argv):
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--host", default="127.0.0.1")
    p.add_argument("--port", type=int, default=6742)
    p.add_argument("--interval", type=float, default=0.25,
                   help="seconds between LED updates")
    p.add_argument("--idle", type=hsv, default=(120.0, 0.38, 0.24),
                   help="HSV at 0%% utilisation, hue in degrees")
    p.add_argument("--busy", type=hsv, default=(0.0, 1.0, 1.0),
                   help="HSV at 100%% utilisation, hue in degrees")
    p.add_argument("--floor", type=float, default=0.0,
                   help="utilisation at or below this shows the idle colour")
    p.add_argument("--ceiling", type=float, default=1.0,
                   help="utilisation at or above this shows the busy colour")
    p.add_argument("--gamma", type=float, default=1.0,
                   help=">1 holds the idle colour over more of the range")
    p.add_argument("--brightness-gamma", type=float, default=2.2,
                   help="LED gamma; makes `value` mean perceived brightness")
    p.add_argument("--attack", type=float, default=0.5,
                   help="smoothing factor while utilisation is rising")
    p.add_argument("--release", type=float, default=0.12,
                   help="smoothing factor while utilisation is falling")
    p.add_argument("--nvidia-smi", default="nvidia-smi")
    return check_args(p, p.parse_args(argv))


def run_once(args, gpu):
    """One connected session; returns only by raising when something drops."""
    client = OpenRGB(args.host, args.port, "usage-leds")
    try:
        controllers = client.controllers()
        if not controllers:
            raise ServerGone("server reported no controllers")
        for ctrl in controllers:
            client.force_direct(ctrl)
            kind = "GPU" if ctrl["type"] == DEVICE_TYPE_GPU else "CPU"
            log(f"driving {ctrl['name']!r} ({ctrl['leds']} LEDs) from {kind}")

        cpu = CpuUsage()
        ramps = {
            c["index"]: Ramp(args.idle, args.busy, args.floor, args.ceiling,
                             args.gamma, args.brightness_gamma,
                             args.attack, args.release)
            for c in controllers
        }
        while True:
            if gpu:
                gpu_level = gpu.tick()
            else:
                gpu_level = None
                time.sleep(args.interval)
            cpu_level = cpu.read()
            client.check_for_notifications()
            for ctrl in controllers:
                on_gpu = ctrl["type"] == DEVICE_TYPE_GPU
                if on_gpu and gpu_level is None:
                    continue
                level = gpu_level if on_gpu else cpu_level
                # Written every tick, not just on change: the controllers come
                # back from S3 at their firmware default and this is what pulls
                # them straight again without anyone having to notice.
                client.set_all_leds(ctrl, ramps[ctrl["index"]].feed(level))
    finally:
        client.close()


def main(argv=None):
    args = parse_args(argv)

    try:
        gpu = GpuUsage(args.nvidia_smi, args.interval)
    except OSError as exc:
        if exc.errno != errno.ENOENT:
            raise
        log("no nvidia-smi on PATH; GPU controllers will be left alone")
        gpu = None

    try:
        backoff = 1.0
        while True:
            started = time.monotonic()
            try:
                run_once(args, gpu)
            except (ServerGone, OSError) as exc:
                # A session that stayed up for a while then dropped is not the
                # same as a server that was never there, so don't punish it
                # with the backoff the previous failures earned.
                if time.monotonic() - started > 60:
                    backoff = 1.0
                log(f"OpenRGB session ended ({exc}); retrying in {backoff:.0f}s")
            time.sleep(backoff)
            backoff = min(backoff * 2, 30.0)
    except ClockGone as exc:
        log(f"{exc}")
        return 1
    finally:
        if gpu:
            gpu.close()


if __name__ == "__main__":
    sys.exit(main())
