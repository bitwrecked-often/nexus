# Next AI Deep Repository Audit Addendum

## Purpose And Precedence

This addendum records concrete findings from a deep read-only audit of the repository on 2026-07-12. It supplements `NEXT_AI_BASELINE_INFRASTRUCTURE_PACKET.md` and provides the dependency order for executing that packet.

When the older packet repeats or sequences the same work differently, use this addendum's order. Preserve all substantive requirements from the older packet, but do not implement duplicate versions of the same file, workflow, or policy.

This is a work manifest, not evidence that any listed correction has been completed.

## Immediate Stop Rules

Before making implementation changes:

- Do **not** run the current `validate_and_package.ps1 -RebuildZip` defaults. They delete and replace the three committed historical archive paths.
- Do **not** modify, regenerate, rename, or silently repair the `v4.0.1` archives.
- Do **not** describe `v4.0.1` as reproducible from its tag. The full archive contains a different GUI script from the tagged source.
- Do **not** use the current no-scripts archive as a passing fixture for new documentation rules. Preserve it as historical evidence with known defects.
- Do **not** choose tuning values, replace the accepted wrapper-composition model with a fixed or mutually exclusive preset model, choose support duration, select a private security contact, define merge policy, or take a Nexus publication action for the owner.
- Do **not** commit commercial game binaries, full proprietary game configuration files, saves, logs with private paths, server data, or extracted game assets.

## Owner Scope Override: Frozen `4.1.0` Technical Baseline

On 2026-07-12, the owner stated that package QA is complete and no further technical package changes are needed for the `4.1.0` baseline. This current direction overrides technical implementation language later in this addendum and in the older work packet.

Treat the following as frozen unless the owner explicitly reopens scope:

- graphical interface behavior and layout;
- composition, tuning, density, route, and XML-generation logic;
- modlet gameplay behavior and values;
- install, reinstall, verify, remove, cap-update, backup, and restore behavior;
- runtime extraction, module/API/CLI work, and new integration tooling.

The remaining authorized baseline work is non-behavioral release infrastructure:

- identity and version metadata, documentation, licensing, and package-specific capability statements;
- historical-artifact quarantine and candidate staging that never overwrites a published artifact;
- exact inventories, checksums, provenance, manifests, and reproducible packaging controls;
- non-mutating validation, test/evidence capture, GitHub health, release gates, and Nexus handoff material.

Owner-reported QA completion is an owner attestation. Do not invent its scenarios, environment, date, or results. Existing code-audit findings remain observations and future backlog. If a read-only check finds a release-blocking mismatch, report it and request authority; do not modify technical behavior by inference.

Work slices E-H and behavior-changing work in Slice L are deferred beyond this frozen baseline. Slices A-D, I-K, M-N, and documentation/evidence-only portions of Slice L remain in scope only where they do not change runtime or gameplay behavior.

## Confirmed Historical Evidence

The committed historical archives are immutable inputs to future audits:

| Artifact | SHA-256 |
| --- | --- |
| `7DTD_WastelandAnimalPopulationTuning_FullPackage.zip` | `52E32D5CC0A0E8D073BB421AEB2BB681D744FEE0F9E5985551EEDB15F8B96901` |
| `7DTD_WastelandAnimalPopulationTuning_Nexus_NoScripts.zip` | `96F0796845DBE53773B445C364CB66A46CD046C1519ED778BFDE3BD066008DA5` |
| `7DTD_WastelandAnimalPopulationTuning_VortexModlet.zip` | `BC64A2F71B09395D62DF3BC6482C5299756F063C10C87B454D7850548BC25485` |

Known legacy exception:

- The full archive's GUI script is 83,705 bytes with SHA-256 `5024B40A318FE0F20AFF1370AE5D572F550D3C8FAC22D00719DEFDB86918C5AB`.
- The GUI script in tagged `v4.0.1` source is 91,758 bytes with SHA-256 `DC15A74076100045CE4BB334B1E65DF001E43029632C0A0A66F89E8C39BF0894`.
- Preserve both. Record that the historical artifact cannot be retroactively given source-equality or reproducible-build provenance.

