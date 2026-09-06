# Day 2 UI Comparison Evidence

Date: 2026-08-14

Scope: Owner-provided Historical Random Start - Alpha 6 Method screenshot, current project
shell, neutral blank template, completed Wasteland 4.1.1 launcher, and accepted
module-host infrastructure

Result: Strong visual-family parity; incomplete product and infrastructure
parity

## Owner Screenshot Observations

The screenshot shows the current project with the activity pane expanded and
the application maximized on a wide display.

Visible strengths:

- Bit Wrecked logo, brand, project title, version/state, and restrained palette
  immediately identify the product family.
- The status card, game-folder row, rounded central panel, bottom action row,
  split activity pane, persistent-log controls, and slim log expander preserve
  the first mod's visual grammar.
- Project wording is honest that the runtime and policy controls do not exist.
- The activity log visibly distinguishes initial Host and project entries.

Visible weaknesses or incomplete areas:

- Maximization leaves the 620-pixel task side fixed while the log consumes the
  remaining width and height, creating a large empty canvas.
- The green folder-recognized state can be mistaken for product readiness.
- `Validate Current Game Settings` currently performs only folder recognition.
- Generic `Feature Group | Control | Action | Current | Result` headings do not
  express the required world-policy workflow.
- The reserved policy checkbox reads as an unfinished control rather than a
  real capability.
- `Runtime Not Built`, `Remove Mod`, and `Open Mods Folder` are scaffold/legacy
  actions rather than the intended Save Settings and Start Game workflow.
- The center has no five-recent world list, browse-one/load-all actions,
  ACTIVE/BYPASSED state, policy selection, saved-state comparison, running-game
  lock, or Saved Settings Record.

## Quantitative Source Comparison

| Measure | Result |
| --- | ---: |
| Current project shell lines | 753 |
| Blank template lines | 753 |
| Current normalized nonblank lines | 670 |
| Current lines matching blank template | 641 / 670 (95.7%) |
| Current lines exactly matching Wasteland UI block | 384 / 670 (57.3%) |
| Current project script bytes | 32,695 |
| Blank template bytes | 32,330 |
| Hardened module-host lines | 896 |
| Completed Wasteland launcher lines | 4,020 |

The current shell is therefore best described as a lightly retargeted blank
template. Exact source overlap with Wasteland understates the visual match but
reveals how much completed product behavior is not present.

## Shared Visual Geometry

Current and Wasteland both use:

- 620-by-660 collapsed client size;
- 930-by-660 initial expanded client size;
- fixed 620-pixel main partition;
- seven-pixel splitter;
- minimum 600-pixel main and 300-pixel log partitions;
- the same header/status/folder/center/capability/action vertical sequence;
- the same Layered Reasoning Log title and general placement; and
- the same collapsed/expanded activity-pane concept.

This confirms direct visual lineage rather than coincidental similarity.

## Important Infrastructure Difference

The blank/current shell is not the strongest available framework source.

The accepted module host adds DPI scaling, High Contrast handling, accessible
metadata and role checks, deterministic tab order, bounded visible logging,
explicit path-hardened persistent logging, stale-result rejection, timing
metrics, literal adapter allowlisting, and a 175-pass acceptance harness.

The completed Wasteland launcher also contains extensive accessible labels,
animated explanatory tooltips, tooltip-to-log indexing, detailed validation,
confirmations, and product-specific state behavior that the blank shell omits.

Future launcher work should preserve the current visual identity while moving
underlying infrastructure toward the accepted module-host standard.

## Review Conclusion

Visual lineage: strong.

Current product-specific workflow: intentionally incomplete.

Current hardened-host parity: incomplete.

Recommended direction: preserve the outer visual language, replace the center
and action model with world-policy behavior, and adopt newer host safety,
accessibility, logging, and responsiveness patterns before enabling writes.

No file outside project documentation was changed to create this evidence.

