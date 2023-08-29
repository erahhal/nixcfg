NixOS Config
============

This is a somewhat opinionated setup for my personal machines and servers, as well as a work laptop.
The setup is as follows:

* Desktop environment: wayland / sway / kitty
  * 2x scaling - apps configured for HiDPI
* Audio: pipewire
* Wireless: network manager
* Browsers: Brave, Firefox
* Other configured apps: Spotify, Gimp, Neovim, VSCodium, Discord, prismlauncher, Blender

# To use yourself

* Fork repo
* Update "config.nix" with your settings
* Rename hosts/nflx-erahhal-t490s/ and configure your host
* Update flake.nix with the updated hostname and hardware import

# To use fingerprint reader

`sudo fprintd-enroll <username>`

- At SDDM login, hit enter without a password, then touch the fingerprint sensor
- When sway is locked, also just hit enter for the password then touch the sensor

# To connect to wifi

* run `nmtui`

# To select audio output

* GUI
  * `pavucontrol`
* command line
  * `pactl list short sinks`
  * `pactl set-default-sink [sink name]`

# To pair/connect a bluetooth device

* run `blueman-manager`

# To update firmware/BIOS

* Updates through this method may not be the latest - check device website

```
sudo fwupdmgr refresh --force
sudo fwupdmgr get-updates
sudo fwupdmgr update
sudo dmidecode -s bios-version
```

# To see current CPU frequency

* `watch -n.1 "grep \"^[c]pu MHz\" /proc/cpuinfo"`

# To see current CPU scaling setting

* `cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor`

or

* `cpufreq-inf`

# To determine if C-states is enabled on a Dell

* `cctk --CStatesCtrl`

# To lookup available vim plugins

* `nix-env -f '<nixpkgs>' -qaP -A vimPlugins`

# To lookup available node packages

* `nix-env -f '<nixpkgs>' -qaP -A nodePackages`

# Configurable params

* To setup monitor layout/config
  - users/<username>/modules/kanshi.nix
* Touchpad configuration
  - mixins/sway.nix
    - config.wayland.windowManager.sway.input, "type:touchpad"
* Thinkpad CPU scaling and battery charge limits
  - services.tlp.settings
* To disable fingerprint login
  - services.fprintd.enable = false;
  - security.pam.services.login.fprintAuth = false;
  - security.pam.services.xscreensaver.fprintAuth = false;

# Repo Layout

- `build/` - files used at nixos-rebuild time

- `containers/` - Container configs, mainly docker setups for use on a server.

- `dotfiles/` - Legacy [dotfile](https://wiki.archlinux.org/index.php/Dotfiles)
  configs that are not written in nix, but should be at a later date.

- `flakes/` - Independent flakes, in development, before they are ready to be broken out into a separate repo

- `helpers/` - Nix helper functions to assist with configuration

- `home/` - [home-manager](https://github.com/nix-community/home-manager) modules and configuration.

- `hosts/` - Configuration for individual machines.

- `modules/` - Custom configurable Nix modules

- `overlays/` - Existing package customizations.
  [overlays](https://devos.divnix.com/outputs/overlays.html)

- `pkgs/` - Custom [Packages/Derivations](https://nixos.org/manual/nix/unstable/expressions/derivations.html) that aren't in nixpkgs.

- `profiles/` - Modular configurations for individual concerns.
  See [profiles](https://devos.divnix.com/concepts/profiles.html)

- `overlays/` - Valid overlays included in all hosts

- `scripts/` - Scripts, or any other files to place in home directory,
  managed by [home-manager](https://github.com/nix-community/home-manager).
  This is done via `home.file."scripts".source = "${self}/scripts"`

- `shells/` - Special Environments/Shells, for example with [Yocto](https://www.yoctoproject.org/).

- `wallpapers/` - Background images
