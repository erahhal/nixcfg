# Note:
# - Running PhotoPrism on a server with less than 4 GB of swap space or setting a memory/swap limit can cause unexpected
#   restarts ("crashes"), for example, when the indexer temporarily needs more memory to process large files.
# - If you install PhotoPrism on a public server outside your home network, please always run it behind a secure
#   HTTPS reverse proxy such as Traefik or Caddy. Your files and passwords will otherwise be transmitted
#   in clear text and can be intercepted by anyone, including your provider, hackers, and governments:
#   https://docs.photoprism.app/getting-started/proxies/traefik/
#
# Documentation : https://docs.photoprism.app/getting-started/docker-compose/
# Docker Hub URL: https://hub.docker.com/r/photoprism/photoprism/
#
# DOCKER COMMAND REFERENCE
# see https://docs.photoprism.app/getting-started/docker-compose/#command-line-interface
# --------------------------------------------------------------------------
# Terminal | docker exec -it photoprism bash
# Help     | docker exec -it photoprism photoprism help
# Config   | docker exec -it photoprism photoprism config
# Reset    | docker exec -it photoprism photoprism reset
# Backup   | docker exec -it photoprism photoprism backup -a -i
# Restore  | docker exec -it photoprism photoprism restore -a -i
# Index    | docker exec -it photoprism photoprism index
# Reindex  | docker exec -it photoprism photoprism index -f
# Import   | docker exec -it photoprism photoprism import
#
# To search originals for faces without a complete rescan:
# docker exec -it photoprism photoprism faces index

{ config, pkgs, hostParams, userParams, ... }:
let
  containerDataPath = "/home/${userParams.username}/DockerData";
  service_ip = "10.0.0.66";
in
{
  networking.interfaces.${hostParams.mainInterface}.ipv4.addresses = [
    { address = service_ip; prefixLength = 8; }
  ];

  virtualisation.oci-containers.containers = {
    photoprism = {
      image = "photoprism/photoprism:latest";
      extraOptions = [
        "--pull=always"
        "--env-file=${config.age.secrets.docker.path}"
        # do not change or remove
        "--workdir=/photoprism"
        # "--security-opt seccomp=unconfirmed"
        # "--security-opt apparmor=unconfirmed"
        ## Share hardware devices with FFmpeg and TensorFlow (optional):
        "--device=/dev/dri"                     # Intel QSV
        # "--device=/dev/nvidia0"                 # Nvidia CUDA
        # "--device=/dev/nvidiactl"
        # "--device=/dev/nvidia-modeset"
        # "--device=/dev/nvidia-nvswitchctl"
        # "--device=/dev/nvidia-uvm"
        # "--device=/dev/nvidia-uvm-tools"
        # "--device=/dev/video11"                 # Video4Linux Video Encode Device (h264_v4l2m2m)
      ];
      dependsOn = [
        "mariadb"
      ];
      ports = [
        "${service_ip}:80:2342"
      ];
      volumes = [
        "${containerDataPath}/photoprism/storage:/photoprism/storage"
        "/mnt/ellis/Photos - sorted:/photoprism/originals"
        "/mnt/ellis/Photos - Import:/photoprism/import"
      ];
      ## Start as non-root user before initialization (supported: 0, 33, 50-99, 500-600, and 900-1200):
      user = "${toString hostParams.uid}:${toString hostParams.gid}";
      environment = {
        PHOTOPRISM_AUTH_MODE = "password";                    # authentication mode (public, password)
        PHOTOPRISM_SITE_URL = "https://photoprism.rahh.al/";  # public server URL incl http:// or https:// and /path, :port is optional
        PHOTOPRISM_ORIGINALS_LIMIT = "10000";                 # file size limit for originals in MB (increase for high-res video)
        PHOTOPRISM_HTTP_COMPRESSION = "gzip";                 # improves transfer speed and bandwidth utilization (none or gzip)
        PHOTOPRISM_LOG_LEVEL = "info";                        # log level: trace, debug, info, warning, error, fatal, or panic
        PHOTOPRISM_READONLY = "true";                         # do not modify originals directory (reduced functionality)
        PHOTOPRISM_EXPERIMENTAL = "false";                    # enables experimental features
        PHOTOPRISM_DISABLE_CHOWN = "false";                   # disables updating storage permissions via chmod and chown on startup
        PHOTOPRISM_DISABLE_WEBDAV = "false";                  # disables built-in WebDAV server
        PHOTOPRISM_DISABLE_SETTINGS = "false";                # disables settings UI and API
        PHOTOPRISM_DISABLE_TENSORFLOW = "false";              # disables all features depending on TensorFlow
        PHOTOPRISM_DISABLE_FACES = "false";                   # disables face detection and recognition (requires TensorFlow)
        PHOTOPRISM_DISABLE_CLASSIFICATION = "false";          # disables image classification (requires TensorFlow)
        PHOTOPRISM_DISABLE_RAW = "false";                     # disables indexing and conversion of RAW files
        PHOTOPRISM_RAW_PRESETS = "false";                     # enables applying user presets when converting RAW files (reduces performance)
        PHOTOPRISM_JPEG_QUALITY = "85";                       # a higher value increases the quality and file size of JPEG images and thumbnails (25-100)
        PHOTOPRISM_DETECT_NSFW = "false";                     # automatically flags photos as private that MAY be offensive (requires TensorFlow)
        PHOTOPRISM_UPLOAD_NSFW = "true";                      # allows uploads that MAY be offensive (no effect without TensorFlow)
        PHOTOPRISM_DATABASE_DRIVER = "mysql";                 # use MariaDB 10.5+ or MySQL 8+ instead of SQLite for improved performance
        PHOTOPRISM_DATABASE_SERVER = "mariadb:3306";          # MariaDB or MySQL database server (hostname:port)
        PHOTOPRISM_DATABASE_NAME = "photoprism";              # MariaDB or MySQL database schema name
        PHOTOPRISM_DATABASE_USER = "photoprism";              # MariaDB or MySQL database user name
        PHOTOPRISM_SITE_CAPTION = "rahh.al photos";
        PHOTOPRISM_SITE_DESCRIPTION = "";                # meta site description
        PHOTOPRISM_SITE_AUTHOR = "";                     # meta site author
        ## Run/install on first startup (options: update gpu tensorflow davfs clitools clean):
        # PHOTOPRISM_INIT = "gpu tensorflow";
        ## Hardware Video Transcoding (for sponsors only due to high maintenance and support costs):
        # PHOTOPRISM_FFMPEG_ENCODER = "software"        # FFmpeg encoder ("software", "intel", "nvidia", "apple", "raspberry";)
        # PHOTOPRISM_FFMPEG_BITRATE = "32";              # FFmpeg encoding bitrate limit in Mbit/s (default: 50)
        ## Run as a non-root user after initialization (supported: 0, 33, 50-99, 500-600, and 900-1200):
        PHOTOPRISM_UID = toString hostParams.uid;
        PHOTOPRISM_GID = toString hostParams.gid;
        # PHOTOPRISM_UMASK: 0000
      };
    };
  };
}
