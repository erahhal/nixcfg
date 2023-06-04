NixOS Config
============

This is a somewhat opinionated setup for on a Thinkpad T490s laptop at Netflix.
The setup is as follows:

* Desktop environment: wayland / sway / i3status / bemenu / kitty
  * No scaling - apps configured for HiDPI
* Audio: pipewire
* Wireless: network manager
* Browsers: Brave, Firefox
* Other configured apps: Spotify, Gimp, VSCodium, Discord, prismlauncher, Blender
* Netflix specific apps
  * Slack
  * OpenVPN coniguration
  * newt
  * metatron

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

# To connect to the VPN

* run `vpn`

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

- `home/` - [home-manager](https://github.com/nix-community/home-manager) modules and configuration.

- `hosts/` - Machines/Hardware definitions.

- `nixpkgs/` - Git Sub-module of nixpkgs fork.  Allows modifying of base packages, and potentially upstreaming them.

- `pkgs/` - Custom [Packages/Derivations](https://nixos.org/manual/nix/unstable/expressions/derivations.html) that aren't in nixpkgs.

- `profiles/` - Configurations intended to be imported into a given system.
  They define the values for module options.
  See [profiles](https://devos.divnix.com/concepts/profiles.html)

- `suites/` - Collections of profiles
  [suites](https://devos.divnix.com/concepts/suites.html)

- `overlays/` - Valid overlays included in all hosts
  [overlays](https://devos.divnix.com/outputs/overlays.html)

- `secrets/` - [`age`](https://github.com/FiloSottile/age) encrypted secrets,
  made possible by [`agenix`](https://github.com/ryantm/agenix)

- `dotfiles/` - Legacy [dotfile](https://wiki.archlinux.org/index.php/Dotfiles)
  configs that are not written in nix, but should be at a later date.

- `scripts/` - Scripts, or any other files to place in home directory,
  managed by [home-manager](https://github.com/nix-community/home-manager).
  This is done via `home.file."scripts".source = "${self}/scripts"`

- `shells/` - Special Environments/Shells, for example with [Yocto](https://www.yoctoproject.org/).
