# Contributing

Thank you for helping improve the Bit Wrecked Mod Framework Template.

## Before opening an issue or pull request

* Use the future public repository's issue tracker for bugs, documentation
  corrections, and small enhancement proposals.
* Read `SECURITY.md` first. Do not place a sensitive vulnerability report in a
  public issue.
* Do not submit game files, saves, player data, credentials, proprietary game
  assets, or content copied from another author without permission.
* Keep gameplay payload ideas out of the framework repository unless a
  maintainer has explicitly approved them as a neutral example.

## Pull-request process

1. Describe the problem, the intended change, and the files affected.
2. Keep changes narrow and do not mix a framework change with a mod payload.
3. Preserve the template's safety boundary: transparent scripts, local-only
   behavior, documented write targets, no obfuscation, and no hidden network
   activity.
4. Run `pwsh -File .\tools\Test-FrameworkIntegrity.ps1` before submitting.
5. A maintainer reviews and approves non-trivial changes before merging. When
   repository rules are available, protected-branch review is required.

## Contribution standards

* PowerShell must remain compatible with Windows PowerShell 5.1 unless a
  documented version change is approved.
* New scripts must declare their intended read/write boundary in nearby
  documentation.
* Release, licensing, recovery, and versioning documents must remain aligned.
* A claim about game behavior needs evidence from the supported game build; do
  not turn an assumption into a release promise.

By submitting a contribution, you agree that it may be distributed under the
repository's GPL-3.0-or-later license.
