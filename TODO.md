TODOs
=====

Warts/Issues
------------

* Try plasmashell on top of Hyprland
  * https://www.reddit.com/r/hyprland/comments/1ch3qkp/plasma_shell_on_hyprland_feels_really_out_of_place/
* Add Zellij as alternative to tmux
* Hibernation broken
  * criticalPowerAction = "Hibernate" doesn't seem to work
  * https://discourse.nixos.org/t/hibernate-doesnt-work-anymore/24673/8
* VERASE is set to ctrl-h doesn't work in kmscon
  * See src/console/console-pty.c
* hyprland crashes if undocked while DPMS off
* ZSH/Tmux/Kitty cut and paste issues
  * DISABLE_MAGIC_FUNCTIONS=true
  * https://unix.stackexchange.com/questions/643018/how-can-i-disable-kittys-paste-from-escaping
* Agenix does not decrypt on boot for Sicmundus
* Figure out ZFS trim schedule
  * https://askubuntu.com/questions/1200172/should-i-turn-on-zfs-trim-on-my-pools-or-should-i-trim-on-a-schedule-using-syste
  * Setup "zpool trim" same as scrub schedule
    * Looks like services.zfs.trim.enable will do this
  * Is scrub setup?
* ZFS tuning
  * zfs set atime=off rpool
* Look into replacing custom recursiveMerge with lib.recursiveMerge
* Get rid of all references to Networkd?
  * There is no GUI or tray applet for Networkd - NetworkManager is used for desktops, networkd for servers/headless
* Erase your darlings / Impermanence
  * https://grahamc.com/blog/erase-your-darlings/
  * https://nixos.wiki/wiki/Impermanence
* Nvim todos in nvim.nix
* Need to unplug/plug USB peripherals after reboot due to quick "sleeping" of mouse/keyboard
  * https://bbs.archlinux.org/viewtopic.php?id=251866
  * Seems to have gone away...
* Slack screen sharing crashes slack
  * https://github.com/flathub/com.slack.Slack/issues/195
  * https://github.com/flathub/com.slack.Slack/issues/196
  * 4.29 worked, 4.31 broke
* Sharing of individual windows in Sway
  * https://github.com/emersion/xdg-desktop-portal-wlr/issues/107
  * https://github.com/emersion/xdg-desktop-portal-wlr/issues/12#issuecomment-770377796
  * https://gitlab.freedesktop.org/wayland/wayland-protocols/-/merge_requests/187
* Openconnect VPN
  * Run as global systemd service
  * Auto-reconnect on disconnect or network change
* Steam games not really working with nVidia
  * Slow
  * Screen artifacts / bad aspect ratio
  * https://github.com/swaywm/sway/issues/6422
  * https://www.reddit.com/r/archlinux/comments/upns2v/how_to_use_prime_nvidia_driver_with_sway_and_steam/
* Gaming
  * Get gamescope to work
    * https://news.ycombinator.com/item?id=38825621
    * https://github.com/NixOS/nixpkgs/issues/162562
    * https://github.com/NixOS/nixpkgs/issues/214275
* Force XWayland to run unscaled, like Hyprland
* On reboot, mouse disappears or hangs, and requires movement for a few seconds to recover.  Same with keyboard.
  * WORKAROUND: Have to unplug and replug to fix
  * Doesn't seem to happen anymore - may be able to remove switch
* Get autodesk fusion to work
  * Snap: https://github.com/Thermionix/fusion360
  * https://github.com/Thermionix/fusion360/issues/25
  * Try running with env vars: https://github.com/Thermionix/fusion360/issues/21#issuecomment-1687528814
  * Use qemu with windows if nothing else works
* Get Fcitx 5 or some Chinese IME working
  * https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland#Fcitx_managed_XKB_layout
  * Seems that you need a version of sway with "text-input-v3" (and maybe "text-input-v2") protocol compiled in

Improvments
-----------

* Centralize all icon theme and sizing code
* Centralize references to waybar
  * e.g. need to change to unstable.waybar in multiple places to avoid collisions
* Share video of canonical VP of cloud on Nix
  * https://www.youtube.com/watch?v=9l-U2NwbKOc
* tailscale with headscale
* lazy nvim
* Ubuntu setup with Determinate
  * https://determinate.systems/posts/determinate-nix-installer/
* Secure boot with automatic TPM decryption
  * https://github.com/nix-community/lanzaboote?tab=readme-ov-file
  * https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md
