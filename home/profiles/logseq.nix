{ config, pkgs, userParams, ... }:
let
  storePath = "/home/${userParams.username}/Documents/logseq";
in
{
    home = {
      packages = with pkgs; [
        git-sync
        logseq
      ];
    };

    systemd.user.services.logseq-sync = {
      Unit = {
        Description = "Logseq sync";
        After = [ "multi-user.target" ];
      };

      Install = {
        WantedBy = [ "default.target" ];
      };

      Service = {
        Type = "simple";
        WorkingDirectory = storePath;
        ## -n      Commit new files even if branch.$branch_name.syncNewFiles isn't set
        ## -s      Sync the branch even if branch.$branch_name.sync isn't set
        ExecStart = "${pkgs.git-sync}/bin/git-sync -n -s";
        PassEnvironment = [
          "HOME"
          "XDG_DATA_HOME"
          "XDG_CONFIG_HOME"
          "XDG_CACHE_HOME"
          "XDG_RUNTIME_DIR"
          "DISPLAY"  # If needed for GUI applications
          "WAYLAND_DISPLAY"  # If using Wayland
        ];
        # You can also set them explicitly if needed
        Environment = [
          "HOME=%h"  # %h is a special variable that expands to the user's home directory
        ];
      };
    };

    systemd.user.services.logseq-sync-watcher = {
      Unit = {
        Description = "Logseq sync starter";
        After = [ "multi-user.target" ];
      };

      Install = {
        WantedBy = [ "default.target" ];
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl --user start logseq-sync";
        PassEnvironment = [
          "HOME"
          "XDG_DATA_HOME"
          "XDG_CONFIG_HOME"
          "XDG_CACHE_HOME"
          "XDG_RUNTIME_DIR"
          "DISPLAY"  # If needed for GUI applications
          "WAYLAND_DISPLAY"  # If using Wayland
        ];
        # You can also set them explicitly if needed
        Environment = [
          "HOME=%h"  # %h is a special variable that expands to the user's home directory
        ];
      };
    };

    systemd.user.paths.logseq-sync-watcher = {
      Unit = {
        Description = "Logseq sync path watcher";
        After = [ "multi-user.target" ];
      };

      Install = {
        WantedBy = [ "default.target" ];
      };

      Path = {
        PathModified = storePath;
      };
    };
}
