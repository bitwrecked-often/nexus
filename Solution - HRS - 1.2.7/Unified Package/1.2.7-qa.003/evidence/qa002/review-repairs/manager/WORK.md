# Manager review repairs — 2026-10-04

F3 and F4 are implemented in the existing `dev/ui/p0158.ps1` manager.
The recipe, generated controls, artifact pins, Apply/acknowledgement workflow,
DEV/customer branch selection and game installation were not changed by this work.

## Changed behavior

- An invalid game-folder choice now gives a native, plain-language warning and
  reopens the chooser. Single discovered installations still bypass the chooser;
  multiple installations still require explicit selection. Cancel returns no
  game folder and the manager entry exits successfully before building its form.
- A failed operation retains its diagnostic in Game details. Classified Launch
  errors stop occupying the main status once their original process, settings,
  acknowledgement or installation guard is positively resolved. Current guards
  determine available actions and new guidance. Recurring blockers are reported
  again. Apply/recovery failure diagnostics and their launch latch remain intact;
  unclassified launch errors are retained. Existing history records are unchanged.

## Focused DEV evidence

`Test-ManagerReviewRepairs.ps1` passed **26 assertions** under Windows PowerShell
5.1.26100.9549 against source SHA-256
`E6CC1E0AFE8E271E6F9DBC8685EC4DDDCB8E9727FDA46758916CA6810D9067D5`.
The receipt is `verification.json` in this directory.

The harness extracts the actual production selection/status functions and
Launch callback, uses native controls and controlled read-only dependencies,
captures dialog decisions and uses inert files in an isolated temporary root.
A separate process executes the actual cancellation entry assignment/guard
and exits zero. Tests cover wrong-folder retry/cancellation, single/multiple
discovery, persistent and resolved process blockers, recurring/new blockers,
policy validation failure after Steam recovery, settings reversion, Apply and
acknowledgement latches, installation drift and unclassified errors. It never
invokes Apply, uninstall or a real process launch.

Initial fixture attempts exposed two harness setup gaps (an omitted extracted
dependency and an unset child-process ManagerRoot); these were corrected before
the passing run. They were not product failures. The earlier 24/25-assertion
runs were superseded by the final 26-assertion receipt. Root will bind broader
callback regression to the final source after runtime/package pins are updated.

## Preserved original bytes

`manager.before.ps1` matches the owner's earlier read-only review snapshot:
`387C0B8C536194E7F85B2C935C115A4AEAE3A4BB55DD2D4990E792840463EF65`.
It was reconstructed by reversing only this agent's bounded F3/F4 patch;
it was not a contemporaneous pre-edit copy. `before-reconstruction.json` records
the exact match and `Reconstruct-ManagerBefore.ps1` makes the reversal inspectable.
Do not overwrite this preserved input when final runtime pins change.

These are isolated DEV fixtures, not independent customer QA or actual
Narrator/DPI validation. No live Apply, uninstall, game launch, runtime build,
contract update, export or publication occurred in this agent's work.
