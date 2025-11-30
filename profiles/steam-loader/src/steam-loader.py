#!/usr/bin/env python3
"""
Steam Big Picture Loading Screen for Niri/Wayland
A fullscreen loading overlay that displays while Steam starts up.
"""

import gi
import subprocess
import threading
import time
import signal
import sys
import os

gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')

from gi.repository import Gtk, Adw, GLib, Gdk

# Try to import layer shell, but gracefully handle if unavailable
try:
    gi.require_version('Gtk4LayerShell', '1.0')
    from gi.repository import Gtk4LayerShell as LayerShell
    HAS_LAYER_SHELL = True
except (ValueError, ImportError):
    HAS_LAYER_SHELL = False
    print("Warning: gtk4-layer-shell not available, using regular fullscreen window")


class SteamLoaderApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id='com.local.steam-loader')
        self.window = None
        self.steam_ready = False

        # Set dark mode immediately on construction
        style_manager = Adw.StyleManager.get_default()
        style_manager.set_color_scheme(Adw.ColorScheme.FORCE_DARK)

        self.connect('activate', self.on_activate)

    def on_activate(self, app):
        self.window = LoaderWindow(application=app)
        self.window.present()

        # Start Steam in a background thread
        threading.Thread(target=self.launch_and_monitor_steam, daemon=True).start()

    def launch_and_monitor_steam(self):
        """Launch Steam and wait for its window to appear."""
        # Wait for Niri to be fully ready (outputs configured)
        max_niri_wait = 30
        niri_start = time.time()
        while time.time() - niri_start < max_niri_wait:
            try:
                result = subprocess.run(
                    ['niri', 'msg', 'outputs'],
                    capture_output=True,
                    text=True,
                    timeout=5
                )
                # Check that we have at least one output configured
                if result.returncode == 0 and result.stdout.strip():
                    print("Niri outputs ready")
                    break
            except (subprocess.TimeoutExpired, FileNotFoundError):
                pass
            time.sleep(0.5)

        # Additional small delay to ensure everything is settled
        time.sleep(2)

        # Launch Steam Big Picture
        # Clear LD_PRELOAD so it doesn't interfere with Steam
        steam_env = os.environ.copy()
        steam_env.pop('LD_PRELOAD', None)

        print("Launching Steam...")
        subprocess.Popen(
            ['steam', '-bigpicture'],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            env=steam_env
        )

        # Poll for Steam window using niri msg
        max_wait = 120  # Maximum seconds to wait
        start_time = time.time()

        while time.time() - start_time < max_wait:
            try:
                result = subprocess.run(
                    ['niri', 'msg', 'windows'],
                    capture_output=True,
                    text=True,
                    timeout=5
                )
                # Check for Steam's Big Picture window
                output_lower = result.stdout.lower()
                if 'steam' in output_lower and ('big picture' in output_lower or 'gamepadui' in output_lower):
                    self.steam_ready = True

                    # Give Steam a moment to fully render, then force fullscreen
                    # time.sleep(0.5)
                    # try:
                    #     subprocess.run(
                    #         ['niri', 'msg', 'action', 'fullscreen-window'],
                    #         capture_output=True,
                    #         timeout=5
                    #     )
                    #     print("Sent fullscreen action to Steam")
                    # except Exception as e:
                    #     print(f"Failed to fullscreen Steam: {e}")
                    #
                    GLib.idle_add(self.quit)
                    return
            except (subprocess.TimeoutExpired, FileNotFoundError):
                pass

            time.sleep(0.5)

        # Timeout - close anyway
        GLib.idle_add(self.quit)


