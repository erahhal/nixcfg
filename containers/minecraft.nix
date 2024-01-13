{ config, lib, pkgs, hostParams, userParams, recursiveMerge, ... }:

## @TODOS
# - Move config files into nix, and out of DockerData
# - Map config files on top of existing volumes
# - Move plugins into nix as derivations
# - Figure out how to snapshot worlds

## Notes
# - Buneecord - Run multiple servers behind one domain:port
# - Advanced Portals - Allows creating portals across servers
# - Portal Gun - Creates a portal gun that doesn't require mods
# - Gyser - Allows Bedrock (mobile) clients to connect to Java server
# - Floodgate - allows Minecraft: Bedrock Accounts to join
#     Java servers without needing a Java Edition account
# - LuckPerms - Allows granular permissions (Requires MySQL)

## Portal setup
# To recreate portals:
# /portal portalblock
# /portal wand
# - Draw portal
# - Select wand tool (special axe)
# - Left click upper left
# - Right click lower right
# /portal create name:creative_to_lobby bungee:lobby

## Troubleshooting
# - If the bungeecord container doesn't start, it's probably because
#   lobby, creative, or survival didn't start, and it's dependent on them
# - If a bungee plugin is added to a spigot server, or vice versa, it won't start
# - If too many creatures were spawned and the server keeps stopping, delete the world folders


