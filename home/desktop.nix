{ pkgs, inputs, hostParams, userParams, ... }:

let
  bcompare-beta = pkgs.libsForQt5.callPackage ../pkgs/bcompare-beta {};
  defaultBrowserApp = "${hostParams.defaultBrowser}.desktop";
  kvantummanager = pkgs.writeShellScriptBin "kvantummanager" ''
    ${pkgs.kdePackages.qtstyleplugin-kvantum}/bin/kvantummanager $@
  '';
  kvantumpreview = pkgs.writeShellScriptBin "kvantumpreview" ''
    ${pkgs.kdePackages.qtstyleplugin-kvantum}/bin/kvantumpreview $@
  '';
in
{
  imports = [
    ../profiles/vdhcoapp.nix
    ../profiles/vlc-wayland.nix
  ];

  environment.systemPackages = with pkgs; [
    ##  mkWindowsApp apps together conflict in home-manager, so install globally
    # inputs.remarkable.packages."${system}".remarkable
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
  #       fcitx5-configtool
  #       fcitx5-chinese-addons
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

  home-manager.users.${userParams.username} = {
    imports = [
      # Terminals
      ./profiles/alacritty.nix
      ./profiles/bambu-studio.nix
      ./profiles/foot.nix
      ./profiles/ghostty.nix
      ./profiles/kitty.nix

      ./profiles/gthumb.nix
      ## Should be handled by wayland scaling now
      # ./profiles/firefox.nix

      ## Should be handled by wayland scaling now
      ## But left in for the theming
      ./profiles/qt4-hidpi.nix
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
        enabled = "fcitx5";
        fcitx5.addons = with pkgs; [
          fcitx5-configtool
          fcitx5-chinese-addons
          fcitx5-gtk
          fcitx5-nord
          fcitx5-rime
          libsForQt5.fcitx5-qt
          plasma5Packages.fcitx5-qt
          rime-data
        ];
      };
    };

    ## Screen scaling doesn't seem to make it into the systemd service,
    ## so set it explicitly
    systemd.user.services.fcitx5-daemon = {
      Service = {
        Environment = [
          "QT_SCALE_FACTOR=2"
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
        "image/png" =  [ "vimiv.desktop" ];
        "image/jpg" =  [ "vimiv.desktop" ];
        "image/jpeg" = [ "vimiv.desktop" ];
        "image/tiff" = [ "vimiv.desktop" ];
        "image/webp" = [ "vimiv.desktop" ];
        "image/gif" =  [ "vimiv.desktop" ];
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
        "image/png" =  [ "vimiv.desktop" ];
        "image/jpg" =  [ "vimiv.desktop" ];
        "image/jpeg" = [ "vimiv.desktop" ];
        "image/tiff" = [ "vimiv.desktop" ];
        "image/webp" = [ "vimiv.desktop" ];
        "image/gif" =  [ "vimiv.desktop" ];
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
      MANPAGER = "vim -c ASMANPAGER -";

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
      # GDK_DPI_SCALE = if hostParams.hostName == "upaya" then "1.75" else "1";
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
      extraOutputsToInstall = [ "man" ]; # Additionally installs the manpages for each pkg

      packages = with pkgs; [
        ## system
        arandr
        lsix
        gucharmap
        solaar            # for logitech unifying receiver setup
        xorg.xdpyinfo
        xorg.xhost
        grim              # Arbitrary capture of portion of screen
        slurp             # Allows user to select portion of screen
        xsel              # Manipulate xwindows clipboard
        wl-clipboard      # Manipulate wayland clipboard
        ## Currently broken
        # wf-recorder       # Record video of screen portions in wayland
        veracrypt
        wezterm

        # kvantummanager
        # kvantumpreview

        ## disk space
        baobab
        qdirstat
        kdePackages.filelight

        ## audio
        easyeffects

        # Browsers
        firefox-wayland
        # librewolf-wayland

        ## apps
        audacity
        unstable.bitwarden
        brave
        czkawka
        unstable.digikam
        discord
        element-desktop
        evolutionWithPlugins
        feh
        gimp-with-plugins
        # pr67576-gimp-wayland.gimp-with-plugins
        # pr67576-gimp-wayland.gimp
        glava
        endeavour       # replaces gnome.gnome-todo
        gnome-calculator
        inkscape
        joplin-desktop
        kdePackages.kcalc
        # Not yet available in stable
        unstable.kphotoalbum
        krita
        libreoffice
        mpv
        unstable.rpi-imager
        shotwell
        signal-desktop
        slack
        spotify
        sxiv # image viewer with vim bindings
        stellarium
        telegram-desktop
        vimiv-qt
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
        wf-recorder

        ## desktop

        ## file managers
        # dolphin          # Doesn't render very well
        nautilus
        krusader
        xfce.thunar
        nemo

        # unstable.ardour
        flavours
        adwaita-icon-theme
        eog # image viewer
        evince # PDF viewer
        # @TODO: figure out a way to overlay instead of replacing the package
        # This will get out of date
        sweethome3d.application
        xfce.xfconf # Needed to save the preferences
        xfce.exo # Used by default for `open terminal here`, but can be changed
        # qt5
        # qt6
        libsForQt5.qtstyleplugins
        playerctl
        teams-for-linux

        # Visualization
        cava
        ## Currently broken
        # mandelbulber
        qosmic
        xaos

        # Pipewire connection tool
        qpwgraph
        helvum            # this one is better
        unstable.coppwr   # not yet in stable

        ## Wine
        ## wine-staging (version with experimental features)
        ## winetricks and other programs depending on wine need to use the same wine version
        bottles
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
        gerbv

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
      package = pkgs.vscodium.fhs;
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
    '';
  };
}
