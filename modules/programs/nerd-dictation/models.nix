# Vosk model catalog (English).
#
# Sizes/urls come from: https://alphacephei.com/vosk/models
#
# To refresh a hash:
#   nix-prefetch-url --type sha256 --unpack <url> | nix hash convert --hash-algo sha256
#
# Small models stream with very low latency on CPU (ideal for real-time
# dictation). Large models are slower to load but more accurate; "lgraph"
# variants are a middle ground (accuracy closer to the big model, ~130 MB).
{
  small-en-us-0_15 = {
    description = "US English, small (~40 MB). Best for low-latency dictation.";
    url = "https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip";
    hash = "sha256-CIoPZ/krX+UW2w7c84W3oc1n4zc9BBS/fc8rVYUthuY=";
  };

  en-us-0_22-lgraph = {
    description = "US English, dynamic-graph variant of 0.22 (~130 MB).";
    url = "https://alphacephei.com/vosk/models/vosk-model-en-us-0.22-lgraph.zip";
    hash = "sha256-GVheflRwix9PnQjIVFl1mkNRduaYRNvZGhTZaobTibY=";
  };

  en-us-0_22 = {
    description = ''
      US English, full 0.22 model (~1.8 GB).
      Highest accuracy of the non-gigaspeech English Vosk models
      (WER ~5.7% on librispeech test-clean). Still streams in real time
      on a modern laptop CPU; ~2 GB RAM once loaded.
    '';
    url = "https://alphacephei.com/vosk/models/vosk-model-en-us-0.22.zip";
    hash = "sha256-kakOhA7hEtDM6WY3oAnb8xKZil9WTA3xePpLIxr2+yM=";
  };
}
