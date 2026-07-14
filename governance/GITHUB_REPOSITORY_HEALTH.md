# GitHub Repository Health

## Purpose

This is the repository-health status for the current `4.1.0` candidate-source
working tree (`develop/4.1.0`, P4 active). No `4.1.0` candidate ZIP has been
built or promoted, and no publication exists. It separates controls proved by
tracked files from dated GitHub observations and service results that cannot be
inferred from the checkout.

The repository is the source of preparation policy and evidence. It is not, by itself, proof that a GitHub rule is enabled, a workflow has passed on GitHub, or a Nexus artifact has been accepted.

## Tracked Controls

| Area | Current control | Evidence |
| --- | --- | --- |
| Text and binary integrity | LF and binary classifications are explicit; editor defaults match the frozen-source byte convention | `.gitattributes`; `.editorconfig` |
| Generated and private material | Designated release output, private/raw evidence paths, local-game paths, common secret-file patterns, logs, and new archives are ignored; ignore rules are not a substitute for review or push protection | `.gitignore` |
| Release identity | One schema-validated manifest owns solution identity, candidate lifecycle intent, editions, exact package mappings, deterministic archive rules, freeze rules, and historical artifacts | `solutions/7dtd_wasteland_animal_population_tuning_files/release-manifest.json` |
| Historical integrity | The 32-file raw-Git baseline and three legacy ZIP hashes are checked without rebuilding or rewriting them | `evidence/baselines/`; `tests/release/Invoke-OfflineTests.ps1` |
| Package preparation | Validation is read-only by default; staging uses exact clean-`HEAD` Git blob bytes and atomically places the tree plus working evidence under ignored output, separate from candidate construction, approval, final-upload promotion, or publication | `tools/release/`; `RELEASING.md` |
| P4 transaction | Release policy reserves `PreparePrimary` as the sole atomic technical P4 path; diagnostic `StagePrimary` is mutually exclusive, and neither action grants public authority | `RELEASING.md`; release manifest and schema |
| Optional editions | No-scripts and Vortex remain machine-blocked until their independent evidence gates are satisfied | Release manifest and schema |
| Contributor intake | Contribution and issue-form files request effects, evidence maturity, privacy-safe diagnostics, rollback, and publication boundaries; GitHub presentation still requires the files on the default branch | `CONTRIBUTING.md`; `.github/` templates |
| Continuous integration | One least-privilege Windows workflow runs read-only contract checks plus guarded disposable staging/package/GUI-smoke integration fixtures, then a whitespace check, with a full-SHA-pinned checkout action | `.github/workflows/validate.yml`; `tests/release/Invoke-OfflineTests.ps1` |

The workflow uses a fixed GitHub-hosted runner label and read-only repository
permission. Checkout uses the ephemeral read-only `GITHUB_TOKEN` but does not
persist it; no repository/environment secret, cache, artifact upload, release,
or Nexus operation is referenced. Workflow presence is policy; only a completed
GitHub run is execution evidence.

## Local Health Gate

Run from the repository root with PowerShell 7.4 or later:

```powershell
pwsh -NoProfile -File tests/release/Invoke-OfflineTests.ps1
git diff --check
```

The suite never edits a game installation, rebuilds a historical ZIP, writes
the checkout's real candidate path, uses the network, contacts Nexus, or
publishes. It does exercise the packaged GUI smoke path and build/promote two
byte-identical test ZIPs inside an owned system-temp clone. Those outputs are
machine-classified as disposable fixtures, use only `dist/.test-fixtures/`,
carry no candidate authority, consume no owner-authorized candidate cycle, and
are deleted with the clone.

The passing hosted run below predates the candidate-source transition. It proves
the P3 preparation checkpoint only; the P4 source must earn its own validation
evidence before candidate construction.

## Live State Not Yet Proven

The following items require repository-owner or GitHub service evidence. They must not be reported as enabled merely because a policy file mentions them:

| Live control | Current evidence state | Required confirmation |
| --- | --- | --- |
| GitHub Actions validation | Passed for commit `29bcb4b85e6ea4dae3c21c614740c702279ed3f9` on 2026-07-13 UTC | [Offline validation run 29234918528](https://github.com/bitwrecked-often/nexus/actions/runs/29234918528) |
| Default-branch ruleset and required check | Unverified | Export, screenshot, or settings record after the first green run |
| Force-push and branch-deletion protection | Unverified | Ruleset evidence |
| Repository visibility/default branch | Observed public with default branch `main` at `2026-07-13T07:31Z` | Recheck before a release-sensitive policy change |
| Issues enabled | Observed enabled at `2026-07-13T07:31Z` | Forms still require a post-merge default-branch UI check |
| Merge methods | Merge commits, squash, and rebase all observed allowed; auto-merge off at `2026-07-13T07:31Z` | Owner still must choose the project method; current platform settings enforce no single method |
| Private vulnerability reporting | Owner decision and live setting required | Verify GitHub's private reporting control, then add an accurate `SECURITY.md` |
| Secret scanning and push protection | Unverified and availability-dependent | Live security-settings evidence |
| Release/tag protection and immutable releases | Deferred until the owner selects lifecycle/tag rules and the live controls are configured | Owner-approved live configuration record |
| Actual code owners | No owner/team mapping has been authorized | Add `CODEOWNERS` only after real identities and scope are selected |

## Intentionally Deferred Files

- `SECURITY.md` waits for a real private reporting route; no placeholder contact is acceptable.
- `CODE_OF_CONDUCT.md` waits for a real private conduct-report route.
- A root `LICENSE` waits for an explicit decision about root and governance-document scope. Solution files already carrying GPL notices keep their existing license.
- `CODEOWNERS` waits for an authorized GitHub user or team mapping.

These are honest gates, not omissions to disguise. None blocks offline preparation of the GPL-complete primary solution package.

## CI Run Chain Of Custody

| Run | Commit | Result | Disposition |
| --- | --- | --- | --- |
| [29234506647](https://github.com/bitwrecked-often/nexus/actions/runs/29234506647) | `cb23a18` | Failed | Direct host-process execution exited during offline validation; public API exposed no detailed log. No gate was waived. |
| [29234726482](https://github.com/bitwrecked-often/nexus/actions/runs/29234726482) | `b94cd01` | Failed | Per-check annotations did not capture the unexpected outer-process exit. The workflow was changed to isolate the suite and capture its exit/output. |
| [29234918528](https://github.com/bitwrecked-often/nexus/actions/runs/29234918528) | `29bcb4b` | Passed | Dedicated PowerShell child completed the full offline suite; whitespace validation also passed. |

The isolated runner invocation is the retained CI contract. Earlier failures are
kept here so a future maintainer can see why the workflow shape changed instead
of mistaking diagnostic evolution for a waived test.

## Reference Basis

- [GitHub: secure use reference for GitHub Actions](https://docs.github.com/en/actions/reference/security/secure-use)
- [GitHub: GitHub-hosted runners reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
- [GitHub: configuring private vulnerability reporting](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/configure-for-a-repository)
- [GitHub: issue and pull request templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates)
- [GitHub repository metadata observed for this audit](https://api.github.com/repos/bitwrecked-often/nexus)
