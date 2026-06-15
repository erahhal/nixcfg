# Two-way sync of ~/Code/homefree <-> 10.0.0.1:~/homefree via mutagen.
#
# Hub-and-spoke topology: the server's ~/homefree is the hub, and each machine
# importing this module syncs bidirectionally with it. The "homefree" session
# name is local to each machine's own daemon, so multiple machines can import
# this without colliding.
{ pkgs, osConfig, lib, ... }:
let
  userParams = osConfig.hostParams.user;
  alpha = "/home/${userParams.username}/Code/homefree";
  beta  = "erahhal@10.0.0.1:/home/erahhal/homefree";
in
{
  home.packages = [ pkgs.mutagen ];

  # Mutagen synchronization daemon
  systemd.user.services.mutagen-daemon = {
    Unit = {
      Description = "Mutagen synchronization daemon";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      Type = "simple";
      Environment = [ "PATH=${lib.makeBinPath [ pkgs.openssh pkgs.mutagen ]}" ];
      ExecStart = "${pkgs.mutagen}/bin/mutagen daemon run";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };

  # Reconcile the ~/Code/homefree <-> 10.0.0.1:~/homefree sync session to
  # match this Nix config. Re-runs on every activation where the script
  # derivation changes (i.e. when any of the values below change), and
  # terminates+recreates the session whenever its actual alpha/beta URLs
  # drift from what's declared here. Idempotent when already in sync.
  systemd.user.services.mutagen-homefree = {
    Unit = {
      Description = "Mutagen sync session: ${alpha} <-> ${beta}";
      After = [ "mutagen-daemon.service" ];
      Requires = [ "mutagen-daemon.service" ];
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      Environment = [ "PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.gawk pkgs.openssh pkgs.mutagen ]}" ];
      ExecStart = pkgs.writeShellScript "mutagen-homefree-reconcile" ''
        set -eu
        DESIRED_ALPHA=${lib.escapeShellArg alpha}
        DESIRED_BETA=${lib.escapeShellArg beta}

        mkdir -p "$DESIRED_ALPHA"

        # wait for the daemon socket to come up
        for _ in $(seq 1 30); do
          mutagen sync list >/dev/null 2>&1 && break
          sleep 0.5
        done

        # If a session named "homefree" exists, read its current endpoints;
        # otherwise treat as empty so the create branch runs.
        if current=$(mutagen sync list homefree 2>/dev/null); then
          current_alpha=$(printf '%s\n' "$current" | awk '/^Alpha:/{a=1;next} /^Beta:/{a=0} a && $1=="URL:"{print $2; exit}')
          current_beta=$(printf  '%s\n' "$current" | awk '/^Beta:/{a=1;next}  a && $1=="URL:"{print $2; exit}')
        else
          current_alpha=""
          current_beta=""
        fi

        if [ "$current_alpha" != "$DESIRED_ALPHA" ] || [ "$current_beta" != "$DESIRED_BETA" ]; then
          mutagen sync terminate homefree >/dev/null 2>&1 || true
          mutagen sync create --name=homefree \
            --sync-mode=two-way-resolved \
            --ignore='/result' --ignore='/result-*' \
            "$DESIRED_ALPHA" \
            "$DESIRED_BETA"
        fi
      '';
    };
  };
}
