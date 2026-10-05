# Tech Demo packaging tool verification — 2026-10-05

The edition-aware exporter and release validator pass the new Tech Demo workflow and retain legacy candidate support. These checks use disposable software fixtures. They perform no installed-game writes, gameplay, human customer acceptance, production candidate export, publication or commit.

## Completed checks

| Suite | Result | Evidence |
| --- | --- | --- |
| New Tech Demo packaging | 34/34 Pass | `edition-verification.json`, `edition.txt` |
| Generic QA tools | 67/67 Pass | `generic.txt`, `legacy-tools-verification.json` |
| Candidate workflow | 39/39 Pass | `workflow.txt`, `legacy-tools-verification.json` |
| Branding | 12/12 Pass | `branding.txt`, `legacy-tools-verification.json` |
| Unified full public package | 40/40 Pass | `unified-verification.json`, `unified.txt` |

The generic count increased from the earlier 64 because it parses the three newly added QA scripts: the Tech Demo baseline creator, contract creator and packaging test. Existing behavior assertions remain intact.

## New edition fixture

`qa_cycle/Test-HrsTechDemoPackaging.ps1` copies the actual new lane's customer inputs, all authenticated runtime source files, build record and current contracts into an isolated lane. Its tool clone has its own empty registry. The synthetic export identity is `1.3.0-qa.991`; it never reserves the production identity.

The current new-edition source gate passes with zero errors and warnings. Four deliberate mutations fail the gate and actual exporter before registry reservation or output staging: an unsupported edition, a wrong declared version label, a legacy QA label in the manager, and a duplicate visible edition assignment.

The real exporter creates one complete unified ZIP from the disposable clone. Its customer manager has exactly one `Tech Demo | 1.3.0` visible assignment, no DEV/QA release label, and exactly one false development-candidate flag. The archive contains the root entry and synthetic source/history/lore/evidence fixtures. There is no companion archive. A standalone tool bootstrap without a registry accepts the explicitly supplied trusted ZIP digest, retains those exact archive bytes, derives a receipt identical to the exporter's receipt, and verifies the entire tree using the packaged tools. Its own release gate also passes with zero errors and warnings.

After every fixture, the production registry, original public qa.003 archive and all copied source-lane inputs match their before hashes. Production `1.3.0-qa.001` remains unused/unregistered at completion. This proof makes no claim about a later production export.

## Passed input snapshot

The final receipt records every actual lane input used, including all fifteen runtime sources. Key identities:

| Input | SHA-256 |
| --- | --- |
| Source manager | `440D6DE1E1C7A1B2621E14EBCF9BFC051BFC201FFD2DF9CF49DDDC3EF8DFFB28` |
| Runtime DLL | `6E143C99DB7519A4D42B047225E7ADBB1C8D3009EFD8E4E18DCA154719316D32` |
| ModInfo | `896451F71AF3B2BF45E09924CBEAD606E0BA2950FD18E1D50B22FE0ACACF69A6` |
| Release record | `BF932CEE74560B197B0FA4B8F816453A71B4BF9DE5AB3FC7628D7141EE41CB9F` |
| Case contract | `83A9BE314EF25C601D7FAFEF9CB0CC9FB1B38A37ECB4E270E6F30C19D45B67BF` |
| Authenticated build record | `01CE59B48AEB3DE6A21010206320B84883BAB34A8F04D640C01A4F4FC9BBEB0F` |

The fixture was held until the root's actual native STA event-loop check passed on that source-manager identity. Native event-loop and logo observations are separate evidence; this packaging suite neither performs nor grants those checks.

## Remaining boundary

These tool regressions support preparation of the new complete public candidate. They do not pass any of the 46 formal customer cases or remove owner feature/visual acceptance, qualified gameplay, display/accessibility/newcomer, save-preservation or release approval requirements. Test the newly identified frozen full public ZIP; distribute those exact approved bytes to QA, customers, Nexus and the site.