* Building out disk automatically for new installs
  * https://github.com/nix-community/disko
* Running VMs using Nix
  * https://github.com/jnsgruk/crafts-flake
  * https://www.tweag.io/blog/2023-02-09-nixos-vm-on-macos/
* Evaluate Jon Seager from Canonical's config
  * https://github.com/jnsgruk/nixos-config
  * Traefik
* Add nixos-infect install scripot
 * Test with an ubuntu image, like done with the umbrel box
* Gnome Keyring in sway
  * https://news.ycombinator.com/item?id=36740062
* Sway updates and upgrades
  * https://github.com/swaywm/sway/wiki/Useful-add-ons-for-sway
* Install synergy alternative
  * https://github.com/feschber/lan-mouse
* Raspberry Pi
  * https://nix.dev/tutorials/nixos/installing-nixos-on-a-raspberry-pi
  * https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#raspberry-pi-4-boot-eeprom
* Command line package search
  * https://github.com/nix-community/nix-index
  * https://discourse.nixos.org/t/which-package-provides-ifconfig/25824/9
* Get rid of pipewire package override when stable version is at least 0.3.77
* Setting up multiple upstream repos
  * https://jigarius.com/blog/multiple-git-remote-repositories
  * git remote add all <url1>
  * git remote set-url --add --push all <url1>
  * git remote set-url --add --push all <url2>
* Look into native nixos containers
  * https://nixos.wiki/wiki/NixOS_Containers
* Look at protonmail-bridge docker image for email service for various servers
  * https://hub.docker.com/r/shenxn/protonmail-bridge
* Terminal
  * Base16
    * https://github.com/SenchoPens/base16.nix
* Network Manager profiles
  * https://github.com/jmackie/nixos-networkmanager-profiles
* Backups
  * Home Assistant
  * Gitea
    * OPNSense config backup plugin
    * Git repos
  * OPNSense
    * Git backup of config
    * Unifi backup
    * Adguard Home backup?
    * how to back up entire device?
  * Android
    * Nova Launcher
    * Netguard
    * Mi band
  * Confirm that backing up /mnt/nas-home/erahhal/Photos is enough
    * Is album data stored here? - maybe not
    * Photos Updated
      * Folder structure now respected
      * Timeline view still exists - files uploaded here are put in date folders
  * Finish adding / sorting photos
    * Re-organize /mnt/nas-home/erahhal/Photos
    * Is there a setting to not automatically re-org?
  * Go through "unsorted" folder
  * Read: https://nixos.wiki/wiki/Borg_backup
    * Backup failure notification (email?)
    * Don't try backup when network is unreachable
    * Mounting point-in-time archives, backups
  * Firefox
    * Sync?
  * Weechat
* NixOps deployment for server
* Network Manager VPN
  * https://www.reddit.com/r/NixOS/comments/tohbaq/openvpn_through_network_manager/i269jof/?context=3
* Add secrets
  * ~/.password-store
    ~/.gnupg
* proliant
  * iSCSI - unclear if following commands stick on reboot - would like to make part of nix config
    * sudo iscsiadm --mode discovery -t sendtargets --portal nas
    * sudo iscsiadm --mode node --targetname iqn.2000-01.com.synology:nas.default-target.e4b1877b03a
    * sudo iscsiadm --mode node --targetname iqn.2000-01.com.synology:nas.default-target.e4b1877b03a --portal nas --login
    * To log out: iscsiadm --mode node --logout
* SDDM
  * monitor order/position config (xrandr?)
    * https://wiki.archlinux.org/title/SDDM#Rotate_display
  * PATH not being loaded, or being overwritten when desktop launched
    * https://discourse.nixos.org/t/home-manager-doesnt-seem-to-recognize-sessionvariables/8488/8
  * Get rid of SDDM patch.  There's probably the "right" way to use vanilla SDDM.  systemd service?
    * exec systemctl --user import-environment
  * Sway is able to connect to existing wayland session from SDDM, but it's tiny - how to remedy this?
* Nvidia
  * Look into lutris
  * Look into Regolith on Sway
* Setup caching server (hydra)
  * https://www.reddit.com/r/Nix/comments/tv1ax7/can_one_self_host_a_nix_package_repo/
