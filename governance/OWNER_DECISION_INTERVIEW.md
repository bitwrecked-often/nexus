# Owner Decision Interview

## Purpose

This is the durable decision log for shaping the `4.1.0` Nexus mod infrastructure. The interview proceeds one yes/no question at a time. Each recorded answer governs the next question.

Target: reach at least 85% shape awareness before implementation begins. Shape awareness means the product editions, authority boundaries, support claims, state-changing behavior, artifact policy, and release path are sufficiently decided to prevent an AI from filling material gaps by inference.

## Interview Rules

- Ask exactly one materially useful yes/no question at a time.
- Prefer the question with the highest effect on downstream architecture.
- Record the owner's answer and its implementation consequence before asking the next question.
- Preserve decision chain of custody: originating observation, governing ideal, owner answer, rationale or qualification, downstream consequence, and superseding decision if one later changes it.
- If an answer is qualified, record the qualification without forcing a false binary interpretation.
- Do not treat an unanswered question as consent.
- Do not begin dependent implementation while its decision remains open.
- Keep questions short, plain, and free of hidden compound choices.
- At the end, record remaining unknowns and the basis for the 85% threshold assessment.

## Status

- Interview state: closed for primary baseline preparation
- Shape awareness: threshold met for primary `4.1.0` preparation; open release gates listed below
- Current question: none
- Implementation authority: existing non-behavioral preparation scope only; not expanded by closure
- Nexus publication authority: not granted

## Decisions

### Q1 — No-Scripts Product Outcome

Question:

> Should the scanner-friendly no-scripts Nexus download produce a meaningful tuning change by default, rather than install the vanilla baseline/template?

Answer: yes

Owner qualification:

> Keep the chain of custody for ideals in the logs so people can see how the project was made and use it as easy research for making their own work.

Originating observation:

- The current no-scripts/modlet-only XML reasserts the documented vanilla baseline and therefore has no intended tuning effect on the matching game baseline.
- The archive is presented as an animal population tuning product.

Governing ideals:

- A public artifact must produce its advertised outcome.
- Show the work so another person can understand, reproduce, critique, or adapt the method.
- Preserve why a decision was made, not only its final wording.

Decision consequence:

- The `4.1.0` scanner-friendly main download must deliver an observable, intentionally selected tuning outcome.
- It must not be shipped as a vanilla no-op while presented as active tuning.
- The exact feature-choice shape and tuning values remain undecided and require subsequent owner answers and field evidence.
- Release evidence must link this decision to implementation, tests, packaged files, and user-facing wording.

Decision state: accepted; dependent design remains open

Later baseline resolution from Q9 and Q11:

- The existing QA-approved technical behavior and tuning values are frozen for `4.1.0`; the AI has no remaining authority to choose or change them.
- Q12 addresses the truthful documentation role of the unchanged no-scripts payload without reopening technical scope.

### Q2 — No-Scripts Choice Without Code

Question:

> Should the no-scripts download give users multiple clearly labeled preset choices, instead of one fixed tuning preset?

Answer: yes

Originating observation:

- A single fixed preset would make the download useful but would choose one play style for every no-scripts user.
- The no-scripts edition cannot use interactive controls to personalize XML after download.

Governing ideals:

- Meaningful behavior should not remove player choice.
- Scanner-friendly packaging should remain readable and code-free.
- Choices must be understandable before files are copied.

Decision consequence:

- The no-scripts product will provide multiple clearly labeled tuning presets.
- Every preset must state its intended effect, exact payload identity, install path, compatibility evidence, conflicts, and removal path.
- Presets must be mutually exclusive unless a future composition model is explicitly designed and tested.
- Packaging must prevent or clearly detect accidental simultaneous installation of conflicting presets.
- Exact preset count, values, names, and archive layout remain open.

Decision state: accepted; packaging shape remains open

Later interpretation correction:

- The owner accepted multiple understandable choices, but the word `preset` led the AI to infer separate, mutually exclusive package outputs.
- Source review and Q4 established that the existing tool already composes independent feature choices through one wrapper.
- The mutually exclusive-package and conflicting-preset consequences above are retained as reasoning history but superseded by Q4. Q2 does not require separate prebuilt modlets.

### Q3 — One Download Or Separate Downloads

Question:

> Should all no-scripts presets be bundled into one Nexus download, rather than published as separate downloadable files?

Answer: yes

Owner qualification:

> The bundled presets can also give modders something to attach as a pipeline for feature sets.

Originating observation:

- Separate downloads fragment discovery, versioning, documentation, and chain of custody.
- A single code-free bundle can expose several readable XML outcomes and their derivation in one reviewed artifact.

Governing ideals:

- Keep the customer choice simple while making the underlying method reusable research.
- Treat presets as transparent feature-set definitions, not opaque finished blobs.
- Preserve one versioned evidence chain across player and modder uses.

Decision consequence:

- Publish the no-scripts preset collection as one versioned Nexus download.
- Give every preset a stable ID, readable name, exact effect, source definition, generated payload, and evidence link.
- Include a player-facing selection/install layer and a separate modder-facing feature-set/index layer in the same artifact.
- The modder layer must explain how preset definitions flow into generated XML without requiring reverse engineering.
- Validation must prove that documentation and generated payloads correspond to the same preset definitions.
- The bundle must avoid making a user install every preset at once.

Decision state: accepted; composition rules remain open

Later interpretation correction:

- The one-download answer remains accepted: the related scanner-friendly choices should not be fragmented across separate Nexus files.
- The inferred `preset collection`, separate preset index, and one-preset-at-a-time mechanics were too literal and are superseded by Q4.
- The durable modder requirement is reuse of the wrapper and its composition method. The exact scanner-friendly representation remains open.

### Q4 — Reusable Wrapper Boundary

Withdrawn question:

> Should ordinary players install exactly one preset at a time, even though modders may reuse preset definitions in broader feature-set pipelines?

Answer: withdrawn without an owner decision

Withdrawal reason:

- The question treated generated choices as separate preset packages and imposed an exclusivity model that was neither present in the source nor intended by the owner.
- It was stopped before answer and therefore grants no product or implementation authority.

Replacement question established by owner clarification:

> Should modders be able to use the wrapper as-is and attach it to other feature-set work?

Answer: yes

