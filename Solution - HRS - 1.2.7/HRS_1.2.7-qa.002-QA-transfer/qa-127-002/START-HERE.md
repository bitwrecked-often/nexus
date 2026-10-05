# New Player Random Start 1.2.7 — independent customer QA

Candidate **1.2.7-qa.002** by **Bit Wrecked**, prepared 2026-10-04.
Extract the complete transfer to a writable local folder outside OneDrive,
synced or linked folders. Open this file inside `qa-127-002`.

1. Read [PACKAGE-IDENTITY.json](PACKAGE-IDENTITY.json), then the
   [QA runbook](QA-RUNBOOK.md). Verify the candidate with its own tools:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\Test-HrsRelease.ps1 -LaneRoot .\context
   ```

2. Start QA with the three returned sizing failures on actual Windows display
   profiles. Continue through the runbook priorities and all
   [46 required cases](QA-REVIEW-CHECKLIST.md). Their initial status is Pending.
3. Run the product through
   [customer/HistoricalRandomStart_1.2.7/START.bat](customer/HistoricalRandomStart_1.2.7/START.bat).
   The product uses Windows PowerShell 5.1 and existing native graphics controls.
   Keep the game closed for Apply/Uninstall; open Steam for Launch.
4. Record actual observations in fresh runs with the supplied `tools` scripts.
   Return the immutable run ZIPs and a case/outcome/environment ledger. Preserve
   failures and missing-fixture evidence. DEV fixtures do not pass customer QA.

The world can already exist. Enter the save's exact **Game Name**, distinct
from its world name. Apply can store intent before a save exists. Random
placement applies to a fresh character's first spawn; played characters stay
in place on reload. Complete the opening tasks and wait for the Journey to
Settlement trader marker before leaving the first Random session.

Formal gameplay qualification requires **7 Days to Die V3.3.0 b17**, local
single-player, EAC disabled, supplied `0_TFP_Harmony`, and Navezgane or supported
Random Gen worlds of 8192 or larger. The runbook records the pinned identities.
A differing game build does not pass that qualification. The DEV reference
root is not a playable game.

`1.2.7-qa.002.zip` is the customer distribution archive. Its receipt and
engineering companion are separate files. `context` contains frozen build,
source and case contracts; `review` contains supporting DEV evidence,
foundation history, original sizing failures and draft public copy.
Inspect [review/README.md](review/README.md) for their evidence boundaries.
The outer `transfer-manifest.json` authenticates every delivered path.

After independent QA passes and release approval is recorded, upload the
**same `1.2.7-qa.002.zip` bytes and SHA-256** to Nexus and the project site.
The planned Nexus label is **Tech Demo**. Do not rebuild, edit or recompress
the tested archive. The outer transfer, companion and private QA evidence
are engineering review material. This handoff does not publish a listing.
