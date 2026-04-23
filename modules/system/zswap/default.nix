# zswap — compressed write-back cache for swap pages.
#
# Intercepts pages destined for the swap device, compresses them in a
# dynamically-allocated RAM pool, and only flushes cold pages to disk
# when the pool fills.  Reduces swap I/O on machines that already have
# disk-based swap (disko swapfiles or partitions).
#
# On kernel 6.9+ zswap is enabled by default, but with lzo-rle.
# We override to zstd for better compression at comparable speed.
{ ... }:
{
  boot.kernelParams = [
    "zswap.enabled=1"
    "zswap.compressor=zstd"
    "zswap.max_pool_percent=20"
  ];
}
