{ pkgs, lib, hostParams, ... }:
let
  # Need to escape bash variables so they aren't interpolated by home-manager during activation
  ircConfigFile = builtins.replaceStrings ["\$"] ["\\$"] (builtins.readFile ./weechat/irc.conf);
  weechatConfigFile = builtins.replaceStrings ["\$"] ["\\$"] (builtins.readFile ./weechat/weechat.conf);
in
{
  @TODO: use ${pkgs.augeas}/bin/augtool
  home.activation.weechatConfig = lib.hm.dag.entryAfter [ "installPackages" ] ''
    mkdir -p ~/.config/weechat
    if [ ! -e ~/.config/weechat/irc.conf ]; then
      cat > ~/.config/weechat/irc.conf<< EOF
${ircConfigFile}
EOF
    fi
    if [ ! -e ~/.config/weechat/weechat.conf ]; then
      cat > ~/.config/weechat/weechat.conf<< EOF
${weechatConfigFile}
EOF
    fi

    if ! grep --quiet "libera" ~/.config/weechat/irc.conf; then
      cat "${./weechat/irc.conf.added}" >> ~/.config/weechat/irc.conf
    fi

    if ! grep --quiet "[filter]" ~/.config/weechat/irc.conf; then
      cat "${./weechat/weechat.conf.added}" >> ~/.config/weechat/irc.conf
    fi
  '';
}
