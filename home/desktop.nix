{ pkgs, inputs, hostParams, userParams, ... }:

let
  defaultBrowserApp = "${hostParams.defaultBrowser}.desktop";
in
{
  imports = [
    ../profiles/vlc-wayland.nix
  ];

  environment.systemPackages = with pkgs; [
    ##  mkWindowsApp apps together conflict in home-manager, so install globally
    # inputs.remarkable.packages."${system}".remarkable
  ];

  environment.sessionVariables = {
    XCURSOR_SIZE = "64";
  };
  environment.variables = {
    XCURSOR_SIZE = "64";
  };

  # i18n.inputMethod.enabled = "ibus";
  # i18n.inputMethod.ibus.engines = with pkgs.ibus-engines; [ libpinyin ];
  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      # enabled = "ibus";
      # ibus = { engines = with pkgs.ibus-engines; [ libpinyin rime ]; };
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-configtool
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
  services.dbus = {
    enable = true;
  };

  home-manager.users.${userParams.username} = {
    imports = [
      # Terminals
      ./profiles/alacritty.nix
      ./profiles/foot.nix
      ./profiles/kitty.nix

      ./profiles/bambu-studio.nix
      ./profiles/element.nix
      ./profiles/gthumb.nix
      ./profiles/signal.nix
      ## Should be handled by wayland scaling now
      # ./profiles/firefox.nix

      ## Should be handled by wayland scaling now
      ## But left in for the theming
      ./profiles/qt4-hidpi.nix
    ];

    # ---------------------------------------------------------------------------
    # MIME apps
    # ---------------------------------------------------------------------------

    ## Desktop file locations:
    # system:           /run/current-system/sw/share/applications
    # home-manager:     /etc/profiles/per-user/erahhal/share/applications
    # manual overrides: ~/.local/share/applications
    # echo $XDG_DATA_DIRS to see full list

    xdg.enable = true;
    xdg.mimeApps = {
      enable = true;
      # Make sure VSCode doesn't take over file mimetype
      associations.added = {
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
      # GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      SDL_IM_MODULE = "fcitx";
      INPUT_METHOD = "fcitx";
      XIM_SERVERS = "fcitx";
      XIM = "fcitx";
      XIM_PROGRAM = "fcitx";

      GLFW_IM_MODULE = "ibus";

      # XMODIFIERS = "@im=ibus";
      # GTK_IM_MODULE = "ibus";
      # QT_IM_MODULE = "ibus";
      # SDL_IM_MODULE = "ibus";
      # INPUT_METHOD = "ibus";
      # XIM_SERVERS = "ibus";


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

      # ---------------------------------------------------------------------------
      # BELOW: Desktop Environment
      # @TODO: How to load them conditionally at
      #        runtime depending on selected DE?
      # ---------------------------------------------------------------------------

      # ---------------------------------------------------------------------------
      # DPI-related
      # ---------------------------------------------------------------------------
      GDK_SCALE = "1";
      # @TODO: HACK, why are the machines acting differently?
      # GDK_DPI_SCALE = if hostParams.hostName == "upaya" then "1.75" else "1";
      GDK_DPI_SCALE = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "0";
      QT_SCALE_FACTOR = "1.25";
      # QT_SCALE_FACTOR = "1";
      QT_FONT_DPI = "96";
      # QT_FONT_DPI = "80";

      # ---------------------------------------------------------------------------
      # Wayland-related
      # ---------------------------------------------------------------------------
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_USE_XINPUT2 = "1";
      WLR_DRM_NO_MODIFIERS = "1";
      ## Sway doesn't load with this
      # WLR_RENDERER = "vulkan";
      ## Steam doesn't work with this enabled
      # SDL_VIDEODRIVER = "wayland";

      ## using "wayland" makes menus disappear in kde apps
      ## UPDATE: Menus seem to work, but some buttons don't work unless the window is floated. (Seems to be fixed by setting QT_AUTO_SCREEN_SCALE_FACTOR=1? )
      ##         and borders between elements are sometimes transparent, showing the background.
      QT_QPA_PLATFORM = "wayland";
      # QT_QPA_PLATFORM = "xcb";

      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      XDG_SESSION_TYPE = "wayland";

      ## @TODO: This should def be loaded at runtime.
      #         This is cofigured in hyprland config.
      ## @TODO: Verify that it's overriden in hyprland.
      XDG_CURRENT_DESKTOP = "sway";

      # Used to inform discord and other apps that we are using wayland
      NIXOS_OZONE_WL = "1";
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
        solaar            # for logitech unifying receiver setup
        xorg.xdpyinfo
        dfeet             # Dbus viewer
        grim              # Arbitrary capture of portion of screen
        slurp             # Allows user to select portion of screen
        xsel              # Manipulate xwindows clipboard
        wl-clipboard      # Manipulate wayland clipboard
        wf-recorder       # Record video of screen portions in wayland

        ## disk space
        baobab
        qdirstat
        filelight

        ## apps
        audacity
        unstable.bitwarden
        brave
        czkawka
        unstable.digikam
        unstable.discord
        evolutionWithPlugins
        feh
        firefox
        # gimp-with-plugins
        # pr67576-gimp-wayland.gimp-with-plugins
        pr67576-gimp-wayland.gimp
        glava
        gnome.gnome-todo
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
        telegram-desktop
        waydroid
        whatsapp-for-linux
        xournalpp
        zoom-us

        ## Video recording

        ## BAD - Saved an almost empty file after recording
        # webcamoid
        ## BAD - Janky video, audio out of sync
        # gnome3.cheese
        ## BAD - audio not recorded with video
        # guvcview
        ## BEST - works great
        obs-studio

        ## desktop
        # unstable.ardour
        flavours
        gnome3.adwaita-icon-theme
        gnome3.eog # image viewer
        gnome3.evince # PDF viewer
        gnome3.nautilus
        # cinnamon.nemo
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
        bottles
        wineWowPackages.stagingFull
        winetricks
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

    ## @TODO: Setup conditional init.vim
    ## https://github.com/vscode-neovim/vscode-neovim
    programs.vscode = {
      enable = true;
      package = pkgs.unstable.vscodium;
      # package = pkgs.unstable.vscodium-fhs;
      extensions = with pkgs.vscode-extensions; [
        # dracula-theme.theme-dracula
        # emroussel.atomize-atom-one-dark-theme
        # enkia.tokyo-night
        # equinusocio.vsc-material-theme
        # mskelton.one-dark-theme
        # viktorqvarfordt.vscode-pitch-black-theme
        dhedgecock.radical-vscode
        # vscodevim.vim
        asvetliakov.vscode-neovim
        yzhang.markdown-all-in-one
      ];
      userSettings = {
        "extensions.experimental.affinity" = {
          "asvetliakov.vscode-neovim" = 1;
        };
        "workbench.colorTheme" = "Radical";
        "editor.renderWhitespace" = "trailing";
      };
    };

    programs.mpv = {
      enable = true;
    };

    xdg.configFile."mpv/mpv.conf".text = ''
      no-border
      fullscreen=yes
      stop-screensaver=yes
      hwdec=auto
      ## Set this in case nvidia opengl is broken
      hwdec=vaapi
      ytdl-format=bestvideo+bestaudio
      gpu-context=wayland

      ## From nixos wiki:
      # hwdec=auto-safe
      vo=gpu
      profile=gpu-hq
    '';

    xdg.configFile."mpv/input.conf".text = ''
      k seek 60
      j seek -60
      h seek -10
      l seek 10
    '';
  };
}
