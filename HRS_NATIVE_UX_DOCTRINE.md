# HRS native UX doctrine

Revision: **2**, updated **2026-10-04**. Owner: **Bit Wrecked**. Revision2 completes the help, copy, newcomer review and external-paperwork rules.

This doctrine records the design rules and reviewed values for the Historical Random Start Windows manager. DEV implements them through the native design recipe and controls; QA checks the resulting customer experience. The companion [DEV manifest](HRS_NATIVE_UX_NEXT_DEV_MANIFEST.md) identifies the work and required evidence.

The current reference is **compact-header preview revision14**, derived from **1.2.6-qa.002**. Its reviewed appearance is a prototype baseline. Production recommendations and outstanding qualification are identified below. This document does not approve publication.

## Product and workflow boundaries

- Keep the customer entry path **START.bat → Windows PowerShell 5.1 → native WinForms manager** and native confirmation dialogs.
- Preserve Standard, Random Any/Chosen/Weighted, saved weights and the independent starting-biome protection choice. A visual revision must preserve their policy meaning and gameplay behavior.
- Keep **Apply Settings**, **Launch Game** and ownership-checked **Uninstall Mod** as distinct actions. Launch is explicit.
- Omit manual **Restore previous settings** from the customer GUI. Retain automatic recovery of prior bytes after a failed Apply, along with required policy/revision/history behavior.
- Uninstall removes the owned HRS installation. It preserves saves, other mods, game files and player progress; it does not reverse a landing or quest destination already saved in the game.
- Preserve the existing major-version compatibility policy and required-hook checks. Report the actually tested game build and qualify other installations within their declared scope. An untested build warning alone is not a demonstrated defect.
- Preserve the existing EAC-off and supplied Harmony requirements. This UX work does not add an EAC toggle or a persisted trader-route repair.

## Information and interaction

Use familiar native controls, compact spacing and clear grouping. Show the available choices before the user acts. Button appearance must agree with actual availability; pressed and keyboard-focus cues describe interaction separately from enabled state.

Keep the logo, **Historical Random Start** title and release label in one header row. Bound the title to available width and allow wrapping at narrow sizes. Remove redundant helper rows while preserving weight statistics, validation, warnings, errors and progress.

