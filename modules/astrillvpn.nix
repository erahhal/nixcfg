{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.astrillvpn;
  astrillvpn = pkgs.callPackage ../pkgs/astrillvpn {};
  packageSet = {
    astrillvpn = astrillvpn;
  };
in
  with lib; {
    options.services.astrillvpn = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          This option enables AstrillVPN.
        '';
      };

      package = mkPackageOption packageSet "astrillvpn" {};
    };

    config = mkIf cfg.enable {
      boot.kernelModules = ["tun"];

      environment.systemPackages = [cfg.package];

      security.wrappers = {
        asproxy = {
          owner = "root";
          group = "root";
          setuid = true;
          source = "${cfg.package}/usr/local/Astrill/.asproxy-wrapped";
        };

        astrill = {
          owner = "root";
          group = "root";
          capabilities = "cap_net_admin,cap_net_raw+ep";
          source = "${cfg.package}/usr/local/Astrill/.astrill-wrapped";
        };
      };
    };

    meta.maintainers = with maintainers; [ErrorNoInternet];
  }
