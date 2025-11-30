# Steam Loader for Niri

A polished GTK4 loading screen that displays while Steam Big Picture Mode starts up on Niri (or any Wayland compositor).

## Features

- 🎨 Modern dark gradient background with Steam-blue accents
- 🔄 Animated spinner and pulsing effects
- 🖥️ Uses `gtk4-layer-shell` for proper fullscreen overlay
- ⏱️ Automatically closes when Steam's window appears
- 🐧 Native NixOS integration via Flake

## Preview

The loader displays:
- A Steam-inspired logo
- "Steam" title in the signature Steam blue
- Animated loading spinner
- "Launching Big Picture Mode..." text with animated dots

## Installation

### Option 1: Add to your flake inputs

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    steam-loader.url = "path:/path/to/steam-loader"; # or your git URL
  };

  outputs = { self, nixpkgs, steam-loader, ... }: {
    # NixOS configuration
    nixosConfigurations.yourhost = nixpkgs.lib.nixosSystem {
      # ...
      modules = [
        steam-loader.nixosModules.default
        {
          programs.steam-loader.enable = true;
        }
      ];
    };

    # Or with Home Manager
    homeConfigurations.youruser = home-manager.lib.homeManagerConfiguration {
      # ...
      modules = [
        steam-loader.homeManagerModules.default
        {
          programs.steam-loader.enable = true;
        }
      ];
    };
  };
}
```

### Option 2: Run directly with nix run

```bash
nix run .#steam-loader
```

### Option 3: Add to environment.systemPackages

```nix
{ pkgs, steam-loader, ... }:
{
  environment.systemPackages = [
    steam-loader.packages.${pkgs.system}.default
  ];
}
```

## Niri Configuration

Add to your `~/.config/niri/config.kdl`:

```kdl
// Launch steam-loader at startup instead of steam directly
spawn-at-startup "steam-loader"
```

Or if you're using NixOS/home-manager for niri config:

```nix
programs.niri.settings = {
  spawn-at-startup = [
    { command = [ "steam-loader" ]; }
  ];
};
```

## How It Works

1. The loader displays a fullscreen overlay using `gtk4-layer-shell`
2. It spawns `steam -bigpicture` in the background
3. It polls `niri msg windows` to detect when Steam's window appears
4. Once Steam is ready, the loader automatically closes
5. If Steam doesn't start within 120 seconds, the loader closes anyway

## Development

Enter a dev shell:

```bash
nix develop
```

Run the script directly:

```bash
python src/steam-loader.py
```

## Customization

You can modify `steam-loader.py` to change:

- Colors (search for `#66c0f4` for Steam blue, `#1a1a2e` etc. for background)
- Text labels
- Spinner size
- Logo design
- Timeout duration

## Troubleshooting

### Loader doesn't close when Steam starts

The loader looks for windows with "steam" AND ("big picture" OR "gamepadui") in the name. If Steam's window title has changed, you may need to update the detection logic in `launch_and_monitor_steam()`.

Check what niri sees:
```bash
niri msg windows
```

### gtk4-layer-shell not working

If layer shell isn't available, the app falls back to a regular fullscreen window. This should still work but may not overlay as cleanly.

## License

MIT