The historical no-scripts archive also has a known documentation defect: it lacks the new requirements guide and tells users to run controls and files absent from that archive. Historical preservation does not convert those instructions into a valid current package contract.

## Owner Decisions Required

Record these in an owner-decision register. Block dependent release work until answered.

The active owner-decision register is `governance/OWNER_DECISION_INTERVIEW.md`. Do not ask the owner to repeat decisions already recorded there.

1. **No-scripts product value — partially resolved by Q1-Q4:** provide meaningful behavior, understandable feature choices in one non-fragmented Nexus distribution, and preserve the wrapper as the reusable composition boundary. The exact scanner-friendly representation and tuning values remain open. The AI must not select them or reintroduce mutually exclusive preset-package assumptions.
2. **Active editions — resolved by Q5-Q8:** retain the casual-player graphical-wrapper product as the primary Nexus file, scanner-friendly no-scripts as a supported optional file, and an artifact-scoped Vortex-supported edition for `4.1.0`. Exact archive layout remains implementation work.
3. **Mod-manager claim — resolved by Q8:** retain explicit Vortex support, conditional on a concise successful import/install/enable/verify/disable/remove audit against the exact candidate. A failed or unavailable audit blocks only the Vortex edition unless it exposes a shared defect.
4. **Artifact retention:** decide whether future release archives are committed under an immutable ledger, attached only to GitHub releases, or both.
5. **Repository lifecycle:** define whether `main` means release-accepted source or Nexus-served source, and place merge/tag/upload/served-file verification accordingly.
6. **Authority identities:** identify the actual maintainer, release owner, Nexus account owner, CODEOWNER, and private security contact. Do not invent a team or committee.
7. **Server configuration scope — deferred by Q9:** do not redesign cap editing for the frozen baseline. Document only the existing behavior and owner-attested QA scope unless a release blocker reopens the decision.
8. **Existing user modifications — deferred by Q9:** do not redesign reinstall/remove behavior for the frozen baseline. Preserve the audit observation as future backlog and document current behavior without inventing guarantees.

## Canonical Vocabulary

Keep support disposition separate from evidence maturity.

Support disposition:

```text
supported | unsupported | not-applicable | unknown
```

Evidence maturity:

```text
verified | observed | inferred | unverified
```

Each compatibility/evidence record should include the evidence date, game build or fingerprint, test ID, source commit, environment classification, and revalidation trigger. `Expected` may be explanatory prose but is not evidence maturity.

Composition vocabulary:

```text
feature input -> wrapper/composer -> resolution rule -> generated modlet
```

The feature input expresses an independently selectable intent. The wrapper/composer reads the supported baseline and combines selected inputs. Resolution rules reconcile shared values and interactions. The generated modlet is the coherent output, not the reusable architecture itself.

Artifact lifecycle:

```text
historical | development | candidate | publishable | published | superseded | archived
```

## Multi-Solution Repository Contract

The repository is intended to hold a collection of mods. Do not make the repository's root `VERSION`, one branch, one tag series, or one JSON object the permanent identity for every solution.

Design for:

- a governance/schema version separate from mod versions;
- one authoritative manifest per solution;
- per-solution Nexus page identity, lifecycle, compatibility, artifacts, and evidence;
- namespaced future branches and tags, while grandfathering `v4.0.1`;
- a repository index that locates each active solution without becoming its version source;
- shared schemas and checks that operate over multiple solution manifests.

## Dependency-Ordered Work Slices

Use one bounded slice per commit or handoff. Update a gate ledger after each slice. A documented blocker is not a passing gate.

### Slice A: Quarantine Historical Artifacts

Outputs:

