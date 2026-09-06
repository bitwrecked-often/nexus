# Release evidence records

`rel.json` is the canonical `1.1.0` release contract. `cases.json` is the QA
acceptance contract. Use the repository-level `qa_cycle/README.md` and scripts
to validate the lane and capture sanitized DEV or QA evidence.

Do not edit these files during an active QA run. A byte or scope change starts a
new versioned cycle.

The release scope is two-point random selection between NG01 and NG02. The
source uses one game-owned random draw against an explicit two-entry approved
index allowlist. The other ten catalog entries remain non-selectable survey
data. QA approval still requires live evidence for both points and the complete
contract.
