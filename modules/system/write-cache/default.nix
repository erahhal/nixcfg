# Dirty page writeback tuning.
#
# The kernel defaults use percentages of total RAM (dirty_ratio=20%,
# dirty_background_ratio=10%).  On machines with large memory (e.g. 60 GB)
# this lets gigabytes of dirty pages accumulate before flushing, which stalls
# I/O for tens of seconds — especially visible on NFS where the network link
# is the bottleneck, but also noticeable with any sustained write workload.
#
# Switching to absolute byte limits keeps flushes small and frequent.
{ ... }:
{
  boot.kernel.sysctl = {
    "vm.dirty_background_bytes" = 64 * 1024 * 1024;  # 64 MB — start background flush
    "vm.dirty_bytes" = 128 * 1024 * 1024;             # 128 MB — hard cap, block writers
  };
}
