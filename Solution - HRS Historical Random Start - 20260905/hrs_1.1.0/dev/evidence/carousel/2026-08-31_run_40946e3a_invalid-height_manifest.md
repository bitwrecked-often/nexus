# Carousel incident evidence — run 40946e3a

Run `40946e3af00842e3ad81fe282fa0cd26` is preserved as defect evidence, not
location-approval evidence. The operator observed repeated landings on light
poles and requested an emergency stop at `NVG-1392` (`street_light_02`).

The run reported 1,391 point passes before the stop, but those results are
invalid for street-level safety. The runtime catalog included the teleport
menu's small decoration entries, and both its anchor and offset resolver used
`World.GetHeight`, which returns the highest block at an X/Z coordinate. At the
observed point the catalogued ground was Y 61 while the requested position was
near the pole top.

The stop exposed a second defect: while the stop file remained present, the
runtime re-entered failure handling during its Restore stage. The final restore
did succeed after the flag was cleared, but the raw log contains 28,783
duplicate `POINT_FAIL` and 28,783 duplicate `RESTORE_BEGIN` lines.

Evidence identity:

- source TSV: 8,388,436 bytes, 63,135 lines, SHA-256
  `0EB077818DDE7F129D3A6DB3623842F33B36C09723F29DE8245B323F48D34EB1`;
- compressed source TSV: `2026-08-31_run_40946e3a_invalid-height_events.zip`,
  376,985 bytes, SHA-256
  `1187AFE25A817D011AA9275EEFFD290CAD233AD55B498C49A1B765BE7B6DD571`;
- terminal result: `2026-08-31_run_40946e3a_invalid-height_result.json`,
  350 bytes, SHA-256
  `B7B221300CECB25C843D1B27C60FD7D9B32FCB51F32DEAE385F7C5DAB9D26A70`.

No point, including NVG-1392, is rejected from this run. `MANUAL_STOP` is an
operator/system result, not a location failure. All eligible locations must be
retested from the beginning under the corrected methodology.

First corrective-build identity: 80,384-byte QA DLL, 745 active non-small entries,
SHA-256 `163059AF05CC4D457F52FEF9C1501AEFB57B15FAB2783DAAC422A556E77DCB9E`.
The deterministic double build matched byte-for-byte, but the artifact was
later retired after its pre-load terrain query failed closed at NVG-0001.
