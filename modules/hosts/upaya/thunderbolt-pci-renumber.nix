{ pkgs, ... }:
{
  # On a hot plug the firmware, not Linux, numbers the PCIe buses behind the
  # Thunderbolt dock (this TB3 controller is BIOS-assisted), and it hands all
  # the spare buses to the dock's empty internal port. The port the P40w-20
  # hangs off gets a single bus, so the monitor's own PCIe switch has nowhere
  # to number its buses and its USB controller -- keyboard and mouse -- never
  # appears ("devices behind bridge are unusable because [bus 0d] cannot be
  # assigned"). A cold boot is fine: "Thunderbolt Adapter Boot Support" makes
  # the BIOS number the whole chain at POST.
  #
  # After each Thunderbolt device add, look for a bridge squeezed to one bus
  # with another bridge behind it. Clear the bus numbers and windows of the
  # bridges behind it, of it, and of its empty sibling ports, then let Linux
  # re-enumerate them. Ports with devices behind them (the dock's own USB
  # controller: ethernet) are left alone.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="thunderbolt", ENV{DEVTYPE}=="thunderbolt_device", TAG+="systemd", ENV{SYSTEMD_WANTS}+="thunderbolt-pci-renumber.service"
  '';

  systemd.services.thunderbolt-pci-renumber = {
    description = "Re-number PCIe buses starved by a Thunderbolt hot plug";
    path = [ pkgs.pciutils ];
    serviceConfig.Type = "oneshot";
    script = ''
      shopt -s nullglob
      D=/sys/bus/pci/devices
      # Child PCI devices only: ports also hold service devices such as
      # 0000:0a:04.0:pcie210.
      kids() { kids=("$1"/0000:??:??.?); }
      is_bridge() { [[ -e $1/class && $(< "$1/class") == 0x0604* ]]; }
      reg() { setpci -s "''${1##*/}" "$2"; }
      reset_bridge() {
        # Hold it awake: a runtime resume restores the saved registers,
        # undoing the writes.
        echo on > "$1/power/control"
        setpci -s "''${1##*/}" SECONDARY_BUS.b=00 SUBORDINATE_BUS.b=00 \
          MEMORY_BASE.w=fff0 MEMORY_LIMIT.w=0000 \
          PREF_MEMORY_BASE.w=fff0 PREF_MEMORY_LIMIT.w=0000 \
          PREF_BASE_UPPER32.l=0 PREF_LIMIT_UPPER32.l=0
      }

      # The dock's and monitor's add events land while their PCIe scan is
      # still settling.
      sleep 3

      for dev in "$D"/*; do
        is_bridge "$dev" || continue
        [[ $(reg "$dev" SECONDARY_BUS) == $(reg "$dev" SUBORDINATE_BUS) ]] || continue
        starved=
        kids "$dev"
        for c in "''${kids[@]}"; do is_bridge "$c" && starved=1; done
        [[ -n $starved ]] || continue
        up=$(dirname "$(readlink -f "$dev")")
        is_bridge "$up" || continue

        echo "''${dev##*/} has one bus but a bridge behind it; re-numbering the ports under ''${up##*/}"
        # The bridges behind it keep whatever single-bus numbering the failed
        # scan gave them unless cleared too. Drop their own subtrees first,
        # while config accesses still route through them.
        for c in "''${kids[@]}"; do
          kids "$c"
          for g in "''${kids[@]}"; do echo 1 > "$g/remove"; done
          is_bridge "$c" && reset_bridge "$c"
          echo 1 > "$c/remove"
        done
        ports=()
        kids "$up"
        for p in "''${kids[@]}"; do
          kids "$p"
          is_bridge "$p" && (( ''${#kids[@]} == 0 )) && ports+=("$p")
        done
        for p in "''${ports[@]}"; do reset_bridge "$p"; done
        for p in "''${ports[@]}"; do echo 1 > "$p/remove"; done
        echo 1 > "$up/rescan"
        exit 0
      done
    '';
  };
}
