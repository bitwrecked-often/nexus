# Historical Random Start: next DEV candidate manifest

Status: **Ready for DEV integration and live acceptance testing**

Baseline: **1.2.5-qa.002**, 7 Days to Die V3.3.0 (b17), Windows PowerShell 5.1

Scope: Add the approved opening-trader session notice to the native manager and customer README. Keep the trader-route runtime behavior unchanged for this candidate unless a separately reviewed repair is approved.

## QA finding and decision

The tester landed in Wasteland, left the world before the opening trader destination was assigned, then returned and received a Pine Forest trader objective. The HRS log recorded a Wasteland landing and `TRADER_ROUTE_READY`, but no completed route decision. A fresh Wasteland run without logout recorded `TRADER_ROUTE_SAME_BIOME`, `TRADER_ROUTE_SELECTED`, and `TRADER_ROUTE_COMPLETED`. This supports a logout/re-entry lifecycle defect; the exact cause remains a DEV hypothesis. The earlier Apply while Steam was closed did not cause the failing run: the policy used by that run was applied after Steam started.

The accepted mitigation is to tell Random-mode players to stay in the first game session until **Journey to Settlement assigns a trader destination**. They do not need to visit the trader before leaving. Do not add persisted player state or change quest hooks as part of this UX handoff. The runtime issue stays open as a known issue.

Evidence and investigation: [QA-FINDING-1.2.5-qa.002-trader-route.md](QA-FINDING-1.2.5-qa.002-trader-route.md). Public wording: [KNOWN-ISSUE-1.2.5-trader-route.md](KNOWN-ISSUE-1.2.5-trader-route.md) and [RELEASE-NOTES-1.2.5-DRAFT.md](RELEASE-NOTES-1.2.5-DRAFT.md).

## Source to integrate

Copy these two files from [prototypes/hrs-1.2.5-trader-session-notice](prototypes/hrs-1.2.5-trader-session-notice) into the next candidate's corresponding customer paths:

| Prototype file | Candidate destination | Purpose |
| --- | --- | --- |
| `p0158.ps1` | `dev/ui/p0158.ps1` | Native WinForms manager popup and Launch Game gate. |
| `README.md` | `README.md` | Player instruction beside Install and start. |

The prototype is based on the frozen 1.2.5 manager, so DEV should merge it with any newer manager changes rather than overwrite those changes. It contains frozen QA release labels, `1.2.5` release-version arguments, verified payload hashes, and a ModInfo version check; DEV must update these against the newly built candidate. Refresh the README's version and pending-QA statement to reflect the new candidate's actual status. Keep the existing major-version compatibility behavior and identify which game build was actually tested. [PROTOTYPE.md](prototypes/hrs-1.2.5-trader-session-notice/PROTOTYPE.md) records its local checks.

The frozen `Solution - HRS Historical Random Start v1.2.5/1.2.5-qa.002.zip` has SHA-256 `90C404EBE1A974448CA85529C1D1274DE6D2429B0A404BBB8E89323584A5966D`. Do not edit that ZIP, its extracted QA package, its receipt, or its transfer manifests. The prototype files alone are not runnable. Build a new candidate ID and regenerate its manifests, receipt, file hashes, and transfer archive. Package only intended source and release files; exclude generated local manager state such as `HistoricalRandomStart_State`.

## Required manager flow

1. Keep the existing pre-write **Yes/No** confirmation of Game Name, biome selection, and protection setting.
2. After **Yes**, disable **Launch Game**. Apply/install the policy and complete its write and readback verification before showing any success message. The popup is an acknowledgement of completed work; its delay is not the mechanism that makes the write safe.
3. On success, show a separate modal **Settings Applied** popup that restates the applied Game Name, selection, and protection setting. For every Random selection method, including RandomSafe, include: **“Do not log out until your first trader is assigned. Complete the opening tasks in this session and wait for the Journey to Settlement trader marker. Leaving earlier may send the quest to Pine Forest when you return.”** Omit the trader warning in Standard mode.
4. Keep **Launch Game** disabled while the popup is open. After **OK**, enable it only when the game is closed and Steam is running. If Steam was closed during Apply, returning to the manager after starting Steam must refresh availability.
5. On a failed write, show the error only, never show **Settings Applied**, and leave Launch Game blocked for that Apply attempt. Do not launch the game automatically.

The companion README carries the same session instruction. The player should continue the opening tasks in that first game session until the Journey to Settlement trader marker appears; simply waiting after launch is not the intended action. The warning applies until the destination marker appears, not until the trader visit is completed. **Settings Applied** confirms the installation and policy, not that a trader has already been assigned in the game. The prototype popup and README now include this opening-task cue; preserve it during integration.

## Community design signals and missing expectations

These Reddit discussions are individual player reports, not a representative survey. They identify expectations to check in the next candidate; they do not expand this UX handoff into a new runtime feature.

