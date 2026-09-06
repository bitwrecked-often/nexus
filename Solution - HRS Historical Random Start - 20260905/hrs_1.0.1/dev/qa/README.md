# Release evidence records

`rel.json` is the canonical `1.0.1` release contract. `cases.json` is the QA
acceptance contract. Use the repository-level `qa_cycle/README.md` and scripts
to validate the lane and capture sanitized DEV or QA evidence.

Do not edit these files during an active QA run. A byte or scope change starts a
new versioned cycle.

The requested release scope is two-point random selection between NG01 and
NG02. The current readiness gate reports that the `1.0.1` source is still fixed
to NG01, so this lane is valid for DEV evidence but is not ready for a new QA
approval under the two-point contract.
