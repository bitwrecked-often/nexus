# HRS native manager copy contract

Revision **1**, **2026-10-04**. DEV implementation instructions for the returning candidate.

Keep wording separate from operational state. The examples below describe intended presentation; they must be selected from verified conditions and never used as the authority for an action gate. Refer to the [doctrine](../../HRS_NATIVE_UX_DOCTRINE.md) and [DEV manifest](../../HRS_NATIVE_UX_NEXT_DEV_MANIFEST.md).

## Controls and reachable help

Retain **New game name**, **Standard**, **Random**, **Apply Settings**, **Launch Game**, **Uninstall Mod**, **Edit weights...** and **Game details**. The method-radio target is **Any biome (equal chance)**, **Choose a biome**, **Custom weights**. Preserve the existing starting-biome protection choice and its policy meaning.

Add a clearly identified **Help** entry or accessible local README link. It must work by keyboard and be discoverable with Narrator. Keep the compact layout; Game details remains technical information and must not be assumed to contain setup help.

Help must explain:

- Enter the exact **Game Name** for a new save, distinct from the world's name. An existing supported world can be used for that new save.
- Any gives equal chances among eligible biomes. Weights are relative values from 0 to 100; zero excludes a biome and at least one weight must be positive.
- Displayed shares are previews. World eligibility and placement safety can affect the final outcome; repeated random selections are possible.
- Protection covers recognized environmental hazards in the starting biome. Enemies, other-biome hazards and unrecognized debuffs remain active.
- Apply saves/verifies settings; acknowledgement follows completed work; Launch starts the game separately. Changing settings does not give an existing character another landing.
- For Random starts, complete the opening tasks in the first session until Journey to Settlement assigns a trader marker. The visit may happen later.

Keep the required trader instruction in the post-write acknowledgement. Accessible help supplements it; removed explanatory rows stay omitted from the main form.

## Status wording

| Verified condition | Copy or copy pattern |
| --- | --- |
| Unsaved changes | Changes not applied. |
| Confirmed operation writing/verifying | Applying settings... |
| Saved policy without verified installation | Saved settings. Apply Settings to verify. |
| Matching verified configuration with acknowledgement gate cleared | Changes applied. |
| Applied configuration, Steam closed | Keep applied state; add Open Steam to launch the game. |
| Game running | Close 7 Days to Die before applying settings or uninstalling. |
| Recorded game result | Last start: followed by the actual recorded outcome |

Applied describes configuration and installation readiness. Last start describes a recorded game result. Neither establishes that the next character has landed or that its trader route has completed. Progress, errors and prerequisites retain readable full messages.

## Before writing

The **Apply settings?** native confirmation restates the exact Game Name, method/selected biome or weights, and protection setting. Keep a clear safe choice before mutation. Existing native Yes/No buttons may remain; preserve the pair and make the question explicit. Check default-button, Enter, Escape and window-close behavior in the actual host. Use a safe default for a pre-write decision; do not assume Escape dismisses every native Yes/No dialog.

Random-only fallback wording:

> If no safe landing is available, HRS keeps the usual start.

This replaces the prototype's **No safe landing: the normal start is kept.** phrasing, which can sound like a failure has already occurred. It is a copy clarification; the current source already limits that fallback text to Random modes. Standard omits Random-only fallback and trader warnings.

Retain the explanation that changing settings will not give existing characters another start and that the game is launched separately. A cancelled pre-write confirmation changes no installed or policy bytes.

## After verified writing

Show **Settings Applied** only after install/write/readback completes successfully. Restate the applied Game Name, selection and protection. For every Random method, with protection either on or off, include:

> Do not log out until your first trader is assigned. Complete the opening tasks in this session and wait for the Journey to Settlement trader marker. Leaving earlier may send the quest to Pine Forest when you return.

Standard omits the trader warning. Keep the operation guard and Launch block until acknowledgement completes. Acknowledgement has no artificial delay and does not perform the write. Test all allowed native dismissal paths against the defined acknowledgement contract; then recheck current launch prerequisites.

## Errors and recovery

Explain the problem, the known outcome and one safe next action. Preserve entered selections when correction is possible. Offer technical details for diagnosis separately from the main instruction. Input problems belong beside the affected field when feasible; important action failures can use the existing native message surface. [Microsoft dialog guidance](https://learn.microsoft.com/en-us/windows/apps/develop/ui/controls/dialogs-and-flyouts/dialogs).

| Condition | Example intended wording | Required evidence before showing it |
| --- | --- | --- |
| Missing name | Enter the Game Name for your new save. | Validation rejected before mutation |
| All weights zero | Set at least one biome weight above zero. | Current weights validated; no write occurred |
| Unwritable manager folder | HRS cannot save settings here. Extract the complete package to a writable local folder and try again. | Folder check identifies the issue before game-file mutation |
| Ownership cannot be verified | HRS cannot verify ownership of these files. Open Game details and keep the diagnostic before changing files. | Actual ownership/verification result |
| Failed Apply with verified recovery | Settings could not be applied. The HRS installation files were returned to their previous state. Keep the diagnostic before trying again. | Existing targets restored and newly created targets removed, with verification |
| Failed Apply with uncertain/failed recovery | Settings could not be applied, and recovery could not be verified. Keep the backup and diagnostic for support. | Recovery failed or remains unknown; Launch stays blocked |

These examples are not existing implemented messages. DEV must map actual validation and recovery outcomes to truthful text. Pre-write rejection has no mutation to recover; a failure after changes begin requires the actual recovery outcome. Never label every failure as **nothing changed** or **restored**. Retain automatic failed-Apply recovery; the removed manual Restore action does not change that contract.

Uninstall confirmation must explain that HRS-owned files will be removed while saves/player progress and unrelated files are preserved. It cannot promise to reset an existing character's start or quest. Retain final ownership/process checks when the user confirms.

## Copy acceptance

- Standard and all Random method/protection combinations have the correct conditional wording.
- Confirmation values, saved policy and post-write summary agree.
- Labels can change without changing operation-state assertions; copy-specific tests still compare the approved wording.
- Verified, unverified, pending, busy, recovered and uncertain-recovery states never borrow each other's success wording.
- Help, popups and full errors are readable and reachable at supported real scales, by keyboard and with assistive technology.
- README, release notes, Nexus text and known-issue notice use the same assignment boundary and scope.
