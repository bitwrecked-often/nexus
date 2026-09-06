# OpenSSF Readiness

## Honest status

This template is **OpenSSF-prepared**, not OpenSSF-badged. It has not been
published to a public repository, enrolled in the OpenSSF Best Practices Badge
application, or assigned an OpenSSF Scorecard result.

The intended first target is the OpenSSF Best Practices **Passing** badge,
followed by the OpenSSF Baseline criteria. The badge is a free voluntary
self-certification; it is not a third-party security audit.

## Evidence now present

| Area | Local evidence | Status |
| --- | --- | --- |
| Clear project purpose | `README.md` | Ready |
| Obtain, feedback, and contribution guidance | `README.md`, `CONTRIBUTING.md` | Ready for public export |
| FLOSS license in a standard location | `LICENSE.md` and full GPL text | Ready |
| Security-reporting path | `SECURITY.md` | Needs GitHub private-reporting setting |
| Maintainer and decision process | `MAINTAINERS.md` | Needs public identity filled in |
| Release, recovery, and version evidence | recipes, templates, and recovery guide | Ready for public export |
| Automated source integrity check | `tools/Test-FrameworkIntegrity.ps1` and GitHub workflow | Ready for public export |
| Dependency-update policy | `.github/dependabot.yml` | Ready for public export |
| Public source boundary | `PUBLIC_REPOSITORY_EXPORT_MANIFEST.md` | Ready |

## Deliberate limits and remaining work

* Do not claim an OpenSSF badge until the public project completes its own
  answers in the Badge application and the site awards it.
* Do not add an OpenSSF Scorecard badge until Scorecard runs successfully in
  the public GitHub repository and publishes results.
* Branch protection, required review, private vulnerability reporting, release
  signing, and repository ownership are hosting-account settings; they cannot
  be completed inside this local folder.
* The frozen 4.1.1 reference is excluded from the initial public export unless
  it passes its own licensing and content review.
* A future public scope should add per-file copyright notices to newly created
  source files and decide how historical reference material is attributed.

## After the public repository exists

1. Create the clean export described in `PUBLIC_REPOSITORY_EXPORT_MANIFEST.md`.
2. Publish it under the approved Bit Wrecked account and set the real project
   URL in the README and maintainer record.
3. Enable private vulnerability reporting and protected default-branch rules.
4. Confirm the GitHub Actions integrity workflow passes.
5. Enable the official OpenSSF Scorecard workflow through GitHub's Security /
   Code Scanning interface. Use OpenSSF's current generated workflow rather
   than copying an aging example from this template.
6. Create a project entry at `bestpractices.dev`, answer every criterion with
   links to this repository, and correct any unmet requirement before claiming
   the Passing badge.
7. Add the public Scorecard and OpenSSF badge links only after each service
   reports a real result.
