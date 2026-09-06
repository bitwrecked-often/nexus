# GUI V3 Work Manifest — Version 4.1.1

## Purpose

This is a duplicated 4.1.0 GUI work lane for the next clarity pass. The
4.1.0 source remains unchanged until the 4.1.1 review is accepted.

## Required Changes

- Keep the title/version display at `Version 4.1.1`.
- Explain `Choose Game Folder` in plain language: select the 7 Days to Die
  game folder, not the `Mods` folder. Explain that the tool needs the game
  folder to find `Mods` and `serverconfig.xml`.
- Rename `Compare Values` to `Validate Current Game Settings`.
- Center the complete validation area: place the `Validate Current Game
  Settings` button in the horizontal middle, center-justify its label, and place
  the dynamic selection summary in a separate centered line above the button.
  The two controls must never overlap.
- Explain the bottom `Restore Global Limit Only` state: it replaces
  `serverconfig.xml` with the newest matching backup and verifies the restored
  animal-cap value. There is no separate Restore button.
- Define `Brutal Science` simply: an optional stress test that backs up the
  server configuration and raises the animal cap to 999. It does not create
  animals by itself.
- Present one visible cap checkbox labeled
  `Raise Animal Spawn Cap - Brutal Science` and remove the separate Restore button.
  Checked enables `Apply Limit Cap Only`. When unchecked and a differing
  saved previous value exists, the bottom action becomes
  `Restore Global Limit Only`.
- Tell users that the normal game default is 50 anywhere the 999 stress-test
  value is explained. Restore must still use the saved backup value, because a
  customized server's previous value may differ from 50.
- State directly that `MaxSpawnedAnimals` is a global game/server ceiling across
  all biomes, while this mod's separate XML tuning targets Wasteland routes.
- Allow Brutal Science to be applied by itself with no animal boxes selected.
  In that state the primary action reads `Apply Limit Cap Only`, changes only the
  backed-up `serverconfig.xml` value, and does not install or modify Wasteland
  XML mod files.
- Render `Apply Limit Cap Only` two points smaller than the normal primary
  Install/Reinstall label: 8-point instead of 10-point.
- When Brutal Science is checked, track its normal default, current value, and
  selected result in the visible choice summary and validation report.
- Center the table headings over their columns using this exact order:
  `Animal Selection | Population Level | Action | Current | Result`.
- When no animals are selected, label the disabled primary action
  `Check any Box Above to Install Here..`; wrap it onto two lines for fit.
- Leave the selection-summary area blank when nothing is selected instead of
  displaying the redundant `No changes selected.` note. Continue showing useful
  animal summaries when animal selections exist.
- Remove global-limit default/current/result wording from the centered selection
  summary. Keep those details in validation, confirmations, tooltips, and logs;
  this line should summarize selected animals only.
- Show a large upward-looking rolling-eyes emoji beside that no-selection
  state, directing attention toward the animal choices. Keep its surrounding
  warning treatment and hide the indicator when Install or Reinstall becomes
  active.
- When Install or Reinstall is active, remove the separate circular indicator.
  Present a simple centered action on a soft-gray background with a crisp green
  rounded outline and a restrained mint-to-violet iridescent highlight.
- Give the active button a translucent molded-plastic appearance using layered
  gloss and lower-edge shading. Add a small mint/violet pixel-art paw on the
  left and tiny pixel glints on the right; keep the action text unobstructed.
- Remove nonessential explanatory paragraphs from the visible layout. Preserve
  their full meaning in long-lived tooltips attached to the exact controls and
  table headings they explain, then tighten the empty space from the layout.
- Remove the redundant `Choose animals for the next Install / Reinstall`
  heading and its reserved vertical space. Pull the complete table, validation
  control, cap panel, and bottom actions upward by 30 pixels.
- Stream each tooltip's wording in three quick progressive text frames, like a
  compact chat response. Keep the full final message visible for four seconds,
  retain fade-in/fade-out, and do not move or scroll the tooltip text.
- After a tooltip reaches its complete frame, index its full wording in the
  Layered Reasoning Log for later review. Record each unique tooltip only once per
  session, even when the user hovers over the same explanation again.
- Route animal-row tooltip entries with both the animal and table column, using
  the readable form `TIP | Animal: Dire wolf | Column: Current | explanation`.
  Apply the same routing to Action and Result so a saved explanation never
  appears under only its displayed value.
- Do not show tooltips on the animal-selection checkboxes/names, individual
  level sliders, or the matching All controls. These repeated explanations add
  noise; retain the useful Action, Current, and Result column explanations.
- Label the master checkbox `All` and present it as the first normal table row,
  directly above Dire wolf. Align its checkbox, shared slider, and `Custom`
  action with the same Animal, Level, and Action columns used below.