- **Choice and surprise.** A recent player described repeated starts near the same Pine Forest trader and asked for a town or trader in another biome; another asked how to start a Wasteland challenge. Preserve the visible Standard, Any, Chosen, and Weighted choices and their saved values. Do not silently turn a player's chosen start into a forced harsh start. [Different-experience discussion](https://www.reddit.com/r/7daystodie/comments/1w8fiy6/best_settings_for_a_different_experience/), [Wasteland-start discussion](https://www.reddit.com/r/7daystodie/comments/1re5b76/spawning_in_a_different_biome/).
- **Challenge needs honest wording.** Players describe day-one Wasteland play as both appealing and punishing. Keep hazard protection independent of biome selection, and explain that it covers recognized environmental hazards in the starting biome, not enemies or every survival risk. Explain that configured weights describe the draw among eligible biomes; world availability and placement safety can still produce an ordinary start. [Wasteland play discussion](https://www.reddit.com/r/7daystodie/comments/1gmec91/they_werent_kidding_when_they_said_wasteland_is/).
- **Trader expectations.** Players complain about long early trader trips. HRS prefers a real trader in the landing biome, but may choose one elsewhere when no usable local route exists. The manager and release copy must not promise a nearby or same-biome trader, and QA must distinguish a logged, valid cross-biome selection from the missing decision observed after early logout. This handoff does not change route-distance rules. [Trader-distance discussion](https://www.reddit.com/r/7daystodie/comments/1va4sqe/best_way_to_find_a_good_trader_position_close_to/).
- **Setup clarity.** A mod user reported that EAC and the extracted folder layout were the reasons their mod did not load. Keep the README's exact `START.bat` path, Windows and game-build scope, anti-cheat instruction, and instruction to preserve the supplied `0_TFP_Harmony`. Test the extracted customer ZIP as a newcomer would; do not tell users to clear their Mods folder. No EAC checkbox or change to game anti-cheat settings is requested for HRS. [Mod setup discussion](https://www.reddit.com/r/7daystodie/comments/1i9rzdn/mods_on_steam/).

The current package explicitly sets `SkipWithAntiCheat=true` in `ModInfo.xml`, and its runtime guard rejects `EACEnabled`. Preserve those boundaries in the next candidate. The existing Harmony use does not establish an EAC-on support path. An EAC-on redesign, if ever pursued, needs its own architecture, package-size, compatibility, and security review; it is outside this trader-notice handoff.

The session notice cannot prevent a crash, power loss, or an early voluntary exit. Public copy must describe that limitation as a known issue and tell affected players that their landing remains saved and that they can follow the trader marker they receive on return. It must not claim that the post-write popup repairs the quest lifecycle.

## DEV acceptance before export

- In an isolated game installation, perform one successful Random Apply and verify policy readback completes before the success popup. Verify the popup text, disabled Launch Game during the popup, and enabled Launch Game after acknowledgement with Steam running.
- Exercise Standard and each Random selection method. Standard has no trader warning; Any, Chosen, Weighted, and protection-on Random all have it. Confirm saved biome settings and installation behavior still match the selected policy.
- Force an Apply failure safely. Confirm there is no success popup and Launch Game remains blocked for that attempt.
- Apply while Steam is closed, acknowledge success, start Steam, and return to the manager. Confirm Launch Game becomes available without reopening the manager.
- Ask a new tester what **Settings Applied** means and what they should do after launch. They should continue the opening tasks, identify the in-game Journey to Settlement trader marker as the logout boundary, and know that the trader visit can happen later.
- Verify the README and manager explain the tested game build versus other builds without implying every build has been tested. Confirm the extracted folder layout, EAC-off launch, and supplied Harmony are clear and work as written.
- Check popup legibility and access to controls at 100%, 150%, 200%, and 225% Windows scaling.
- From the newly extracted candidate ZIP, run its own `START.bat` and verify Apply, launch, upgrade, and uninstall paths. Rebuild and validate the new candidate's manifest, receipt, hashes, and QA identity.

The prototype passed the Windows PowerShell 5.1 parser and isolated manager `-SmokeTest` for controls and selection binding. Those checks do not exercise a real policy write or the post-write popup; the above DEV checks remain required.

## QA return and release note

Return the new ZIP, source commit, manifest and receipt, hashes, build and test results, and any deviations. QA should test one uninterrupted Random start through `TRADER_ROUTE_COMPLETED`, one logout before trader assignment to confirm the known limitation, and one logout after assignment but before the trader visit to confirm that the assigned marker survives re-entry. In an uninterrupted run, a missing route decision or wrong marker blocks release. After assignment, a lost marker on re-entry also blocks release; only the documented pre-assignment exit is accepted as the known limitation. Check a legitimate cross-biome fallback separately so it is not mislabeled as the early-logout defect. Keep the known-issue copy in both release notes and the Nexus description when the next candidate is published, unless a verified runtime repair changes the behavior.
