{ pkgs, inputs, userParams, ... }:

let
  env_vars = {
    EDITOR = "vim";
    # PATH = "$HOME/Scripts:$HOME/.yarn/bin:$HOME/.local/bin:$PATH";
    PATH = "$HOME/Scripts:$HOME/.local/bin:$PATH:/snap/bin:$HOME/.local/share/JetBrains/Toolbox/scripts";
    # NODE_PATH = "$HOME/.local/share/yarn/global/node_modules";
    SSH_ASKPASS = "";
  };
  ia = pkgs.callPackage ../pkgs/ia {};
in
{
  users.users."${userParams.username}" = {
    isNormalUser = true;
    description = userParams.fullName;
    extraGroups = [
      "dialout" # needed for usb console cable to switch
      "docker"
      "input"
      "lp"
      "nac"
      "networkmanager"
      "podman"
      "scanner"
      "sudo"
      "video"
      "wheel"
    ];
    uid = userParams.uid;
    shell = if userParams.shell == "zsh" then pkgs.zsh else pkgs.bash;
  };

  imports = [
    ../overlays/ranger-image-preview.nix
    ../overlays/weechat.nix
  ];

  nixpkgs.config.permittedInsecurePackages = [
    # "electron-25.9.0"
    # "python3.9-mistune-0.8.4"
    # "polymc-1.4.2"
  ];

  home-manager.users.${userParams.username} = {config, ...}: {
    _module.args.inputs = inputs;

    imports = [
      inputs.nix-colors.homeManagerModules.default
      ./profiles/system-theme.nix
      ./profiles/btop.nix
      # ./profiles/captive-browser.nix
      # ./profiles/node-modules.nix
      ./profiles/nvim.nix
      # ./profiles/syncthing.nix
      ./profiles/vifm.nix
      # ./profiles/weechat.nix
      ./profiles/zellij.nix
    ];

    # ---------------------------------------------------------------------------
    # Nix-specific
    # ---------------------------------------------------------------------------

    programs.home-manager.enable = true;
    programs.direnv = {
      enable = true;
      enableBashIntegration = true; # see note on other shells below
      nix-direnv.enable = true;
    };

    # ---------------------------------------------------------------------------
    # General
    # ---------------------------------------------------------------------------

    xdg.enable = true;

    home.username = userParams.username;
    home.homeDirectory = "/home/${userParams.username}";
    home.file."Scripts".source = ../scripts;

    home.sessionVariables = env_vars;
    programs.bash.sessionVariables = env_vars;
    programs.zsh.sessionVariables = env_vars;
    systemd.user.sessionVariables = env_vars;

    home.file.".yarnrc.yml".text = ''
      # Matches default location
      cacheFolder: "./.yarn/cache"
    '';

    # Some apps require ~/.local/bin to exist
    home.file.".local/bin/.keep".text = "";

    # ---------------------------------------------------------------------------
    # Selected packages for all hosts
    # ---------------------------------------------------------------------------

    home = {
      extraOutputsToInstall = [ "man" ]; # Additionally installs the manpages for each pkg

      packages = with pkgs; [
        ## system
        brightnessctl
        dconf
        docker-compose
        man-pages
        samba # to get rid of wine ntml_auth errors
        speedtest-cli
        stress
        stress-ng
        wlsunset

        ## terminal tools
        bintools-unwrapped
        cryptsetup
        ia
        jq
        killall
        lsd
        ncdu
        pdftk # for removing password from PDFs
        ripgrep
        silver-searcher
        unzip

        ## needed by zsh plugins
        acpi
        autojump
        fortune
        fzf
        ripgrep
        thefuck
        wol

        ## terminal apps
        joplin
        pandoc
        ranger
        # unstable.youtube-dl
        unstable.yt-dlp
        weechat

        ## dev
        devbox
        difftastic
        git-secrets
        go
        cargo
        cmake
        deno
        maven
        nodejs
        tokei
        yarn

        ## python
        pyright
        s-tui
        (python3.withPackages(python-packages: with python-packages; [
          docker
          docker-compose
          lxml
          pandas
          pip
          pyyaml
          requests
          virtualenv
        ]))

        ## Unfree apps
        obsidian
      ];
    };

    # ---------------------------------------------------------------------------
    # Program configuration
    # ---------------------------------------------------------------------------

    programs.bash = {
      enable = true;
      bashrcExtra = ''
        TERM=xterm-256color
      '';
      # initExtra = builtins.readFile ../dotfiles/bashrc;
      # bashrcExtra = ''
      #   export EDITOR=vim
      #
      #   mach-shell() {
      #     pypiApps=$(for arg; do printf '.%s' "$arg"; done)
      #     nix shell github:davhau/mach-nix#gen.pythonWith$pypiApps
      #   }
      #
      #   # Prints a list of webm urls for a given 4chan thread link
      #   getwebm() {
      #     ${pkgs.curl}/bin/curl -sL "$1.json" | ${pkgs.jq}/bin/jq -r '.posts[] | select(.ext == ".webm") | "https://i.4cdn.org/'"$(echo "$1" | sed -r 's/.*(4chan|4channel).org\/([a-zA-Z0-9]+)\/.*/\2/')"'/\(.tim)\(.ext)"';
      #   }
      #
      #   # Makes `nix inate` as an alias of `nix shell`.
      #   nix() {
      #     case $1 in
      #       inate)
      #         shift
      #         command nix shell "$@"
      #         ;;
      #       *)
      #         command nix "$@";;
      #     esac
      #   }
      # '';
      # shellAliases = {
      #   something = "${pkgs.ffmpeg}/bin/ffmpeg --someoption";
      #   n = "nix-shell -p";
      #   # r = "nix repl ${inputs.flake-utils-plus.lib.repl}";
      #   ssh = "env TERM=xterm-256color ssh";
      #   ipv6off = "sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 -w net.ipv6.conf.default.disable_ipv6=1 -w net.ipv6.conf.lo.disable_ipv6=1";
      #   ipv6on = "sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0 -w net.ipv6.conf.default.disable_ipv6=0 -w net.ipv6.conf.lo.disable_ipv6=0";
      #   ls = "lsd";
      #   cheat = "function cheat_fn() { curl cht.sh/$1; }; cheat_fn";
      # };
    };

    ## zsh doesn't source .profile by default.
    ## but this is handled without this symlink by programs.zsh.sessionVariables above;
    # home.file.".zprofile".source = config.lib.file.mkOutOfStoreSymlink "/home/${userParams.username}/.profile";

    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
      ## Need 18.3.0 to fix zfs zpool timeout issue;
      ## https://github.com/atuinsh/atuin/issues/952#issuecomment-2121671620
      # package = pkgs.unstable.atuin;
      settings = {
        # Show only history for current terminal. ctrl-r to toggle through modes
        filter_mode = "session";

        # Enter runs command instead of just pasting it to command line
        enter_accept = "true";

        # Don't use full terminal height
        inline_height = "25";

        # Don't check for  updates
        update_check = "false";

        # Show command preview at bottom, for long commands
        show_preview = "true";

        # no borders
        # style = "compact";

        ## Need 18.3.0 to fix zfs zpool timeout issue;
        ## https://github.com/atuinsh/atuin/issues/952#issuecomment-2121671620
        daemon = {
          enabled = false;
          # systemd_socket = true;
          # socket_path = "/home/${userParams.username}/.local/share/atuin/atuin.sock";
        };
      };
    };

    # systemd.user.sockets.atuin = {
    #   Unit = {
    #     Description = "Atuin Magical Shell History Daemon";
    #     ConditionPathIsDirectory = "/home/${userParams.username}/.local/share/atuin";
    #     ConditionPathExists = "/home/${userParams.username}/.config/atuin/config.toml";
    #   };
    #   Install.WantedBy = [ "default.target" ];
    #   Socket = {
    #     Restart = "always";
    #     ListenStream = "/home/${userParams.username}/.local/share/atuin/atuin.sock";
    #     Accept = false;
    #     SocketMode = "0600";
    #   };
    # };
    # systemd.user.services.atuin = {
    #   Unit = {
    #     Description = "Atuin Magical Shell History Daemon";
    #     ConditionPathIsDirectory = "/home/${userParams.username}/.local/share/atuin";
    #     ConditionPathExists = "/home/${userParams.username}/.config/atuin/config.toml";
    #   };
    #   Install.WantedBy = [ "default.target" ];
    #   Service = {
    #     Restart = "always";
    #     ExecStart = "${pkgs.atuin}/bin/atuin daemon";
    #   };
    # };

    programs.zsh = {
      enable = if userParams.shell == "zsh" then true else false;

      enableCompletion = false;

      shellAliases = {
        something = "${pkgs.ffmpeg}/bin/ffmpeg --someoption";
        n = "nix-shell -p";
        ns = "nix search nixpkgs";
        # r = "nix repl ${inputs.flake-utils-plus.lib.repl}";
        # ssh = "env TERM=xterm-256color ssh";
        ls = "lsd";
        cheat = "function cheat_fn() { curl cht.sh/$1; }; cheat_fn";
      };

      ## Now using atuin

      # history = {
      #   size = 10000;
      #   path = "${config.xdg.dataHome}/zsh/history";
      # };

      plugins = [
        {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
      ];

      zplug = {
        enable = true;
        plugins = [
          { name = "chisui/zsh-nix-shell"; }

          # { name = "romkatv/powerlevel10k"; }

          ## Now using atuin
          # { name = "erahhal/zsh-directory-history"; }
        ];
      };

      initExtra = ''
        # Use ctrl-p in addition to the default up-arrow for activating atuin
        bindkey '^p' _atuin_search_widget

        tree () {
          ${pkgs.tree}/bin/tree -C $1 | less
        }
      '';

      oh-my-zsh = {
        enable = true;

        extraConfig = ''
          # case-sensitive tab completion
          CASE_SENSITIVE="true"

          # ambiguous completion
          setopt MENU_COMPLETE
          # setopt AUTO_MENU

          # Autocomplete for make
          zstyle ':completion::complete:make:*:targets' call-command true
        '';

        ## See: https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins
        plugins = [
          #-----------------------------------
          # History
          # - All disabled, now using Atuin
          #-----------------------------------

          # "history-substring-search"

          ## Not great as it requires manual toggling between local and global history
          ## use ctrl-g to toggle to global
          # "per-directory-history"

          ## Aliases
          ## e.g. h, hs, hsi
          # "history"

          #-----------------------------------
          # New shell functionality
          #-----------------------------------

          ## Doesn't seem to find or generate sqlite db - doesn't work with flakes
          ##  https://github.com/NixOS/nixpkgs/issues/171054
          ##  https://discourse.nixos.org/t/why-isnt-there-an-official-built-in-way-to-find-what-package-provides-a-specific-executable/22937
          # "command-not-found"
          ## ctrl-o to copy command line
          "copybuffer"
          "copypath"
          "emoji"
          ## Switch back and forth between vim and terminal using ctrl-z
          "fancy-ctrl-z"
          "fzf"
          ## Expands globs. Makes command line slow and messy sometimes, especially with a lot of matches
          # "globalias"

          "percol"
          "safe-paste"
          ## hit ESC twice to prefix previous command with sudo
          "sudo"
          ## needs: pkgs.thefuck
          "thefuck"
          ## See: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/vi-mode
          "vi-mode"
          ## works with fzf
          # "zsh-interactive-cd"
          "zsh-navigation-tools"

          #-----------------------------------
          # Display
          #-----------------------------------

          ## requires pkgs.acpi
          "battery"
          ## requires pkgs.python39Packages.pygments
          "colorize"
          "colored-man-pages"
          "git-prompt"
          "grc"
          "kube-ps1"
          "screen"
          "virtualenv"

          #-----------------------------------
          # Aliases
          #-----------------------------------

          ## e.g. alias-finder "git pull"
          "alias-finder"
          ## e.g. acs, acs status
          "aliases"
          ## See: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/common-aliases
          "common-aliases"
          ## List recent files with v, o, and j
          "fasd"
          ## See: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/nmap
          "nmap"
          "python"
          ## e.g. rsync-copy, rsync-move, rsync-update, rsync-synchronize
          "rsync"
          ## See: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/systemd
          "systemd"

          #-----------------------------------
          # New commands
          #-----------------------------------

          ## e.g. j foo, jc bar, jo music, jco images
          ## requires pkgs.autojump
          # "autojump"
          "copyfile"
          "emoji-clock"
          "extract"
          "jira"
          ## e.g. pp_json, is_json, urlencode_json, urldecode_json
          "jsontools"
          ## jump <mark-name>, mark [mark-name], unmark [mark-name], marks
          "jump"
          ## e.g. node-docs fs
          "node"
          ## Set PROJECT_PATHS=(~/src ~/work ~/"dir with spaces")
          ## Then jump with pj <project name>
          "pj"
          "scd"
          ## e.g. urlencode, urldecode
          "urltools"
          ## e.g. wake <tab>, wake <device name>
          ## needs: pkgs.wol
          "wakeonlan"
          ## e.g. z <substring of recent directory>
          "z"

          #-----------------------------------
          # Completion plugins
          #-----------------------------------

          # "adb" ## No longer exists?
          "ant"
          "autopep8"
          "aws"
          "bazel"
          "cabal"
          "docker"
          "docker-compose"
          "gem"
          "gitfast"
          "gradle"
          "grails"
          "kops"
          "kubectl"
          "lxd"
          "microk8s"
          "minikube"
          "mvn"
          "mosh"
          "npm"
          "pass"
          "pep8"
          "pip"
          "pylint"
          "redis-cli"
          # "ripgrep" ## No longer exists?
          "rust"
          "stack"
          "yarn"

          #-----------------------------------
          # Mac plugins
          # @TODO: only include these on macs
          #-----------------------------------

          "brew"
          "iterm2"
          "macos"
        ];

        ## See: https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
        theme = "fino-time";
        # theme = "robbyrussell";
        # theme = "half-life";
        # theme = "jonathan";
        # theme = "lambda";
        # theme = "mortalscumbag";
      };
    };

    programs.autojump = {
      enable = true;
    };

    programs.starship = {
      enable = true;
      enableBashIntegration = true;
      settings = {
        username = {
          format = "user: [$user]($style) ";
          show_always = true;
        };
        shlvl = {
          disabled = false;
          format = "$shlvl ▼ ";
          threshold = 4;
        };
        command_timeout = 1000;
      };
    };

    programs.git = {
      enable = true;
      userName = userParams.fullName;
      aliases = {
        undo = "reset HEAD~1 --mixed";
        date = "for-each-ref --sort=committerdate refs/heads/";
      };
      extraConfig = {
        checkout = {
          defaultRemote = "origin";
        };
        color = {
          ui = "auto";
        };
        core = {
          # Can't specify "${pkgs.neovim}/bin/nvim" because programs.neovim
          # wraps neovim-unwrapped in a special way to load plugins, so must
          # expect nvim to be in $PATH here
          editor = "nvim";
          excludesfile = "~/.gitignore_global";
        };
        # diff = {
        #   colorMoved = "default";
        #   tool = "vimdiff";
        #   mnemonicprefix = true;
        # };
        # difftool = {
        #   prompt = false;
        #   vimdiff = {
        #     trustExitCode = true;
        #   };
        # };
        delta = {
          enable = true;
        };
        filter = {
          lfs = {
            clean = "${pkgs.git-lfs}/bin/git-lfs clean -- %f";
            smudge = "${pkgs.git-lfs}/bin/git-lfs smudge --skip -- %f";
            process = "${pkgs.git-lfs}/bin/git-lfs filter-process --skip";
            required = true;
          };
        };
        push = {
          default = "simple";
        };
        rerere = {
          enabled = true;
        };
        include = {
          path = "~/.gitconfig.local";
        };

        #==========================
        # Diff settings
        #==========================

        pager = {
          difftool = true;
        };

        #-------------------
        ## nvim
        # - text-based
        #------------------
        # diff = {
        #   tool = "nvimdiff";
        # };
        # difftool = {
        #   prompt = true;
        # };
        # merge = {
        #   tool = "nvimdiff";
        #   trustExitCode = false;
        # };
        # mergetool = {
        #   trustExitCode = false;
        # };

        #-------------------
        ## meld
        # - gui
        #------------------
        # diff = {
        #   tool = "meld";
        # };
        # difftool = {
        #   prompt = true;
        # };
        # merge = {
        #   tool = "meld";
        #   trustExitCode = true;
        # };

        #-------------------
        ## kdiff3
        # - gui
        #------------------
        diff = {
          tool = "kdiff3";
        };
        difftool = {
          prompt = false;
          keepBackup = false;
          trustExitCode = false;
        };
        "difftool \"kdiff3\"" = {
          cmd = ''${pkgs.kdiff3}/bin/kdiff3'';
        };
        merge = {
          tool = "kdiff3";
          trustExitCode = false;
        };
        mergetool = {
          prompt = false;
          keepBackup = false;
          keepTemporaries = false;
          trustExitCode = false;
        };
        "mergetool \"kdiff3\"" = {
          cmd = ''${pkgs.kdiff3}/bin/kdiff3 -o "$MERGED" "$BASE" "$LOCAL" "$REMOTE"'';
        };

        #-------------------
        ## p4merge
        # - gui
        # - NO WAYLAND
        #------------------

        #-------------------
        ## bcompare
        # - gui-based
        # - commercial
        #------------------
        # merge = {
        #   tool = "bc";
        #   trustExitCode = true;
        # };
        # mergetool = {
        #   bc = {
        #     trustExitCode = true;
        #   };
        # };

        #-------------------
        ## difftastic
        # - uses treesitter to compare at code level
        # - home-manager has first-class setting for this
        # - doesn't seem to support merge
        #------------------
        # diff = {
        #   tool = "difftastic";
        #   external = "${pkgs.difftastic}/bin/difft";
        # };
        # difftool = {
        #   prompt = false;
        # };
        # "difftool \"difftastic\"" = {
        #   cmd = ''${pkgs.difftastic}/bin/difft "$LOCAL" "$REMOTE"'';
        # };
        # merge = {
        #   tool = "difftastic";
        #   trustExitCode = true;
        # };

        #-------------------
        ## diff-so-fancy
        # - text based
        # - home-manager default
        # - home-manager has first-class setting for this.
        #------------------

        # opendiff
        # kdiff3
        # tkdiff
        # xxdiff
        # meld
        # tortoisemerge
        # gvimdiff
        # diffuse
        # diffmerge
        # ecmerge
        # p4merge
        # araxis
        # bc
        # codecompare
        # smerge
        # vimdiff
        # nvimdiff
        # emerge
      };

      # difftastic = {
      #   enable = true;
      #   background = "dark";
      # };

      # diff-so-fancy = {
      #   enable = true;
      # };
    };

    programs.go.enable = true;

    programs.java = {
      enable = true;
      package = pkgs.zulu17;
    };

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    home.stateVersion = "22.11";
  };
}
