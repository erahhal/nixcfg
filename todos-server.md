Server TODOs
============

* Backups

* ZFS tuning

* iLO upgrade

* other services

* perf tuning

* journalctl -xb

## Likely not a problem
Mar 08 20:54:07 sicmundus kernel: ACPI BIOS Warning (bug): 32/64X length mismatch in FADT/Pm1aControlBlock: 16/32 (20210730/tbfadt-564)
Mar 08 20:54:07 sicmundus kernel: ACPI BIOS Warning (bug): 32/64X length mismatch in FADT/Pm2ControlBlock: 8/32 (20210730/tbfadt-564)
Mar 08 20:54:07 sicmundus kernel: ACPI BIOS Warning (bug): Invalid length for FADT/Pm1aControlBlock: 32, using default 16 (20210730/tbfadt-669)
Mar 08 20:54:07 sicmundus kernel: ACPI BIOS Warning (bug): Invalid length for FADT/Pm2ControlBlock: 32, using default 8 (20210730/tbfadt-669)

## Not a problem: https://xcp-ng.org/forum/topic/3128/acpi-spcr-unexpected-spcr-access-width-defaulting-to-byte-size
Mar 08 20:54:07 sicmundus kernel: ACPI: SPCR: Unexpected SPCR Access Width.  Defaulting to byte size

## Not a problem: https://askubuntu.com/questions/1331090/dmar-firmware-bug-broken-bios
## Only an issue if using a GPU passthrough to a windows virtual machine
Mar 08 20:54:07 sicmundus kernel: DMAR: [Firmware Bug]: No firmware reserved region can cover this RMRR [0x00000000000e8000-0x00000000000e8fff], contact BIOS vendor for fixes
Mar 08 20:54:07 sicmundus kernel: DMAR: [Firmware Bug]: Your BIOS is broken; bad RMRR [0x00000000000e8000-0x00000000000e8fff]
                                  BIOS vendor: HP; Ver: P80; Product Version:
Mar 08 20:54:07 sicmundus kernel: DMAR: RMRR base: 0x000000addee000 end: 0x000000addeefff
Mar 08 20:54:07 sicmundus kernel: DMAR: RMRR base: 0x000000c0000000 end: 0x000000dfffffff
Mar 08 20:54:07 sicmundus kernel: DMAR: [Firmware Bug]: No firmware reserved region can cover this RMRR [0x00000000c0000000-0x00000000dfffffff], contact BIOS vendor for fixes
Mar 08 20:54:07 sicmundus kernel: DMAR: [Firmware Bug]: Your BIOS is broken; bad RMRR [0x00000000c0000000-0x00000000dfffffff]
                                  BIOS vendor: HP; Ver: P80; Product Version:

## Not a problem: https://www.serveradminblog.com/2015/04/firmware-bug-the-bios-has-corrupted-hw-pmu-resources/
Mar 08 20:54:07 sicmundus kernel: [Firmware Bug]: the BIOS has corrupted hw-PMU resources (MSR 38d is 330)

## Not a problem: https://askubuntu.com/questions/1250040/how-do-i-fix-mds-cpu-bug-present-and-smt-on-data-leak-possible-errors-from-lo
## BUT: Update CPU microcode for safety
Mar 08 20:54:07 sicmundus kernel: MDS CPU bug present and SMT on, data leak possible. See https://www.kernel.org/doc/html/latest/admin-guide/hw-vuln/mds.html for more details.
Mar 08 20:54:07 sicmundus kernel:   #5  #6  #7

## Normal: https://bbs.archlinux.org/viewtopic.php?id=270199
Mar 08 20:54:07 sicmundus kernel: ENERGY_PERF_BIAS: Set to 'normal', was 'performance'

## Not a problem it seems?
Mar 08 20:54:07 sicmundus kernel: pci 0000:00:01.0: bridge has subordinate 04 but max busn 05

## Not a problem - ZFS uses a non-compatible license
Mar 08 20:54:08 sicmundus kernel: spl: loading out-of-tree module taints kernel.
Mar 08 20:54:08 sicmundus kernel: znvpair: module license 'CDDL' taints kernel.
Mar 08 20:54:08 sicmundus kernel: Disabling lock debugging due to kernel taint

