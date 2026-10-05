# One package, one shared view

New Player Random Start **1.2.7-qa.003**. This is the complete public package for
QA, customers, reviewers, Nexus and the project site. They receive the identical
ZIP bytes. Product, corresponding source, history, lore, evidence, license and
QA tools are all included. No second product download is required.

For play, run **START.bat** at this root and follow [README.md](README.md).
For the source and story, use its Explore links. For independent QA, follow
[QA-RUNBOOK.md](QA-RUNBOOK.md). The canonical release and all 46 Pending case
definitions are in `context/dev/qa`. The gameplay target remains **V3.3.0 b17**.

`distribution-manifest.json` lists every shipped file and its hash. The embedded
`public-package-receipt.json` identifies the runtime, build and contracts. The
final ZIP's SHA-256 is recorded by the publisher outside the archive to avoid
a self-hash cycle. Use that trusted checksum when preparing independent QA.

After independent QA and release approval, distribute this original archive
unchanged. A changed file or recompressed ZIP creates a new candidate and QA
cycle. Historical and DEV evidence is included for learning; it does not assert
that this new candidate passed independent gameplay, display or accessibility QA.
