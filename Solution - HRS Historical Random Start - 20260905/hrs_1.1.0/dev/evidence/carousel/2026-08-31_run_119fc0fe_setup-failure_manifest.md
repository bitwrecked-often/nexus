# Carousel setup failure — run 119fc0fe

Run `119fc0fe611a4700afd78f2532c334cd` is setup-failure evidence, not
NVG-0029 location evidence. During the 30-second preflight the player moved
about 59 metres and health fell from 100 to 11 after loading on a roof under
normal gravity. The later NVG-0029 `CHUNK_TIMEOUT` cannot reject that point.
Origin restoration succeeded.

Evidence identity:

- events TSV: 651 bytes, SHA-256
  `B22B5A4AE261CE8733ED8D413CC3F1E09585450E19FCDFBFBDA3B5ED892AEE1E`;
- result JSON: 351 bytes, SHA-256
  `F54F408D8210DD714699D0829B8A5512F0A9E19BEC6E6D0F75A74977B5B3B1C2`.

Corrective action: reject preflight health loss or movement beyond three metres
as `PREFLIGHT_CHANGED` before beginning any point. Retry from NVG-0029.
