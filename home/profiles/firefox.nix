{ pkgs, lib, userParams, ... }:

let
  firefox-scaled = pkgs.symlinkJoin {
    name = "firefox";
    paths = [ pkgs.firefox ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/firefox \
        --set GDK_DPI_SCALE 1.5
    '';
  };
in
{
  # home.packages = with pkgs; [ firefox-scaled ];
  home.packages = with pkgs; [ unstable.firefox ];

  home.activation.firefox = lib.hm.dag.entryAfter [ "installPackages" ] ''
    ## See:
    ## https://bugzilla.mozilla.org/show_bug.cgi?id=1780508
    ## https://bugzilla.mozilla.org/show_bug.cgi?id=1778349
    ## Menus don't show and sometimes firefox crashes when they are too tall
    ## This will likely go away once Sway is updated to the latest
    USE_MOVE_TO_RECT_PREF='user_pref("widget.wayland.use-move-to-rect", false);'

    # DEV_PIXELS_PER_PX_PREF='user_pref("layout.css.devPixelsPerPx", "1.25");'

    ## This shouldn't be needed with GDK_DPI_SCALE=1.5
    # DEV_PIXELS_PER_PX_PREF='user_pref("layout.css.devPixelsPerPx", "-1");'

    for PROFILE_PATH in ~/.mozilla/firefox/*; do
      if [ -f "$PROFILE_PATH/prefs.js" ]; then
        if grep -q "use-move-to-rect" "$PROFILE_PATH/prefs.js"; then
          sed -i "/use-move-to-rect/c\\$USE_MOVE_TO_RECT_PREF" $PROFILE_PATH/prefs.js
        else
          echo $USE_MOVE_TO_RECT_PREF >> $PROFILE_PATH/prefs.js
        fi
        if grep -q "devPixelsPerPx" "$PROFILE_PATH/prefs.js"; then
          sed -i "/devPixelsPerPx/c\\$DEV_PIXELS_PER_PX_PREF" $PROFILE_PATH/prefs.js
        else
          echo $DEV_PIXELS_PER_PX_PREF >> $PROFILE_PATH/prefs.js
        fi
      fi
    done
  '';
}
