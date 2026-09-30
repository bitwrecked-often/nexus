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

The prototype is based on the frozen 1.2.5 manager, so DEV should merge it with any newer manager changes rather than overwrite those changes. [PROTOTYPE.md](prototypes/hrs-1.2.5-trader-session-notice/PROTOTYPE.md) records its local checks. The last prototype change is commit `537f828`.

The frozen `Solution - HRS Historical Random Start v1.2.5/1.2.5-qa.002.zip` has SHA-256 `90C404EBE1A974448CA85529C1D1274DE6D2429B0A404BBB8E89323584A5966D`. Do not edit that ZIP, its extracted QA package, its receipt, or its transfer manifests. Build a new candidate ID and regenerate its manifests, receipt, file hashes, and transfer archive.

## Required manager flow

1. Keep the existing pre-write **Yes/No** confirmation of Game Name, biome selection, and protection setting.
2. After **Yes**, disable **Launch Game**. Apply/install the policy and complete its write and readback verification before showing any success message. The popup is an acknowledgement of completed work; its delay is not the mechanism that makes the write safe.
3. On success, show a separate modal **Settings Applied** popup that restates the applied Game Name, selection, and protection setting. For every Random selection method, including RandomSafe, include: **“Do not log out until your first trader is assigned. Wait for the Journey to Settlement trader marker.”** Explain that leaving earlier may point the quest to Pine Forest on return. Omit the trader warning in Standard mode.
4. Keep **Launch Game** disabled while the popup is open. After **OK**, enable it only when the game is closed and Steam is running. If Steam was closed during Apply, returning to the manager after starting Steam must refresh availability.
5. On a failed write, show the error only, never show **Settings Applied**, and leave Launch Game blocked for that Apply attempt. Do not launch the game automatically.

The companion README carries the same session instruction. The warning applies until the destination marker appears, not until the trader visit is completed.

## DEV acceptance before export

- In an isolated game installation, perform one successful Random Apply and verify policy readback completes before the success popup. Verify the popup text, disabled Launch Game during the popup, and enabled Launch Game after acknowledgement with Steam running.
- Exercise Standard and each Random selection method. Standard has no trader warning; Any, Chosen, Weighted, and protection-on Random all have it. Confirm saved biome settings and installation behavior still match the selected policy.
- Force an Apply failure safely. Confirm there is no success popup and Launch Game remains blocked for that attempt.
- Apply while Steam is closed, acknowledge success, start Steam, and return to the manager. Confirm Launch Game becomes available without reopening the manager.
- Check popup legibility and access to controls at 100%, 150%, 200%, and 225% Windows scaling.
- From the newly extracted candidate ZIP, run its own `START.bat` and verify Apply, launch, upgrade, and uninstall paths. Rebuild and validate the new candidate's manifest, receipt, hashes, and QA identity.

The prototype passed the Windows PowerShell 5.1 parser and isolated manager `-SmokeTest` for controls and selection binding. Those checks do not exercise a real policy write or the post-write popup; the above DEV checks remain required.

## QA return and release note

Return the new ZIP, source commit, manifest and receipt, hashes, build and test results, and any deviations. QA should test one uninterrupted Random start through `TRADER_ROUTE_COMPLETED`, one logout before trader assignment to confirm the known limitation, and one logout after assignment but before the trader visit to confirm that the assigned marker survives re-entry. Keep the known-issue copy in both release notes and the Nexus description when the next candidate is published, unless a verified runtime repair changes the behavior.
