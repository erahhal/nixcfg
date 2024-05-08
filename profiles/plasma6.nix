{ hostParams, userParams, pkgs, ... }:

{
  config = if (hostParams.defaultSession == "plasma6" || hostParams.multipleSessions) then {
    environment.systemPackages = with pkgs; [
      unstable.kdePackages.kate
    ];

    ## Not yet available on stable
    # services.desktopManager.plasma6.enable = true;

    home-manager.users.${userParams.username} = args@{ pkgs, ... }: {
      # home.sessionVariables = {
      #   QT_QPA_PLATFORM_PLUGIN_PATH = "${pkgs.qt5.qtbase.bin}/lib/qt-${pkgs.qt5.qtbase.version}/plugins”;
      # };
      home.sessionVariables = {
        QT_QPA_PLATFORM_PLUGIN_PATH = "${pkgs.qt5.qtbase.bin}/lib/qt-${pkgs.qt5.qtbase.version}/plugins";
      };
      # imports = [
      #   ( import ../home/profiles/plasma6.nix (args // {
      #     hostParams = hostParams;
      #     userParams = userParams;
      #   }))
      # ];
    };
  } else {};
}
