TODOs
=====

## Functionality

* Convert niri KDL string config to niri-flake programs.niri.settings (native Nix attrsets)
  * Add niri-flake input to ~/Code/nixcfg-niri
  * Rewrite modules/desktop/niri/home.nix from KDL strings to programs.niri.settings
  * Convert per-host niri.nix overrides (antikythera, nflx-erahhal-p16, msi-linux)
* Once nixcfg-niri is stable, update ~/Code/nflx-nixcfg to use it instead of the niri config that is in there.
* Greeter config option
  * DMS Greeter vs SDDM vs new Plasma greeter
  * Is the new Plasma greeter the same as SDDM?
* Centralize all theming with light and dark modes. Look into the idiomatic way used by most people using Niri+DMS
* Backups
  * Get proper backup regime of home folder
  * Borg backups? what's the best right now? https://nixos.wiki/wiki/Borg_backup
* Get secure boot setup (lanzaboote?)
* Erase your darlings / Impermanence
  * https://grahamc.com/blog/erase-your-darlings/
  * https://nixos.wiki/wiki/Impermanence

## Bugs

* host antikythera hangs when several video windows open in firefox simultaneously
* Hibernation broken
  * criticalPowerAction = "Hibernate" doesn't seem to work
  * https://discourse.nixos.org/t/hibernate-doesnt-work-anymore/24673/8
* Can't use backspace when kmscon is enabled. VERASE is set to ctrl-h doesn't work in kmscon
  * See src/console/console-pty.c
