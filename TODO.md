TODOs
=====

Functionality/Fixes
-------------------

* Figure out why IPv6 needs to be disabled for docker for portal client to be accessible
* hyperland
  * https://git.sr.ht/~misterio/nix-config/tree/main/item/home/misterio/features/desktop/hyprland/config.nix
* Setting up multiple upstream repos
  * https://jigarius.com/blog/multiple-git-remote-repositories
  * git remote add all <url1>
  * git remote set-url --add --push all <url1>
  * git remote set-url --add --push all <url2>
* Use wayland for Blender (should be version 3.4)
* Look into native nixos containers
  * https://nixos.wiki/wiki/NixOS_Containers
* Move secrets to a flake
* Move NFLX code to a flake
* Look at protonmail-bridge docker image for email service for various servers
  * https://hub.docker.com/r/shenxn/protonmail-bridge
* Still some issues with xdg-portal-* / gtk / dbus hangs on sway startup
  * Only happens on second and subsequent logins
  * There might be some things left behind on exit...
  * What else related to gtk/xdg-portal/dbus?
    * Do a ps aux capture then compare
* Try remarkable app again
  * https://github.com/emmanuelrosa/sumatrapdf-nix/issues/1
* Terminal
  * ZSH
    * https://github.com/zplug/zplug
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
* Xorg log - failed to load libinput. Check other logs
* i3
  * Create script that creates "virtual" monitors, either using EDID or xrandr position after autorandr
    * https://chipsenkbeil.com/notes/linux-virtual-monitors-with-xrandr/
    * Then use virtual monitor names in i3 config
    * Added scripts to do this, but behaves weirdly - i3 doesn't seem to fully recognize
  * make sure workspaces on right monitor
    * https://www.reddit.com/r/i3wm/comments/hjiwtv/is_there_a_way_to_have_different_workspace_output/
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
  * Look into Regolith
* Setup caching server (hydra)
  * https://www.reddit.com/r/Nix/comments/tv1ax7/can_one_self_host_a_nix_package_repo/
* General Desktop
  * Try pop-shell
  * Switch to a bar that can be shared across x-windows and wayland
    * back to i3status-rs with better config?
    * yambar
  * De-dupe i3 and sway settings as much as possible
  * SMB Browsing
    * https://nixos.wiki/wiki/Samba#links
    * Need to launch sway with dbus
  * Try other Launchers/menus
    - rofi
    - wofi
  * Trackpad gestures like Mac (e.g. switch workspaces)
* xserver
  * "xrandr output names" change on disconnect/connect
    * Create script that creates "virtual" monitors, either using EDID or xrandr position after autorandr
      * https://chipsenkbeil.com/notes/linux-virtual-monitors-with-xrandr/
      * Then use virtual monitor names in i3 config
    * https://github.com/i3/i3/discussions/4830
    * https://www.reddit.com/r/i3wm/comments/sic67s/xrandr_outputs_change_names/
    * not an issue for autorandr since it uses EDID
    * Issue for i3, since it uses output name for workspace assignment
    * Slow mouse scrolling after wake from suspend
      * https://askubuntu.com/questions/1136187/how-do-i-fix-very-slow-scrolling-usb-wheel-mouse-after-waking-from-suspend-whi
  * investigate setupCommands for default monitor layout
    * https://discourse.nixos.org/t/proper-way-to-configure-monitors/12341
  * investigate autorandr-rs
    * https://github.com/theotherjimmy/autorandr-rs/
* i3
  * No idle lock
    * https://wiki.archlinux.org/title/I3
  * i3 spinning mouse cursor on startup
    * https://faq.i3wm.org/question/6200/obtain-info-on-current-workspace-etc.1.html
    * https://www.reddit.com/r/i3wm/comments/3n7txe/i_cant_get_rid_of_the_loading_mouse_cursor_on/
  * bemenu positioned incorrectly on laptop screen
  * Get bemenu to be larger on laptop screen
    * Need to figure out which output is focused
    * https://www.reddit.com/r/i3wm/comments/gsdrsy/can_i_get_the_currently_active_output_screen/
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
  * On reboot, mouse disappears or hangs, and requires movement for a few seconds to recover.  Same with keyboard.
    * WORKAROUND: Have to unplug and replug to fix
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
  * tmux - sometimes only pgup and pgdown work for navigating scrollback
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
  * VIM updates
    - Make another pass at Nix-managed vim plugin config
      - READ: https://github.com/NixOS/nixpkgs/blob/master/pkgs/misc/vim-plugins/vim-utils.nix
      - node modules installed through custom package are not found by nvim-lspconfig
      - coq_nvim writes to its intallation path, which is read-only
      - How to enable unstable vim plugins in home-manager? The plugins aren't in pack folder
  * Node modules
    - Where is the global `node_modules` path?
      - with node itself?
      - https://jingsi.space/post/2019/09/23/nix-install-npm-packages/
      - do other packages get installed here?
    - How to get apps to recognize this location?
    - Add node-modules generate to makefile
  * Protoncheck
    - https://github.com/servusdei2018/protoncheck
  * Personal VPN
    - https://tailscale.com/
  * Get Blender 3 additional libs compiled
    - OSL - Open Shading Language - Sony
      - https://github.com/AcademySoftwareFoundation/OpenShadingLanguage
    - USD (Universal Scene Description) - Pixar
      - https://github.com/PixarAnimationStudios/USD
    - nanovdb
      - https://github.com/AcademySoftwareFoundation/openvdb/tree/feature/nanovdb
    - Jack library
    - Pulse library
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

