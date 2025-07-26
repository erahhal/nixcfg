{ config, lib, pkgs, ... }:
let
  containerDataPath = "/var/lib/ollama-webui";

  preStart = ''
    mkdir -p ${containerDataPath}
  '';

  port-internal = 8254;
  port = 8087;

  containerBridge = if config.hostParams.containers.backend == "docker" then "docker0" else "podman0";
in
{
  environment.systemPackages = [
    pkgs.ollama
  ];

  services.ollama = {
    enable = true;
    port = 11434; # Default: 11434
    host = "[::]";
    loadModels = [
      "deepseek-r1:8b"
      "deepseek-r1:14b"
      "gemma3:12b"
      "qwen2.5-coder"
    ];
    acceleration = lib.mkIf config.hostParams.gpu.nvidia.enable "cuda";
  };

  networking.firewall = {
    interfaces."${containerBridge}".allowedTCPPorts = [ config.services.ollama.port ];
  };

  systemd.services."${config.hostParams.containers.backend}-ollama-webui" = {
    description = "Open Web UI";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "ollama-webui-prestart" preStart}" ];
    };
  };

  virtualisation.oci-containers.containers = {
    ollama-webui = {
      image = "ghcr.io/open-webui/open-webui:main";

      autoStart = true;

      extraOptions = [
        "--add-host=host.docker.internal:host-gateway"
      ];

      ports = [
        "0.0.0.0:${toString port}:${toString port-internal}"
      ];

      volumes = [
      "/etc/localtime:/etc/localtime:ro"
        "${containerDataPath}:/app/backend/data"
      ];

      environment = {
        TZ = config.hostParams.system.timeZone;
        PORT = toString port-internal;
        WEBUI_URL = "http://localhost:${toString port}";
        OLLAMA_BASE_URL = "http://host.docker.internal:${toString config.services.ollama.port}";
        ## @TODOS
        # WEBUI_SECRET_KEY
        # DEFAULT_LOCALE
        # DEFAULT_PROMPT_SUGGESTIONS
        # CORS_ALLOW_ORIGIN (defualt is *)
        # USER_AGENT
        ## Single user mode (can't change after first run)
        # WEBUI_AUTH=False
      };
    };
  };
}