- committed historical artifact ledger containing the hashes above;
- read-only legacy contracts describing what each historical archive actually contains;
- separate, ignored development/candidate output location such as `dist/<solution>/<version>/`;
- build refusal to overwrite a registered historical artifact or an existing release identity;
- explicit artifact states: historical, development, candidate, publishable, and published.

Tests:

- historical hashes remain unchanged;
- default development build cannot target historical paths;
- failed build preserves last-known-good output;
- old archives validate against their legacy contracts, not new `4.1.0` rules.

### Slice B: Reconcile Current Truth

Inventory every version-, feature-, scope-, package-, compatibility-, and path-bearing document. Classify each as authoritative current source, generated mirror, historical evidence, or retired.

Known drift to resolve or retire:

- `solutions/7dtd_wasteland_animal_population_tuning.md` says version `2.0.0`, describes roll-weight-only behavior, omits `spawning.xml`, and uses obsolete `_game_dev_ai_tracking` paths.
- `solutions/README.md` exposes obsolete `Qwen32` routing language.
- multiple maintainer commands use a nonexistent repository path and omit a valid explicit `-GameRoot`.
- `TECHNICAL_FILE_MANIFEST.md` describes a two-archive builder although current source builds three.
- `RELEASE_NOTES.md` claims an archive contents report that does not exist.
- release documentation says only `3.0-era`; it does not record the exact build promised by the new no-scripts guide.
- shared release notes describe full-package features when copied into no-scripts output.

Add automated checks for stale internal paths, package-absent features, version drift, broken local references, and conflicting scope claims. Do not rewrite text inside historical archives.

### Slice C: Resolve Product And Authority Decisions

Create the owner-decision register and authority matrix:

```text
Action -> AI -> maintainer -> release owner -> Nexus account owner
```

Cover edits, tests, pushes, PR approval, settings, tags, private distribution, compatibility approval, release publication, Nexus metadata, and archival. Resolve or block on the eight owner decisions above.

### Slice D: Define Per-Solution Identity And Capabilities

Create the per-solution manifest/schema after truth reconciliation. Model capabilities per artifact and component, not as flat global booleans.

For each edition record:

- exact identity and audience;
- gameplay outcome or template purpose;
- allowed path/type inventory;
- included documentation;
- processes and privileges;
- network and telemetry behavior;
- files read, written, backed up, restored, and deleted;
- install, upgrade, remove, and support disposition;
- source/support URL, license, and unofficial status.

A public artifact must produce its advertised outcome. On the matching baseline, the current no-scripts and modlet-only XML reassert vanilla values and have no intended tuning effect. Q1 requires meaningful behavior, while Q4 establishes the wrapper/composer rather than mutually exclusive preset packages as the reusable model. Q6 retains no-scripts as a supported static-inspection surface: exact payload, documentation, allowlist, inventory, and checksum must make its intent assessable without executing code. Tuning values remain owner decisions and tested product-contract work.

### Slice E: Create Testable Architecture

The current GUI script mixes UI construction, game discovery, tuning logic, XML generation, install/remove, server configuration, backup/restore, and validation in one file of roughly 2,500 lines.

Preserve its confirmed composition behavior: independently selected animal levels are reconciled through shared-density and pressure-route rules, then emitted as one `entitygroups.xml` and `spawning.xml` pair. Extraction must not turn these feature inputs into mutually exclusive artifacts. Q5 records a future preference for a callable non-GUI core; Q9 freezes the `4.1.0` technical baseline and defers extraction. Current source structure alone does not prove a stable integration surface.

Extract or isolate:

- pure tuning and XML-generation logic;
- game-baseline inspection;
- operational state evaluation;
- owned-path and filesystem operations;
- server-cap backup/update/restore;
- package construction and inspection;
- WinForms presentation/event binding.