- Unchecking `All` must clear every individual animal checkbox
  and reset pending animal levels. It must not change the independent Brutal
  Science selection.
- When the green Installed state is active, compare every unchecked animal with
  installed XML. Show `Uninstall` and its default result when that animal is
  currently tuned; otherwise show `Keep`. Name affected objects on the bottom
  action as `Uninstall Mod - <animal names>`. Mixed
  install/remove confirmations must list both outcomes. Removing the last tuned
  animals removes the generated mod XML and now-empty mod folder, returning the
  game's effective XML configuration to its defaults. Do not describe the XML
  configuration as untouched.
- Do not show a centered selection-summary line above validation; it duplicates
  the primary action and adds visual noise. Name pending animals directly on
  the bottom action using `Uninstall Mod -`
  followed by the affected animal names, explaining that unchecked installed
  objects return to game defaults. Use 6-point for the multi-object label.
- Align the `All` checkbox with the individual animal-row checkboxes below it.
- Horizontally align the grouped level slider's track line with the individual
  animal slider tracks below it.
- Lower the grouped slider into the vertical center of the grouped-selection
  row and keep its `Custom` value clear of the slider thumb and track.
- Apply the final visual adjustment by raising the grouped slider five pixels.
- Constrain the grouped slider's control height so it cannot paint a dotted
  artifact into the header row, and move the `Action` heading three pixels left.
- Move the `Current` and `Result` headings three pixels left to match the final
  column-label alignment.
- Center-justify `Population Level` directly over the slider tracks.
- Replace the clipped bottom status line with a dedicated right-side activity
  pane. It must show timestamped starts, selections, cancellations, outcomes,
  and failures; preserve long paths; wrap entries to the narrower pane width;
  auto-follow the newest entry; and support vertical scrolling like a
  host-management task console.
- Start the activity pane collapsed. Provide a slim debug arrow on the right
  edge that expands/collapses the pane without clearing its session history.
- Make the open activity pane a true split partition: the arrow snaps it open
  to approximately half the main application's width or closed, and the user
  can pull the divider sideways to resize it. Protect the main application's
  designed width; additional window width belongs to the activity-log side.
- Use a stable single border on the resizable activity pane so dragging or
  expanding it cannot leave repeated rounded-border trails.

## Important Behavior Rules

- Choosing the game folder must not install or run the mod.
- Clicking or editing the displayed directory must not install, launch, or run
  the mod.
- `Choose Game Folder` opens the Windows folder chooser for the 7 Days to Die
  game root. It does not open the user's other installed mods.
- `Open Mods Folder` creates `<selected 7DTD game root>\Mods` if it is missing,
  then opens it in Windows Explorer.
  It is not the same destination or action as `Choose Game Folder`.
- `Validate Current Game Settings` performs a fresh read and opens a read-only
  validation report. In the current design it does not refresh the values
  already displayed in the visible `Current` column. It does not modify game,
  mod, or server configuration. When the user has explicitly enabled Persistent
  log, validation entries are written to the chosen text log. The GUI must make
  this behavior clear.
- Do not append `Next:` instructions to validation reports. Return the detected
  state and comparison details without telling the user which action to take.
- When Brutal Science is included in validation, show a labeled global-limit
  history: game default, last recorded setting from the newest Bit Wrecked
  backup, current detected setting, and selected Brutal Science result. If no
  backup exists or a value cannot be read, state that directly.
- Always include the `Raise Animal Spawn Cap - Brutal Science` state in
  validation, even when its checkbox is unchecked. Report the file, setting,
  checkbox state, default, newest backup value, current value, and selected
  result (raise, restore, or keep).
- Mirror validation-report lines into the Layered Reasoning Log as `VALIDATION` entries.
  Record each distinct nonblank line only once per session; repeated validation
  adds only lines whose content is new or changed.
- Name the sidebar `Layered Reasoning Log / Recent Actions` and identify its
  order as facts/file effects, gameplay consequences, then weighted generated
  commentary. Keep it runtime-only by default: it creates no file and clears
  when the application restarts. In the log pane, provide an independent
  `Persistent log` checkbox and `Choose Log File` button. Enabling persistence
  must warn the user, open a Windows Save dialog when no path has been chosen,
  save the visible session history, and keep later entries current. This path
  must not reuse or alter game-folder, Mods-folder, install, or validation-file
  wiring. Turning persistence off must not delete an already saved log.
- Require explicit consent before opening the persistent-log Save dialog. Show
  `Are you sure you want to write a log file to your computer?` and require the
  user to click a conspicuous `I want to write a log file to my computer`
  button rendered in bold Comic Sans MS 16 on dark red with yellow lettering
  and a yellow outline. The alternate action must retain runtime-only logging;
  Enter must not silently accept file writing.
