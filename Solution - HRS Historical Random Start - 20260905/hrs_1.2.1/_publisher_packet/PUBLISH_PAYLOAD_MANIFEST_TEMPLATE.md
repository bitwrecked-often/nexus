# HRS Publication Payload Manifest

This file is a TEMPLATE.

Create a release-specific copy when preparing an actual publication.

Suggested naming:

`PUBLISH_PAYLOAD_MANIFEST_<VERSION>.md`

Do not fill unknown values by inference.

Use `UNKNOWN` or `NOT VERIFIED` and stop at the appropriate gate when required authority is
missing.

## Release Identity

HRS version:

Build ID:

Source Git commit:

Source branch:

Publication date:

Publisher/platform:

Publisher release/page ID:

## Promotion Authority

Promoted artifact source path:

Promotion evidence reference:

Promotion approved by:

Promotion date:

## Runtime DLL

Filename:

Relative publication path:

Bytes:

SHA256:

MVID:

Deterministic build attempt ID:

Deterministic double-build:

Game Assembly-CSharp compatibility MVID:

Live-tested:

Live-test evidence reference:

## ModInfo

Filename:

Bytes:

SHA256:

Declared HRS version:

## Exact Payload Allowlist

Record every file in the final staging tree.

| Relative Path | Purpose | Bytes | SHA256 | Source Authority |
| --- | --- | ---: | --- | --- |
| | | | | |

No unlisted file is authorized.

## Staging Directory

Local staging path:

Confirmed empty before assembly:

Assembly date/time:

Unexpected files found:

## Privacy Review

Local paths found:

Emails found:

Credentials/tokens found:

Private notes found:

Unrelated project files found:

Game-owned/proprietary files found:

Disposition:

## Security Review

Expected executable/runtime behaviors confirmed:

Unexpected network behavior:

Unexpected process behavior:

Unexpected filesystem behavior:

Security/scanner manifest reviewed:

Reviewer notes:

## Archive Identity

Archive filename:

Archive bytes:

Archive SHA256:

Archive creation date/time:

Archive root structure verified:

Archive contents exactly match allowlist:

## Final Package Smoke

Performed:

Test environment:

Installation method:

Game version:

Observed runtime version/build:

Smoke result:

Uninstall/upgrade result if tested:

Evidence reference:

## Human Publication Gate

Intended release confirmed:

Exact artifact confirmed:

Payload reviewed:

Privacy boundary approved:

Security boundary approved:

Known limitations disclosed:

Publication approved:

Approved by:

Approval date/time:

## Post-Upload Verification

Publisher upload completed:

Publisher-reported hash:

Clean download performed:

Downloaded archive SHA256:

Matches local archive:

If not independently verified, reason:

## Final Status

Choose exactly one:

- NOT READY
- STAGED
- ARCHIVED
- APPROVED FOR PUBLICATION
- PUBLISHED
- PUBLISHED AND POST-UPLOAD VERIFIED
- BLOCKED
- WITHDRAWN

Status:

Blocking issue, if any:

## Re-entry / Continuity

Last verified gate:

What must not be changed:

Exact next action:

If execution ends here:

PRESERVE THE STATE.
LEAVE THE TRAIL.
WE WALK FROM HERE.