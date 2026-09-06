# Carousel location rejection — NVG-0175

Run `4bcfeb84f9894b25b56b276faaea9c9e` failed its first point, NVG-0175,
with `DWELL_GROUND_FAILED`. NVG-0175 is `downtown_filler_06`, Downtown
Apartments, at `-1626 / 61 / -1793` in Wasteland.

The point initially grounded and remained within the position bound, but did
not renew three grounded samples during the five-second dwell plus two-second
grace. Health remained 100 and origin restoration succeeded. This is a
confirmed location rejection; continuation begins at NVG-0176.

Evidence identity:

- events TSV: 939 bytes, SHA-256
  `65DCBCDD1D5196868114E975A74A3AA0EA90FDB8E895CED8C84058F54FE6CD65`;
- result JSON: 360 bytes, SHA-256
  `2FA6BA7066BBD26B5DE0C790A70BF17A32EB5FE4FFF58364BE683196A3F000B9`.