Owner clarification (normalized for readability):

> The tool was set up as a wrapper. Modders should be able to use it as-is and bolt it onto whatever.

Originating implementation evidence:

- `7DTD_WastelandAnimalPopulationTuning_Tool.ps1` accepts independently selected animal levels rather than requiring one global preset.
- `Get-DensityLevelFromAnimalLevels` resolves shared density from the combined selection.
- `Get-PressureSpawnRoutes` adds routes only for selected features that require them.
- `Write-InstalledAnimalConfig` and `Write-InstalledSpawningConfig` emit one resolved `entitygroups.xml` and `spawning.xml` pair into one installed modlet.

Governing ideals:

- Keep the composition mechanism useful without requiring a modder to dismantle or reverse-engineer it.
- Resolve interacting feature choices at one documented boundary so the installed result remains coherent.
- Make reuse explicit while keeping compatibility and official-support claims evidence-based.

Decision consequence:

- Treat the wrapper/composer, not a mutually exclusive preset package, as the reusable architecture boundary.
- Preserve independently selectable feature inputs and deterministic resolution into one coherent modlet output.
- Document the inputs, composition rules, generated outputs, attachment boundary, and validation expectations for modders.
- Do not imply that `bolt it onto whatever` guarantees compatibility with every downstream mod. Downstream combinations require their own evidence and are not automatically official project releases.
- Q4 supersedes Q2's mutually exclusive-package inference and Q3's separate preset-layer inference; it does not supersede their accepted goals of understandable choice and one non-fragmented Nexus distribution.

Decision state: accepted; attachment interface shape remains open

Supersedes: the withdrawn Q4 question; Q2 mutually exclusive-package consequence; Q3 separate preset-layer consequence

### Q5 — Headless Composition Boundary

Question:

> Should the wrapper's composition engine be usable without opening the graphical interface?

Answer: yes, with scope qualification

Owner qualification (normalized for readability):

> The engine can likely already be used that way, but there is no tooling for it yet. This product was made for the casual gamer and should stay that way. New integration features can be added later.

Originating implementation evidence:

- Composition behavior already exists in named PowerShell functions, but those functions share one script with WinForms construction and operational code.
- The repository has no documented command-line interface, module contract, integration manifest, compatibility policy, or tests establishing a supported headless product surface.

Governing ideals:

- Preserve a clean extension seam without making casual players carry modder-oriented complexity.
- Separate an architectural capability from a supported, documented product claim.
- Add future features incrementally after the reliable player baseline exists.

Decision consequence:

- Isolate the composition core so maintainers and automated tests can invoke it without opening WinForms.
- Keep the graphical wrapper as the primary supported `4.1.0` player experience and optimize its wording and flow for casual gamers.
- Do not make a public CLI, module API, plug-in SDK, or modder integration tool a `4.1.0` release requirement.
- Label any non-GUI attachment surface as internal or experimental until it has an explicit input/output contract, compatibility scope, documentation, and tests.
- Later releases may add integration tooling without changing the accepted composition model.

Decision state: accepted; callable core required, public integration tooling deferred

Later scope correction from Q9:

- The architectural preference for a callable core remains useful future direction.
- Isolating or refactoring that core is not authorized technical work for the frozen `4.1.0` baseline.
- Existing composition behavior may be documented and exercised through non-mutating validation; technical extraction requires a later owner decision.

### Q6 — Scanner-Friendly Edition

Question:

> Should the scanner-friendly no-scripts package remain a supported `4.1.0` download alongside the graphical wrapper?

Answer: yes

Owner rationale (normalized for readability):

> Nexus uses the no-scripts package to scan the mod's intent.

Evidence classification:

- This is owner-reported operational workflow evidence for this project.
- It is not, by itself, independent verification of Nexus policy, scanner implementation, review outcome, or future platform behavior.

Originating repository evidence:

- The historical no-scripts edition packages readable XML and documentation without executable-style helper files.
- `NEXUS_UPLOAD_NOTES_NO_SCRIPTS.md` already treats that edition as the scanner-friendly Nexus path when script scanning is a concern.
- The deep audit found that the historical archive's documentation and vanilla-equivalent payload are not an acceptable `4.1.0` product contract.

Governing ideals:

- Make gameplay intent statically inspectable to a distributor or reviewer.
- Give every supported download a complete, truthful, useful product contract.
- Distinguish project experience from independently verified platform policy.

Decision consequence:

- Retain the no-scripts edition as a supported `4.1.0` product alongside the casual-player graphical wrapper.
- Its readable XML, plain-language outcome, requirements, install, verification, removal, license, identity, and support boundaries must agree.
- It must provide meaningful behavior under Q1 and must not advertise GUI, cap-management, or automation features it does not contain.
- Enforce an exact scanner-friendly file allowlist and publish an inventory/checksum so intent can be assessed without executing code.
- Record actual Nexus handling as dated release evidence; do not claim universal or permanent scanner acceptance before that evidence exists.

Decision state: accepted; Nexus file placement resolved by Q7

### Q7 — Primary Nexus File

Original question:

> Should the scanner-friendly no-scripts package be the primary Nexus file for `4.1.0`?

Owner response: undecided

Owner observation (normalized for readability):

> Making the no-scripts edition primary seems like extra product surface.

Clarification:

- Q6 already keeps both editions supported.
- `Primary` only decides which edition Nexus presents as the obvious/default player path; it does not remove the other edition.
- The accepted casual-gamer focus points toward the graphical wrapper, while no-scripts can remain available for static inspection and users who prefer a code-free package.

Reframed question:

> Should the graphical wrapper be the primary Nexus file, with no-scripts offered as a supported optional file?

Answer to reframed question: yes

Owner confirmation (normalized for readability):

> Yes, that layout is preferred.

Originating observations:

- Q5 establishes the graphical wrapper as the casual-gamer product experience.
- Q6 retains no-scripts as a supported static-inspection and code-free edition.
- Making the inspection edition primary felt like unnecessary product emphasis when the graphical wrapper is the intended default experience.

Governing ideals:

- The primary file should match the primary customer journey.
- Progressive disclosure should keep one obvious path without hiding valid alternatives.
- Optional placement must not weaken an artifact's truth, testing, or support contract.

Decision consequence:

- Present the graphical wrapper package as the primary/main Nexus file for `4.1.0`.
- Present the no-scripts package as a clearly labeled, supported optional file for static inspection and code-free installation.
- Keep version, gameplay intent, compatibility scope, source identity, and release evidence synchronized while documenting each edition's distinct capabilities.
- Do not describe the optional no-scripts file as containing graphical, automation, or server-cap controls.
- This decision governs planned file placement but does not authorize upload, publication, or archival of an older Nexus file.

Decision state: accepted; graphical wrapper primary, no-scripts optional

### Q8 — Explicit Vortex Support

Question:

> Should `4.1.0` explicitly support Vortex, which would require successful Vortex installation and removal testing before release?

Answer: yes

Owner qualification (normalized for readability):

> The Vortex path should be supportable, and its audit should be quick.

Originating repository evidence:

- A historical archive is named `VortexModlet`, but the repository contains no retained successful Vortex install/remove evidence.
- That historical archive omits the `LICENSE.txt` referenced by its XML and cannot serve as a passing `4.1.0` fixture.
- The modlet payload is small enough for a bounded integration audit, but small size does not prove manager behavior.

Governing ideals:

- A named third-party integration is a testable support claim.
- Keep acceptance checks proportional, repeatable, and artifact-specific.
- Speed should come from a narrow test matrix, not from lowering the evidence bar.

Decision consequence:

- Retain an explicitly Vortex-supported `4.1.0` edition rather than silently renaming it to generic `ModletOnly`.
- Before that edition becomes publishable, record the Vortex version, game build, candidate artifact hash, and a successful import/install, enable, installed-inventory verification, game recognition/load, disable, removal, and owned-leftover check.
- Correct its license/package-contract defect and validate the exact archive served to the tester.
- Keep the audit concise through a written checklist and reusable evidence template; do not invent unnecessary automation around Vortex.
- If the Vortex audit fails or cannot be performed, block the Vortex edition and its compatibility claim. Other editions remain governed by their own gates unless the failure reveals a shared defect.

Decision state: accepted; Vortex support retained, integration evidence pending

### Q9 — Safe Server-Cap Controls

Withdrawn question:

> Should cap-lifting controls stay disabled until the exact active `serverconfig.xml` is identified and a verified backup can be made?

Answer: not applicable to the frozen `4.1.0` technical baseline

Owner scope correction (normalized for readability):

> We do not need to change anything technical in the package. I already completed QA on it.

Evidence classification:

- QA completion is an owner attestation and establishes the owner's acceptance of the current technical baseline.
- The interview does not currently contain a test matrix, environment fingerprint, date, detailed results, or retained QA artifacts. Those specifics remain unverified and must not be invented.
- Earlier code-audit findings remain documented observations and future-hardening candidates; they do not grant authority to redesign an owner-accepted package.

Governing ideals:

- An audit identifies facts and risks; it does not silently expand implementation authority.
- Preserve a QA-accepted baseline unless the owner explicitly reopens its technical scope.
- Distinguish owner acceptance, source inspection, and retained test evidence.

Decision consequence:

- Freeze `4.1.0` runtime and gameplay behavior: do not refactor the GUI, composition/tuning logic, XML-generation behavior, install/remove behavior, cap-management behavior, or modlet behavior.
- Continue only non-behavioral release work: identity/version metadata, documentation, licensing, manifests, inventories, checksums, safe staging/packaging infrastructure, non-mutating validation, evidence capture, and release controls.
- Q9 makes no new design choice about cap behavior; the question is withdrawn because it presumed technical change authority that is not in scope.
- Validation may document the accepted package as it exists. If it exposes a release-blocking mismatch, stop and report it rather than editing the package without separate owner authorization.
- Preserve technical audit findings as deferred backlog for a later feature or hardening release.

Decision state: accepted scope correction; technical package frozen for `4.1.0`

Supersedes for `4.1.0`: Q5's current core-isolation consequence and technical implementation directives in the work packets. It does not erase their reasoning or authorize unsupported release claims.

### Q10 — Release Archive Retention

Question:

> Should final `4.1.0` release ZIPs be committed to this repository as immutable evidence as well as uploaded to release services?

Answer: deferred; the owner did not choose an artifact-storage policy

Owner planning direction (normalized for readability):

> This stage is a copy of what works. We can make the new `4.1.0` package after the manifest and instructions are complete. For us, the work is 95% preparation and 5% execution.

Interpretation:

- `95% preparation / 5% execution` is a governing workflow heuristic, not a measured effort promise.
- The technical baseline stays frozen while its identity, manifests, instructions, package contracts, validation evidence, and release controls are prepared.
- The final candidate should be produced in one controlled execution phase after the planning gate, not through trial-and-error changes to the package.
- At Q10, this response did not answer whether final ZIPs belong in Git, so no retention policy was inferred until Q20.

Decision consequence:

- Do not build, upload, publish, or archive a Nexus file during the planning stage.
- Complete and reconcile the authoritative solution manifest, per-edition contents, version map, requirements, install/verify/remove instructions, allowlists, acceptance checklist, and evidence templates first.
- Identify the exact QA-approved baseline before it is copied into guarded `4.1.0` staging.
- After planning approval, execute one controlled candidate/promotion cycle, validate it against the completed manifests, and retain the resulting hashes and evidence.
- A failed check returns the work to planning or owner review; it does not authorize modification of frozen technical behavior.
- Later result: Q20 keeps future final ZIPs out of Git history, uses an ignored versioned final-upload stage, and commits their evidence instead. The historical committed ZIPs remain grandfathered and immutable.

Decision state: accepted preparation-first sequence; artifact retention later resolved by Q20

### Q11 — QA Baseline Identity

Question:

> Is the current solution folder on `develop/4.1.0` the authoritative QA-approved technical baseline for the eventual `4.1.0` candidate?

Answer: yes

Owner lineage direction (normalized for readability):

> `4.1.0` should be a copy forward for the next version. `4.0.1` stays intact as the authoritative parent that works.

Repository anchor at owner confirmation:

- Commit: `b3c3551c0c5bfc8d24c68d3036da4c8045a90b54`
- Solution Git tree: `010454d19b10f46c71d9150335905766b946176e`
- Solution working tree: clean
- Parent release identity: immutable `v4.0.1`

Evidence qualification:

