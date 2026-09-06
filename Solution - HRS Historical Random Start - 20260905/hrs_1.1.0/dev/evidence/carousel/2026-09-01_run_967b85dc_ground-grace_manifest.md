# Carousel ground-grace tuning — run 967b85dc

Run `967b85dc505f49b8b8d8f2bc6dd5dff3` passed NVG-0170 and NVG-0171 at
health 100. NVG-0172 then ended with `DWELL_GROUND_FAILED`. It had completed
the initial grounded settle, retained health 100, and remained within about
0.7 metres of its landing, but `onGround` was false on the single dwell-deadline
frame.

This is test-timing evidence, not a location rejection. The continuous
position bound successfully distinguished it from the earlier 42–47 metre
falls. The corrected runtime allows two seconds of grace and requires three
renewed grounded samples. Retry from NVG-0172.

Evidence identity:

- events TSV: 1,918 bytes, SHA-256
  `D703F7E812FF807BBA83B827666420010779374BEFB95E09BF9D4B4A95B50565`;
- result JSON: 360 bytes, SHA-256
  `F556962C99878CF8E70CA0DAED4F737135CD2F3C9A43F27B9E55DA8B7652F810`.
