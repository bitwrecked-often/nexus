# Asset Provenance Register

## Purpose

This public-safe register records provenance and release gates for non-code assets that may enter a Nexus download. It does not replace a license, prove facts not supported by its cited evidence, or modify an immutable historical artifact.

Keep these fields separate:

```text
asset identity
creator or author
copyright holder
ownership evidence
copyright license
preferred editable source
brand or trademark treatment
distribution scope
release status
```

A Git commit proves repository history, not copyright ownership. Public display proves use, not a redistribution license. An owner attestation is recorded as an attestation unless independent documentary evidence is later added.

## Records

### AWAPT-AVATAR-001 — Bit Wrecked Channel Avatar

| Field | Record |
| --- | --- |
| Solution | 7DTD Wasteland Animal Population Tuning |
| Repository path | `solutions/7dtd_wasteland_animal_population_tuning_files/Support_Files_Do_Not_Edit/Assets/bit-wrecked-channel-avatar.png` |
| Intended use | Small optional brand/avatar image loaded by the Windows GUI header |
| SHA-256 | `6131A56A3C966EDE04B3E0A60D5EDCA3D4CB24D69425012BB2C0686D50E88562` |
| File facts | PNG; 14,833 bytes; 256 x 256; 24-bit RGB |
| Historical relationship | The immutable `4.0.1` FullPackage contains the same byte-identical image |
| Creator or author | Not yet recorded |
| Copyright holder | Bit Wrecked — owner attestation recorded by Q15 on 2026-07-12 |
| Ownership evidence | Explicit owner answer in `OWNER_DECISION_INTERVIEW.md`; Git history is corroborating identity/history only |
| Public identity context | Owner reports that the Bit Wrecked YouTube presence is open in the workspace for review; exact URL and identity match not yet retained as evidence |
| Copyright license | Pending Q16 |
| Preferred editable source | Pending owner record; do not assume the PNG is or is not the preferred form |
| Brand/trademark treatment | Pending; keep separate from the copyright license |
| Planned distribution | Provisional member of the primary `4.1.0` ZIP allowlist |
| Release status | Blocked until copyright license and preferred editable source are recorded |

## Validation Rule

Before an asset becomes publishable:

1. match its staged digest to this register;
2. confirm the recorded holder had authority to grant the selected license;
3. include the preferred editable source or document why the distributed form is that source;
4. state any separate brand/trademark treatment without narrowing GPL rights in covered work;
5. verify the license and attribution text carried by each applicable edition;
6. record the exact source commit and artifact inventory.

If provenance cannot be established, exclude or replace the asset through an owner-approved package decision. Never repair or rewrite a historical archive to retrofit later evidence.
