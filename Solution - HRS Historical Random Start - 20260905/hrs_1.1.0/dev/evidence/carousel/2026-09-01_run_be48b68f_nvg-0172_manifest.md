# Carousel location rejection — NVG-0172

Run `be48b68f4f09450982d50ccaf1532097` retested NVG-0172 under the corrected
position-bound and ground-grace contract. The point initially grounded near
Y 59, then fell to Y 55.397 within 0.66 seconds, exceeding the three-metre
landing tolerance. The runtime stopped with `DWELL_POSITION_FAILED` at health
100 and restored origin successfully.

NVG-0172 is `downtown_filler_02`, Le Spank, at `-1543 / 61 / -1726` in
Wasteland. This clean retry resolves the earlier timing ambiguity and confirms
a location rejection. Continuation begins at NVG-0173.

Evidence identity:

- events TSV: 952 bytes, SHA-256
  `603964EC7B903D095656A10609FF9E9A29D6551A252CDBB3E5051C04A0BF1D08`;
- result JSON: 362 bytes, SHA-256
  `5D8C47BDA5D00B5C043F4C5B7A07E9372FA027141DF8CA6BE38888D4DA87BCFA`.