- Before applying any actionable settings combination, show a concise summary
  of selected Wasteland animals/levels and whether the global limit changes.
  Add an original blunt, dry systems-programmer aside without imitating or
  attributing a real person. Cover animal-only single-level, mixed-level,
  Brutal-only, and animal-plus-Brutal combinations. Generate the aside through
  weighted context-aware fragment selection rather than stored complete quips.
  Keep the generated voice attentive to the combination's intent: wry and
  nearly judgmental, but comfortable, constructive, and never dismissive.
  Calculate positive, negative/cautious, neutral, and surprised weights at
  runtime from animal count, average level, level diversity, and Brutal Science.
  Store only reusable words and semantic fragments in source; assemble complete
  replies through randomized weighted grammar at runtime. The generator must be
  entirely local and make no API, telemetry, network, or internet calls.
- Calibrate ordinary focused/grouped choices toward neutral-positive replies;
  increase surprised and cautious-negative probability as average intensity,
  level diversity, animal count, and Brutal Science increase. Provide an
  offline 500-roll-per-case distribution simulation for QA.
  Keep log data clean by writing a structured `CONFIRM` line and a separate
  generated `EASTER EGG` line. Index each exact combination once per session;
  repeating the identical combination must not duplicate either line.
- Add a separate locally generated gameplay assessment to validation and the
  Layered Reasoning Log. Weight its `RELAXED`, `BALANCED`, `HARD`, and `BRUTAL` result
  from selected animal count, average/peak population level, and selected or
  currently raised global cap. Keep file/setting/default/current/result facts
  deterministic; assemble the blunt difficulty opinion at runtime from weighted
  semantic fragments so no complete final response is stored in source. Cache
  one generated assessment per exact settings state during the session.
- Bottom-action global-limit restore must not remove the mod, install animal
  XML, or require the global-limit checkbox to remain selected.
- `Remove Mod` remains separate and must not restore the cap.
- Existing backup-selection behavior remains: use the newest matching backup;
  do not force a hard-coded default.
- The animal checkboxes select which animals will be changed by the next action.
  An unchecked installed animal is pending uninstall to game defaults; an
  unchecked animal that is not installed stays unchanged. Selecting or clearing
  boxes alone does not write files; the bottom action applies the choices.
- No XML tuning, cap behavior, backup behavior, or package-contract changes
  are authorized by this GUI-only manifest.

## Plain-Language Answers The GUI Must Communicate

- **What is Brutal Science?** An optional animal-pressure stress test. If it is
  checked during install/reinstall and the user confirms, the tool first backs
  up `serverconfig.xml`, then raises the maximum allowed animal count to 999.
  It does not spawn animals by itself.
- **What is Restore Global Limit?** It replaces `serverconfig.xml` with the newest
  matching Bit Wrecked backup, returning the animal cap to the value saved
  before Brutal Science changed it. It works independently of the checkbox and
  is not a generic “reset to game defaults” command.
- **What is Remove Mod?** It deletes this tool's owned mod folder from the
  selected game's `Mods` folder, returning the affected routes' effective XML
  configuration to game defaults. It does not restore the animal cap.
- **Remove versus Restore:** they are separate actions affecting separate
  things. Remove deletes this mod's installed files; Restore recovers the
  backed-up server configuration containing the prior cap.
- **Why select animals?** To choose exactly which Wasteland animal entries the
  next install or reinstall will tune. This lets the user change one animal,
  several animals, or all animals while leaving the others alone.

## Acceptance Questions

1. Can a new user tell which folder to choose without knowing the mod layout?
2. Can a new user explain what `Restore Global Limit Only` will do before clicking it?
3. Is `Brutal Science` understandable without prior modding knowledge?
4. Are the five table headings visibly centered and easy to scan?
5. Does the interface clearly distinguish validation, install, restore, and
   removal actions?

## Status

Implemented, owner-approved, packaged, and release-ready in the parent 4.1.1
working source.

QA completed:

- Windows PowerShell parser: pass.
- DPI-aware visible-label fit checks: pass.
- Real WinForms `-SmokeTest`: pass.
- Rendered-form visual review: pass; labels fit and all five table headings are
  centered over their matching columns.
- XML parsing and live XPath-target checks: pass.
- GPL/license guardrails: pass.
- Full-package extracted GUI smoke test: pass.
- Full-package, Nexus no-scripts, and Vortex archive shape checks: pass against
  archives rebuilt on 2026-07-18.
- Embedded `ModInfo.xml` version check: all three archives report `4.1.1`.
- SHA-256 release hashes recorded in `Upload_To_Nexus/4.1.1_SHA256.txt`.

Release archives were built into `Upload_To_Nexus`. No external upload, tag, or
publication has been performed.