## Not a problem
Mar 08 20:54:08 sicmundus kernel: hpsa 0000:07:00.0: can't disable ASPM; OS doesn't have ASPM control
Mar 08 20:54:08 sicmundus kernel: hpsa 0000:07:00.0: Logical aborts not supported
Mar 08 20:54:08 sicmundus kernel: hpsa 0000:07:00.0: HP SSD Smart Path aborts not supported

## Not a problem
Mar 08 20:54:08 sicmundus kernel: hpsa can't handle SMP requests

## Is IPv6 working?
Mar 08 20:54:09 sicmundus systemd-sysctl[1230]: Couldn't write '2' to 'net/ipv6/conf/enp4s0f0/use_tempaddr', ignoring: No such file or directory

## THIS IS A REAL PROBLEM
Mar 08 20:54:09 sicmundus systemd[1]: home-erahhal.mount: Mount process exited, code=exited, status=128/n/a
░░ Subject: Unit process exited
░░ Defined-By: systemd
░░ Support: https://lists.freedesktop.org/mailman/listinfo/systemd-devel
░░
░░ An n/a= process belonging to unit home-erahhal.mount has exited.
░░
░░ The process' exit code is 'exited' and its exit status is 128.
Mar 08 20:54:09 sicmundus systemd[1]: home-erahhal.mount: Failed with result 'exit-code'.
░░ Subject: Unit failed
░░ Defined-By: systemd
░░ Support: https://lists.freedesktop.org/mailman/listinfo/systemd-devel
░░
░░ The unit home-erahhal.mount has entered the 'failed' state with result 'exit-code'.
Mar 08 20:54:09 sicmundus systemd[1]: Failed to mount /home/erahhal.
░░ Subject: A start job for unit home-erahhal.mount has failed
░░ Defined-By: systemd
░░ Support: https://lists.freedesktop.org/mailman/listinfo/systemd-devel
░░
░░ A start job for unit home-erahhal.mount has finished with a failure.
░░
░░ The job identifier is 29 and the job result is failed.
Mar 08 20:54:09 sicmundus systemd[1]: Dependency failed for Home Manager environment for erahhal.
░░ Subject: A start job for unit home-manager-erahhal.service has failed
░░ Defined-By: systemd
░░ Support: https://lists.freedesktop.org/mailman/listinfo/systemd-devel
░░
░░ A start job for unit home-manager-erahhal.service has finished with a failure.
░░
░░ The job identifier is 137 and the job result is dependency.

## Not a problem: https://bugs.archlinux.org/task/56989
## Create /etc/avahi/services to get rid of error
Mar 08 21:03:53 sicmundus avahi-daemon[3548]: Failed to read /etc/avahi/services.

## Not a problem: https://askubuntu.com/questions/1190002/powertop-autotune-error-cannot-load-from-file
Mar 08 21:03:58 sicmundus powertop[4493]: modprobe cpufreq_stats failedLoaded 0 prior measurements
Mar 08 21:03:58 sicmundus powertop[4493]: RAPL device for cpu 0
Mar 08 21:03:58 sicmundus powertop[4493]: RAPL Using PowerCap Sysfs : Domain Mask 7
Mar 08 21:03:58 sicmundus powertop[4493]: RAPL device for cpu 0
Mar 08 21:03:58 sicmundus powertop[4493]: RAPL Using PowerCap Sysfs : Domain Mask 7
Mar 08 21:03:58 sicmundus powertop[4493]: Devfreq not enabled
Mar 08 21:03:58 sicmundus powertop[4493]: glob returned GLOB_ABORTED
Mar 08 21:03:59 sicmundus powertop[4493]: Leaving PowerTOP
Mar 08 21:03:59 sicmundus powertop[4493]: Cannot load from file /var/cache/powertop/saved_parameters.powertop
Mar 08 21:03:59 sicmundus powertop[4493]: File will be loaded after taking minimum number of measurement(s) with battery only
Mar 08 21:03:59 sicmundus powertop[4493]: Cannot load from file /var/cache/powertop/saved_parameters.powertop
Mar 08 21:03:59 sicmundus powertop[4493]: File will be loaded after taking minimum number of measurement(s) with battery only
Mar 08 21:03:59 sicmundus systemd[1]: Finished Powertop tunings.