- The Git tree ID anchors the confirmed repository snapshot but does not replace the planned per-file SHA-256 baseline manifest.
- `4.0.1` parent authority does not erase the recorded mismatch between its tagged GUI source and published full-package GUI script. Do not claim retroactive source equality or reproducibility.

Governing ideals:

- Copy a known-good parent into a new identity; never mutate the parent in place.
- Keep product lineage, source identity, artifact identity, and reproducibility as separate evidence claims.
- Make the exact handoff point inspectable before documentation or packaging work begins.

Decision consequence:

- Treat the solution tree anchored above as the authoritative owner-QA-approved technical baseline for `4.1.0` preparation.
- Preserve the `v4.0.1` tag and all registered `4.0.1` archives byte-for-byte as the working parent record.
- Create future `4.1.0` staging and artifacts under new identities; never overwrite or repurpose a `4.0.1` path.
- Produce a per-file SHA-256 baseline inventory that distinguishes frozen technical inputs from authorized release metadata and documentation work.
- Record `v4.0.1` as parent lineage while carrying its known provenance exception forward honestly.
- This baseline decision does not authorize candidate construction, publication, or archival of the served parent file.

Decision state: accepted; exact QA baseline and parent lineage established

### Q12 — No-Scripts Product Truth

Original question:

> Should the unchanged no-scripts file be documented as an inspection/template artifact rather than as a ready-to-play tuned mod?

Owner response: undecided; requested a smaller artifact-focused framing

Owner observation (normalized for readability):

> Can we trim this? Everything a player or reviewer really needs should be inside the ZIP.

Read-only package observation:

- The historical no-scripts archive contains the three-file modlet payload plus `CHANGELOG.md`, `LEGAL_AND_USE.md`, `LICENSE_NOTICE.md`, `LICENSE.txt`, `NEXUS_UPLOAD_NOTES_NO_SCRIPTS.md`, `README_FIRST.txt`, and `RELEASE_NOTES.md`.
- `NEXUS_UPLOAD_NOTES_NO_SCRIPTS.md` is maintainer-facing and does not belong in a minimal player/reviewer artifact.
- Its README refers to `REQUIREMENTS_AND_INSTALL.txt`, but that guide is absent from the historical archive.
- The three runtime files are `ModInfo.xml`, `Config/entitygroups.xml`, and `Config/spawning.xml`.

Clarified boundary:

- The future optional ZIP can carry its complete install/review contract in one concise README plus the applicable license and modlet payload.
- The archive checksum and authoritative external inventory must remain outside the ZIP so a reviewer can verify the ZIP itself.
- `4.0.1` remains unchanged; trimming applies only to the future `4.1.0` artifact contract.

Reframed question:

> Should the optional no-scripts ZIP contain only the three-file modlet, one concise self-contained README, and `LICENSE.txt`, with checksum/inventory evidence kept outside the ZIP?

Response to first reframing: not answered; withdrawn after the owner clarified the target with a screenshot

Second scope correction:

- The screenshot shows the solution workspace/outer package: `Support_Files_Do_Not_Edit`, `README_FIRST.txt`, `7DTD_WastelandAnimalTuning.bat`, and `Upload_To_Nexus`.
- The owner is asking to simplify the primary full-package extraction surface, not deciding the no-scripts product label in this question.
- Read-only inspection confirms the registered historical FullPackage ZIP already excludes `Upload_To_Nexus` and logically presents three top-level items: the README, launcher, and support folder.
- Its support folder still contains publishing covers, validators, QA/build material, advanced tools, and maintainer documents in addition to true launcher dependencies. Any deeper trim needs an exact dependency allowlist so QA-approved behavior is preserved.

Current reframed question:

> Should the primary `4.1.0` customer ZIP expose exactly `README_FIRST.txt`, `7DTD_WastelandAnimalTuning.bat`, and `Support_Files_Do_Not_Edit` at its top level, while forbidding `Upload_To_Nexus` and other maintainer-only root content?

Answer: yes, conditional on industry practice filtered through practical Nexus requirements

Owner qualification (normalized for readability):

> Use that shape if it is wise under industry standards, filtered through the healthy reality of our vendor.

Current vendor evidence reviewed on 2026-07-12:

