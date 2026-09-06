# Carousel dwell-invariant incident — run b13092e0

Run `b13092e0efa242d09719bac32eb00f8b` exposed a false-pass defect. NVG-0167
(`downtown_building_03`, Stand Tower) initially settled near Y 60, then fell to
Y 17.927 during its five-second dwell. The old dwell stage checked health and
world bounds but did not retain the landing-position invariant, so it counted
the point as passed. The run was manually stopped at NVG-0170 and restored
origin successfully.

A landing-to-pass audit of all 166 pass records from the clean full-catalog
segments found two outliers above the three-metre tolerance:

- NVG-0075 (`canyon_gift_shop`) moved 47.399 metres, from landing Y 56 to
  pass Y 9.148;
- NVG-0167 moved 42.073 metres, from landing Y 60 to pass Y 17.927.

The other 164 records ended within three metres of their proven landing; the
largest remaining displacement was 1.19 metres. NVG-0075 and NVG-0167 are
location rejections supported by direct runtime evidence. The corrective
runtime continuously bounds dwell position and requires final ground contact.

Incident evidence identity:

- events TSV: 3,804 bytes, SHA-256
  `BFFC132DB5D3700E049C0F35E3C28A82DA0A7B80C9BCBFC6AC375E72CC3DF664`;
- result JSON: 352 bytes, SHA-256
  `D8BF4389486D32E06643A9E243912BF6D7CF17ECD5C195501ACD5CBFAABEC8ED`.
