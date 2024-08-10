{ hostParams, lib, pkgs, userParams, ... }:

{
  config = lib.mkMerge [
    (if (hostParams.defaultSession == "plasma6" || hostParams.multipleSessions) then {
      services.xserver.enable = true;
      services.displayManager.sddm.enable = true;
      services.displayManager.sddm.wayland.enable = true;
      services.desktopManager.plasma6.enable = true;
    } else {})

    {
      environment.systemPackages = with pkgs; [
        kdePackages.kate
        kdePackages.qtwayland
        kdePackages.kwallet
      ];

      # Conflicts with TLP
      services.power-profiles-daemon.enable = lib.mkForce false;

      home-manager.users.${userParams.username} = args@{ pkgs, ... }: {
        ## in system-theme-dark.nix
        # qt = {
        #   enable = true;
        #   platformTheme = "qtct";
        #   style.name = "kvantum";
        # };
        #
        # xdg.configFile = {
        #   "Kvantum/ArcDark".source = "${pkgs.arc-kde-theme}/share/Kvantum/ArcDark";
        #   "Kvantum/kvantum.kvconfig".text = "[General]\ntheme=ArcDark";
        # };
      };
    }
  ];
}
