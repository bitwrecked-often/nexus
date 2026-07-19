# GUI Feedback V2

This is the reviewed behavior and design record for the minimalist 4.1.x GUI
clarity pass.

## Answers To User Questions

### Does Compare Values Refresh The Current Column?

No. **Compare Values** performs a fresh read and opens a read-only report that
compares game, installed, and selected values. It does not change files or
refresh the visible table. The label and tooltip now describe that behavior.

Final label: `Compare Values`

### Brutal Science

Brutal Science is an optional stress-test mode. When confirmed during install
or reinstall, it backs up
`serverconfig.xml` and raises `MaxSpawnedAnimals` to `999`. It removes a global
safety limit; it does not create animals by itself.

The risk and backup behavior are explained directly in the cap panel and again
in the confirmation dialog.

### Does Clicking The Directory Run The Mod?

No. Clicking or editing the game-folder field only selects text or changes the
path the tool will inspect. It does not install, launch, or run the mod.

### Browse

**Choose Game Folder** opens a normal Windows folder chooser for selecting the
7 Days to Die game root. It starts at the current path when that path exists.
It does not run the mod or browse a catalog of other mods.

Final label: `Choose Game Folder`

### Mods Folder

**Mods Folder** opens the game's `Mods` folder in Windows Explorer. It does not
open the Nexus repository or a list of other mods.

### Choose Game Folder Versus Mods Folder

They are different:

- `Choose Game Folder` changes the game root used by the tool.
- `Mods Folder` opens `<game root>\Mods` in Windows Explorer. It creates that
  directory first if it does not exist.

### Remove Versus Restore Cap

They are different actions:

- **Remove Mod** removes this mod's folder from the game's `Mods` directory.
- **Restore Cap** restores `serverconfig.xml` from the newest timestamped
  Bit Wrecked cap backup.

Remove Mod does not restore the cap. Restore Cap is available only when a
matching Bit Wrecked backup exists. The checkbox does not need to be selected
at restore time. Restore uses the newest matching backup and restores its prior
value; it does not force a hard-coded game default.

Final labels: `Remove Mod` and `Restore Cap`

### Select Animals

The animal checkboxes choose which Wasteland animals will be included in the
next install or reinstall. Selecting an animal activates its tuning slider.
The `All` control includes every listed animal and applies one shared level.

Final section title: `Select animals to tune`

## Final V2 Clarity Design

1. Use `Compare Values` for the read-only report action.
2. Use `Choose Game Folder` for game-root selection and give it enough width.
3. Keep `Mods Folder` as the distinct Windows Explorer action.
4. Explain Brutal Science's backup and cap behavior directly in the panel.
5. State visibly that Restore Cap uses the newest backup and Remove Mod is
   separate.
6. Use `Select animals to tune` and explain each animal checkbox by tooltip.
7. Add concise accessible names/descriptions to the clarified controls.
