{ broken, config, pkgs, userParams, ... }:

let
  bcompare-beta = pkgs.libsForQt5.callPackage ../pkgs/bcompare-beta {};
  defaultBrowserApp = "${config.hostParams.programs.defaultBrowser}.desktop";
  kvantummanager = pkgs.writeShellScriptBin "kvantummanager" ''
    ${pkgs.kdePackages.qtstyleplugin-kvantum}/bin/kvantummanager $@
  '';
  kvantumpreview = pkgs.writeShellScriptBin "kvantumpreview" ''
    ${pkgs.kdePackages.qtstyleplugin-kvantum}/bin/kvantumpreview $@
  '';
in
{
  imports = [
    # ../profiles/vdhcoapp.nix
    ../profiles/vlc-wayland.nix
    # ../profiles/ubports-installer-appimage.nix
    # ../overlays/zoom-us.nix
    ../overlays/igv-scaled.nix
    # ../overlays/firefox-nvidia.nix
    ../overlays/blender-with-nvidia-offload.nix
    ../profiles/bambu-studio-appimage.nix
  ];

  environment.sessionVariables = {
    # ---------------------------------------------------------------------------
    # IME
    # ---------------------------------------------------------------------------
    # XMODIFIERS = "@im=ibus";
    # GTK_IM_MODULE = "ibus";
    # QT_IM_MODULE = "ibus";
    # SDL_IM_MODULE = "ibus";
    # INPUT_METHOD = "ibus";
    # XIM_SERVERS = "ibus";
    # GLFW_IM_MODULE = "ibus";

    GLFW_IM_MODULE = "fcitx";
    ## This interferes with wayland input, and should be set per-app
    # GTK_IM_MODULE = "fcitx";
    INPUT_METHOD = "fcitx";
    XMODIFIERS = "@im=fcitx";
    IMSETTINGS_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    SDL_IM_MODULE = "fcitx";
    XIM_SERVERS = "fcitx";
    XIM = "fcitx";
    XIM_PROGRAM = "fcitx";
  };

  ### DON'T USE THIS - USE HOME MANAGER CONFIG INSTEAD
  # # i18n.inputMethod.enabled = "ibus";
  # # i18n.inputMethod.ibus.engines = with pkgs.ibus-engines; [ libpinyin ];
  # i18n = {
  #   defaultLocale = "en_US.UTF-8";
  #   inputMethod = {
  #     # enabled = "ibus";
  #     # ibus = { engines = with pkgs.ibus-engines; [ libpinyin rime ]; };
  #     enabled = "fcitx5";
  #     fcitx5.addons = with pkgs; [
  #       qt6Packages.fcitx5-configtool
  #       qt6Packages.fcitx5-chinese-addons
  #       fcitx5-gtk
  #       fcitx5-nord
  #       fcitx5-rime
  #       libsForQt5.fcitx5-qt
  #       plasma5Packages.fcitx5-qt
  #       rime-data
  #     ];
  #   };
  # };

  # For xdg-desktop-portal-wlr
  # GTK apps will hang for 30 seconds at start of sway and render strangely without this
  services.dbus = {
    enable = true;
  };

  services.gnome.gnome-keyring.enable = true;

  home-manager.users.${userParams.username} = { osConfig, ... }: {
    imports = [
      # Terminals
      ./profiles/alacritty.nix
      ./profiles/audio-visualizers.nix
      ./profiles/foot.nix
      ./profiles/ghostty.nix
      ./profiles/kitty.nix

      ./profiles/gthumb.nix

      ## Should be handled by wayland scaling now
      ## But left in for the theming
      ./profiles/qt4-hidpi.nix

      # VSCode Roo MCP configuration
      ./profiles/vscode-settings.nix

      # Startup applications service
      ./modules/startup-apps.nix

      # KDE Connect
      ./profiles/kdeconnect.nix
    ];

    ## Until Hyprland bug https://github.com/hyprwm/Hyprland/issues/5815 is resolved
    ## Go to Fctix Configure --> Addons --> Wayland Input method front end --> disable "Forward key event..."

    ## Fcitx in Home Manager works properly, as it's run as a systemd service
    ## which seems to import all the proper input methods
    ## and doesn't need to be launched in the WM (e.g. Hyprland) config
    i18n = {
      # defaultLocale = "en_US.UTF-8";
      inputMethod = {
        # enabled = "ibus";
        # ibus = { engines = with pkgs.ibus-engines; [ libpinyin rime ]; };
        type = "fcitx5";
        enable = true;
        fcitx5.addons = with pkgs; [
          qt6Packages.fcitx5-configtool
          qt6Packages.fcitx5-chinese-addons
          fcitx5-gtk
          fcitx5-nord
          fcitx5-rime
          libsForQt5.fcitx5-qt
          plasma5Packages.fcitx5-qt
          rime-data
        ];
      };
    };

    gtk = {
      gtk2.extraConfig = ''
        gtk-im-module="fcitx"
      '';
      gtk3.extraConfig = {
        gtk-im-module = "fcitx";
      };
      gtk4.extraConfig = {
        gtk-im-module = "fcitx";
      };
    };

    ## Screen scaling doesn't seem to make it into the systemd service,
    ## so set it explicitly
    systemd.user.services.fcitx5-daemon = {
      Service = {
        PassEnvironment = [
          "HOME"
          "XDG_DATA_HOME"
          "XDG_CONFIG_HOME"
          "XDG_CACHE_HOME"
          "XDG_RUNTIME_DIR"
          "DISPLAY"  # If needed for GUI applications
          "WAYLAND_DISPLAY"  # If using Wayland
        ];
        # You can also set them explicitly if needed
        Environment = [
          "HOME=%h"  # %h is a special variable that expands to the user's home directory
          "QT_SCALE_FACTOR=1.5"
        ];
      };
    };

    # ---------------------------------------------------------------------------
    # MIME apps
    # ---------------------------------------------------------------------------

    ## Desktop file locations:
    # system:           /run/current-system/sw/share/applications
    # home-manager:     /etc/profiles/per-user/erahhal/share/applications
    # manual overrides: ~/.local/share/applications
    # Flatpack: /var/lib/flatpak/exports/share/applications
    # Flatpack local: ~/.local/share/flatpak/exports/share/applications
    # Nix profile: ~/.nix-profile/share/applications
    # Nix profile: /nix/profile/share/applications
    # Local state: ~/.local/state/nix/profile/share/applications

    # echo $XDG_DATA_DIRS to see full list

    xdg.enable = true;
    xdg.mimeApps =
      let mimeTypes = {
        "inode/directory"                                                               = [ "org.gnome.Nautilus.desktop" ];

        "x-scheme-handler/http"                                                         = [ defaultBrowserApp ];
        "x-scheme-handler/https"                                                        = [ defaultBrowserApp ];
        "x-scheme-handler/about"                                                        = [ defaultBrowserApp ];
        "x-scheme-handler/unknown"                                                      = [ defaultBrowserApp ];
        "x-scheme-handler/chrome"                                                       = [ defaultBrowserApp ];
        "text/html"                                                                     = [ defaultBrowserApp ];
        "application/x-extension-htm"                                                   = [ defaultBrowserApp ];
        "application/x-extension-html"                                                  = [ defaultBrowserApp ];
        "application/x-extension-shtml"                                                 = [ defaultBrowserApp ];
        "application/xhtml+xml"                                                         = [ defaultBrowserApp ];
        "application/x-extension-xhtml"                                                 = [ defaultBrowserApp ];
        "application/x-extension-xht"                                                   = [ defaultBrowserApp ];
        "application/x-www-browser"                                                     = [ defaultBrowserApp ];
        "application/pdf"                                                               = [ defaultBrowserApp ];
        "x-www-browser"                                                                 = [ defaultBrowserApp ];
        "x-scheme-handler/webcal"                                                       = [ defaultBrowserApp ];

        "image/png"                                                                     = [ "vimiv.desktop" ];
        "image/jpg"                                                                     = [ "vimiv.desktop" ];
        "image/jpeg"                                                                    = [ "vimiv.desktop" ];
        "image/tiff"                                                                    = [ "vimiv.desktop" ];
        "image/webp"                                                                    = [ "vimiv.desktop" ];
        "image/gif"                                                                     = [ "vimiv.desktop" ];

        "video/x-flv"                                                                   = [ "mpv.desktop" ];
        "video/mp4"                                                                     = [ "mpv.desktop" ];
        "application/x-mpegURL"                                                         = [ "mpv.desktop" ];
        "video/MP2T"                                                                    = [ "mpv.desktop" ];
        "video/3gpp"                                                                    = [ "mpv.desktop" ];
        "video/quicktime"                                                               = [ "mpv.desktop" ];
        "video/webm"                                                                    = [ "mpv.desktop" ];
        "video/x-msvideo"                                                               = [ "mpv.desktop" ];
        "video/x-ms-wmv"                                                                = [ "mpv.desktop" ];

        "audio/flac"                                                                    = [ "vlc.desktop" ];
        "audio/mpeg"                                                                    = [ "vlc.desktop" ];
        "audio/mp3"                                                                     = [ "vlc.desktop" ];
        "audio/x-wav"                                                                   = [ "vlc.desktop" ];
        "audio/wav"                                                                     = [ "vlc.desktop" ];
        "audio/ogg"                                                                     = [ "vlc.desktop" ];
        "audio/x-vorbis+ogg"                                                            = [ "vlc.desktop" ];
        "audio/aac"                                                                     = [ "vlc.desktop" ];
        "audio/x-aac"                                                                   = [ "vlc.desktop" ];
        "audio/mp4"                                                                     = [ "vlc.desktop" ];
        "audio/x-m4a"                                                                   = [ "vlc.desktop" ];
        "audio/x-ms-wma"                                                                = [ "vlc.desktop" ];
        "audio/x-mpegurl"                                                               = [ "vlc.desktop" ];
        "audio/mpegurl"                                                                 = [ "vlc.desktop" ];
        "application/x-cue"                                                             = [ "vlc.desktop" ];

        "application/x-bittorrent"                                                      = [ "transmission-gtk.desktop" ];
        "x-scheme-handler/magnet"                                                       = [ "transmission-gtk.desktop" ];

        "x-scheme-handler/kdeconnect"                                                   = [ "org.kde.dolphin.desktop" ];

        # Zoom URL schemes
        "x-scheme-handler/zoommtg"                                                        = [ "Zoom.desktop" ];
        "x-scheme-handler/zoomus"                                                         = [ "Zoom.desktop" ];
        "x-scheme-handler/zoomphonecall"                                                  = [ "Zoom.desktop" ];
        "application/x-zoom"                                                              = [ "Zoom.desktop" ];

        "application/msword"                                                            = [ "writer.desktop" ];
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"       = [ "writer.desktop" ];
        "application/vnd.openxmlformats-officedocument.wordprocessingml.template"       = [ "writer.desktop" ];
        "application/vnd.ms-word.document.macroEnabled.12"                              = [ "writer.desktop" ];
        "application/vnd.ms-word.template.macroEnabled.12"                              = [ "writer.desktop" ];

        "application/vnd.ms-excel"                                                      = [ "calc.desktop" ];
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"             = [ "calc.desktop" ];
        "application/vnd.openxmlformats-officedocument.spreadsheetml.template"          = [ "calc.desktop" ];
        "application/vnd.ms-excel.sheet.macroEnabled.12"                                = [ "calc.desktop" ];
        "application/vnd.ms-excel.template.macroEnabled.12"                             = [ "calc.desktop" ];
        "application/vnd.ms-excel.addin.macroEnabled.12"                                = [ "calc.desktop" ];
        "application/vnd.ms-excel.sheet.binary.macroEnabled.12"                         = [ "calc.desktop" ];

        "application/vnd.ms-powerpoint"                                                 = [ "impress.desktop" ];
        "application/vnd.openxmlformats-officedocument.presentationml.presentation"     = [ "impress.desktop" ];
        "application/vnd.openxmlformats-officedocument.presentationml.template"         = [ "impress.desktop" ];
        "application/vnd.openxmlformats-officedocument.presentationml.slideshow"        = [ "impress.desktop" ];
        "application/vnd.ms-powerpoint.addin.macroEnabled.12"                           = [ "impress.desktop" ];
        "application/vnd.ms-powerpoint.presentation.macroEnabled.12"                    = [ "impress.desktop" ];
        "application/vnd.ms-powerpoint.template.macroEnabled.12"                        = [ "impress.desktop" ];
        "application/vnd.ms-powerpoint.slideshow.macroEnabled.12"                       = [ "impress.desktop" ];

        "application/vnd.ms-access"                                                     = [ "base.desktop" ];
      };
    in
    {
      enable = true;
      # Make sure VSCode doesn't take over file mimetype
      associations.added = mimeTypes;
      defaultApplications = mimeTypes;
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

    # xdg.dataFile."applications/mimeinfo.cache".text = ''
    #   [MIME Cache]
    #   application/rdf+xml=${defaultBrowserApp};
    #   application/rss+xml=${defaultBrowserApp};
    #   application/xhtml+xml=${defaultBrowserApp};
    #   application/xhtml_xml=${defaultBrowserApp};
    #   application/xml=${defaultBrowserApp};
    #   text/html=${defaultBrowserApp};
    #   text/xml=${defaultBrowserApp};
    # '';

    # ---------------------------------------------------------------------------
    # Display, Theme, DPI, Cursor Size settings
    # ---------------------------------------------------------------------------

    home.sessionVariables = {

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
      # MANPAGER = "vim -c ASMANPAGER -";

      # ---------------------------------------------------------------------------
      # BELOW: Desktop Environment
      # @TODO: How to load them conditionally at
      #        runtime depending on selected DE?
      # ---------------------------------------------------------------------------

      # ---------------------------------------------------------------------------
      # DPI-related
      # ---------------------------------------------------------------------------
      # GDK_SCALE = "1";
      # @TODO: HACK, why are the machines acting differently?
      # GDK_DPI_SCALE = if osConfig.hostParams.system.hostName == "upaya" then "1.75" else "1";
      # GDK_DPI_SCALE = "1";
      # QT_AUTO_SCREEN_SCALE_FACTOR = "0";
      ## Fractional QT_SCALE_FACTOR results in rendering artifacts, e.g. transparent lines
      # QT_SCALE_FACTOR = "1.25";
      # QT_FONT_DPI = "96";
    };

    # ---------------------------------------------------------------------------
    # Audio
    # ---------------------------------------------------------------------------

    ## Enable easyeffects service, which can add a Dolby Atmos filter
    ## Dolby Atmos is proprietary and typically only available for Windows
    ## https://forum.manjaro.org/t/how-can-i-make-easyeffects-run-on-startup-background/99041/3
    ## https://www.reddit.com/r/linuxquestions/comments/pfl0g7/dolby_atmos_support_in_linux/
    ## https://raw.githubusercontent.com/JackHack96/PulseEffects-Presets/master/install.sh
    ## https://github.com/shuhaowu/linux-thinkpad-speaker-improvements
    ### Install effects:
    ## bash -c "$(curl -fsSL https://raw.githubusercontent.com/JackHack96/PulseEffects-Presets/master/install.sh)"

    # systemd.user.services.easyeffects = {
    #   Unit = {
    #     Description = "Audio Filter";
    #     After = [ "multi-user.target" ];
    #   };
    #   Service = {
    #     Restart = "always";
    #     ExecStart = "${pkgs.easyeffects}/bin/easyeffects --gapplication-service";
    #   };
    #
    #   Install = {
    #     WantedBy = [ "default.target" ];
    #   };
    # };

    # ---------------------------------------------------------------------------
    # Selected packages for all hosts
    # ---------------------------------------------------------------------------

    home = {
      ## @TODO: Is this still necessary?
      extraOutputsToInstall = [ "man" ]; # Additionally installs the manpages for each pkg

      packages = with pkgs; [
        ## system
        arandr
        lsix
        grim              # Arbitrary capture of portion of screen
        gucharmap
        slurp             # Allows user to select portion of screen
        solaar            # for logitech unifying receiver setup
        # ubports-installer
        veracrypt
        wezterm
        wl-clipboard      # Manipulate wayland clipboard
        wf-recorder       # Record video of screen portions in wayland
        xorg.xdpyinfo
        xorg.xeyes
        xorg.xhost
        xsel              # Manipulate xwindows clipboard

        ## Cross-system desktop KVM
        deskflow
        # lan-mouse - provided by flake module in user.nix

        # kvantummanager
        # kvantumpreview

        ## disk space
        baobab
        qdirstat
        kdePackages.filelight

        ## audio
        easyeffects

        # Browsers
        firefox
        # librewolf-wayland

        ## apps
        audacity
        bambu-studio
        bitwarden-desktop
        brave
        calibre
        czkawka
        # digikam
        discord
        element-desktop
        evolutionWithPlugins
        feh
        freecad
        git-sync
        gimp3-with-plugins
        # pr67576-gimp-wayland.gimp-with-plugins
        # pr67576-gimp-wayland.gimp
        glava
        endeavour       # replaces gnome.gnome-todo
        gnome-calculator
        igv # Integrative Genomics Viewer
        inkscape
        joplin-desktop
        # Not yet available in stable
        unstable.kphotoalbum
        krita
        libreoffice
        logseq
        mpv
        rpi-imager
        shotwell
        signal-desktop-bin
        slack
        spotify
        subsurface
        sxiv # image viewer with vim bindings
        stellarium
        telegram-desktop
        vesktop
        vimiv-qt
        waydroid
        wasistlos
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
        wf-recorder

        ## Video editing

        kdePackages.kdenlive
        shotcut

        ## desktop

        ## file managers
        # dolphin          # Doesn't render very well
        nautilus
        krusader
        thunar
        nemo

        # unstable.ardour
        flavours
        adwaita-icon-theme
        eog # image viewer
        evince # PDF viewer
        openscad
        # @TODO: figure out a way to overlay instead of replacing the package
        # This will get out of date
        sweethome3d.application
        xfconf # Needed to save the preferences
        xfce4-exo # Used by default for `open terminal here`, but can be changed
        # qt5
        # qt6
        libsForQt5.qtstyleplugins
        playerctl
        teams-for-linux

        # Visualization
        cava
        mandelbulber
        qosmic
        xaos

        # Pipewire connection tool
        qpwgraph
        helvum            # this one is better
        unstable.coppwr   # not yet in stable

        ## Wine
        ## wine-staging (version with experimental features)
        ## winetricks and other programs depending on wine need to use the same wine version
        bottles # Has issues with i686 dependencies (mangohud)
        wineWowPackages.stagingFull
        winetricks
        # wineWowPackages.stable
        # winetricks
        # wineWowPackages.waylandFull

        # Dev
        kdiff3
        krename
        meld
        p4v
        sqlitebrowser

        # Hardware Dev
        (broken gerbv)

        ## unfree
        bcompare
        # bcompare-beta
        # nixpkgs-windsurf.windsurf
        windsurf
        code-cursor
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
      # package = pkgs.unstable.vscodium;
      ## fhs package allows for arbitrary extension installation
      # package = pkgs.vscodium.fhs;
      package = pkgs.vscode.fhs;
      # package = pkgs.unstable.vscodium-fhs;
      # extensions = with pkgs.vscode-extensions; [
      #   # dracula-theme.theme-dracula
      #   # emroussel.atomize-atom-one-dark-theme
      #   # enkia.tokyo-night
      #   # equinusocio.vsc-material-theme
      #   # mskelton.one-dark-theme
      #   # viktorqvarfordt.vscode-pitch-black-theme
      #   dhedgecock.radical-vscode
      #   # vscodevim.vim
      #   asvetliakov.vscode-neovim
      #   yzhang.markdown-all-in-one
      # ];
      # userSettings = {
      #   "extensions.experimental.affinity" = {
      #     "asvetliakov.vscode-neovim" = 1;
      #   };
      #   "workbench.colorTheme" = "Radical";
      #   "editor.renderWhitespace" = "trailing";
      # };
    };

    programs.mpv = {
      enable = true;
    };

    xdg.configFile."mpv/mpv.conf".text = ''
      no-border
      fullscreen=yes
      stop-screensaver=yes

      ytdl-format=bestvideo+bestaudio


      ## From nixos wiki:
      hwdec=auto
      # hwdec=auto-safe
      # hwdec=vaapi   # Set this in case nvidia opengl is broken
      vo=gpu
      opengl-es=yes
      profile=gpu-hq
      gpu-context=wayland

      ## GPU Accelerated Vulkan
      # vo=gpu-next
      # gpu-api=vulkan
      # hwdec=vulkan
      # gpu-context=waylandvk

      ## Key bindings

      # Rotate video
      r cycle_values video-rotate 90 180 270 0
    '';

    xdg.configFile."mpv/input.conf".text = ''
      k seek 60
      j seek -60
      h seek -10
      l seek 10
      s cycle sub
    '';

    xdg.configFile."vimiv/vimiv.conf".text = ''
      [GENERAL]
      start_fullscreen = True
      monitor_filesystem = True
      startup_library = True
      style = default
      read_only = False

      [COMMAND]
      history_limit = 100

      [COMPLETION]
      fuzzy = False

      [SEARCH]
      ignore_case = True
      incremental = True

      [IMAGE]
      autoplay = True
      autowrite = ask
      overzoom = 1.0
      zoom_wheel_ctrl = True

      [LIBRARY]
      width = 0.3
      show_hidden = False

      [THUMBNAIL]
      size = 128
      save = True

      [SLIDESHOW]
      delay = 2.0
      indicator = slideshow:

      [STATUSBAR]
      collapse_home = True
      show = True
      message_timeout = 60000
      mark_indicator = <b>*</b>
      left = {pwd}{read-only}
      left_image = {index}/{total} {basename}{read-only} [{zoomlevel}]
      left_thumbnail = {thumbnail-index}/{thumbnail-total} {thumbnail-basename}{read-only}
      left_manipulate = {basename}   {image-size}   Modified: {modified}   {processing}
      center_thumbnail = {thumbnail-size}
      center = {slideshow-indicator} {slideshow-delay} {transformation-info}
      right = {keys}  {mark-count}  {mode}
      right_image = {keys}  {mark-indicator} {mark-count}  {mode}

      [KEYHINT]
      delay = 500
      timeout = 5000

      [TITLE]
      fallback = vimiv
      image = vimiv - {basename}

      [METADATA]
      keys1 = Exif.Image.Make,Exif.Image.Model,Exif.Photo.LensModel,Exif.Image.DateTime,Exif.Image.Artist,Exif.Image.Copyright
      keys2 = Exif.Photo.ExposureTime,Exif.Photo.FNumber,Exif.Photo.ISOSpeedRatings,Exif.Photo.ApertureValue,Exif.Photo.ExposureBiasValue,Exif.Photo.FocalLength,Exif.Photo.ExposureProgram
      keys3 = Exif.GPSInfo.GPSLatitudeRef,Exif.GPSInfo.GPSLatitude,Exif.GPSInfo.GPSLongitudeRef,Exif.GPSInfo.GPSLongitude,Exif.GPSInfo.GPSAltitudeRef,Exif.GPSInfo.GPSAltitude
      keys4 = Iptc.Application2.Caption,Iptc.Application2.Keywords,Iptc.Application2.City,Iptc.Application2.SubLocation,Iptc.Application2.ProvinceState,Iptc.Application2.CountryName,Iptc.Application2.Source,Iptc.Application2.Credit,Iptc.Application2.Copyright,Iptc.Application2.Contact
      keys5 = Exif.Image.ImageWidth,Exif.Image.ImageLength,Exif.Photo.PixelXDimension,Exif.Photo.PixelYDimension,Exif.Image.BitsPerSample,Exif.Image.Compression,Exif.Photo.ColorSpace

      [SORT]
      image_order = alphabetical
      directory_order = alphabetical
      reverse = False
      ignore_case = False
      shuffle = False

      [PLUGINS]
      print = default
      metadata = default

      [ALIASES]
    '';

    xdg.configFile."vimiv/keys.conf".text = ''
      [GLOBAL]
      <colon> : command
      o : command --text='open '
      yi : copy-image
      yI : copy-image --primary
      yy : copy-name
      ya : copy-name --abspath
      yA : copy-name --abspath --primary
      yY : copy-name --primary
      x : delete %%
      gi : enter image
      gl : enter library
      gm : enter manipulate
      gt : enter thumbnail
      f : fullscreen
      G : goto -1
      gg : goto 1
      m : mark %%
      q : quit
      [ : quit
      . : repeat-command
      J : scroll down
      H : scroll left
      L : scroll right
      K : scroll up
      / : search
      ? : search --reverse
      N : search-next
      P : search-prev
      zh : set library.show_hidden!
      b : set statusbar.show!
      tl : toggle library
      tm : toggle manipulate
      tt : toggle thumbnail

      [IMAGE]
      M : center
      <button-right> : enter library
      <button-middle> : enter thumbnail
      | : flip
      _ : flip --vertical
      <end> : goto -1
      <home> : goto 1
      <button-forward> : next
      <page-down> : next
      j : next
      <ctrl>j : next --keep-zoom
      <space> : play-or-pause
      <button-back> : prev
      <page-up> : prev
      k : prev
      <ctrl>k : prev --keep-zoom
      > : rotate
      < : rotate --counter-clockwise
      W : scale --level=1
      <equal> : scale --level=fit
      w : scale --level=fit
      E : scale --level=fit-height
      e : scale --level=fit-width
      # H : scroll-edge left
      # J : scroll-edge down
      # K : scroll-edge up
      # L : scroll-edge right
      n : scroll left
      m : scroll down
      , : scroll up
      . : scroll right
      sl : set slideshow.delay +0.5
      sh : set slideshow.delay -0.5
      ss : slideshow
      + : zoom in
      l : zoom in
      - : zoom out
      h : zoom out

      [LIBRARY]
      <button-middle> : enter thumbnail
      go : goto 1 --open-selected
      <button-forward> : scroll down --open-selected
      n : scroll down --open-selected
      <ctrl>d : scroll half-page-down
      <ctrl>u : scroll half-page-up
      <button-right> : scroll left
      <ctrl>f : scroll page-down
      <ctrl>b : scroll page-up
      <button-back> : scroll up --open-selected
      p : scroll up --open-selected
      L : set library.width +0.05
      H : set library.width -0.05

      [THUMBNAIL]
      $ : end-of-line
      <button-right> : enter library
      ^ : first-of-line
      <ctrl>d : scroll half-page-down
      <ctrl>u : scroll half-page-up
      <button-back> : scroll left
      <ctrl>f : scroll page-down
      <ctrl>b : scroll page-up
      <button-forward> : scroll right
      + : zoom in
      - : zoom out

      [COMMAND]
      <tab> : complete
      <shift><tab> : complete --inverse
      <ctrl>p : history next
      <ctrl>n : history prev
      <up> : history-substr-search next
      <down> : history-substr-search prev
      <escape> : leave-commandline

      [MANIPULATE]
      <colon> : command
      f : fullscreen
      b : set statusbar.show!
    '';
  };
}