The DEV design target is a vertical group of three native radios: **Any biome (equal chance)**, **Choose a biome**, and **Custom weights**. Keep it in a separate parent from Standard/Random. Prefer stable positions for the subordinate picker and Edit weights action, disabling them when inactive. This target is not implemented in revision14. Microsoft recommends radios for visible mutually exclusive choices; WinForms groups them by parent container. [Radio guidance](https://learn.microsoft.com/en-us/windows/apps/develop/ui/controls/radio-button), [WinForms grouping](https://learn.microsoft.com/en-us/dotnet/desktop/winforms/controls/how-to-group-windows-forms-radiobutton-controls-to-function-as-a-set).

Retain the existing meaning of weights: they describe selection among eligible biomes; zero excludes a biome. Placement safety and world availability remain relevant. Compact copy must not promise a particular landing, nearby trader or guaranteed same-biome route. Put necessary explanations in accessible help and customer documentation.

Provide a clearly identified, keyboard/Narrator-reachable Help entry or local README link. Game details currently exposes technical folder/result information; it is not setup help. Keep exact Game Name versus world-name guidance, relative weights, protection limits and the first-session instruction findable without restoring the removed helper paragraphs.

## Task clarity and copy

Review the whole setup journey using [Jakob Nielsen's usability heuristics](https://www.nngroup.com/articles/ten-usability-heuristics/): familiar terms, clear outcomes, predictable choices and correction before committing. Use [W3C cognitive instructions](https://www.w3.org/WAI/WCAG2/supplemental/patterns/o4p07-step-instructions/) to make necessary guidance available when needed. These are review principles for HRS.

Confirmations explain the exact action and consequences. Important failures explain what happened, the verified outcome and the next safe action. Distinguish pre-write rejection, verified recovery and uncertain recovery; a failed Apply does not automatically justify saying nothing changed. Preserve selections during correction. [Microsoft dialog guidance](https://learn.microsoft.com/en-us/windows/apps/develop/ui/controls/dialogs-and-flyouts/dialogs).

State possible fallback conditionally: **If no safe landing is available, HRS keeps the usual start.** Standard omits Random-only wording. Apply confirmation precedes mutation; Settings Applied acknowledgement follows verified completion. Native default-button/Enter/Escape/window-close behavior requires actual qualification. The [UI copy contract](dev-handoff/hrs-native-ux/UI-COPY-CONTRACT.md) defines these surfaces.

Use [WCAG2ICT](https://www.w3.org/WAI/standards-guidelines/wcag/non-web-ict/) as informative guidance for applying accessibility criteria to desktop software, alongside actual WinForms host checks. It is not a conformance claim. Observe a newcomer completing realistic goals without control-by-control coaching and record misunderstandings and assistance. [Usability test guidance](https://www.gov.uk/service-manual/user-research/using-moderated-usability-testing), [HRS newcomer recipe](dev-handoff/hrs-native-ux/NEWCOMER-USABILITY-CHECKLIST.md).

## Reviewed recipe values

Values below describe the prototype source at revision14. Geometry uses the recipe's logical units; typography uses points. Title/logo sizes, compact spacing and button/status treatment are today's reviewed changes. Font family, body size, button height and shared radius are inherited baseline values. High Contrast uses system colors.

| Token or role | Reviewed value | DEV treatment |
| --- | --- | --- |
| Font family | Segoe UI | Preserve native readability |
| Title size | 16pt | Keep bounded wrapping |
| Body size | 10pt | Retain |
| Logo size | 28 logical units | Retain header alignment |
| Content padding | 20 logical units | Retain safe insets |
| General row spacing | 8 logical units | Retain compact rhythm |
| Frame and biome padding | 8 logical units | Retain |
| Choice-row margin | 4 logical units | Retain |
| Shared corner radius | 8 logical units | Retain pending a reviewed change |
| Default command height | 42 logical units | Preserve usable native targets; retain reviewed exceptions below |
| Apply-state badge | 8pt in prototype | DEV target: inherited 10pt body font; review compact layout |
| Normal text | `#242628` | Apply and enabled Uninstall use normal text |
| Enabled button outline | `#85877F` | Apply consistently across styled commands |
| Disabled fill / border / text | `#F4F4F1` / `#E3E3DE` / `#73756F` | Preserve genuine disabled behavior |
| Pending fill / border / text / dot | `#FFF6E6` / `#E6C994` / `#805A21` / `#AE7119` | Amber, with readable pending wording |
| Applied fill / border / text / dot | `#EDF6EF` / `#B7D3BE` / `#316D41` / `#3F7D50` | Green, with verified ready wording |
| Uninstall visual role | Secondary | Same normal enabled text treatment as Apply |

The general spacing/height tokens have reviewed exceptions: native method/biome combos use an 8-unit bottom margin, Edit weights is 154 by 34 logical units and Uninstall is 140 by 32. Preserve those roles and dimensions when integrating; do not force every control to the general choice margin or command height.

Place **Changes not applied.** or **Changes applied.** immediately beside Apply Settings. Text and placement convey state alongside color. Progress, warnings and failures retain their full message area. The 10pt badge is a DEV readability recommendation, requiring new visual review; it is not an already implemented value. [Microsoft WinForms accessibility guidance](https://learn.microsoft.com/en-us/dotnet/desktop/winforms/advanced/walkthrough-creating-an-accessible-windows-based-application).

## Operational state is authoritative

Use one validated selection value and explicit operation/readiness state. Render wording, color and enabled controls from those values. Changing a label must not change application behavior.

Revision14 maps specific status strings to its badge presentation. That mechanism is prototype history. Production must use explicit state, batch saved-policy restoration and refresh once the complete selection is loaded. Reject unknown selections and invalid biome indices explicitly; avoid accidental fallthrough to Weighted or the last biome.

| State or condition | Visible feedback | Required behavior |
| --- | --- | --- |
| Unsaved changes | Changes not applied. | Launch blocked; Apply subject to validation and game state |
| Saved policy without verified installation | Saved settings with a verification instruction | Launch blocked; no green success badge |
| Confirmed Apply in progress | Applying settings... | Prevent repeat/conflicting mutations; Launch blocked |
| Verified write awaiting acknowledgement | Settings Applied popup | Launch blocked until acknowledgement |
| Matching policy, verified installation and cleared acknowledgement gate | Changes applied. | Launch also requires Steam running, game closed and current preflight |
| Error, invalid input, unsafe ownership or missing prerequisite | Specific readable reason | Block the affected action; preserve diagnostics and recovery |

Saved settings alone do not establish a verified installation. Button animation, elapsed time and a green screenshot do not establish successful Apply. Preserve the current acknowledgement gate, fresh launch preflight and verified write/readback contract.

Applied configuration and environment availability are separate. A verified, matching, acknowledged configuration may stay green while Steam is closed; show the launch prerequisite alongside it. Every status refresh and event must respect the active operation guard. Hold it through write/readback and required acknowledgement, then clear it safely on completion or failure.

The success popup follows completed verification. For Random modes it retains the instruction **Do not log out until your first trader is assigned**, with the opening-task and **Journey to Settlement** marker explanation. Standard omits that warning. Assignment is the boundary; the trader visit may happen later. The [trader-session handoff](HRS_TRADER_SESSION_NEXT_DEV_MANIFEST.md) records the accepted known issue and scope.

## Geometry and accessibility

Fit the manager within the actual monitor work area, preserve outer width during automatic height fits and recalculate scroll extent after layout changes. Every action must remain reachable after real minimum resizing, repeated method changes, maximize/restore and monitor moves. The three recorded sizing failures remain open until equivalent tests pass on a new candidate.

Minimum-width captures do not prove minimum-height reachability. The existing 440 by 360 logical-unit minimum, seen as 880 by 720 physical pixels at 200%, belongs to the failing resize scenario and is not an accepted reachability result.

Scale through the actual WinForms host once. Retain safe insets for text, focus and borders; avoid hardcoded patches per monitor. The current captures use Windows compatibility scaling and do not establish per-monitor DPI awareness. [WinForms autoscaling](https://learn.microsoft.com/en-us/dotnet/desktop/winforms/forms/autoscale?view=netframeworkdesktop-4.8).

The supplied rounded-bezel article is hardware guidance. Its clipping and effective-pixel principles inform content protection; its OEM radius range is not an HRS control requirement. Microsoft's 4px control and 8px surface geometry provides an optional reference if separate radius tokens are reviewed later. Current HRS radii remain unchanged. [Rounded-display guidance](https://learn.microsoft.com/en-us/windows-hardware/design/component-guidelines/guidance-for-rounded-display-bezels), [App geometry](https://learn.microsoft.com/en-us/windows/apps/design/signature-experiences/geometry).

Qualify real Tab, arrows, Space, focus visibility, dialog Enter/Escape, Narrator and Windows High Contrast. Preserve accessible names and role information when compacting copy. The local UI Automation provider exposes generic Pane information for ordinary and custom controls; that observation does not establish a failure of actual keyboard or Narrator use. These checks remain outstanding.

## Motion and processing feedback

Keep immediate hover, pressed, focus and status feedback as the default. Optional motion should briefly clarify an interaction or state change and preserve stable controls. The XAML animation library uses a different UI framework; its design principles inform this WinForms recipe. [XAML animation overview](https://learn.microsoft.com/en-us/windows/apps/develop/motion/xaml-animation), [Windows motion guidance](https://learn.microsoft.com/en-us/windows/apps/design/signature-experiences/motion).

| Proposed recipe setting | Value or rule |
| --- | --- |
| Default effect | None; duration 0ms |
| Optional future trial | 120ms background/accent interpolation; an HRS experiment |
| Essential text, focus and action gates | Update immediately |
| Layout, row-height and window-size animation | Disabled |
| Windows animation preference off, query failed or High Contrast | Instant final rendering |
| Operational delay | 0ms; no artificial wait |

If an optional effect is built, query `SystemParametersInfoW` with `SPI_GETCLIENTAREAANIMATION` through a read-only adapter. Respect preference changes and use an instant fallback. Effects must stop on newer state, theme/preference changes or disposal and leave no idle timer. [Microsoft API reference](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-systemparametersinfow).

Current Apply work is synchronous. A UI timer cannot make that work responsive. Use truthful processing text and an explicit busy guard; measure duration before adding a worker. Avoid sleeps or nested event pumping to sustain animation. Cancellation during mutation requires a defined recovery contract; cancelling a decorative effect has no transaction meaning.

## Evidence and maintenance

Keep recipe values, native control source and generated manager traceable by version and hash. Integrate through DEV's generator; its input files are absent from this QA transfer. The prototype's source-string color override is a review aid and must become a normal upstream control change.

Bind QA evidence to candidate, actual host/display profile and observation scope. Label simulated states. The [latest revision14 screenshot](prototypes/hrs-1.2.6-compact-header/screenshots/round-64-uninstall-enabled-final.png) shows the current layout. The [green-state fixture](prototypes/hrs-1.2.6-compact-header/screenshots/round-55-highlight-applied-visual-fixture.png) is appearance-only and includes earlier UI; it cannot prove Apply or Launch behavior.

Human approval establishes expected behavior for a declared baseline. Each machine replay gathers fresh observations. The operator continues to perform starter gameplay through trader assignment; qualified automation can repeat manager/setup checks around that handoff. Keep this doctrine connected to the [QA harness manifest](HRS_QA_HARNESS_ARCHITECTURE_MANIFEST.md) and [structured prototype record](prototypes/hrs-1.2.6-compact-header/preview-summary.json).

The [DEV packet](dev-handoff/hrs-native-ux/START-HERE.md) links the internal contracts and player-facing drafts. README, release notes, Nexus text and known-issue notice must agree with implemented behavior and actual qualification. Final version/build/archive identity and release approval are completed with the returning candidate; prepared copy does not establish a release.