Future hardening should make the core runnable without opening the GUI and add synthetic fixtures, deterministic clock/path injection where needed, and a shared local test entry point. Do not perform that refactor in the frozen `4.1.0` baseline. Non-mutating validation may exercise existing seams without changing the package. Keep the casual-gamer GUI as the primary product surface.

### Slice F: Fail-Closed Preflight And Authoritative Verification

Current risk: `Test-GameRoot` checks only for `7DaysToDie.exe`, while missing or incomplete live XML silently falls back to hardcoded data and can authorize installation.

Require before any write:

- canonical supported game root or explicitly selected server root;
- exact build/fingerprint evidence when available;
- both live XML files;
- both Wasteland groups and both routes;
- required attributes and unique target cardinality;
- all generated semantic targets;
- no partial group/route acceptance;
- no fallback data as install authority.

Fallback values may support an explicitly labeled preview/template only.

Build one authoritative verifier covering ModInfo identity/version, `entitygroups.xml`, `spawning.xml`, appended pressure routes, cap state, ownership, and corruption/partial states. The current Scan Values implementation checks only entity-group XML while reporting that all XML is current; correct that claim and behavior.

### Slice G: Transactional Owned-State Operations

Install/reinstall/remove must use canonical containment and reparse-point checks, owned-folder identity, staged construction, full validation, and atomic promotion where practical.

Address:

- current merge-copy behavior leaves stale files and overwrites modifications;
- generated config failure can leave a partially installed mod;
- folder existence is currently reported as Installed without identity/integrity proof;
- removal recursively deletes any folder with the expected name;
- advanced scripts repeat these risks;
- removal lacks read-back verification;
- removing the mod does not restore the separate cap state.

Model the modlet and animal cap as two resources with explicit combined state and recovery. Test fresh install, repeat install, upgrade, modified existing state, interruption, removal, and recovery.

### Slice H: Property-Safe Server Configuration

Current cap handling rewrites the full file with PowerShell-version-dependent UTF-8 behavior, and Restore Cap copies an older whole-file snapshot over the live configuration. That can erase unrelated administrator changes.

Require:

- active config selection/identity appropriate to the supported mode;
- property-only update/restore semantics;
- preservation or explicitly controlled handling of encoding, line endings, comments, and unrelated settings;
- validated backup metadata, hash, target identity, unique naming, and retention;
- pre-restore safety backup;
- selection or fallback among valid backups rather than only newest timestamp;
- temp write, full parse/read-back, atomic replacement, and rollback;
- failure injection for write, lock, damaged backup, changed live config, and interruption.

### Slice I: Exact And Reproducible Artifact Pipeline

Refactor packaging before use:

- require explicit offline versus live-validation modes and explicit `-GameRoot` for live checks;
- use versioned candidate filenames;
- build completely in guarded temp storage;
- validate before atomic promotion;
- enforce exact per-edition allowlists rather than short deny lists;
- compare every packaged file hash with staged authoritative source;
- reject duplicate/case-colliding, absolute, traversal, ambiguous, reparse, encrypted, nested-archive, excessive-size, and suspicious-ratio entries;
- normalize `/` paths, ordering, timestamp, encoding policy, and compression;
- build twice and compare archive digests;
- generate external inventory/checksum/provenance reports;
- guard user-supplied output paths before deletion or replacement.

### Slice J: Distribution Compliance And Asset Provenance

Every distributed edition must carry or clearly expose its applicable license, official source/support URL, version/variant identity, and unofficial-mod notice.

Known issue: the historical modlet-only/Vortex XML says `See LICENSE.txt`, but its archive omits that file. Q8 retains Vortex as a `4.1.0` support goal, not a verified claim. Correct the candidate and complete the versioned Vortex audit before marking that edition publishable; preserve the historical archive unchanged.

Create an asset/component provenance inventory covering source/tool, author/owner, creation date when known, license/redistribution rights, trademarks/branding, alt text, crop/safe-area intent, and which artifact should contain it. Do not imply Nexus, Microsoft, Broadcom, the game developer, or any other vendor endorses the project.

