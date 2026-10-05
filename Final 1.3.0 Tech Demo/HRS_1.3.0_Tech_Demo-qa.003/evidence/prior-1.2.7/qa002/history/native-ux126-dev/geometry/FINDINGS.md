# Native manager geometry, 2026-10-04

DEV result: the integrated manager passes **224 empirical assertions and 28 settled captures**, using the actual native manager staged unchanged into an inert TEMP game fixture. The tested source SHA-256 is `EE2750642C80EBE78EE5627F1AE1003229D9E7FF3B16A8F8EF45EFC894522F3D`. The aggregate verification.json binds each profile record and screenshot to exact bytes. This is DEV fixture evidence; independent QA's original physical display/resize retests remain Pending.

| Original finding | Implemented correction | Native fixture result |
| --- | --- | --- |
| HRS-UX-001, repeated fitting shrinks width | Fit changes outer Height and normal Bounds, retaining outer Width; it never copies scrollbar-reduced ClientSize.Width into a new size | Equivalent Any/Chosen/Weighted states retain 712/1060/1408/1582 outer units at Form.Scale 1/1.5/2/2.25 |
| HRS-UX-002, growth behind taskbar | Clamp final normal outer size and location to Screen.FromControl WorkingArea | Repeated fits and a deliberate near-bottom placement finish inside the reported work area |
| HRS-UX-003, bottom actions clipped at minimum | Settle wrapped rows, inner table, surface and frame; publish explicit AutoScrollMinSize; retain user's scroll position through relayout | API-driven native permitted-minimum resize followed by maximum scrolling fully exposes Uninstall and Game details; each action is individually reachable; expanded final text reaches its bottom |

The original layout plus only the geometry patch also passed 50 assertions; its separate legacy record was retained. The compact integrated campaign adds fresh weights-dialog return and minimize/restore checks at every synthetic factor.

Two related mechanisms appeared during empirical investigation:

- AutoSize relayout scrolled the focused Game Name textbox into view, moving maximum scrolling from -736 to -229 in the original minimum layout. Explicitly preserving the previous scroll position through extent updates prevents that movement. The final original-layout bottom position was -736 with maximum 1056 and page 321.
- This host's .NET Framework maximized-to-normal restoration lost exactly one 17-unit scrollbar width: 753 became 736, despite the normal RestoreBounds initially reporting 753. The helper records normal outer bounds and uses one BeginInvoke after the native transition completes to restore them. The final integrated campaign verifies both maximize/restore and minimize/restore exact outer size at all four factors.

`Initialize-HrsManagerGeometryEvents` distinguishes a native size change from a move by comparing outer Size across ResizeBegin/ResizeEnd. Manual sizing remains selected through policy projection, dialog return and status refresh. Automatic fitting leaves minimized/maximized windows alone. The fitting helper rechecks the current monitor work area at resize completion and activation. The observed host exposed one screen, so no second-monitor qualification is claimed.

## Reproduction

Run in a fresh Windows PowerShell 5.1 STA process for each factor:

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File hrs_1.2.6/dev/qa/native-ux-round2/geometry/Test-ManagerGeometry.ps1 -Scale 1.5 -ManagerPath hrs_1.2.6/dev/ui/p0158.ps1 -Integrated
```

Allowed factors are 1, 1.5, 2 and 2.25. The harness does not edit the manager. It copies the manager and existing native launcher modules to TEMP, injects only a harmless test driver, and opens an inert game folder. It uses native WM_ENTERSIZEMOVE/SetWindowPos/WM_EXITSIZEMOVE to exercise WinForms' resize-event path. It never applies settings, launches the game, removes a real installation or changes display preferences. The test driver does pump messages to let native UI settle; the shipping geometry code does not perform nested event pumping.

## Evidence limit

Form.Scale changes control geometry, with original point-size fonts; it is not actual Windows compatibility/DPI scaling. The API-driven native resize is not a physical mouse drag. These records therefore do not close the original QA sizing attempt or the current customer case ledger. The returning customer package still needs actual 100/150/200/225% display profiles, the original 200% physical minimum drag, repeated 150% selection stress, any supported secondary 300% profile, human legibility, keyboard/Narrator/High Contrast and native popup checks.

The frozen qa.002 ZIP/ledger and QA's failed-attempt evidence remain the original record. Gameplay and operator transaction checks are outside this geometry fixture.