let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.84";
  network = "minecraft";
  pod = "minecraft_pod";
  pod_ports = [
    "${service_ip}:25565:25565/tcp"
    "${service_ip}:25569:25569/udp"
    "${service_ip}:19132:19132/tcp"
    "${service_ip}:19132:19132/udp"
    "${service_ip}:19133:19133/tcp"
    "${service_ip}:19133:19133/udp"
  ];
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  networking.firewall.allowedTCPPorts = [
    # bungeecord
    25565

    # bedrock
    19132

    # bedrock lobby
    19133

    # portal-gun
    25569
  ];

  networking.firewall.allowedUDPPorts = [
    # bungeecord
    25565

    # bedrock
    19132

    # bedrock lobby
    19133

    # portal-gun
    25569
  ];

  systemd.services = if hostParams.containerBackend == "docker" then {
    "docker-init-network-${network}" = {
      description = "Create docker network bridge: ${network}";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig.Type = "oneshot";
      script = let cli = "${config.virtualisation.docker.package}/bin/docker";
               in ''
                 if [ "${network}" == "host" ]; then
                   exit 0
                 fi
                 # Put a true at the end to prevent getting non-zero return code, which will
                 # crash the whole service.
                 check=$(${cli} network ls | grep "${network}" || true)
                 if [ -z "$check" ]; then
                   ${cli} network create ${network}
                 else
                   echo "container ${network} already exists"
                 fi
               '';
    };
  } else {
    "podman-init-pod-${pod}" = {
      description = "Create podman pod: ${pod}";
      after = [ "network.target" "podman.service" ];
      requires = [ "systemd-networkd-wait-online.service" ];
      wantedBy = [ "multi-user.target" ];

      # @TODO: This script is not idempotent.  If ports change, then the containers
      #        need to be stopped, then the pod removed before running this again
      # @TODO: Maybe it *is* idempotent. During build all containers are stopped
      #        and then started again, so this might work.
      serviceConfig.Type = "oneshot";
      script = let
                  cli = "${config.virtualisation.podman.package}/bin/podman";
                  concat = lib.foldr (a: b: " -p ${a}" + b) "";
               in ''
                 # Put a true at the end to prevent getting non-zero return code, which will
                 # crash the whole service.
                 check=$(${cli} pod ls | grep "${pod}" || true)
                 if [ -z "$check" ]; then
                   ${cli} pod create --name ${pod} ${concat pod_ports}
                 else
                   echo "pod ${pod} already exists"
                 fi
               '';
    };
  };

  virtualisation.oci-containers.containers = {
    minecraft-mysql = (
    let
      baseConfig = {
        image = "mysql:8.0.22";
        extraOptions = [
          "--pull=always"
          "--env-file=${config.age.secrets.docker.path}"
        ];
        user = "${toString userParams.uid}:${toString userParams.gid}";
        volumes = [
          "${containerDataPath}/minecraft/mysql-data:/var/lib/mysql"
        ];
      };
      podmanConfig = {
        dependsOn = [
          "init-pod-${pod}"
        ];
        extraOptions = [
          "--pod=${pod}"
        ];
      };
      dockerConfig = {
        dependsOn = [
          "init-network-${network}"
        ];
        extraOptions = [
          "--network=${network}"
        ];
      };
    in
      if hostParams.containerBackend == "podman" then
        recursiveMerge [ baseConfig podmanConfig ]
      else
        recursiveMerge [ baseConfig dockerConfig ]
    );

    minecraft-bungeecord = (
    let
      baseConfig = {
        image = "itzg/bungeecord:latest";
        dependsOn = [
          "minecraft-lobby"
          "minecraft-creative"
          "minecraft-survival"
        ];
        extraOptions = [
          "--pull=always"
        ];
        user = "${toString userParams.uid}:${toString userParams.gid}";
        volumes = [
          "${containerDataPath}/minecraft/config-bungeecord:/config"
          "${containerDataPath}/minecraft/plugins-bungeecord:/plugins"
          "${containerDataPath}/minecraft/server-bungeecord:/server"
        ];
        environment = {
          UID = toString userParams.uid;
          GID = toString userParams.gid;
          TYPE = "BUNGEECORD";
        };
      };
      dockerConfig = {
        dependsOn = [
          "init-network-${network}"
        ];
        extraOptions = [
          "--network=${network}"
        ];
        ports = [
          "${service_ip}:19132:19132/udp"
          "${service_ip}:19132:19132/tcp"
          "${service_ip}:25565:25565"
        ];
      };
      podmanConfig = {
        dependsOn = [
          "init-pod-${pod}"
        ];
        extraOptions = [
          "--pod=${pod}"
        ];
      };
    in
      if hostParams.containerBackend == "podman" then
        recursiveMerge [ baseConfig podmanConfig ]
      else
        recursiveMerge [ baseConfig dockerConfig ]
    );

    minecraft-lobby = (
    let
      baseConfig = {
        image = "itzg/minecraft-server:latest";
        dependsOn = [
          "minecraft-mysql"
        ];
        extraOptions = [
          "--pull=always"
        ];
        ## DO NOT add this, as it conflicts with UID and GID in the "environment section"
        # user = "${toString userParams.uid}:${toString userParams.gid}";
        volumes = [
          "${containerDataPath}/minecraft/data-lobby:/data"
          "${containerDataPath}/minecraft/plugins-spigot:/plugins:ro"
          "${containerDataPath}/minecraft/worlds:/worlds:ro"
        ];
        environment = {
          UID = toString userParams.uid;
          GID = toString userParams.gid;
          VERSION = "1.19";
          # OPS = "jumpingnosepizza,theomobile";
          OPS = "ektoklast";
          EULA = "TRUE";
          TYPE = "SPIGOT";
          SERVER_PORT = "25566";
          MODE = "adventure";
          # ENABLE_RCON = "TRUE";
          # RCON_PASSWORD = "REPLACEME";
          # RCON_PORT = "28016";
          MOTD = "Rahhal Family Lobby";
          ANNOUNCE_PLAYER_ACHIEVEMENTS = "TRUE";
          SPAWN_PROTECTION = "0";
          WORLD = "/worlds/Lobby";
          CONSOLE = "FALSE";
          GUI = "FALSE";
          ## Not enabled - doesn't work well with bungee-cord multi-server, as it takes a couple minutes
          ## For each server to start, and they don't start until a portal is entered
          # ENABLE_AUTOPAUSE = "TRUE";
          # Time to autopause after last player logs off
          AUTOPAUSE_TIMEOUT_EST = "900";
          # Time to autopause after server start
          AUTOPAUSE_TIMEOUT_INIT = "60";
          # Needed for autopause
          MAX_TICK_TIME="-1";
          WATCHDOG="-1";
          # Needed for bungeecord
          ONLINE_MODE = "FALSE";
          RESOURCE_PACK = "https://github.com/FentisDev/PortalGun/raw/master/resourcepacks/PortalGun-By-Fentis-1.0.0.zip";
          RESOURCE_PACK_SHA1 = "eed7b6a1513957143fbc8841bd497e9ee41fdf1a";
          RESOURCE_PACK_ENFORCE = "TRUE";
        };
      };
      dockerConfig = {
        dependsOn = [
          "init-network-${network}"
        ];
        extraOptions = [
          "--network=${network}"
        ];
        ports = [
          "${service_ip}:19133:19133/udp"
          "${service_ip}:19133:19133/tcp"
        ];
      };
      podmanConfig = {
        dependsOn = [
          "init-pod-${pod}"
        ];
        extraOptions = [
          "--pod=${pod}"
        ];
      };
    in
      if hostParams.containerBackend == "podman" then
        recursiveMerge [ baseConfig podmanConfig ]
      else
        recursiveMerge [ baseConfig dockerConfig ]
    );

    minecraft-creative = (
    let
      baseConfig = {
        image = "itzg/minecraft-server:latest";
        dependsOn = [
          "minecraft-mysql"
        ];
        extraOptions = [
          "--pull=always"
        ];
        ## DO NOT add this, as it conflicts with UID and GID in the "environment section"
        # user = "${toString userParams.uid}:${toString userParams.gid}";
        volumes = [
          "${containerDataPath}/minecraft/data-creative:/data"
          "${containerDataPath}/minecraft/plugins-spigot:/plugins:ro"
        ];
        environment = {
          UID = toString userParams.uid;
          GID = toString userParams.gid;
          VERSION = "1.19";
          OPS = "jumpingnosepizza,theomobile";
          EULA = "TRUE";
          TYPE = "SPIGOT";
          SERVER_PORT = "25567";
          MODE = "creative";
          # ENABLE_RCON = "TRUE";
          # RCON_PASSWORD = "REPLACEME";
          # RCON_PORT = "28017";
          MOTD = "Rahhal Family Creative Server";
          ANNOUNCE_PLAYER_ACHIEVEMENTS = "TRUE";
          SPAWN_PROTECTION = "0";
          ALLOW_NETHER = "TRUE";
          LEVEL_TYPE = "FLAT";
          ## Not enabled - doesn't work well with bungee-cord multi-server, as it takes a couple minutes
          ## For each server to start, and they don't start until a portal is entered
          # ENABLE_AUTOPAUSE = "TRUE";
          # Time to autopause after last player logs off
          AUTOPAUSE_TIMEOUT_EST = "900";
          # Time to autopause after server start
          AUTOPAUSE_TIMEOUT_INIT = "60";
          # Needed for autopause
          MAX_TICK_TIME="-1";
          WATCHDOG="-1";
          # Needed for bungeecord
          ONLINE_MODE = "FALSE";
          RESOURCE_PACK = "https://github.com/FentisDev/PortalGun/raw/master/resourcepacks/PortalGun-By-Fentis-1.0.0.zip";
          RESOURCE_PACK_SHA1 = "eed7b6a1513957143fbc8841bd497e9ee41fdf1a";
          RESOURCE_PACK_ENFORCE = "TRUE";
        };
      };
      dockerConfig = {
        dependsOn = [
          "init-network-${network}"
        ];
        extraOptions = [
          "--network=${network}"
        ];
      };
      podmanConfig = {
        dependsOn = [
          "init-pod-${pod}"
        ];
        extraOptions = [
          "--pod=${pod}"
        ];
      };
    in
      if hostParams.containerBackend == "podman" then
        recursiveMerge [ baseConfig podmanConfig ]
      else
        recursiveMerge [ baseConfig dockerConfig ]
    );

    minecraft-survival = (
    let
      baseConfig = {
        image = "itzg/minecraft-server:latest";
        dependsOn = [
          "minecraft-mysql"
        ];
        extraOptions = [
          "--pull=always"
        ];
        ## DO NOT add this, as it conflicts with UID and GID in the "environment section"
        # user = "${toString userParams.uid}:${toString userParams.gid}";
        volumes = [
          "${containerDataPath}/minecraft/data-survival:/data"
          "${containerDataPath}/minecraft/plugins-spigot:/plugins:ro"
        ];
        environment = {
          UID = toString userParams.uid;
          GID = toString userParams.gid;
          VERSION = "1.19";
          OPS = "jumpingnosepizza,theomobile";
          EULA = "TRUE";
          TYPE = "SPIGOT";
          SERVER_PORT = "25568";
          MODE = "survival";
          # ENABLE_RCON = "TRUE";
          # RCON_PASSWORD = "REPLACEME";
          # RCON_PORT = "28018";
          MOTD = "Rahhal Family Survival Server";
          ANNOUNCE_PLAYER_ACHIEVEMENTS = "TRUE";
          SPAWN_PROTECTION = "0";
          ALLOW_NETHER = "TRUE";
          LEVEL_TYPE = "largeBiomes -e 'GENERATOR_SETTINGS=3;minecraft:bedrock,230*minecraft:stone,5*minecraft:dirt,minecraft:grass_block;minecraft:mountains;biome_1,decoration,stronghold,mineshaft,dungeon'";
          GENERATE_STRUCTURES = "TRUE";
          PVP = "FALSE";
          ## Not enabled - doesn't work well with bungee-cord multi-server, as it takes a couple minutes
          ## For each server to start, and they don't start until a portal is entered
          # ENABLE_AUTOPAUSE = "TRUE";
          # Time to autopause after last player logs off
          AUTOPAUSE_TIMEOUT_EST = "900";
          # Time to autopause after server start
          AUTOPAUSE_TIMEOUT_INIT = "60";
          # Needed for autopause
          MAX_TICK_TIME="-1";
          WATCHDOG="-1";
          # Needed for bungeecord
          ONLINE_MODE = "FALSE";
          RESOURCE_PACK = "https://github.com/FentisDev/PortalGun/raw/master/resourcepacks/PortalGun-By-Fentis-1.0.0.zip";
          RESOURCE_PACK_SHA1 = "eed7b6a1513957143fbc8841bd497e9ee41fdf1a";
          RESOURCE_PACK_ENFORCE = "TRUE";
        };
      };
      dockerConfig = {
        dependsOn = [
          "init-network-${network}"
        ];
        extraOptions = [
          "--network=${network}"
        ];
      };
      podmanConfig = {
        dependsOn = [
          "init-pod-${pod}"
        ];
        extraOptions = [
          "--pod=${pod}"
        ];
      };
    in
      if hostParams.containerBackend == "podman" then
        recursiveMerge [ baseConfig podmanConfig ]
      else
        recursiveMerge [ baseConfig dockerConfig ]
    );

    # minecraft-portal-gun = (
    # let
    #   baseConfig = {
    #     image = "itzg/minecraft-server:latest";
    #     dependsOn = [
    #       "minecraft-mysql"
    #     ];
    #     extraOptions = [
    #       "--pull=always"
    #     ];
    #     ## DO NOT add this, as it conflicts with UID and GID in the "environment section"
    #     # user = "${toString userParams.uid}:${toString userParams.gid}";
    #     volumes = [
    #       "${containerDataPath}/minecraft/data-portal-gun:/data"
    #       "${containerDataPath}/minecraft/plugins-spigot:/plugins:ro"
    #       "${containerDataPath}/minecraft/plugins-portal-gun:/mods:ro"
    #     ];
    #     environment = {
    #       UID = toString userParams.uid;
    #       GID = toString userParams.gid;
    #       VERSION = "1.19";
    #       OPS = "jumpingnosepizza,theomobile,ektoklast";
    #       EULA = "TRUE";
    #       TYPE = "SPIGOT";
    #       SERVER_PORT = "25569";
    #       MODE = "creative";
    #       # ENABLE_RCON = "TRUE";
    #       # RCON_PASSWORD = "REPLACEME";
    #       # RCON_PORT = "28019";
    #       MOTD = "Rahhal Family Portal Gun Server";
    #       ANNOUNCE_PLAYER_ACHIEVEMENTS = "TRUE";
    #       SPAWN_PROTECTION = "0";
    #       ALLOW_NETHER = "TRUE";
    #       GENERATE_STRUCTURES = "TRUE";
    #       RESOURCE_PACK = "https://github.com/FentisDev/PortalGun/raw/master/resourcepacks/PortalGun-By-Fentis-1.0.0.zip";
    #       RESOURCE_PACK_SHA1 = "eed7b6a1513957143fbc8841bd497e9ee41fdf1a";
    #       RESOURCE_PACK_ENFORCE = "TRUE";
    #       PVP = "FALSE";
    #       ## Not enabled - doesn't work well with bungee-cord multi-server, as it takes a couple minutes
    #       ## For each server to start, and they don't start until a portal is entered
    #       # ENABLE_AUTOPAUSE = "TRUE";
    #       # Time to autopause after last player logs off
    #       AUTOPAUSE_TIMEOUT_EST = "900";
    #       # Time to autopause after server start
    #       AUTOPAUSE_TIMEOUT_INIT = "60";
    #       # Needed for autopause
    #       MAX_TICK_TIME="-1";
    #       WATCHDOG="-1";
    #     };
    #   };
    #   dockerConfig = {
    #     dependsOn = [
    #       "init-network-${network}"
    #     ];
    #     extraOptions = [
    #       "--network=${network}"
    #     ];
    #     ports = [
    #       "${service_ip}:25569:25569"
    #     ];
    #   };
    #   podmanConfig = {
    #     dependsOn = [
    #       "init-pod-${pod}"
    #     ];
    #     extraOptions = [
    #       "--pod=${pod}"
    #     ];
    #   };
    # in
    #   if hostParams.containerBackend == "podman" then
    #     recursiveMerge [ baseConfig podmanConfig ]
    #   else
    #     recursiveMerge [ baseConfig dockerConfig ]
    # );
  };
}
