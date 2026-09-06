# GUI V2 Work Manifest

## Status

Ready for owner GUI review. The DEV-side GUI matches the reviewed repo-side
source and passes parser, smoke, label-fit, and current-display visual checks.
No runtime, XML, tuning, cap, backup, restore, removal, or package-contract
behavior changed.

The full release suite passes 27 of 29 checks. Its two expected failures are
the technical-freeze guard detecting the authorized GUI clarity delta. Owner
acceptance and a separately scoped governance/freeze update are required before
candidate preparation.

## Answers Encoded In The GUI

- `Compare Values` opens a fresh read-only report; it does not refresh the
  visible table or write files.
- `Choose Game Folder` selects the game root and does not run the mod.
- `Mods Folder` opens `<game root>\Mods` in Explorer.
- `Brutal Science` is an explicit, confirmed stress-test option that backs up
  `serverconfig.xml` before setting the animal cap to `999`.
- `Restore Cap` uses the newest matching backup; it is not tied to the current
  checkbox state and does not force a hard-coded default.
- `Remove Mod` removes only this solution's mod folder; it does not restore the
  cap.
- `Select animals to tune` controls which entities are included in the next
  install or reinstall.

The complete question-by-question audit, exact changed-file list, layout notes,
hash, and validation results are in the corresponding repo-side
`GUI_V2_MANIFEST.md` and `GUI_FEEDBACK_V2.md`.

No build, promotion, upload, tag, or publication was performed. Historical
4.0.1 artifacts were not modified.

## Round Two — Larger-LLM Clarity Review

These notes are requirements for the next reasoning and GUI wording pass:

- Explain `Choose Game Folder` plainly: it means the 7 Days to Die game root,
  not the `Mods` folder. State why the tool needs it and whether the user must
  choose it every time.
- Rename `Compare Values` to `Validate Current Game Settings`.
- Define `Restore Cap` in simple language and explain the GUI action: it puts
  the animal-cap value back from the latest matching backup.
- Define `Brutal Science` simply: an optional stress test that temporarily
  raises the animal cap to 999 after backing up the server configuration; it
  does not spawn animals by itself.
- Center the table headlines and use this readable order and wording:
  `Animal | Level | Action | Current | Result`.

The wording must be understandable without prior knowledge of mod folders,
server configuration, backups, or the term “cap.”
