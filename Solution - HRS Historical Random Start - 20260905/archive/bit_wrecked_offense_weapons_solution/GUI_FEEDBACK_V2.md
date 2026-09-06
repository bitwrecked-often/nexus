# GUI Feedback V2

This is the reviewed behavior and design record for the minimalist 4.1.x GUI
clarity pass.

## Answers

- `Compare Values` performs a fresh read and opens a read-only comparison
  report. It does not change files or refresh the visible table.
- Clicking or editing the game-folder field does not run the mod.
- `Choose Game Folder` selects the 7 Days to Die game root.
- `Mods Folder` opens `<game root>\Mods` in Windows Explorer; it is a different
  action from choosing the game root.
- `Brutal Science` is an optional stress test that backs up `serverconfig.xml`
  and raises `MaxSpawnedAnimals` to `999` after confirmation. It does not create
  animals by itself.
- `Restore Cap` uses the newest matching Bit Wrecked backup. It does not require
  the checkbox to be selected, does not remove the mod, and does not force a
  hard-coded game default.
- `Remove Mod` removes the owned mod folder. It does not restore the cap.
- Animal checkboxes choose which animals are included in the next install or
  reinstall; `All` applies one level to every listed animal.

The corresponding Nexus-repo document is the full authority for wording and
validation results.