- [Nexus Mods File Submission Guidelines](https://help.nexusmods.com/article/28-file-submission-guidelines) require files to be functional with caveats/requirements presented to users, and require names, descriptions, and capability claims to be accurate and supportable.
- [Nexus Mods quarantine guidance](https://help.nexusmods.com/article/117-why-has-my-mod-been-quarantined) recommends ZIP or 7z, explains that uploads are previewed/scanned, rejects nested archives, and notes that separate Nexus files are preferable to archives inside archives.
- [Nexus Mods Best Practices for Mod Authors](https://help.nexusmods.com/article/136-best-practices-for-mod-authors) recommends concise installation instructions, clear version identity, and explicit descriptions for optional files, with a focus on non-technical users.

Evidence interpretation:

- Nexus does not mandate exactly three top-level items. That layout is this project's proportionate application of the vendor's functional, accurate, understandable, and scan-friendly expectations.
- A small exact allowlist reduces customer ambiguity and reviewer noise without changing the QA-approved runtime.
- This decision does not claim Nexus certification, endorsement, guaranteed scan acceptance, or a universal mod-packaging standard.

Decision consequence:

- Lock the primary `4.1.0` customer archive root to `README_FIRST.txt`, `7DTD_WastelandAnimalTuning.bat`, and `Support_Files_Do_Not_Edit`.
- Forbid `Upload_To_Nexus`, candidate archives, publishing-only assets, raw QA/build material, and other maintainer-only root content from the customer ZIP.
- Build the customer archive from an exact allowlist using a normal, non-password-protected ZIP with no nested archives.
- Keep the root README short and sufficient for a casual player to launch, understand requirements, verify operation, and find removal/support guidance.
- Validate that the launcher and support folder remain adjacent and that every shipped internal file is either a runtime/UI dependency, applicable license, or user-facing support document.
- Preserve all `4.0.1` artifacts unchanged. Apply this enforced staging contract only to the future `4.1.0` candidate.

Decision state: accepted; three-item customer root locked, internal support allowlist remains open

### Q13 — Advanced Command-Line Tools

Question:

> Should the advanced command-line installer and uninstaller be excluded from the primary casual-player ZIP?

Answer: yes, with a casual-player scope qualification

Owner rationale (normalized for readability):

> The package is mainly for the casual gamer, so its contents should respect that point of view.

Originating repository evidence:

- `Support_Files_Do_Not_Edit/Advanced_CommandLine` contains five installer/uninstaller files totaling 7,879 uncompressed bytes in the historical FullPackage.
- The root launcher invokes the WinForms PowerShell tool; neither the launcher nor that GUI invokes the advanced command-line installer/uninstaller.
- Removing the advanced directory from staging therefore does not change the accepted graphical workflow.

Governing ideals:

- The primary package should optimize for its primary audience instead of presenting every maintainer capability at once.
- Advanced paths should be intentionally supported and documented, not shipped merely because they exist in source.
- Preserve source availability without turning source inventory into customer inventory.

Decision consequence:

- Exclude `Support_Files_Do_Not_Edit/Advanced_CommandLine` from the primary `4.1.0` customer ZIP.
- Retain the advanced files in the open-source repository as source/maintainer material.
- Do not advertise command-line installation or removal as a primary-package capability.
- A future separately supported tool/source artifact may include them only after its own package contract and tests are approved.
- Validate that excluding them does not change root-launcher startup, GUI install/verify/remove behavior, or shipped documentation truth.

Decision state: accepted; advanced command-line tools excluded from primary ZIP

### Q14 — Primary ZIP Internal Allowlist

Question:

> Should the primary ZIP contain only the launcher, concise README, GUI script, source modlet, GPL license, changelog, and small avatar used by the GUI?

Answer: yes, subject to GPL-3.0-or-later completeness

Owner qualification (normalized for readability):

> Keep the package lean for the casual player, but remember that it is GNU-licensed. The package and process must preserve that character as well.

Originating repository evidence:

- The proposed nine-file set contains the actual editable program: the BAT launcher, PowerShell GUI source, and three XML modlet source files. The primary package does not distribute compiled EXE or DLL object code in place of that source.
- The full GPLv3 text is already present as `Support_Files_Do_Not_Edit/LICENSE.txt`.
- The launcher, GUI, and XML files carry copyright and `SPDX-License-Identifier: GPL-3.0-or-later` notices; the GUI also carries a no-warranty notice.
- The small avatar is loaded by the GUI, and the GUI tells users that the changelog is beside the tool. Both are therefore part of the intended primary-package contract, subject to the open licensing/provenance gates.
- `README_FIRST.txt` currently names GPL-3.0-or-later but does not provide the public source location or an exact source-version route. `ModInfo.xml` also has an empty `Website` value.
- `LICENSE_NOTICE.md` and `LEGAL_AND_USE.md` contain plain-language licensing, no-warranty, and unofficial-origin guidance, but Q14 otherwise excludes them from the customer allowlist.
- The advanced command-line files, validation/build tools, publishing artwork, upload notes, and maintainer documents are not invoked by the primary launcher/GUI path and remain available as repository source.
- The avatar's Git history identifies when it entered the repository, but the repository does not record its creator, copyright holder, license, or whether the PNG is its preferred editable source. Git authorship is not evidence of copyright ownership.

Official GNU evidence reviewed on 2026-07-12:

- [GNU GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html) defines source code as the preferred form for modification; its source-conveyance terms require preservation of applicable notices and a copy of the license, and its object-code terms require Corresponding Source by an allowed method.
- [GNU's GPL application guide](https://www.gnu.org/licenses/gpl-howto.html) recommends clear per-file copyright/license notices and including the full GPL with the program.
- [GNU's GPL FAQ](https://www.gnu.org/licenses/gpl-faq.html) explains why explicit notices should travel with source files rather than relying only on a repository-level license.

Governing ideals:

- Minimal means low-friction for the player, not source-stripped or rights-stripped.
- Open source is part of the product contract: recipients must be able to inspect, copy, change, and share the work under the GPL.
- Each downloadable edition must stand on its own for license, identity, source, and provenance; a repository license must not be used to excuse a deficient ZIP.
- Origin and support statements may prevent confusion about which copy is an official project release, but they must not create additional restrictions on GPL-granted activity.
- The official nine-file allowlist and `Support_Files_Do_Not_Edit` name govern this project's supported build; recipients remain free to modify, rename, repackage, and redistribute under the GPL.
- Legal/compliance review is a release gate and evidence discipline, not a warranty or a claim of legal advice.

Decision consequence:

- Accept the following provisional primary-package file allowlist for planning:

```text
README_FIRST.txt
7DTD_WastelandAnimalTuning.bat
Support_Files_Do_Not_Edit/7DTD_WastelandAnimalPopulationTuning_Tool.ps1
Support_Files_Do_Not_Edit/BitWrecked_7DTD_WastelandAnimalPopulationTuning/ModInfo.xml
Support_Files_Do_Not_Edit/BitWrecked_7DTD_WastelandAnimalPopulationTuning/Config/entitygroups.xml
Support_Files_Do_Not_Edit/BitWrecked_7DTD_WastelandAnimalPopulationTuning/Config/spawning.xml
Support_Files_Do_Not_Edit/LICENSE.txt
Support_Files_Do_Not_Edit/CHANGELOG.md
Support_Files_Do_Not_Edit/Assets/bit-wrecked-channel-avatar.png
```

- Preserve the preferred editable BAT, PowerShell, and XML source, the complete GPL text, applicable copyright/SPDX/no-warranty notices, and the changelog's modification history in the staged package.
- Give the primary README an exact official public source/version route and a faithful plain-language statement of GPL freedoms, redistribution duties, and no warranty before the allowlist can pass.
- Block final inclusion of the avatar until its ownership, license, and preferred editable source are recorded. If those cannot be established, remove or replace it through an owner-approved non-runtime-breaking package decision.
- State the license scope for the README and changelog. Do not copy `LEGAL_AND_USE.md` wording about cheats, unrelated files, or required removal instructions into the slim package as conditions on downstream GPL redistribution; official-project publishing and support standards must be labeled as such.
- Apply the same stand-alone license/source/provenance gate to the no-scripts and Vortex editions; do not rely on a license located only in another ZIP or elsewhere in the repository.
- Keep checksum, full inventory, source-commit mapping, build evidence, publishing assets, validation tools, and other maintainer material outside the customer ZIP.
- Review any future compiled or object-code addition separately for Corresponding Source obligations; Q14 approves only the present source-form package shape.
- Treat “official project release” language as provenance and support clarification, never as a restriction on copying, modifying, or redistributing under GPL-3.0-or-later.
- Do not alter the frozen runtime or build a candidate yet. Q15 resolves avatar ownership; Q16 and later decisions must close its remaining license/source treatment and the plain-language notice consolidation.
- Later result: Q16 selected Q14's removal branch for the avatar, so the current primary allowlist has eight files. Preserve this nine-file proposal as the decision path, not the current package contract.

Decision state: accepted with copyleft-completeness conditions; avatar portion superseded by Q16, plain-language notice consolidation remains open

### Q15 — Avatar Ownership

Question:

> Do you own the copyright to the small Bit Wrecked avatar used by the GUI?

Answer: yes

Owner statement (normalized for readability):

> Bit Wrecked owns it. The Bit Wrecked YouTube presence is open in the workspace now.

Originating evidence:

- The owner explicitly attests that Bit Wrecked owns the avatar copyright.
- The exact file is `Support_Files_Do_Not_Edit/Assets/bit-wrecked-channel-avatar.png`, SHA-256 `6131A56A3C966EDE04B3E0A60D5EDCA3D4CB24D69425012BB2C0686D50E88562`, 14,833 bytes, 256 by 256 pixels.
- Read-only inspection confirms the same byte-identical avatar is present in the immutable historical FullPackage archive.
- Git records when the file was committed, but that commit alone did not prove copyright ownership; the owner's Q15 statement supplies the recorded ownership attestation.
- The owner reports that the Bit Wrecked YouTube presence is open in the workspace for review. No exact channel URL or independent platform verification is retained by this decision, and public display would not by itself establish a redistribution license.

Governing ideals:

- Tie ownership decisions to the exact bytes they cover.
- Separate owner attestation, public brand use, copyright license, trademark treatment, and preferred editable source instead of treating them as interchangeable.
- Do not infer missing asset rights from a filename, Git author, website, or public profile.

Decision consequence:

- Record Bit Wrecked as the owner-attested copyright holder for the fingerprinted PNG in `governance/ASSET_PROVENANCE.md`.
- Treat the same bytes in the historical FullPackage as covered by the ownership attestation without modifying that immutable archive.
- Do not yet mark the avatar distributable in the `4.1.0` candidate. Q15 establishes ownership only; Q16 must decide its copyright license, and a later record must identify its preferred editable source and brand/trademark treatment.
- Do not treat the YouTube presence as a license grant, an endorsement, or proof of an exact public URL until separately recorded and verified.
- Later result: Q16 excludes the avatar from the future primary `4.1.0` ZIP instead of selecting a new license. Its license/preferred-source questions no longer block that edition but remain required before any future redistribution.

Decision state: accepted; ownership resolved by owner attestation, primary-package inclusion superseded by Q16

### Q16 — Cross-Domain Avatar Boundary

Original question:

> Should the avatar image itself be released under GPL-3.0-or-later with the package?

Owner response: not answered; asked whether the image could instead be fixed or removed

Clarifying evidence:

- The GUI loads the PNG only inside a `Test-Path` condition. If it is absent, no picture control is created and the tool continues to launch.
- The visible `Bit Wrecked` text and title are separate from the image, so omitting the PNG removes the decorative avatar without making the package anonymous.
- Creating or editing a replacement image would introduce a new asset fingerprint, provenance record, license/source decision, and visual-QA surface.

Reframed question:

> Should we remove the optional avatar from the `4.1.0` primary ZIP while retaining the existing text branding?

Answer: yes to removing the avatar, with a cross-domain portability qualification; the breadth of retained personalization remains open

Owner rationale (normalized for readability):

> If we do this correctly, remove personalization so the package flows between domains.

Governing ideals:

- Portable infrastructure separates reusable behavior from unnecessary decorative personalization.
- The smallest safe baseline change uses the GUI's existing optional-asset path instead of redesigning or rewriting the QA-frozen tool.
- Portability must not be confused with erasing legal provenance, breaking stable paths, or silently creating an unbranded/white-label product.

Decision consequence:

- Remove `Support_Files_Do_Not_Edit/Assets/bit-wrecked-channel-avatar.png` from the future primary `4.1.0` customer ZIP allowlist, reducing it from nine files to eight.
- Keep the source PNG, ownership record, and immutable historical FullPackage unchanged. Do not edit or replace the image for this baseline.
- Validate the primary candidate rejects the avatar and all other non-allowlisted images.
- Do not treat the unanswered original GPL-license question as a license grant or revocation. Exclusion from `4.1.0` does not alter rights already conveyed with any historical copy.
- Do not yet remove or rename `Bit Wrecked` copyright notices, author metadata, window/status text, backup names, mod folder/ID, or install paths. Those span legal provenance and technical identity, and Q16 does not authorize changing them.
- Ask Q17 to distinguish removal of optional decorative branding from a broader de-branding/white-label change that would reopen the frozen technical baseline.
- Do not build a candidate until the remaining package/license decisions are complete.
- Later result: Q17 preserves the existing Bit Wrecked identity and technical identifiers for `4.1.0`; only the optional avatar is removed.

Decision state: accepted for avatar exclusion; supersedes the avatar portion of Q14, broader personalization resolved by Q17

### Q17 — Portable Identity Boundary

Question:

> Should `4.1.0` remove only the optional avatar while preserving its existing Bit Wrecked names, copyright notices, and technical identifiers?

Answer: qualified yes

Owner response:

> I think so.

Originating repository evidence:

- `Bit Wrecked` appears in copyright notices in the BAT, PowerShell, and XML source; those notices are legal provenance, not optional decoration.
- `BitWrecked_7DTD_WastelandAnimalPopulationTuning` is the source folder, `ModInfo.xml` name, installed folder, verification/removal target, and player-facing manual path.
- `BitWrecked` also namespaces server-configuration backup filenames and the lookup/restore messages that find those backups.
- The GUI window title and visible brand label use `Bit Wrecked`, while the optional avatar is loaded independently.
- Renaming these identifiers would change install, verify, remove, recovery, upgrade, and support identity. It would not be a packaging-only trim.

Governing ideals:

- Preserve authorship and legal chain of custody even when the implementation is freely reusable.
- Stable owned identifiers protect upgrade, removal, and recovery boundaries.
- GPL portability means downstream recipients may adapt and rebrand their versions; it does not require the official upstream release to erase its origin.
- A tentative answer may govern a conservative baseline when the reversible choice preserves the accepted technical package and the more expansive choice can be designed later.

Decision consequence:

- Preserve all existing Bit Wrecked copyright notices, author metadata, GUI text, mod/folder identifiers, install/remove targets, backup names, diagnostics, and official-release provenance in `4.1.0`.
- Remove only the optional avatar from primary candidate staging, as established by Q16. Do not edit the GUI to close the cosmetic gap during this frozen baseline.
- Describe the official eight-file allowlist as a supported upstream build contract, not a restriction on downstream GPL modification, renaming, or redistribution.
- Keep domain-neutral naming, configurable branding, and white-label packaging as future feature work. It requires an explicit product contract, version decision, namespace/migration plan, and tests; Q17 does not authorize it for `4.1.0`.
- If the owner later reverses this qualified answer, retain Q17 and record the superseding decision rather than silently rewriting history.

Decision state: accepted with owner uncertainty; preserve current identity for `4.1.0`, defer broader de-branding

### Q18 — Plain-Language GPL Notice

Question:

> Should `README_FIRST.txt` carry the single plain-language GPL, source, no-warranty, and unofficial-origin notice while `LICENSE.txt` and the source-file notices remain intact?

Answer: qualified yes

Owner priority (normalized for readability):

> Respect the users first, then the industry, then place the identifier on whatever surface is left.

Originating repository evidence:

- The current primary README gives launch and feature guidance but only one license-identifier line, no exact public source route, and a short unofficial-mod statement.
- `LICENSE_NOTICE.md` and `LEGAL_AND_USE.md` repeat useful GPL, no-warranty, and origin guidance alongside maintainer/publishing guardrails that should not become extra downstream restrictions.
- The accepted eight-file customer allowlist includes `README_FIRST.txt` and the complete `LICENSE.txt`, but excludes those two separate explanatory documents.
- The BAT, PowerShell, and XML files retain their copyright/SPDX notices independently of the README.

Governing ideals:

- A casual player should encounter the shortest safe path before legal mechanics or promotion.
- Industry and GPL obligations must be complete and accurate without making the customer reverse-engineer maintainer documents.
- Project identity should remain discoverable and trustworthy without occupying the surface needed for operation, safety, or rights.
- Plain-language summaries explain the contract; they do not replace or modify the full GPL text.

Decision consequence:

- Make `README_FIRST.txt` the single plain-language customer notice for the primary ZIP. Keep the full `Support_Files_Do_Not_Edit/LICENSE.txt` and all source-file notices intact.
- Structure the README in this presentation order:

```text
user: purpose -> requirements -> launch/use -> safety -> verify/remove/help
field: executable/source disclosure -> GPL freedoms/duties -> exact source version
       -> no warranty -> unofficial-mod/vendor boundary
identity: concise Bit Wrecked authorship and official source/support route
```

- Keep `LICENSE_NOTICE.md` and `LEGAL_AND_USE.md` as repository/source material, not customer-package files. Merge only accurate customer-relevant substance; do not import restrictions on downstream GPL use, modification, sale, repackaging, or redistribution.
- State that `Support_Files_Do_Not_Edit` is an operational cue for casual users, not a limitation on GPL modification rights.
- Validate the README against the exact eight-file archive so it mentions no excluded avatar, maintainer tool, advanced CLI, or absent document.
- Do not modify the frozen solution documentation yet; apply this approved content contract only after the required per-file QA-baseline fingerprint and remaining planning decisions are complete.
- Later result: Q19 licenses both the README and changelog under `GPL-3.0-or-later`.

Decision state: accepted with user-first presentation qualification; documentation license scope resolved by Q19

### Q19 — Documentation License Scope

Question:

> Should `README_FIRST.txt` and `CHANGELOG.md` themselves be GPL-3.0-or-later with the rest of the primary package?

Answer: yes

Owner response:

> Yes.

Originating repository and field evidence:

- `CHANGELOG.md` already carries `Copyright (C) 2026 Bit Wrecked` and `SPDX-License-Identifier: GPL-3.0-or-later`.
- `README_FIRST.txt` currently states `License: GPL-3.0-or-later` but lacks an equally explicit copyright/SPDX notice.
- Both files are distributed in plain text/Markdown, their preferred editable forms, so recipients do not need a separate documentation-source offer.
- Official GNU guidance reviewed on 2026-07-12 identifies GPL version 3 as the latest GNU GPL; OSI approved GPLv3, and SPDX recognizes `GPL-3.0-or-later` as the current unambiguous identifier.

Official references:

- <https://www.gnu.org/licenses/>
- <https://opensource.org/blog/osi-board-approves-gpl-v3-and-lgpl-v3>
- <https://spdx.org/licenses/>

Governing ideals:

- Give modders the same study, adaptation, and redistribution freedom for the operational documentation as for the scripts and XML it explains.
- Use one recognized license expression across a small integrated package instead of introducing needless license boundaries.
- Preserve authorship and modification history without restricting legitimate downstream reuse.
- Keep the license grant precisely scoped; an answer about two customer documents must not silently license unrelated governance material.

Decision consequence:

- License `README_FIRST.txt` and `Support_Files_Do_Not_Edit/CHANGELOG.md` under `GPL-3.0-or-later` in the `4.1.0` source and staged customer package.
- Preserve the changelog's existing copyright/SPDX notice and add an equivalent concise notice to the README during the authorized documentation-preparation slice.
- Keep the complete `LICENSE.txt` in the primary ZIP. Treat the text and Markdown files themselves as their preferred editable source.
- State that downstream recipients may copy, modify, redistribute, and charge for copies under the GPL, must preserve applicable notices/license freedoms, and must mark distributed modifications without representing them as official Bit Wrecked releases.
- Apply Q19 only to these solution documents. Root/governance-document license scope remains a separate repository decision.
- Do not edit the solution files until the required QA-baseline per-file fingerprint is captured; Q19 supplies content authority, not permission to skip the planning gate.

Decision state: accepted; primary README and changelog license scope resolved as GPL-3.0-or-later

### Q20 — Future Release Artifact Storage

Relationship to Q10: this reframes the still-unanswered release-archive retention decision with one concrete, recommended policy.

Question:

> Should future final ZIPs stay out of Git history and be attached to GitHub releases, while Git retains their checksums, inventories, and provenance records?

Answer: yes, with a dedicated final-upload staging boundary

Owner rationale (normalized for readability):

> Make a spot only for the final upload so we know exactly what we are putting up. Treat it as a stage.

Originating repository evidence:

- The three `4.0.1` ZIPs are committed historical artifacts and must remain byte-identical.
- The current packaging script defaults to those historical paths and can delete/replace them, so a separate output boundary is required before any future build.
- Generated ZIPs are binary release outputs. Repeatedly committing them enlarges Git history while providing less useful review detail than source, checksums, inventories, and provenance.
- This repository may contain multiple solutions, so an unversioned shared upload folder can mix products, variants, or releases.

Governing ideals:

- Make the publication set physically obvious: the final-upload stage contains exactly what is intended for external upload and nothing else.
- Keep source control focused on reviewable source and durable evidence while release services carry immutable distribution bytes.
- Separate development, candidate, publishable, and published states so a file cannot become public merely by existing.
- Preserve historical exceptions without repeating their unsafe layout.

Decision consequence:

- Grandfather the committed `4.0.1` ZIPs as immutable historical evidence. Do not move, rebuild, delete, or retroactively apply Q20 to them.
- Keep future generated/final ZIPs out of Git history and attach owner-approved final artifacts to the corresponding GitHub Release.
- Use this versioned, Git-ignored logical layout:

```text
dist/<solution-id>/<version>/
|-- candidate/
|-- final-upload/
`-- evidence/
```

- Put only exact, versioned, variant-qualified, fully validated publishable ZIPs in `final-upload/`. Keep checksums, inventories, provenance, logs, and tools outside that folder so its contents answer “what will be uploaded?” without interpretation.
- Generate the path from authoritative solution/version identity, reject stale or mixed content, validate before atomic promotion, and refuse to overwrite an already promoted final artifact.
- Generate working evidence under the ignored `dist/.../evidence/` directory, then commit its sanitized durable release record under `evidence/releases/<solution-id>/<version>/` without copying ZIP bytes into Git.
- The durable record must cover checksums, inventory, source/tag, build, approval, GitHub attachment, and Nexus-served references.
- Add the entire generated `dist/` tree to `.gitignore` during the authorized repository-hygiene slice; do not create a candidate or final ZIP during the interview.
- Treat a file in `final-upload/` as technically publishable, not publication-authorized. Merge, tag, GitHub Release, Nexus upload, and prior-file archival remain explicit owner actions.
- Q20 resolves and supersedes Q10's deferred storage question.

Decision state: accepted; future ZIPs are release attachments promoted through an ignored final-upload stage, historical committed ZIPs grandfathered

### Q21 — Cross-Channel Byte Identity

Question:

> Should the same checksum-verified ZIP from `final-upload/` be uploaded unchanged to both GitHub Releases and Nexus?

Owner response: withdrawn from the owner interview as implementation-level detail

Owner observation:

> We are way in the weeds on this.

Interpretation:

- The interview had crossed from material product/authority choices into reversible release mechanics.
- Q20 already establishes one explicit final-upload stage so the publishable bytes are known.
- Byte-preserving reuse of that promoted artifact is the safest implementation default and does not need another owner decision.

Implementation consequence:

- Use the identical checksum-verified ZIP from `final-upload/` for GitHub Releases and Nexus by default.
- If a channel technically requires different bytes, stop silent promotion: create a separately named variant with its own contract, inventory, checksum, provenance, and channel-specific justification.
- Do not ask the owner to choose routine staging, checksum, path, or evidence mechanics when established project policy and reversible engineering can resolve them.
- Continue to ask for explicit authority before tagging, creating a GitHub Release, uploading to Nexus, or archiving a prior Nexus file.

Decision state: owner question withdrawn; safe implementation default established from Q20 and chain-of-custody policy

## Shape Awareness Assessment

The interview has enough shape for non-behavioral baseline preparation. It does not approve a release.

Resolved for the primary `4.1.0` baseline:

- immutable `v4.0.1` parent and owner-QA-approved `4.1.0` source baseline;
- frozen runtime/gameplay/GUI/install behavior;
- casual-player-first primary product and exact eight-file archive allowlist;
- GPL-3.0-or-later source/documentation treatment and user-first public-surface order;
- avatar exclusion with Bit Wrecked legal/technical identity retained;
- future artifact retention, candidate/final-upload promotion boundary, and durable evidence model;
- AI, owner, and Nexus publication authority boundaries.

Explicit remaining gates, not invitations to infer:

- capture the required per-file SHA-256 fingerprint before editing solution documentation or metadata;
- reconcile the optional no-scripts edition's meaningful-outcome requirement with the frozen payload; block that edition rather than invent tuning values or alter behavior;
- complete the exact-candidate Vortex audit before claiming Vortex support;
- implement and validate the approved README, manifest, version, allowlist, staging, evidence, and repository-health controls;
- resolve repository-wide governance-document license scope and any real GitHub settings/authority choices only when their implementation slice requires them;
- obtain explicit owner approval before candidate promotion into any public release action.

Further owner questions must cross the owner-altitude boundary above. Ordinary implementation details belong in the work packet, code review, and evidence—not a continuing interview.


## Decision Chain-Of-Custody Standard

Each accepted decision must retain:

```text
Decision ID
Question
Originating observation or field evidence
Governing ideal
Owner answer
Owner rationale or qualification
Implementation consequence
Tests/evidence required
Files/releases affected
Decision state
Supersedes / superseded by
```

Keep this record concise enough to read and complete enough to reconstruct the design path. Link to detailed test or incident evidence rather than copying raw logs. Never include private tester identities, machine details, or conversation material unrelated to the decision.

## Routing

Future AIs must read this file after `PROJECT_MANIFEST.md` and `NEXT_AI_DEEP_REPO_AUDIT_ADDENDUM.md`, before selecting implementation work or asking the owner to repeat a recorded decision.
