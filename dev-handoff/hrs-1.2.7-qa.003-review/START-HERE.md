# New Player Random Start DEV review and human testing

Prepared **2026-10-05** for **Bit Wrecked**. Baseline: **1.2.7-qa.003**, public name **New Player Random Start**.

The owner requested that the current QA findings and player usability concerns become DEV work to do, including today's approved manual Check settings action. On 2026-10-05 the owner chose to finish implementation and the remaining release validation on the DEV workstation. Implement the corrections, export a newly identified customer candidate, and validate its extracted package there. The owner has authorized the full validation effort once the complete product is accepted for features and appearance. Current targeted review establishes baseline observations; begin the full consolidated matrix after that acceptance, using the final frozen candidate.

## Read and act

| Document | Use |
| --- | --- |
| [DEV work to do](DEV-TODO.md) | Twelve tasks, acceptance checks, implementation order and return requirements |
| [Human testing](HUMAN-TEST.md) | Operator task goals, evidence and baseline versus returning candidate checks |
| [Workstation completion plan](DEV-WORKSTATION.md) | Transfer contents, remaining coverage and final Nexus release sequence |
| [Machine review](../../qa-review/1.2.7-qa.003/dev-review.json) | Detailed source and screenshot findings, owner decisions and usability risks |
| [QA intake](../../qa-review/1.2.7-qa.003/intake-review.json) | ZIP identity, initial release validation, screenshots and environment |
| [Packet identities](handoff-manifest.json) | Document hashes and readiness fields |
| [Final handoff review](../../qa-review/1.2.7-qa.003/handoff-final-review.json) | Session reconciliation, transfer review and corrected wording |

The [earlier native UX packet](../hrs-native-ux/START-HERE.md) remains the historical design reference. This follow-up addresses the actual returned 1.2.7 product.

## Today's guided review — 2026-10-05

The [session ledger](HUMAN-TEST.md#current-guided-session) combines the operator reports and screenshots. Tests 2–4, 6 and 7 passed their limited guided steps; the owner accepted the noticeable restoration redraw delay for this review. Test 1 established the raw-diagnostic comprehension issue under D01. Test 5's scrolling actions were reported working, but the reduced-state screenshot remains pending; the captured larger window is a capture-state mismatch, not a demonstrated sizing defect.

Today's DEV decisions are included: D01 keeps raw diagnostics in Game details; D06 attributes saved outcomes correctly; D08 defaults protection on where no saved Random choice exists, preserves opt-outs and hides the Chosen Forest control without clearing its preference; D12 adds the explicit Check settings action. These changes are approved work, with implementation and returning-candidate verification pending.

The subsequent owner-authorized Apply/removal round captured six successful Apply history records and four removals. Each observed installed state verified with exactly one active policy; each removed state had none. No additive-policy problem appeared in the settled samples. The watcher is stopped and the final state is uninstalled. This disk evidence does not establish UI acknowledgement timing, save preservation or gameplay behavior.

The owner considers the earlier monitored battery sufficient for this GUI review round. The proposed repeat cancellation step was deferred; no additional check was attested. The session ledger records the completed observations. Reduced-window evidence and native confirmation coverage remain in the final-candidate checks. The new Check button cannot be tested in qa.003. The frozen package and all 46 formal case outcomes remain unchanged.

## Baseline and evidence

The received full public ZIP is [1.2.7-qa.003.zip](<../../Solution - HRS - 1.2.7/Unified Package/1.2.7-qa.003.zip>), **5,037,729 bytes**, SHA-256:

```text
8527F11CAAFF4173AB9880FD906E9E7DF4F6C56E45E2B81098F5688C94B27881
```

Its 394 listed files match their recorded bytes and hashes; embedded receipt references match. The independent native release validator reports zero errors and warnings. The native control smoke and root START startup succeeded. [Physical screenshot](../../qa-review/1.2.7-qa.003/root-start-native.png) and [control smoke](../../qa-review/1.2.7-qa.003/manager-smoke.png) record their respective scope. The digest identifies the original DEV archive received here; it is not an independently published checksum.

All **46 formal QA cases remain Pending**. Initial intake and DEV fixtures do not approve publication. At intake, the laptop had HRS 1.2.5 installed; opening the 1.2.7 manager did not upgrade it.

The prepared owned-upgrade case remains pending: later monitoring verified qa.003 installed files and Apply history, but complete upgrade and save-preservation evidence is absent. No gameplay result or case Pass follows from these observations. The [human testing plan](HUMAN-TEST.md) records the feature and visual gate and the budget of 21 fresh-save scenarios, with additional return sessions and conditional fixtures.

The separate verified local workspace is:

```text
C:\Users\mobil\AppData\Local\HRS-QA\1.2.7-qa.003-20261005-intake
```

Use its root START.bat and bundled runbook for current tests. The extracted repository copy has Git newline changes; task D11 covers preservation.

## Finish on the DEV workstation

Complete the DEV tasks in source, regenerate the customer manager where applicable, update matching copy, and export a new candidate with fresh identities. Record the completed task ledger and focused verification, including exact-message error reconciliation and geometry checks.

Final QA can run on the DEV workstation using the actual extracted full customer ZIP and its root START.bat. Keep development fixtures and customer acceptance results distinct. After required evidence and release-owner approval, publish those same ZIP bytes. Keep test observations outside the frozen public package.
