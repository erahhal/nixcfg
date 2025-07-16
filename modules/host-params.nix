{ lib, ... }:
{
  options.hostParams = {
    system = {
      hostName = lib.mkOption {
        type = lib.types.str;
        default = null;
        description = "Hostname for the system";
      };

      ## @TODO: Detect or have user enter during setup
      timeZone = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "America/Los_Angeles";
        description = ''
          Timezone for the system in tz database format.
          See: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

          example: Etc/UTC
        '';
      };
    };

    gpu = {
      amd = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable AMD GPU support";
        };
      };

      intel = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Intel GPU support";
        };
      };

      nvidia = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable NVidia GPU support";
        };
      };
    };
  };
}
