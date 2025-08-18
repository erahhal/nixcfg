TODOs
=====

* Xorg log - failed to load libinput. Check other logs
* i3
  * Create script that creates "virtual" monitors, either using EDID or xrandr position after autorandr
    * https://chipsenkbeil.com/notes/linux-virtual-monitors-with-xrandr/
    * Then use virtual monitor names in i3 config
    * Added scripts to do this, but behaves weirdly - i3 doesn't seem to fully recognize
  * make sure workspaces on right monitor
    * https://www.reddit.com/r/i3wm/comments/hjiwtv/is_there_a_way_to_have_different_workspace_output/
  * No idle lock
    * https://wiki.archlinux.org/title/I3
  * i3 spinning mouse cursor on startup
    * https://faq.i3wm.org/question/6200/obtain-info-on-current-workspace-etc.1.html
    * https://www.reddit.com/r/i3wm/comments/3n7txe/i_cant_get_rid_of_the_loading_mouse_cursor_on/
  * bemenu positioned incorrectly on laptop screen
  * Get bemenu to be larger on laptop screen
    * Need to figure out which output is focused
    * https://www.reddit.com/r/i3wm/comments/gsdrsy/can_i_get_the_currently_active_output_screen/
* General Desktop
  * Switch to a bar that can be shared across x-windows and wayland
    * back to i3status-rs with better config?
    * yambar
  * De-dupe i3 and sway settings as much as possible
  * SMB Browsing
    * https://nixos.wiki/wiki/Samba#links
    * Need to launch sway with dbus
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
