{ osConfig, ... }:
let
  userParams = osConfig.hostParams.user;
in
{
  accounts.email.accounts.protonmail = {
    primary = true;
    address = userParams.protonmailEmail;
    userName = userParams.protonmailEmail;
    realName = userParams.fullName;
    imap = {
      host = "127.0.0.1";
      port = 1143;
      tls.enable = false; # Bridge handles encryption
    };
    smtp = {
      host = "127.0.0.1";
      port = 1025;
      tls.enable = false;
    };
    thunderbird = {
      enable = true;
      profiles = [ "default" ];
    };
  };

  programs.thunderbird = {
    enable = true;
    profiles.default = {
      isDefault = true;
    };
  };
}
