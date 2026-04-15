TODOs
=====

## Functionality

* ~~Make specialization-based dark/light toggle faster and more reliable~~
  * ~~Replaced full HM activate with fast symlink-swap toggle~~
  * ~~Added Mod+Shift+T keybinding via DMS~~
  * ~~Stylix does NOT support runtime toggling (issue #447) — kept specialization for build-time generation~~
* Fix all evaluation warnings during build
* in the Niri migration, it seems the touchpad mode got switched to modern mode. I prefer the old reverse mode, where moving the fingers up scrolls up, and moving the fingers down scrolls down.
* Backups
  * Get proper backup regime of home folder
  * Borg backups? what's the best right now? https://nixos.wiki/wiki/Borg_backup
* Get secure boot setup (lanzaboote?)
* Erase your darlings / Impermanence
  * https://grahamc.com/blog/erase-your-darlings/
  * https://nixos.wiki/wiki/Impermanence
* Greeter config option
  * DMS Greeter vs SDDM vs new Plasma greeter
  * Is the new Plasma greeter the same as SDDM?

## Bugs

* host antikythera hangs when several video windows open in firefox simultaneously
* Hibernation broken
  * criticalPowerAction = "Hibernate" doesn't seem to work
  * https://discourse.nixos.org/t/hibernate-doesnt-work-anymore/24673/8
* Can't use backspace when kmscon is enabled. VERASE is set to ctrl-h doesn't work in kmscon
  * See src/console/console-pty.c