class LoaderWindow(Adw.ApplicationWindow):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.set_title("Loading Steam")

        # Debug: check what is_supported returns
        if HAS_LAYER_SHELL:
            print(f"Layer shell imported, is_supported() = {LayerShell.is_supported()}")

        # Skip is_supported() check - Niri supports layer-shell but the check
        # may fail if called before the display is fully initialized.
        # Just try to use it and fall back if init_for_window fails.
        self.use_layer_shell = HAS_LAYER_SHELL

        # Configure as layer shell surface if available
        # MUST be called before the window is mapped/realized
        if self.use_layer_shell:
            try:
                print("Initializing gtk4-layer-shell...")
                LayerShell.init_for_window(self)
                LayerShell.set_namespace(self, "steam-loader")
                LayerShell.set_layer(self, LayerShell.Layer.OVERLAY)
                # Anchor to all edges = fullscreen
                LayerShell.set_anchor(self, LayerShell.Edge.TOP, True)
                LayerShell.set_anchor(self, LayerShell.Edge.BOTTOM, True)
                LayerShell.set_anchor(self, LayerShell.Edge.LEFT, True)
                LayerShell.set_anchor(self, LayerShell.Edge.RIGHT, True)
                # -1 means don't reserve any exclusive zone (overlay everything)
                LayerShell.set_exclusive_zone(self, -1)
                LayerShell.set_keyboard_mode(self, LayerShell.KeyboardMode.NONE)

                print(f"Layer shell initialized, is_layer_window = {LayerShell.is_layer_window(self)}")
            except Exception as e:
                print(f"Layer shell init failed: {e}, falling back to fullscreen")
                self.use_layer_shell = False
                self.connect('realize', lambda w: w.fullscreen())
        else:
            print("Layer shell not available, using regular fullscreen")
            self.connect('realize', lambda w: w.fullscreen())

        # Dark background
        self.add_css_class('loader-window')

        # Load custom CSS
        css_provider = Gtk.CssProvider()
        css_provider.load_from_string('''
            .loader-window {
                background: linear-gradient(145deg, #1a1a2e 0%, #16213e 50%, #0f0f23 100%);
            }

            .loader-title {
                font-size: 48px;
                font-weight: bold;
                color: #ffffff;
                text-shadow: 0 2px 10px rgba(102, 192, 244, 0.5);
            }

            .loader-subtitle {
                font-size: 18px;
                color: #a0a0a0;
            }

            .steam-accent {
                color: #66c0f4;
            }

            .loader-spinner {
                color: #66c0f4;
            }

            .pulse-ring {
                background: radial-gradient(circle, rgba(102, 192, 244, 0.1) 0%, transparent 70%);
                border-radius: 50%;
            }
        ''')

        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        # Main layout
        overlay = Gtk.Overlay()
        self.set_content(overlay)

        # Pulsing background effect
        pulse_box = Gtk.Box()
        pulse_box.add_css_class('pulse-ring')
        pulse_box.set_halign(Gtk.Align.CENTER)
        pulse_box.set_valign(Gtk.Align.CENTER)
        pulse_box.set_size_request(600, 600)
        overlay.add_overlay(pulse_box)

        # Center content
        center_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=30)
        center_box.set_halign(Gtk.Align.CENTER)
        center_box.set_valign(Gtk.Align.CENTER)
        overlay.set_child(center_box)

        # Steam icon (using a simple SVG representation)
        icon_box = Gtk.Box()
        icon_box.set_halign(Gtk.Align.CENTER)
        icon_box.set_size_request(120, 120)

        # Create Steam logo using DrawingArea
        steam_logo = Gtk.DrawingArea()
        steam_logo.set_size_request(120, 120)
        steam_logo.set_draw_func(self.draw_steam_logo)
        icon_box.append(steam_logo)
        center_box.append(icon_box)

        # Title
        title_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        title_box.set_halign(Gtk.Align.CENTER)

        steam_label = Gtk.Label(label="Steam")
        steam_label.add_css_class('loader-title')
        steam_label.add_css_class('steam-accent')
        title_box.append(steam_label)

        center_box.append(title_box)

        # Spinner
        spinner = Gtk.Spinner()
        spinner.set_size_request(64, 64)
        spinner.add_css_class('loader-spinner')
        spinner.start()
        center_box.append(spinner)

        # Loading text
        loading_label = Gtk.Label(label="Launching Big Picture Mode...")
        loading_label.add_css_class('loader-subtitle')
        center_box.append(loading_label)

        # Animated dots
        self.dots_label = Gtk.Label(label="")
        self.dots_label.add_css_class('loader-subtitle')
        center_box.append(self.dots_label)

        # Start dot animation
        self.dot_count = 0
        GLib.timeout_add(500, self.animate_dots)

    def draw_steam_logo(self, area, cr, width, height):
        """Draw a simplified Steam logo."""
        # Center coordinates
        cx, cy = width / 2, height / 2
        radius = min(width, height) / 2 - 10

        # Steam blue color
        cr.set_source_rgba(0.4, 0.75, 0.96, 1.0)  # #66c0f4

        # Outer circle
        cr.set_line_width(4)
        cr.arc(cx, cy, radius, 0, 2 * 3.14159)
        cr.stroke()

        # Inner gear-like shape (simplified)
        inner_radius = radius * 0.6
        cr.arc(cx, cy, inner_radius, 0, 2 * 3.14159)
        cr.stroke()

        # Piston arm
        cr.set_line_width(6)
        cr.move_to(cx, cy)
        cr.line_to(cx + radius * 0.8, cy + radius * 0.5)
        cr.stroke()

        # Center dot
        cr.arc(cx, cy, 8, 0, 2 * 3.14159)
        cr.fill()

        # Small circle at end of arm
        cr.arc(cx + radius * 0.8, cy + radius * 0.5, 12, 0, 2 * 3.14159)
        cr.stroke()

    def animate_dots(self):
        """Animate the loading dots."""
        self.dot_count = (self.dot_count + 1) % 4
        self.dots_label.set_text("." * self.dot_count)
        return True  # Continue animation


def main():
    # Handle SIGTERM/SIGINT gracefully
    signal.signal(signal.SIGTERM, lambda s, f: sys.exit(0))
    signal.signal(signal.SIGINT, lambda s, f: sys.exit(0))

    app = SteamLoaderApp()
    return app.run(None)


if __name__ == '__main__':
    sys.exit(main())
