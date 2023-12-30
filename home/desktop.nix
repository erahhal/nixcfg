{ pkgs, inputs, hostParams, userParams, ... }:

let
  defaultBrowserApp = "${hostParams.defaultBrowser}.desktop";
in
{
  imports = [
    #   # ../overlays/spotify-hidpi.nix
    #   ../overlays/zoom-us.nix
    # ../overlays/brave-wayland.nix
  ];

  environment.systemPackages = with pkgs; [
    ##  mkWindowsApp apps together conflict in home-manager, so install globally
    inputs.remarkable.packages."${system}".remarkable
  ];

  # i18n.inputMethod.enabled = "ibus";
  # i18n.inputMethod.ibus.engines = with pkgs.ibus-engines; [ libpinyin ];
  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enabled = "fcitx5";
      # enabled = "ibus";
      # ibus = { engines = with pkgs.ibus-engines; [ libpinyin rime ]; };
      fcitx5.addons = with pkgs; [
        fcitx5-chinese-addons
        fcitx5-gtk
        fcitx5-mozc
        fcitx5-rime
        libsForQt5.fcitx5-qt
        rime-data
      ];
    };
  };

  # For xdg-desktop-portal-wlr
  # GTK apps will hang for 30 seconds at start of sway and render strangely without this
  services.dbus = {
    enable = true;
  };

  home-manager.users.${userParams.username} = {
    _module.args.hostParams = hostParams;

    imports = [
      ./profiles/element.nix
      ./profiles/kitty.nix
      ./profiles/gthumb.nix
      ./profiles/signal.nix
      ## Should be handled by wayland scaling now
      # ./profiles/firefox.nix
      ## Should be handled by wayland scaling now
      # ./profiles/qt4-hidpi.nix
    ];

    # ---------------------------------------------------------------------------
    # MIME apps
    # ---------------------------------------------------------------------------

    ## Desktop file locations:
    # ~/.local/share/applications
    # /run/current-system/sw/share/applications
    # $XDG_DATA_DIRS
    #   /etc/profiles/per-user/erahhal/share/applications

    xdg.enable = true;
    xdg.mimeApps = {
      enable = true;
      # Make sure VSCode doesn't take over file mimetype
      associations.added = {
        # "inode/directory" = [ "nemo.desktop" ];
        "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
        "x-scheme-handler/http" = [ defaultBrowserApp ];
        "x-scheme-handler/https" = [ defaultBrowserApp ];
        "x-scheme-handler/about" = [ defaultBrowserApp ];
        "x-scheme-handler/unknown" = [ defaultBrowserApp ];
        "x-scheme-handler/chrome" = [ defaultBrowserApp ];
        "text/html" = [ defaultBrowserApp ];
        "application/x-extension-htm" = [ defaultBrowserApp ];
        "application/x-extension-html" = [ defaultBrowserApp ];
        "application/x-extension-shtml" = [ defaultBrowserApp ];
        "application/xhtml+xml" = [ defaultBrowserApp ];
        "application/x-extension-xhtml" = [ defaultBrowserApp ];
        "application/x-extension-xht" = [ defaultBrowserApp ];
        "application/x-www-browser" = [ defaultBrowserApp ];
        "application/pdf" = [ defaultBrowserApp ];
        "x-www-browser" = [ defaultBrowserApp ];
        "x-scheme-handler/webcal" = [ defaultBrowserApp ];
        "image/png" = [ "org.gnome.gThumb.desktop" ];
        "image/jpg" = [ "org.gnome.gThumb.desktop" ];
        "image/jpeg" = [ "org.gnome.gThumb.desktop" ];
        "image/tiff" = [ "org.gnome.gThumb.desktop" ];
        "image/webp" = [ "org.gnome.gThumb.desktop" ];
        "image/gif" = [ "org.gnome.gThumb.desktop" ];
        "video/x-flv" = [ "mpv.desktop" ];
        "video/mp4" = [ "mpv.desktop" ];
        "application/x-mpegURL" = [ "mpv.desktop" ];
        "video/MP2T" = [ "mpv.desktop" ];
        "video/3gpp" = [ "mpv.desktop" ];
        "video/quicktime" = [ "mpv.desktop" ];
        "video/webm" = [ "mpv.desktop" ];
        "video/x-msvideo" = [ "mpv.desktop" ];
        "video/x-ms-wmv" = [ "mpv.desktop" ];
        "application/x-bittorrent" = [ "transmission-gtk.desktop" ];
        "x-scheme-handler/magnet" = [ "transmission-gtk.desktop" ];

      };
      defaultApplications = {
        # "inode/directory" = [ "nemo.desktop" ];
        "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
        "x-scheme-handler/http" = [ defaultBrowserApp ];
        "x-scheme-handler/https" = [ defaultBrowserApp ];
        "x-scheme-handler/about" = [ defaultBrowserApp ];
        "x-scheme-handler/unknown" = [ defaultBrowserApp ];
        "x-scheme-handler/chrome" = [ defaultBrowserApp ];
        "text/html" = [ defaultBrowserApp ];
        "application/x-extension-htm" = [ defaultBrowserApp ];
        "application/x-extension-html" = [ defaultBrowserApp ];
        "application/x-extension-shtml" = [ defaultBrowserApp ];
        "application/xhtml+xml" = [ defaultBrowserApp ];
        "application/x-extension-xhtml" = [ defaultBrowserApp ];
        "application/x-extension-xht" = [ defaultBrowserApp ];
        "application/x-www-browser" = [ defaultBrowserApp ];
        "application/pdf" = [ defaultBrowserApp ];
        "x-www-browser" = [ defaultBrowserApp ];
        "x-scheme-handler/webcal" = [ defaultBrowserApp ];
        "image/png" = [ "org.gnome.gThumb.desktop" ];
        "image/jpg" = [ "org.gnome.gThumb.desktop" ];
        "image/jpeg" = [ "org.gnome.gThumb.desktop" ];
        "image/tiff" = [ "org.gnome.gThumb.desktop" ];
        "image/webp" = [ "org.gnome.gThumb.desktop" ];
        "image/gif" = [ "org.gnome.gThumb.desktop" ];
        "video/x-flv" = [ "mpv.desktop" ];
        "video/mp4" = [ "mpv.desktop" ];
        "application/x-mpegURL" = [ "mpv.desktop" ];
        "video/MP2T" = [ "mpv.desktop" ];
        "video/3gpp" = [ "mpv.desktop" ];
        "video/quicktime" = [ "mpv.desktop" ];
        "view/webm" = [ "mpv.desktop" ];
        "video/x-msvideo" = [ "mpv.desktop" ];
        "video/x-ms-wmv" = [ "mpv.desktop" ];
        "x-scheme-handler/zoommtg" = [ "Zoom.desktop" ];
        "application/x-zoom" = [ "Zoom.desktop" ];
        "application/x-bittorrent" = [ "transmission-gtk.desktop" ];
        "x-scheme-handler/magnet" = [ "transmission-gtk.desktop" ];
      };
    };

    # @TODO: For some reason ~/.config/mimeapps.list is ignored by the following commands:
    #
    #    XDG_UTILS_DEBUG_LEVEL=2 xdg-settings get default-web-browser
    #    XDG_UTILS_DEBUG_LEVEL=2 xdg-mime query default text/html
    #
    # but "mimeinfo.cache" is not ignored.
    #
    # @SHIT: seems that /etc/profiles/per-user/erahhal/share/applications/mimeinfo.cache still overriding everything
    #        location: echo $(readlink /etc/static/profiles/per-user/erahhal)/share/applications/mimeinfo.cache
    #
    xdg.dataFile."applications/mimeinfo.cache".text = ''
      [MIME Cache]
      application/rdf+xml=${defaultBrowserApp};
      application/rss+xml=${defaultBrowserApp};
      application/xhtml+xml=${defaultBrowserApp};
      application/xhtml_xml=${defaultBrowserApp};
      application/xml=${defaultBrowserApp};
      text/html=${defaultBrowserApp};
      text/xml=${defaultBrowserApp};
    '';

    # ---------------------------------------------------------------------------
    # Display, Theme, DPI, Cursor Size settings
    # ---------------------------------------------------------------------------

    home.file."Wallpapers".source = ../wallpapers;

    home.sessionVariables = {
      # ---------------------------------------------------------------------------
      # IME
      # ---------------------------------------------------------------------------
      XMODIFIERS = "@im=fcitx";
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      SDL_IM_MODULE = "fcitx";
      INPUT_METHOD = "fcitx";
      XIM_SERVERS = "fcitx";
      GLFW_IM_MODULE = "ibus";

      # ---------------------------------------------------------------------------
      # Browser
      # ---------------------------------------------------------------------------
      BROWSER = "firefox";
      DEFAULT_BROWSER = "firefox";

      # ---------------------------------------------------------------------------
      # Java / Jetbrains
      # ---------------------------------------------------------------------------
      _JAVA_AWT_WM_NONREPARENTING = "1";

      # ---------------------------------------------------------------------------
      # Command line
      # ---------------------------------------------------------------------------
      MANPAGER = "vim -c ASMANPAGER -";
    };

    # ---------------------------------------------------------------------------
    # Selected packages for all hosts
    # ---------------------------------------------------------------------------

    home = {
      extraOutputsToInstall = [ "man" ]; # Additionally installs the manpages for each pkg

      packages = with pkgs; [
        ## system
        captive-browser
        gucharmap
        xorg.xdpyinfo
        # Dbus viewer
        dfeet

        ## disk space
        baobab
        qdirstat
        filelight

        ## apps
        audacity
        czkawka
        brave
        unstable.digikam
        unstable.discord
        evolutionWithPlugins
        feh
        unstable.firefox
        glava
        gnome.gnome-todo
        gnome3.cheese
        gnome3.gnome-calculator
        joplin-desktop
        kcalc
        # Not yet available in stable
        unstable.kphotoalbum
        krita
        libreoffice
        mpv
        unstable.rpi-imager
        shotwell
        spotify
        sxiv # image viewer with vim bindings
        unstable.stellarium
        vlc
        unstable.bitwarden
        # gimp-with-plugins
        # pr67576-gimp-wayland.gimp-with-plugins
        pr67576-gimp-wayland.gimp
        zoom-us
        waydroid
        webcamoid
        whatsapp-for-linux
        xournalpp

        # games
        wesnoth

        ## desktop
        # unstable.ardour
        flavours
        gnome3.adwaita-icon-theme
        gnome3.eog # image viewer
        gnome3.evince # PDF viewer
        gnome3.nautilus
        # cinnamon.nemo
        obs-studio
        # @TODO: figure out a way to overlay instead of replacing the package
        # This will get out of date
        sweethome3d.application
        xfce.thunar
        xfce.xfconf # Needed to save the preferences
        xfce.exo # Used by default for `open terminal here`, but can be changed
        # qt5
        # qt6
        libsForQt5.qtstyleplugins
        playerctl
        teams-for-linux

        # Pipewire connection tool
        qpwgraph

        ## Wine
        ## wine-staging (version with experimental features)
        ## winetricks and other programs depending on wine need to use the same wine version
        # wineWowPackages.staging
        # (winetricks.override { wine = wineWowPackages.staging; })
        # wineWowPackages.stable
        # winetricks
        # wineWowPackages.waylandFull

        ## unfree
        bcompare
      ];
    };

    # ---------------------------------------------------------------------------
    # Program configuration
    # ---------------------------------------------------------------------------

    home.file.".fehrc".text = ''
      feh --auto-zoom
    '';

    services.caffeine = {
      # Using Wayland's idle functionality + a waybar widget
      enable = false;
    };

    # programs.vscode = {
    #   enable = true;
    #   package = pkgs.unstable.vscode;    # omit this to use the unfree version
    #   extensions = with pkgs.unstable.vscode-extensions; [
    #     # Some example extensions...
    #     dracula-theme.theme-dracula
    #     vscodevim.vim
    #     yzhang.markdown-all-in-one
    #   ];
    # };

    programs.mpv = {
      enable = true;
    };

    xdg.configFile."mpv/mpv.conf".text = ''
      no-border
      fullscreen=yes
      stop-screensaver=yes
      hwdec=auto
      ytdl-format=bestvideo+bestaudio
      gpu-context=wayland
      # profile=gpu-hq
    '';

    xdg.configFile."mpv/input.conf".text = ''
      k seek 60
      j seek -60
      h seek -10
      l seek 10
    '';
  };
}
