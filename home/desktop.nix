{ pkgs, inputs, hostParams, userParams, ... }:

let
  defaultBrowserApp = "${hostParams.defaultBrowser}.desktop";

  gnome-calculator-hidpi = pkgs.callPackage ../pkgs/gnome-calculator-hidpi {};
  sweethome3d-hidpi = pkgs.callPackage ../pkgs/sweethome3d-hidpi {};

  xwayland_settings = ''
    Xcursor.size: ${if hostParams.defaultSession == "none+i3" then "48" else "24"}
    Xcursor.theme: Adwaita
    Xft.dpi: 100
    xterm*background: black
    xterm*faceName: Monospace
    xterm*faceSize: 12
    xterm*foreground: lightgray
  '';
in
{
  imports = [
  #   # ../overlays/spotify-hidpi.nix
  #   ../overlays/zoom-us.nix
    ../overlays/brave-wayland.nix
    ../overlays/chromium-wayland.nix
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
      fcitx5.addons = with pkgs; [
        fcitx5-chinese-addons
        fcitx5-gtk
        fcitx5-rime
        libsForQt5.fcitx5-qt
        rime-data
      ];
    };
  };

  # For xdg-desktop-portal-wlr
  # GTK apps will hang for 30 seconds at start of sway and render strangely without this
  services.dbus.enable = true;

  home-manager.users.${userParams.username} = {
    _module.args.inputs = inputs;
    _module.args.hostParams = hostParams;

    imports = [
      ./profiles/kitty.nix
      ## Should be handled by wayland scaling now
      # ./profiles/firefox.nix
      ## Should be handled by wayland scaling now
      # ./profiles/qt4-hidpi.nix
    ];

    # ---------------------------------------------------------------------------
    # MIME apps
    # ---------------------------------------------------------------------------

    xdg.enable = true;
    xdg.mimeApps = {
      enable = true;
      # Make sure VSCode doesn't take over file mimetype
      associations.added = {
        "inode/directory" = ["nemo.desktop"];
        "x-scheme-handler/http" = [defaultBrowserApp];
        "x-scheme-handler/https" = [defaultBrowserApp];
        "x-scheme-handler/about" = [defaultBrowserApp];
        "x-scheme-handler/unknown" = [defaultBrowserApp];
        "x-scheme-handler/chrome" = [defaultBrowserApp];
        "text/html" = [defaultBrowserApp];
        "application/x-extension-htm" = [defaultBrowserApp];
        "application/x-extension-html" = [defaultBrowserApp];
        "application/x-extension-shtml" = [defaultBrowserApp];
        "application/xhtml+xml" = [defaultBrowserApp];
        "application/x-extension-xhtml" = [defaultBrowserApp];
        "application/x-extension-xht" = [defaultBrowserApp];
        "application/x-www-browser" = [defaultBrowserApp];
        "x-www-browser" = [defaultBrowserApp];
        "x-scheme-handler/webcal" = [defaultBrowserApp];
        "image/png" = ["org.gnome.gThumb.desktop"];
        "image/jpg" = ["org.gnome.gThumb.desktop"];
        "image/jpeg" = ["org.gnome.gThumb.desktop"];
        "image/tiff" = ["org.gnome.gThumb.desktop"];
        "image/webm" = ["org.gnome.gThumb.desktop"];
        "image/gif" = ["org.gnome.gThumb.desktop"];
        "video/x-flv" = ["mpv.desktop"];
        "video/mp4" = ["mpv.desktop"];
        "application/x-mpegURL" = ["mpv.desktop"];
        "video/MP2T" = ["mpv.desktop"];
        "video/3gpp" = ["mpv.desktop"];
        "video/quicktime" = ["mpv.desktop"];
        "video/x-msvideo" = ["mpv.desktop"];
        "video/x-ms-wmv" = ["mpv.desktop"];
      };
      defaultApplications = {
        "inode/directory" = ["nemo.desktop"];
        "x-scheme-handler/http" = [defaultBrowserApp];
        "x-scheme-handler/https" = [defaultBrowserApp];
        "x-scheme-handler/about" = [defaultBrowserApp];
        "x-scheme-handler/unknown" = [defaultBrowserApp];
        "x-scheme-handler/chrome" = [defaultBrowserApp];
        "text/html" = [defaultBrowserApp];
        "application/x-extension-htm" = [defaultBrowserApp];
        "application/x-extension-html" = [defaultBrowserApp];
        "application/x-extension-shtml" = [defaultBrowserApp];
        "application/xhtml+xml" = [defaultBrowserApp];
        "application/x-extension-xhtml" = [defaultBrowserApp];
        "application/x-extension-xht" = [defaultBrowserApp];
        "application/x-www-browser" = [defaultBrowserApp];
        "x-www-browser" = [defaultBrowserApp];
        "x-scheme-handler/webcal" = [defaultBrowserApp];
        "image/png" = ["org.gnome.gThumb.desktop"];
        "image/jpg" = ["org.gnome.gThumb.desktop"];
        "image/jpeg" = ["org.gnome.gThumb.desktop"];
        "image/tiff" = ["org.gnome.gThumb.desktop"];
        "image/webm" = ["org.gnome.gThumb.desktop"];
        "image/gif" = ["org.gnome.gThumb.desktop"];
        "video/x-flv" = ["mpv.desktop"];
        "video/mp4" = ["mpv.desktop"];
        "application/x-mpegURL" = ["mpv.desktop"];
        "video/MP2T" = ["mpv.desktop"];
        "video/3gpp" = ["mpv.desktop"];
        "video/quicktime" = ["mpv.desktop"];
        "video/x-msvideo" = ["mpv.desktop"];
        "video/x-ms-wmv" = ["mpv.desktop"];
        "x-scheme-handler/zoommtg" = ["Zoom.desktop"];
        "application/x-zoom" = ["Zoom.desktop"];
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

    # For X
    home.file.".Xresources".text = xwayland_settings;
    # For sway
    home.file.".Xdefaults".text = xwayland_settings;

    gtk = {
      enable = true;

      # Used by Zenity and Firefox menus and tabs
      # GDK_DPI_SCALE is used in conjunction with this
      font = {
        name = "DejaVu Sans";
        size = 10;
      };

      theme.name = "Arc-Dark";
      theme.package = pkgs.arc-theme;
      # theme.name = "SolArc-Dark";
      # theme.package = pkgs.solarc-gtk-theme;
      # theme.name = "Materia";
      # theme.package = pkgs.materia-theme;
      iconTheme.package = pkgs.gnome3.adwaita-icon-theme;
      iconTheme.name = "Adwaita";

      gtk2.extraConfig = if hostParams.defaultSession == "none+i3" then ''
        gtk-cursor-theme-name="Adwaita"
        gtk-cursor-theme-size=48
        gtk-application-prefer-dark-theme=1
      '' else ''
        gtk-cursor-theme-name="Adwaita"
        gtk-cursor-theme-size=24
        gtk-application-prefer-dark-theme=1
      '';
      gtk3.extraConfig = if hostParams.defaultSession == "none+i3" then {
        "gtk-cursor-theme-name" = "Adwaita";
        "gtk-cursor-theme-size" = 48;
        "gtk-application-prefer-dark-theme" = 1;
      } else {
        "gtk-cursor-theme-name" = "Adwaita";
        "gtk-cursor-theme-size" = 24;
        "gtk-application-prefer-dark-theme" = 1;
      };
      gtk4.extraConfig = if hostParams.defaultSession == "none+i3" then {
        "gtk-cursor-theme-name" = "Adwaita";
        "gtk-cursor-theme-size" = 48;
      } else {
        "gtk-cursor-theme-name" = "Adwaita";
        "gtk-cursor-theme-size" = 24;
      };
    };

    dconf = {
      enable = true;
      settings = {
        "org/gnome/desktop/interface" = {
          "cursor-size" = if hostParams.defaultSession == "none+i3" then 48 else 24;
          "color-scheme" = "prefer-dark";
        };
      };
    };

    qt = {
      enable = true;
      platformTheme = "gnome";
      style = {
        name = "adwaita-dark";
        package = pkgs.adwaita-qt;
      };
    };

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
        gthumb
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
        gimp-with-plugins
        zoom-us
        webcamoid
        xournalpp

        ## desktop
        flavours
        gnome3.adwaita-icon-theme
        gnome3.eog # image viewer
        gnome3.evince # PDF viewer
        gnome3.nautilus
        cinnamon.nemo
        unstable.element-desktop
        obs-studio
        # @TODO: figure out a way to overlay instead of replacing the package
        # This will get out of date
        sweethome3d.application
        xfce.thunar
        xfce.xfconf # Needed to save the preferences
        xfce.exo # Used by default for `open terminal here`, but can be changed
        qt4
        libsForQt5.qtstyleplugins
        playerctl

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
    '';

    # @TODO: move to a home.activation script
    xdg.configFile.kcalcrc.text = ''
      [Colors]
      BackColor=35,38,41
      ConstantsButtonsColor=35,38,41
      ConstantsFontsColor=252,252,252
      ForeColor=255,255,255
      FunctionButtonsColor=35,38,41
      FunctionFontsColor=252,252,252
      HexButtonsColor=35,38,41
      HexFontsColor=252,252,252
      MemoryButtonsColor=35,38,41
      MemoryFontsColor=252,252,252
      NumberButtonsColor=35,38,41
      NumberFontsColor=252,252,252
      OperationButtonsColor=35,38,41
      OperationFontsColor=252,252,252
      StatButtonsColor=35,38,41
      StatFontsColor=252,252,252

      [General]
      CalculatorMode=science
      ShowHistory=true
    '';
  };
}
