# Module Host 0.0.1 Manual Accessibility Checklist

Copyright (C) 2026 Bit Wrecked contributors  
SPDX-License-Identifier: GPL-3.0-or-later

Status: **pending human observation**.

The automated acceptance harness verifies structural accessibility evidence:
DPI-aware startup, accessible names and descriptions, roles, tab order,
high-contrast code paths, and dynamic result-row metadata. Automation cannot
honestly substitute for the human checks below.

Run this checklist with the released launcher:

    ..\7DTD_BitWreckedModuleHost.bat

Record Windows version, display scale, assistive technology version, date,
tester, result, and notes for each run. Do not mark a row passed without
direct observation.

## Keyboard-only

- [ ] Forward Tab traversal reaches every interactive control once in a
  sensible order.
- [ ] Shift+Tab traverses the same controls in reverse without trapping focus.
- [ ] The module selector opens from the keyboard and all three reviewed
  modules can be selected.
- [ ] Enter and Space activate focused buttons according to standard Windows
  behavior.
- [ ] Escape collapses the activity-log panel without exiting or discarding
  state.
- [ ] Focus remains visible when changing modules, choosing a folder, starting
  validation, and expanding or collapsing the log.

## Screen reader

- [ ] Narrator announces the module selector name, selected module, version,
  and state.
- [ ] Narrator announces the game-folder field, buttons, status region,
  workspace heading, result rows, and activity log with useful names.
- [ ] Module switching announces the new workspace without implying that
  validation occurred.
- [ ] Validation completion is understandable without relying on color alone.

## Windows visual modes

- [ ] At 100% display scale, no label, row, button, focus indicator, or status
  message is clipped.
- [ ] At 150% display scale, the same content remains readable and reachable.
- [ ] In Windows High Contrast, text, borders, focus, selection, status, and
  disabled states remain distinguishable.
- [ ] Success, warning, unavailable, and error states remain distinguishable
  without color as the only signal.

## Signoff

- [ ] All failures are documented with reproduction steps.
- [ ] Required corrections were retested.
- [ ] A named human reviewer approved the completed checklist.

Until this checklist is completed, the build has automated accessibility
coverage but not a human accessibility signoff.
