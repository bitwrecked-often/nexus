# Visible Game Name label — 2026-10-05

The owner reviewed the sealed `1.3.0-qa.002` application and requested that its
field label read exactly **Game Name**. The label now comes from
`copy.manager.gameNameLabel` in the canonical quiet recipe. A recipe without
this optional field uses **Game Name**. The internal controls, Help,
confirmation wording, accessibility descriptions and setup/runtime behavior
are preserved.

The sealed baseline archive remains unchanged: SHA-256
`48AD02DF397917C95E7BD27422C030910860824F9B11CE152258DA47FB68DE45`.
The scoped proof reads its corresponding source entries directly. No runtime,
release contract, cases, build record, public helper/template or prior archive
was edited by this task.

| Input | Sealed qa.002 source SHA-256 | Current source SHA-256 |
| --- | --- | --- |
| Manager | `5C522439354FEF0E6C370D5C92C99DE74D5453BD2B8F34B432A5394EDD18073D` | `1C827974BB914030600237070A02A5A5A9E2140AD62168285621F003BE9285FA` |
| Quiet recipe | `4564D45D2D2DB003F2BA668AB0EE72B61E75D7BF9B22A0B27C44FFE8F728C4C2` | `50A017D864CCDDB7EE266183F03D3CBCDE93E2F740E97777395D41769E944E86` |
| Recipe validator | `D090EE4FC7312C00ED30EF1557368798B281785F20C6AF0F26E2B5B42D17EDE1` | `3326CF450DD096CFB945C303744921F1196965E9C11F2E372E199271A4155BD3` |

Native controls remain
`7533751906025A9604236CD3DDF1669E953396499E4698965BE52C2CD8B40B69`.

The exact source changes are recorded in [manager.diff](../../manager/presentation-delta/manager.diff),
[recipe.diff](../../manager/presentation-delta/recipe.diff) and
[recipe-tooling.diff](../../manager/presentation-delta/recipe-tooling.diff): one new recipe text field,
its optional plain-text validation, the field-label assignment, and generated
recipe embedding/hash. The existing focused manager test's label assertion
was updated to expect `Game Name`; its prior execution receipt was preserved.

[The carry receipt](../../manager/presentation-delta/verification.json) reports **23 scoped checks**
under Windows PowerShell 5.1. Applying the declared label assignment to the
sealed manager and regenerating the design produces the exact current manager
SHA-256. Removing the single new recipe field reproduces the prior recipe
structure; the exact recipe text and optional validation changes also match.
The current and prior no-field recipes are accepted. Integer, empty,
control-bearing and overlength optional labels are rejected through the
existing exported recipe reader. The prior no-field binding and current
binding both resolve to `Game Name`. The manager parses and embedding checks
report `Current`, `Embedded=True`, `Changed=False`.

The fresh native proof is
[event-loop run-006](../../native-event-loop/verification.json),
bound directly to the current `1C827…` manager. Its normal STA blocking
`ShowDialog` host repainted, minimized/restored, activated, resized and closed
cleanly with zero native thread errors. The root reviewer inspected its actual
manager capture and confirmed the **Game Name** label and picture-only logo.
That unchanged receipt is also copied into this scoped proof for binding.

Prior DEV evidence is carried through this exact label-only change: **86
focused assertions**, **26 review assertions** and **97 callback scenarios**
remain recorded against their original `5C522…` source. Their receipts were
neither rerun nor relabeled. Prior history-failure, layout-comparison and
runtime evidence retain their original scopes and hashes. These are DEV
checks; independent customer/gameplay QA and publication approval remain
Pending.

`run-001` preserves a scoped test-driver failure before any native host ran:
the driver initially called the module's private validation function directly.
`run-002` corrects the driver to use its exported recipe reader. Product source
did not change in response to that test-driver failure.

The new immutable candidate `1.3.0-qa.003` is prepared and exported separately
by the parent task; this wording task performs no export or publication.
