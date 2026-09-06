# Carousel location rejection — NVG-0124

Run `eabb6a792a334e62984e4ee5e3f2f0fd` cleanly passed NVG-0029 through
NVG-0123 (95 points) at health 100, then failed closed at NVG-0124 with
`SETTLE_FAILED`.

NVG-0124 is `crater_deco_01` at catalog coordinates `-1755 / 61 / -1535`
in Wasteland. The player remained exactly at the terrain landing for the full
15-second settle window with health 100 but never produced the required three
grounded samples. Origin restoration succeeded.

This is a confirmed location rejection. NVG-0124 is recorded in
`dev/qa/carousel-rejections.json`; continuation begins at NVG-0125. Combined
with the prior clean segment, 122 eligible points have passed so far.

Evidence identity:

- events TSV: 46,732 bytes, SHA-256
  `EC6F2B4D42DEA1C166D05DD86588E43E1162FD1E2C3C6BA9A9AF9E157CDCA4AF`;
- result JSON: 355 bytes, SHA-256
  `45C8D17EEF002487D2E33E092880C6E8EB573AAA31ABE77C532B5B49F1E9D7D4`.
