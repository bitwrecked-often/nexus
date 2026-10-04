# HRS 1.2.6 final QA review

Reviewed: **2026-10-04**. Repository baseline: `d14ca25` on `main`.

Candidate: **1.2.6-qa.002**, under `Solution - HRS Historical Random Start 1.2.6 Polish/qa-002`.

Disposition: **Independent QA started; manager sizing fixes needed before its QA pass. Publication remains pending.** The package and source checks pass after repairing Git's newline conversion. The live sizing review below found UI defects. Gameplay cases and release approval remain outstanding.

## Live sizing review — 2026-10-04

Case: **HRS-BIOME-Manager**, run `hrsqa-20261004T175350Z-32724833`.

The native customer `START.bat` was reopened at actual **100%, 150%, 200%, and 225% Windows display scaling**. Screenshots were taken for the sizing rounds, selection changes, dialog openings/returns, and final restoration. The primary screen is 2560×1440; its working area changes with taskbar scaling. The secondary display remained at its original 300% setting. Captures use physical pixels; the manager reports window DPI 96, so these results describe Windows compatibility scaling rather than per-monitor DPI awareness.

Open the [screenshot gallery](qa-review/1.2.6-qa.002/ui-sizing/index.html) and [structured findings](qa-review/1.2.6-qa.002/ui-sizing/sizing-findings.json). The [failed-attempt evidence ZIP](qa-review/1.2.6-qa.002/ui-sizing/manager-sizing-failed-evidence.zip) contains 63 round captures plus the initial live screenshot. Its SHA-256 is `3DB464D746203717FE4B2983D5F94B542D3EBF0DE29CCF588A494FD38A0CF2EC`. PNGs retain their original resolution. Early captures made before saved settings or repaint completed are diagnostic only; the gallery uses settled captures for findings.

| Review | Observed result |
| --- | --- |
| Main text and rounded actions | Readable in the settled captures; narrow labels and actions wrap |
| Weights dialog at 100%, 150%, 200%, 225% | All five biome rows, numeric controls, shares, help, Use Weights, and Cancel readable |
| Normal and maximized scrolling | Lower actions reachable in the captured normal/maximized layouts |
| Automatic sizing during selection changes | Fail: cumulative width loss at 150% |
| Automatic window positioning | Fail: normal window can extend behind the taskbar at 150% |
| Minimum-size vertical scrolling | Fail: maintenance controls cannot be fully revealed at 200% after a genuine mouse resize |

### HRS-UX-001 — automatic fitting progressively narrows the manager

At actual 150% scaling, one process and window remained in use with no move or resize requests. The settled Weighted state was **1028 pixels wide**. Two Chosen ↔ Weighted keyboard cycles produced equivalent Weighted states of **951**, then **875 pixels wide**. The intervening Chosen widths were 1002 and 926 pixels. Repeatedly opening and cancelling weights in the same Weighted state held the width stable, isolating the loss to selection/content transitions.

Reproduce: open the manager with saved Chosen settings, select Weighted, then use the selection dropdown to alternate Chosen and Weighted twice. HOME/DOWN traverses intermediate selection indices and can invoke several layout changes. Capture settled bounds after each selection. Do not resize the window or apply settings.

Source review identifies `Fit-HrsManagerWindow`, manager line **1059**, feeding scrollbar-reduced `ClientSize.Width` into a new size assignment. Microsoft documents that [ClientSize excludes scrollbars](https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.control.clientsize?view=netframework-4.8.1). The repeated losses match approximately one or two scrollbar widths at the measured scale. DEV should preserve **outer width** when fitting height. Review the equivalent weights-dialog assignment at line **916** as well; no cumulative dialog-width defect was demonstrated here.

### HRS-UX-002 — content growth can extend the normal window behind the taskbar

In the same 150% reproduction, the window retained top **114** and grew to height **1332**, placing its bottom at **1446**. The monitor's working-area bottom was **1368**. The screenshot shows the taskbar covering the lower window area. Initial Chosen height 1283 also placed the bottom at 1397, beyond the working area.

DEV should clamp the **final outer bounds and position** to the current monitor's working area after automatic fitting. Limiting height alone does not account for the existing top position. This is a normal-window finding; maximized windows' invisible resize borders may legitimately extend beyond the working rectangle.

### HRS-UX-003 — minimum-size scrollbar range does not expose maintenance controls

At actual 200%, a genuine mouse drag reduced the Weighted manager from **1480×1250 to its permitted 880×720 minimum**. Scrolling to the bottom and sending additional mouse-wheel input left Restore clipped, with Uninstall and Game details below the visible area. The vertical position was already its maximum: `891 − 321 + 1 = 571`.

