TODOs
=====

## Functionality

* Investigate whether all the Makefile functionality could be moved to scripts managed by the flake
  * This would include getting rid of the "build" folder
* Delete "pi" package if it's not used anywhere
* Look into replacing custom recursiveMerge with lib.recursiveMerge
* Get rid of all references to Networkd? Only if it's not used.
  * There is no GUI or tray applet for Networkd - NetworkManager is used for desktops, networkd for servers/headless
* Erase your darlings / Impermanence
  * https://grahamc.com/blog/erase-your-darlings/
  * https://nixos.wiki/wiki/Impermanence
* Greeter config option
  * DMS Greeter vs SDDM vs new Plasma greeter
  * Is the new Plasma greeter the same as SDDM?
* Centralize all theming with light and dark modes. Look into the idiomatic way used by most people using Niri+DMS
* Backups
  * Get proper backup regime of home folder
  * Borg backups? what's the best right now? https://nixos.wiki/wiki/Borg_backup
* Get secure boot setup (lanzaboote?)
* Add first-class protonmail-bridge support if it is not already added.

## Bugs

* host antikythera hangs when several video windows open in firefox simultaneously
* Hibernation broken
  * criticalPowerAction = "Hibernate" doesn't seem to work
  * https://discourse.nixos.org/t/hibernate-doesnt-work-anymore/24673/8
* Can't use backspace when kmscon is enabled. VERASE is set to ctrl-h doesn't work in kmscon
  * See src/console/console-pty.c
