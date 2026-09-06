# HRS Publish Release Checklist

Use this checklist only after a release candidate has completed the required development,
validation, live-test, and promotion gates.

If promotion is not established, stop here.

## A. Establish Release Authority

- [ ] Target HRS version is explicitly identified.
- [ ] Current Git commit is recorded.
- [ ] Promoted DLL identity is known.
- [ ] Promoted DLL SHA256 is known.
- [ ] Promoted DLL byte count is known.
- [ ] Promoted DLL MVID is known.
- [ ] Deterministic build evidence exists.
- [ ] Required live validation evidence exists.
- [ ] Promotion status is explicit.
- [ ] No unresolved release-blocking issue remains.

STOP if any item above is ambiguous.

## B. Establish Exact Publication Allowlist

Create the exact list of files allowed into the player package.

For every file record:

- relative destination path;
- purpose;
- source authority;
- byte count;
- SHA256.

No wildcard inclusion unless the wildcard itself is explicitly justified and validated.

Anything not on the allowlist is excluded.

## C. Create Empty Staging Area

- [ ] Create a new empty publication staging directory.
- [ ] Confirm it is empty before copying files.
- [ ] Do not reuse a previous release staging directory.
- [ ] Do not stage directly from the installed game Mods folder.
- [ ] Do not stage by copying the entire repository.

## D. Copy Only Allowlisted Files

- [ ] Copy each approved file.
- [ ] Verify no unexpected file exists.
- [ ] Verify no file is missing.
- [ ] Verify no duplicate DLL exists.
- [ ] Verify no stale version file exists.

## E. Verify Release Identity

- [ ] Runtime DLL SHA256 matches promoted authority.
- [ ] Runtime DLL byte count matches promoted authority.
- [ ] Runtime DLL MVID matches promoted authority.
- [ ] `ModInfo.xml` version is correct.
- [ ] Runtime log version is correct.
- [ ] Package filename/version is correct.
- [ ] Player-facing documentation version is correct.
- [ ] Build identifier, if published, has explicit authority.

STOP on disagreement.

## F. Privacy / Contamination Review

Search staged text and filenames for:

- [ ] local `C:\Users\...` paths;
- [ ] OneDrive development paths;
- [ ] private email addresses;
- [ ] API keys;
- [ ] access tokens;
- [ ] passwords;
- [ ] bearer credentials;
- [ ] certificates/private keys;
- [ ] machine-specific paths;
- [ ] unrelated project names;
- [ ] unrelated mods;
- [ ] test game names;
- [ ] temporary files;
- [ ] debug logs;
- [ ] DEV-only notes;
- [ ] proprietary game binaries.

Any unexpected hit must be resolved before publication.

## G. Security Boundary Review

- [ ] Executable behavior matches documented HRS intent.
- [ ] No unexpected network/download behavior exists.
- [ ] No unrelated process interaction exists.
- [ ] File writes remain within intended HRS/game boundaries.
- [ ] Uninstall/removal remains ownership-safe.
- [ ] Security/scanner documentation reflects actual release behavior.

## H. Player Package Review

- [ ] Installation path is clear.
- [ ] Upgrade path is clear.
- [ ] Uninstall path is clear.
- [ ] Anti-cheat compatibility/requirements are stated.
- [ ] Game version compatibility is stated.
- [ ] Known limitations are stated.
- [ ] License is present if required.
- [ ] Player documentation contains no development-only instructions.

## I. Archive

- [ ] Create archive from the clean staging directory.
- [ ] Inspect archive file listing.
- [ ] Verify correct root-folder shape.
- [ ] Verify no double-nested release directory.
- [ ] Verify `ModInfo.xml` is where expected.
- [ ] Verify exactly the intended runtime DLL is included.
- [ ] Verify no DEV/test files are included.

## J. Record Final Package Identity

Record:

- [ ] archive filename;
- [ ] archive bytes;
- [ ] archive SHA256;
- [ ] archive inventory;
- [ ] runtime DLL SHA256;
- [ ] runtime DLL MVID;
- [ ] source Git commit;
- [ ] target version;
- [ ] build attempt ID;
- [ ] promotion evidence reference.

## K. Final-Package Test

When required by release risk:

- [ ] extract the final archive into a clean location;
- [ ] install using player-facing instructions;
- [ ] launch the game;
- [ ] confirm the mod loads;
- [ ] perform minimal smoke path;
- [ ] confirm runtime release identity;
- [ ] verify removal/upgrade behavior if required.

Record whether this gate was:

- PASS;
- NOT REQUIRED;
- BLOCKED.

Do not silently omit it.

## L. Human Publish Gate

Human answers:

- [ ] Is this the intended version?
- [ ] Is this the exact intended artifact?
- [ ] Is the package content understandable to a player?
- [ ] Does the package contain only what should be public?
- [ ] Are known limitations disclosed?
- [ ] Publish?

No automatic publisher upload before this gate unless the project explicitly adopts a future
policy authorizing it.

## M. After Upload

Record:

- [ ] publisher/platform;
- [ ] release/page identifier;
- [ ] published version;
- [ ] publication timestamp;
- [ ] local archive SHA256;
- [ ] publisher hash if available;
- [ ] downloaded verification hash if performed;
- [ ] whether uploaded/downloaded identity was independently verified.

## N. Closeout

- [ ] Publication record completed.
- [ ] Flight recorder updated.
- [ ] Git state captured.
- [ ] No release-only local mutation left undocumented.
- [ ] Re-entry handoff states that publication is complete or identifies exact unfinished gate.

## Emergency Stop Conditions

Immediately stop if:

- promoted artifact identity is unclear;
- unexpected payload file appears;
- archive contains extra files;
- release version disagrees;
- credentials/private data appear;
- game-owned binaries appear unexpectedly;
- DLL identity changes;
- build ID lacks authority;
- package must be manually "fixed" after promotion;
- upload identity cannot be distinguished from another candidate.

DO NOT PATCH THE ZIP.

RETURN TO THE CORRECT AUTHORITY.