* Sway
  * Get swaylock to work with both password and fprintd
   - https://github.com/swaywm/swaylock/issues/61
  * way-displays
    - Better kanshi alternative
    - https://www.reddit.com/r/swaywm/comments/q737e3/waydisplays_manage_your_wayland_displays/
  * Other tools
    - https://github-wiki-see.page/m/swaywm/sway/wiki/Useful-add-ons-for-sway
  * Still not sure that SwayWM is being loaded correctly as a systemd service
    - Can't source user environment without patching SDDM
    - programs.sway.extraSessionCommands doesn't work
    - systemd.user.sessionVariables doesn't work
    - Need to figure out how to use "startsway" script
        - new session, but how to make it a wayland session instead of xsession?
    - does a new WM session need to be created that launches sway through systemd after sourcing the user environment?
* hardware/peripherals
  * Add brother printer / scanner driver
    - https://discourse.nixos.org/t/install-cups-driver-for-brother-printer/7169
    - https://nixos.wiki/wiki/Scanners
  * Look into whether acpid is needed/useful
    - https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/hardware/acpid.nix
    - https://github.com/NixOS/nixpkgs/issues/25248
* Dell
  * cctk not working
    * https://aur.archlinux.org/packages/dell-command-configure/
  * General tuning for XPS 9560
    * https://github.com/NixOS/nixos-hardware/tree/master/dell/xps/15-9560
    * https://grahamc.com/blog/nixos-on-dell-9560
* Apps/Software
  * platformio installation automation
    - https://nixos.wiki/wiki/Platformio
    - Automatically update settings
      - platformio-ide.useBuiltinPIOCore: false
      - platformio-ide.customPATH: <path to platformio>
      - also teensy "upload_command"
  * INSTEAD, use command line for teensy
    - https://rzetterberg.github.io/teensy-development-on-nixos.html
    - https://gist.github.com/the-kenny/9511975
  * wine
    - declarative DPI to 210 instead of using `winecfg`
      - see reg file in remarkable flake
    - https://github.com/emmanuelrosa/erosanix
    - https://github.com/emmanuelrosa/sumatrapdf-nix
  * Get `nmtui` working without root again
    - disable wifi iwd if that doesn't help freezes?
  * Protoncheck
    - https://github.com/servusdei2018/protoncheck
  * Get weechat config wrapped in Nix
    - https://gist.github.com/erahhal/f859602c4c1825769be8f11220a993cc
    - -r, --run-command <command>
    - setup servers
      /server add libera irc.libera.chat/6697 -ssl
      /set irc.server.libera.nicks "colordrops"
      /set irc.server.libera.autoconnect on

      /secure passphrase xxxxx
      /secure set libera_password xxxxx

      /set irc.server.libera.sasl_username "colordrops"
      /set irc.server.libera.sasl_password "${sec.data.libera_password}"
        or
      /set irc.server.libera.command "/msg nickserv identify ${sec.data.libera_password}"

      /set irc.server.libera.autojoin "#nixos,#linux,#neovim,#javascript,#sway,#nextcloud,#lineageos,#zsh,#peertube,#opnsense,#lua,#blender"
        - filter join/quit/part
      /set irc.look.smart_filter on
      /filter add irc_smart * irc_smart_filter *
      /filter add joinquit * irc_join,irc_part,irc_quit *

      /set irc.server.libera.command "/filter add irc_smart * irc_smart_filter *"
      /filter add irc_smart * irc_smart_filter *
      /filter add joinquit * irc_join,irc_part,irc_quit *
        - switch between server buffers: ctrl+x
        - disable automerge of server buffers
      /set irc.look.server_buffer independent
* Get windows games working on steam
  - https://www.reddit.com/r/NixOS/comments/koa1a9/play_windows_games_on_steam/
* OpenVPN
  - Doesn't recover from suspend
  - Sometimes unstable - due to suspend?  Seems to be ok now
  - Move docker `daemon.json` update from openvpn config script to proper managed config
    - this requires figuring out how to get docker to pick up openvpn's DNS without writing to `daemon.json` use networkmanager to connect to VPN
    - Or at least easier command line command

Template System
---------------

* Look into DevOS as template
  - https://devos.divnix.com/start/
* Configurable options
  - defaultLocale
  - keyboard repeat rate, delay
    - maps appropriate depending on WM
  - idle timeout (to WM)
  - suspend timeout (to system)
  - terminal
  - fingerprint enabled
  - display manager
  - window manager
  - editor
  - IRC client
  - browser
* UI configuration
  - https://github.com/nix-gui/nix-gui
  - https://github.com/pmiddend/nixos-manager
* Mitchell Hashimoto's NixOS dev VM on macs
  - https://twitter.com/mitchellh/status/1452721115009191938
