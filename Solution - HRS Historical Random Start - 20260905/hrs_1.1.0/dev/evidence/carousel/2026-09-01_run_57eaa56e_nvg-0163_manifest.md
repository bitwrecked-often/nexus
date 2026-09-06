# Carousel location rejection — NVG-0163

Run `57eaa56e86264524be2c0a1c78299cdd` passed NVG-0125 through NVG-0162
(38 points) at health 100, then failed closed at NVG-0163 with
`SAFE_LANDING_FAILED`.

NVG-0163 is `docks_04`, Middleman Docks, at `-1400 / 44 / 599` in Pine
Forest. It is a `NavOnly` waterfront prefab. After its chunk loaded, the native
ground/headroom check found no safe landing within the bounded 32-block search.
The runtime did not commit an unsafe landing and restored origin successfully.

This is a confirmed location rejection. NVG-0163 is recorded in
`dev/qa/carousel-rejections.json`; continuation begins at NVG-0164. Cumulative
clean passes are 160.

Evidence identity:

- events TSV: 19,212 bytes, SHA-256
  `909F54B5FF5A4AABA2530F03EBD01F03B797B54421385F532254A191D47BB971`;
- result JSON: 361 bytes, SHA-256
  `00E511313EEAEA62AF37085EA86925500CEA820C663E5CB465462817524C8FBD`.