Physical bounds independently support the screenshot: the window bottom was 768; Restore occupied y=750–814, Uninstall y=814–878, and Game details y=902–948. UI Automation's `offscreen=false` flags did not describe actual clipping. Enlarging/maximizing exposed the controls. This establishes failure of vertical-scroll reachability at that size; it does not claim every possible keyboard interaction fails.

DEV should recompute scroll extent after wrapped labels, button rows, and surface height finish layout. Recheck the final scroll range at minimum size after a real drag, selection changes, and dialog returns. Increasing the minimum size alone would require deliberate review against the supported display profiles.

### DEV acceptance and session closeout

- Equivalent settled Any/Chosen/Weighted states retain outer width through repeated selection and keyboard changes.
- Automatic normal-window bounds stay inside the working area, including after content growth and near screen edges.
- At actual 100%, 150%, 200%, and 225%, a real resize to the permitted minimum followed by scrolling exposes every action and Game details.
- Opening/Cancel weights preserves unsaved settings; all dialog rows and buttons remain readable.
- Genuine user sizing remains respected; maximize/restore and monitor changes do not introduce geometry drift.
- Return a new candidate for the fixes and repeat the affected manager checks.

Windows primary scaling was restored to **200%**, the secondary remained **300%**, and the manager's original maximized placement and saved Chosen selection were restored. The installed policy, result, runtime DLL, and ModInfo hashes exactly match the before-session inventory. No settings were applied and no game was launched. The frozen customer ZIP still hashes to `F578291FBC41E87F2C06C82CB9F4157C7F46BC66B8D2DC0D1D734F63CA385FA5`.

This sizing attempt was exported as **QA / Fail**. Three observed manual checks were confirmed; fourteen were left unconfirmed. The tool consequently reports **Mismatch** for its all-check assessment, with zero missing or forbidden runtime events. This is not a completed accessibility or gameplay qualification. High Contrast, Narrator, full keyboard navigation, native Apply popups, and the other contract checks remain outstanding. The transferred case ledger is unchanged. The exporter's all-check assessment must not be read as a runtime defect when unperformed manual checks are left unconfirmed.

## Customer artifact

Use the polished candidate's [START.bat](<Solution - HRS Historical Random Start 1.2.6 Polish/qa-002/customer/HistoricalRandomStart_1.2.6/START.bat>) for this session. The older `1.2.6-qa.001` package has an earlier manager layout.

The preserved customer archive for this review is **`1.2.6-qa.002.zip`**. Its sizing attempt failed. Integrating the required fixes and reviewed UX changes needs a **new candidate**; the eventual Nexus upload must be that newly verified archive after independent QA and release-owner approval. Follow the [native UX DEV manifest](HRS_NATIVE_UX_NEXT_DEV_MANIFEST.md) and [doctrine](HRS_NATIVE_UX_DOCTRINE.md). Keep this archive, its ledger and review evidence as the original candidate record. QA context, tools, receipts and review evidence remain separate from the customer upload.

| Identity | Verified value |
| --- | --- |
| Customer ZIP size | 208801 bytes |
| Customer ZIP SHA-256 | `F578291FBC41E87F2C06C82CB9F4157C7F46BC66B8D2DC0D1D734F63CA385FA5` |
| Runtime SHA-256 | `E5EA99BBD4DBAE122264835CC2090157F3A549C0E6FB379EB5DF5860EEF56D7B` |
| ModInfo release | `1.2.6` |
| Independent QA ledger | 41 required cases, all Pending |

## Finding resolved: checkout altered frozen bytes

The initial checkout had **24 mismatches among the 59 transfer-manifest entries**. Five runtime-source mismatches caused `Test-HrsRelease.ps1` to fail. The receipt, some manifests, documentation, and three QA tools also differed from their recorded hashes. The customer and companion ZIPs, runtime DLL, manager script, and ModInfo already matched.

`core.autocrlf=true` converted original LF and mixed newline sequences into CRLF. The existing `.gitattributes` rules covered earlier HRS packages but did not cover this polished 1.2.6 transfer.

Resolution:

- Added an exact-byte preservation rule for `Solution - HRS Historical Random Start 1.2.6 Polish/**`.
- Restored archive-backed files from the verified customer and companion ZIPs, after confirming that their logical text differed only in newlines.
- Restored other text only when the result matched both the recorded SHA-256 and byte count. The three QA tools were recovered from the preserved 1.2.5 copies, which already had exactly the hashes required by the 1.2.6 transfer.
- Revalidated all **59 entries: zero hash or size mismatches**.

Neither ZIP was changed. No customer logic was changed. The package diffs disappear when end-of-line whitespace is ignored; `.gitattributes` is the only substantive edit to existing tracked files. These changes still need a commit to preserve the repaired bytes on future checkouts.

## Checks performed here

