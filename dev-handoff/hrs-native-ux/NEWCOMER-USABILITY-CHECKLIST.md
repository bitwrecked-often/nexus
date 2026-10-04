# HRS newcomer usability review

Revision **1**, **2026-10-04**. Proposed human acceptance recipe for the returning candidate; no tasks in this checklist have been performed by writing it.

The review checks whether an intended player can complete setup and explain the result without coaching. Use the ordinary customer package and reachable help. Give goals without naming the controls that solve them; record help requests, hesitations, wrong assumptions and successful corrections. [GOV.UK usability testing guidance](https://www.gov.uk/service-manual/user-research/using-moderated-usability-testing).

## Prepare one useful session

- Declare the new candidate/archive hash, actual game build, Windows/display profile, world and fresh test-save name.
- Use a controlled installation fixture that permits the intended Apply/removal steps. Preserve personal saves and unrelated mods. Keep dangerous failure injection in an isolated component test.
- Start from a freshly extracted customer ZIP, not a developer shortcut or a state-injected preview.
- Explain that the interface is being tested. Ask the reviewer to describe what they believe will happen as they work. Observe before helping.
- Record whether each observation comes from this human session, a separate live operation check or a simulated fixture.

## Tasks and comprehension checks

| Task goal | What to observe |
| --- | --- |
| Set up a new Random start using a supported existing world | Reviewer finds START.bat, understands complete extraction/EAC/Harmony requirements and distinguishes Game Name from world name |
| Select Snow, then explore custom weights and return to the preferred choice | Choices are discoverable; preserved values are understandable; reviewer finds help for relative weights, zero exclusions and preview shares |
| Decide whether starting-biome protection suits the desired challenge | Reviewer can explain what protection covers and which hazards/enemies remain active |
| Review the proposed settings and back out once before applying | Consequences and safe cancellation are understood; no pre-write cancellation mutates files |
| Apply and explain the acknowledgement | Reviewer distinguishes verified configuration from an in-game landing and identifies first trader assignment as the logout boundary |
| Understand unavailable Launch while Steam is closed, then open Steam and return | Applied configuration remains clear; reviewer finds the prerequisite and does not unnecessarily reapply unchanged settings |
| Correct an invalid name or all-zero weights | Error identifies the affected input and a usable next action; selections survive correction |
| Explain removal before deciding whether to confirm it | Reviewer understands removal preserves saves/progress and does not reverse the recorded landing or quest |

Continue through starter gameplay only when the selected release case requires it. The operator performs gameplay through trader assignment; record current save/session, frames and required runtime events. A usability explanation alone is not a gameplay pass.

## Record the result

For each task record the goal, actual actions, observed outcome, assistance, misunderstanding, recovery and evidence reference. Time-to-complete can help identify friction; it is not a substitute for correct outcomes. Document any assistance so a coached success is not counted as independent completion.

Use **Pass** only when the declared acceptance and required evidence are satisfied. Use **Fail** for observed violations, **Blocked** for an unavailable required fixture/observation, and **Pending** for unperformed checks, subject to the case tool's permitted schema. An exporter's incomplete-check assessment is separate from an observed product defect.

The reviewer should be able to explain:

- What Apply changed, what Launch still needs, and what Last start records.
- Why a chosen biome or displayed share cannot guarantee a safe landing.
- Which protection limits apply.
- When leaving the first session is acceptable and what to do after leaving early.
- What Uninstall removes and preserves.

Turn discovered confusion into a specific copy/control requirement and a fresh retest. Keep reusable human-approved expectations separate from fresh execution observations, as required by the [QA harness manifest](../../HRS_QA_HARNESS_ARCHITECTURE_MANIFEST.md).