Separate minimal player packages from source/maintainer and publishing assets. The current full archive is dominated by cover/source PNGs and maintainer documents not needed for player operation.

### Slice K: Repository Hygiene, Fixtures, And Offline CI

Add foundational controls before depending on CI:

- `.gitignore` protecting temp archives, logs, backups, saves, game files, private evidence, and candidate outputs;
- `.gitattributes` defining line endings, text/binary treatment, and archive/image handling;
- `.editorconfig` defining encoding, newline, indentation, and final-newline policy;
- `tests/` containing only minimal synthetic or redistributable fixtures;
- one stable offline validation/test command;
- Pester or an equivalently maintainable PowerShell test structure;
- PSScriptAnalyzer with version pinning and documented narrow suppressions;
- Windows PowerShell 5.1 and applicable PowerShell 7 parsing/behavior matrix;
- fixture tests for every tuning level, mixed selections, special XML/path characters, conflicts, partial writes, and negative archive cases.

Split read-only PR validation from any owner-triggered/tag-bound release/provenance workflow. A workflow file is policy evidence; it becomes automation evidence only after a real passing GitHub run.

### Slice L: UI, Diagnostics, And Accessibility Evidence

Address the concrete UI gaps:

- fixed pixel layout and future animal-row clipping;
- no explicit accessible names/descriptions/tab ordering/mnemonics;
- clickable label that is not keyboard-operable;
- path field without a clear accessible label;
- invalid/unused trackbar range values;
- no DPI autoscaling/high-contrast evidence;
- path changes trigger repeated reparsing and UI rebuilding without debounce;
- parse failures may be hidden behind optimistic/default-looking state;
- transient errors have no stable ID or copyable privacy-safe diagnostic record.

Test keyboard-only use, Narrator or equivalent, accessible names/status, visible focus, non-color cues, 125/150/200% scaling, high contrast, small display, non-ASCII/special paths, and restricted permissions.

### Slice M: GitHub, Evidence, And Release Flow

Implement repository front-door files, read-only PR checks, settings audit, protected release identity, provenance, rollout, incident learning, and acceptance only after the earlier truth, product, test, and artifact gates exist.

Maintain two records:

```text
gate | status | evidence | blocker | owner decision | revalidation trigger
```

and:

```text
requirement | risk | test ID | evidence | release status
```

Sanitize retained evidence. Raw logs with private paths remain uncommitted. Verify the newly served Nexus artifact before beginning its observation window or archiving the prior file.

### Slice N: Final Audit

Confirm:

- historical hashes match this addendum;
- no old artifact was rebuilt;
- all owner decisions are resolved or block dependent claims;
- the per-solution manifest, player guide, operations guide, UI, and artifact contents agree;
- no silent fallback can authorize writes;
- install/cap operations pass transactional failure tests;
- packages pass exact inventory, source-equality, legal, safety, and reproducibility checks;
- offline CI has real passing evidence;
- live-game, mod-manager, accessibility, and field evidence are accurately labeled;
- solution changelog contains player/release changes, while governance work is recorded separately;
- `git diff --check` and the stable test command pass;
- the working tree contains only intended changes.

## Document Precedence

When repository sources conflict, apply:

```text
current explicit user authorization
-> AGENTS.md
-> PROJECT_MANIFEST.md
-> current repository/release policy
-> active per-solution manifest
-> this deep-audit addendum
-> bounded work packet
-> historical documentation
```

Current filesystem, Git, and artifact evidence overrides stale handoff assertions. Record contradictions; do not resolve material product or authority questions by guessing.

## Final Report Requirements

For every completed slice report:

- exact outputs and commit;
- tests and evidence produced;
- historical hash comparison;
- owner decisions consumed or still needed;
- claims that remain unverified;
- live/proprietary checks skipped;
- gate status and next dependency;
- branch and clean/dirty working-tree state.