| Check | Result | Scope |
| --- | --- | --- |
| Customer archive, receipt, registry, and manifest verification | Pass | Exact candidate identity and permitted customer files |
| Extracted workspace verification | Pass | Customer and context match the two frozen archives |
| Transfer manifest | Pass | 59 files, zero mismatches |
| `Test-HrsRelease.ps1 -LaneRoot .\context` | Pass | Ready for QA; zero errors, zero warnings; ten pass findings |
| Windows PowerShell 5.1 parsing | Pass | All 13 supplied `.ps1` and `.psm1` files |
| Freshly extracted customer `START.bat -SmokeTest` | Pass | Real native controls, chosen selection, weight save/cancel, all-zero rejection, and retained weights; inert game folder |
| Manager and weights-dialog screenshots | Reviewed | Current native rendering; scrolling is present in the short manager window |
| Runtime, ModInfo, and five launcher modules versus qa.001 | Identical | Polish candidate reuses those bytes |
| Trader notice and launch-flow source review | Pass | Required behavior is present; live modal interaction still needs QA |

The source comparison also records manager differences from qa.001. Its callbacks and several state functions changed between those candidates; DEV's unchanged-callback comparison was against its later pre-polish source. Do not treat that DEV comparison as proof that qa.001 and qa.002 managers are identical.

Evidence is saved in [qa-review/1.2.6-qa.002](qa-review/1.2.6-qa.002), outside the frozen transfer. [review-summary.json](qa-review/1.2.6-qa.002/review-summary.json) records the scope and limitations; the folder also contains the release validator result, every transfer hash, the transport repair record, manager comparison, and screenshots.

## DEV handoff integration

The native `START.bat` to PowerShell WinForms method is preserved. Standard, Any, Chosen, Weighted, and starting-biome protection remain available.

The successful Apply handler completes install/write/readback before showing **Settings Applied**. The approved trader warning appears for Random modes, including protection-on Random, and is omitted for Standard. Launch remains blocked until acknowledgement. Launch also requires matching applied fields, verified installed files, Steam running, and the game closed. Returning to the manager refreshes availability. A confirmed failed Apply retains its launch block and has no success popup.

The warning correctly uses **first trader assignment / Journey to Settlement marker** as the boundary. A trader visit can happen later. The README, release notes, and Nexus listing draft disclose the early-exit limitation, including unexpected exits, and do not claim that the popup repairs routing. They also explain saved landing behavior and legitimate cross-biome trader fallback. EAC-off and supplied Harmony requirements remain explicit.

No persistent trader-route repair is represented as part of this candidate. The known early-exit issue remains accepted only within the documented boundary in our [DEV manifest](HRS_TRADER_SESSION_NEXT_DEV_MANIFEST.md).

## Local game environment

The installed game assembly SHA-256 is:

`FCEEC27300FFD3A1F97B097E43B60F3B07597F441E7ECBC6E1B59EEBB234C705`

The qualified V3.3.0 b17 assembly SHA-256 recorded by DEV is:

`AA4275991736D276EC75BB4047E45F76E0242AA47D9895890F3761098D4CC146`

Steam's local app manifest selects `latest_experimental`. The exact qualified assembly is therefore not installed here. This is an **environment qualification limitation**, not evidence of a runtime defect or a requirement to refuse every other version. The manager warns about untested builds and permits Apply; the runtime probes the required compatible hook. Testing the current installation can establish best-effort results for that installation, but cannot certify the recorded b17 target. No game files were modified, and no game was launched by this review.

## Remaining publication gates

All **41 independent QA cases are still Pending** in the supplied contract. DEV's integration checks and this no-install review do not complete them. The QA checklist and evidence tools are in the candidate handoff; use observed results and the actual game environment for the final cycle.

Material remaining checks include:

- Live install, Apply/acknowledgement, failure handling, Steam return, launch, upgrade, restore, and removal.
- Standard and all biome-selection modes on Navezgane and Random Gen worlds of at least 8192, including unavailable-biome and safety fallbacks, protection, reloads, and respawns.
- Uninterrupted first-session trader assignment; assignment surviving a subsequent logout before the visit; the documented early-logout case; and valid cross-biome fallback.
- Real Windows 100%, 150%, 200%, and 225% scaling, narrow/maximized windows, keyboard operation, High Contrast, Narrator, and native popup legibility. Synthetic scaling evidence is not actual monitor-DPI certification.

An uninterrupted run with no valid trader decision, or a lost destination after assignment and re-entry, remains a release blocker. Early exit before assignment is the disclosed known issue. Complete the returning candidate's QA evidence and cycle decision, obtain release-owner approval, and publish that candidate's verified customer ZIP with the known-issue copy in both release notes and the Nexus description.

No QA cases were marked complete and no publication approval was recorded during this review.
