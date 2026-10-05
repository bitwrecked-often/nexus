# HRS 1.2.6 UX polish

**Current handoff — 2026-10-04:** the owner-authorized source round is complete
and frozen in `1.2.6-qa.003`. The
returned native UX manifest, revision 2
is covered by the acceptance matrix.
The work record records native
recipe integration, compact controls, explicit states/guards, Help/copy,
geometry repairs and the source/candidate evidence boundaries. Customer
verification passed 92 checks and actual extracted START smoke; the
portable transfer is verified
with its own extracted tools. All **46 independent QA cases remain Pending**;
the three returned qa.002 sizing failures still require equivalent actual-host
retests. Runtime source/payload, returned QA and frozen older transports remain
unchanged. Publication follows independent QA and owner approval. See the
readiness record for exact bytes.

**Owner smoothness observation — 2026-10-04:** during the live review of the
exact extracted `1.2.6-qa.003` manager, the owner reported that the animation
and opening felt smoother. Record this as owner-observed presentation quality;
startup latency, frame pacing and the cause of the improvement have not been
measured. It is consistent with the new batched saved-policy projection,
checked-only selection handlers, stable dependent-control positions and settled
layout/scroll/window geometry. Existing custom-control double buffering and
main-form construction batching were retained from 002. No timed decorative
animation was introduced; Apply/Uninstall stopwatches measure operations only.

Microsoft's [WinForms layout guidance](https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.control.suspendlayout?view=netframework-4.8.1)
supports batching related layout changes. Its
[double-buffering guidance](https://learn.microsoft.com/en-us/dotnet/desktop/winforms/advanced/how-to-reduce-graphics-flicker-with-double-buffering-for-forms-and-controls)
explains the retained flicker-reduction approach. The guarded restore callback
uses [BeginInvoke on the control's UI thread](https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.control.begininvoke?view=netframework-4.8.1)
to finish native restoration; it does not move Apply to a worker thread.
[Windows motion guidance](https://learn.microsoft.com/en-us/windows/apps/design/signature-experiences/motion)
favors fast, direct feedback and consistent use of existing OS behavior. Its
WinUI examples inform design principles; HRS remains native WinForms.

Preserve the observed smoothness in future recipe changes: restore settings as
one batch, keep hit targets stable and avoid repeated visible bounds changes.
If a future performance claim is wanted, compare exact 002/003 packages on the
same host at the same scale, separate cold/warm opens, measure time to an
interactive settled window and record visible flicker/jumps alongside timings.
Optional paint-only motion remains deferred under the returned doctrine and
must respect the Windows animation preference; off, unknown or High Contrast
uses instant rendering. This review note and the source-based draft release
wording are post-export documentation only. Frozen customer/transfer bytes and
all 46 Pending independent cases are unchanged; owner familiarity does not pass
newcomer acceptance. The visual review record
binds the observation to the exact customer manager and retained capture.

**Source-round authorization checkpoint — 2026-10-04:** the owner authorized implementing the
returned native UX manifest, revision 2.
The frozen 002 manager's native sizing attempt failed on three demonstrated
geometry defects; its original 41-case ledger remains Pending. Current source
integration and acceptance are recorded in round 2.
Integrate the compact design through the generator, preserve gameplay and
automatic failed-write recovery, and return a newly identified candidate.
Actual display/accessibility/gameplay and newcomer qualification remain distinct
from disposable component checks. Earlier exported-candidate checkpoints below
are preserved history.

Date: 2026-10-03
**QA packaging — exported and verified, 2026-10-03:** the owner requested
continuing to a review package. Frozen `1.2.6-qa.002` contains the integrated
source and unchanged qualified runtime, with new frozen contracts. Independent
extraction, 144 package checks, clean source/extracted gates and actual START
smoke passed. See the **Polished QA candidate 002** checkpoint below and
QA readiness record for exact transport
files. QA, customers and eventual Nexus/site distribution use the same customer
ZIP; receipt and engineering support remain separate. All 41 independent QA
cases remain Pending, including actual OS presentation and gameplay.
The installed game assembly differs from the qualified b17 input. This
presentation-only candidate authenticated the frozen `.001` archive/companion
and proved exact runtime source/payload/build-record equality before retaining
its b17 target. No runtime rebuild or current-game certification is claimed.
Earlier ZIPs, receipts, companions, build records and public-release map remain
preserved. Active contracts and registry advanced to 002; prior contract and
registry bytes are snapshotted in the packaging record. The portable QA transfer
is built and independently verified; use its `qa-002/START-HERE.md` entry.

**Manager tooling integration — implemented and offline verified, 2026-10-03:**
the owner's request to apply the graphical workbench tooling to the whole real
manager is complete in source. The Quiet recipe and native controls are embedded
in `dev/ui/p0158.ps1`; the manager and weights dialog share the new presentation.
Real callbacks, confirmations, the exact trader warning, acknowledgement and
Launch gates are preserved. The existing 12-file customer layout passed its
actual START smoke without adding graphics modules or recipe files. Evidence is
under `dev/qa/ux-polish/design-integration/`; the **Integrated native graphics**
checkpoint below records the source pass. Actual OS scaling, high contrast,
Narrator and operator visual review remain Pending in the new 002 QA contract.
No runtime repair, game installation, game launch, independent gameplay QA or
publication occurred. Earlier frozen candidates remain unchanged.

Status: source polish and native graphics integration implemented and offline
verified; polished candidate `1.2.6-qa.002` frozen and package-verified;
first-time-user walkthrough and optional design guidance recorded; all 41
independent QA cases and publication remain pending

The **Integrated native graphics** checkpoint below is the latest source pass.
The **Polished QA candidate 002** checkpoint is the current package resume point.
Earlier checkpoints describe their source at the recorded time; their captures,
claims and verification records retain their original source hashes.

**Earlier DEV tooling work — 2026-10-03:** the owner requested local graphics
and presentation tools using the dev box's existing native facilities, with no
new downloads or Adobe purchase. Build a reusable WinForms/System.Drawing
workbench under `hrs_1.2.6/dev/tools/NativeGraphics/`. Scope: antialiased surfaces,
outlined controls, code-drawn icons, editable presentation settings, preview and
PNG/ICO export. Keep production manager source, callbacks and frozen artifacts
unchanged during this tooling pass. Verify actual tool entry points, export
formats, invalid-input refusal, keyboard/disabled behavior and protected hashes;
record simulated scale/high-contrast checks separately from actual OS display
and assistive-technology review. Tooling is implemented and offline verified;
the **Recipe-driven rework** checkpoint below records that tooling pass. The
subsequent manager integration is recorded in **Integrated native graphics**.

**Recipe rework — implemented, 2026-10-03:** the owner requested a rework using the
new recipe approach. Create named Quiet and Contrast JSON recipes with shared
human guidance and an optional Mermaid flow; bind their actual values to the
native workbench and card renderer. Quiet remains the light, unshaded manager
direction; Contrast targets release graphics. Build a complete proposed manager
study with compact Standard mode, real Chosen/Weighted preview controls,
visible limits and disclosed details. Verify rendering consumers, recipe change
propagation, invalid/unsupported recipes, preview state and preserved hashes.
At that checkpoint this was a DEV design rework in the workbench. Its subsequent
integration into the real manager is recorded below. Frozen candidates remain
unchanged.

The owner requested a quiet, minimalist Bit Wrecked manager and natural search
wording in the public release copy. They confirmed that the target is HRS
1.2.6, rather than a separate 1.3.6 website.

## Scope and preserved behavior

Refine `hrs_1.2.6/dev/ui/p0158.ps1`, its picture-only `logo.ico`, the customer
README, release notes and publication copy. Reuse the existing controls,
selection bindings and Apply,
launch, recovery and uninstall callbacks. Keep the exact Game Name instruction,
selection odds and fallback limitations, optional protection boundary, verified
post-Apply acknowledgement, and first-session trader notice.

The manager is a native Windows application. Search improvements belong in
natural public copy and proposed website title/description fields. This checkout
contains no project website to edit; metadata instructions are a publishing
handoff rather than deployed website changes.

The frozen `1.2.6-qa.001` archive, receipt, companion, registry, QA contracts,
runtime payload, prior candidates and public-release map remain unchanged.
The polished source differs from that archive and needs a new candidate and
independent QA before publication. Do not inherit the old package verification
as verification of the new manager. The existing 41 QA cases remain Pending.

## Optional design guidance for future tools

Owner direction on 2026-10-03: keep the nine forum concern categories as options
to draw from later when a tool asks what the manager should look like or aim
to achieve. This is a design reference, not a request to implement every option
or start another source pass. Select relevant options within the future task's
scope. The existing behavior and QA requirements still apply.

**Appearance and purpose:** a calm, compact native Windows manager with a warm
neutral surface, comfortable Segoe UI text and restrained orange Bit Wrecked
branding. A newcomer should see the main choices, understand the current state
and know the next action. Keep the manager's wording practical. Public copy
should name Historical Random Start and 7 Days to Die naturally, with search
metadata supplied through the publication handoff.

**Logo rule — owner direction:** display the existing Bit Wrecked picture by
itself, with no brand name underneath or inside the logo. Use the picture-only
`hrs_1.2.6/dev/ui/Assets/i0141.png` or its existing `logo.ico` equivalent rather
than the image containing the large BIT WRECKED lettering. Keep an accessible
name for the image. Ordinary product titles and public-copy brand attribution
remain separate from the logo artwork.

**Copy rule — owner direction:** keep manager wording short. Use labeled
settings summaries, state each caution once, and show build caveats only when
they apply. Retain exact Game Name, selection/weights, protection boundaries,
one-shot behavior, fallback and first-session instructions. Detailed technical
explanation belongs in the README or disclosed details rather than routine
confirmation prose.

**Highlight style — owner-approved option, 2026-10-03:** the owner supplied an
`UPDATE / 3.3.0 EXP` game banner as a contrast reference. It pairs a dark
charcoal ground with a bold white heading and a bright lime-green highlight;
the most important information is immediately distinct. Keep this as an
additional highlight option alongside the quiet Bit Wrecked direction. Possible
uses are a compact version badge, a next-action or applied-settings summary,
a last-start result, or a public release headline. Use one clear focal point,
short text and generous separation. Keep ordinary controls readable and the
picture-only logo intact. State readiness and results in words; decorative
emphasis must not imply that pending settings or an unverified landing have
succeeded. This reference adds an appearance option, not a requirement to
apply a green theme or reproduce the banner's character artwork. Exact colors
and native Windows rendering have not been selected or verified.

**Current manager choice — owner direction, 2026-10-03:** after reviewing the
dark status panel, the owner selected **Light surface with small orange
highlights**, then asked to unshade **Apply Settings**. The banner remains a
reference for clear hierarchy and restrained emphasis; its charcoal/lime palette
is an optional reference for future uses. Use the light neutral main form with
orange limited to the release label and Game details interaction. Apply Settings
and Launch Game use white backgrounds, dark text and subtle gray outlines.
Keep status and next-action text compact on the plain surface.

| Reference | Optional aim | Possible HRS treatment |
| --- | --- | --- |
| F01 | Comfortable reading and clear contrast | Readable labels and status text; inspect actual Windows scaling and popup legibility. |
| F02 | Recognizable actions | Subtle button boundaries, descriptive labels and visible keyboard focus, including maintenance actions. |
| F03 | Find important information easily | Visible state and last-start summary; disclose paths and technical detail separately. |
| F04 | Fewer steps in routine setup | Show mode-relevant settings and keep the next action nearby; preserve required confirmations and acknowledgement. |
| F05 | Efficient use of window space | Compact spacing that accommodates both modes, wrapping and scrolling on smaller work areas. |
| F06 | Familiar, predictable operation | Native controls and keyboard navigation; preserve saved choices when switching modes. |
| F07 | Recognizable identity and state | Consistent Bit Wrecked accent; label current, stale, unavailable and blocked states clearly. |
| F08 | Calm visual presentation | Opaque neutral surfaces and restrained decoration; keep the settings and actions visually prominent. |
| F09 | Useful control over appearance | Consider display and appearance preferences where relevant; check high-contrast readability before deciding whether additional appearance controls would help. |

The forum review preserves the
source links, grouping and limitations of the nine categories. Its four HRS
follow-ups are possible refinements: expose the result summary, clarify
maintenance buttons, tighten Standard-mode space and explain disabled Launch.
They remain proposals. This optional guidance does not establish nine HRS
defects, a theme-system requirement, or release approval.

## Work order and acceptance

**Active follow-up — 2026-10-03:** the owner's **continue** instruction selects
the first-time-user review's N01/N02 saved-state and readiness fixes, N04 visible
result summary, N05 maintenance clarity, and a short N06 setup-copy pass.
The subsequent owner selection replaces the charcoal/white/lime panel with a
light surface, small orange highlights and compact status text.
Preserve the current first-launch Standard default (N03 remains a product
choice), remembered Random controls, the native logo and all installation,
ownership, confirmation, acknowledgement and first-session warning boundaries.
N07 is limited to sensible spacing within this layout; additional appearance
controls and a new candidate are outside this pass.

Verify fresh/invalid-name gates, edits and exact reverts across effective fields,
Steam refresh while dirty, loaded policy behavior, popup activation, failed
Apply after edits/reverts, result freshness and maintenance/removal through the
existing disposable callback harness. Inspect fresh, applied, dirty, result and
narrow-window captures. Evidence belongs in `ux-polish/clear-state/`; protect
the same frozen files and keep independent QA Pending.

1. Inspect and capture the existing manager; record protected-file hashes.
2. Refine hierarchy, typography, spacing and secondary actions. Keep labels
   readable, keyboard access intact, and narrower/scaled windows scrollable.
3. Rewrite README and listing copy with clear product/game names, concise
   setup instructions, honest compatibility and the known trader limitation.
4. Parse the real manager in Windows PowerShell 5.1; run its smoke path and
   inspect manager and weight-dialog captures. Run existing disposable callback
   checks for selection, post-Apply warning, failure and Steam refresh.
5. Record results and remaining actual display-scale/operator checks. Recheck
   protected hashes and update the development/publication resume points.

Evidence goes in `hrs_1.2.6/dev/qa/ux-polish/`. Synthetic scaling and captured
callback fixtures are DEV evidence, not live gameplay or actual Windows scaling
certification. The development doctrine remains the governing working method.

## Result — 2026-10-03

The native manager uses Segoe UI, a warm neutral background, a picture-only
Bit Wrecked logo and restrained orange primary action, a borderless biome panel, and
separate setup and maintenance actions. Game details are collapsed by default;
opening them reveals the existing result and game folder and scrolls them into
view. Descriptions wrap with window width, and narrower windows scroll
vertically. The weight editor uses the same typography and button treatment.

The follow-up review on the same date tightened the header into a single
brand/version row and enabled native Windows visual styles. Standard hides
the Random-only biome and protection controls and shows a short explanation;
Random reveals those controls. Switching modes preserves the selected method,
weights and protection preference. The default window is 40 pixels shorter.
The website title and description now read as ordinary product copy.

The README now groups setup, first-session guidance, selection and maintenance
under clear headings. The listing fields
carry natural product/game wording and proposed website title, description and
share text. The existing trader-session popup text and Apply acknowledgement
callback are unchanged. The original frozen-candidate release draft is
preserved separately; updated release notes describe the new source.

The verification record records:

- Windows PowerShell 5.1 parsing and the real manager smoke path passed,
  including weight-editor zero rejection, save/cancel and selection retention.
- Twelve existing disposable callback cases passed against the follow-up source
  recorded in that verification file:
  Standard Apply/cancel; Any, five Chosen and two Weighted selections; injected
  policy-readback failure with rollback and blocked Launch; Steam activation
  refresh after a Steam-closed Random Apply. Popup fixtures capture modal text
  and state rather than displaying the real success popup.
- A disposable capture driver exercised Standard, Any, Chosen, Weighted,
  primary-action scrolling and the details disclosure at synthetic 100%, 150%,
  200% and 225% geometry scales. Keyboard navigation from Game Name reaches the
  selected mode. A 424-pixel client-width window wraps descriptions, preserves
  vertical scrolling and has no horizontal scrollbar.
- All ten recorded protected-file hashes matched. The frozen candidate's 41
  independent cases remain Pending. Windows CRLF source bytes are retained;
  `git -c core.whitespace=cr-at-eol diff --check` passed.

The capture driver is local generated work in `hrs_1.2.6/dev/tmp/`; its output
images and layout records are preserved with the evidence. Synthetic scaling
changes geometry and does not certify real Windows DPI/font scaling. The weight
dialog was visually inspected at the current desktop scale. Real popup
legibility, actual Windows 100%/150%/200%/225% scaling and fresh-tester review
remain operator checks. No live game installation, gameplay, export or upload
was performed.

The manager preview and
weight editor
show the current source. When packaging is
requested, use the QA bundle skill and a new candidate identity, regenerate its
contracts from the final bytes, and complete
independent QA before publishing.

The follow-up source passed the same twelve callback cases, parser and smoke
checks. Updated captures also verify conditional visibility and retained Random
preferences across mode switches. The current verification record describes
the follow-up source before the logo update. First-pass verification, callbacks
and representative previews
are retained under `hrs_1.2.6/dev/qa/ux-polish/first-pass/`.

## Forum-informed rethink — 2026-10-03

The owner subsequently requested research into Apple user forums. The
forum review records source links,
mixed user experiences and the limits of self-selected feedback. Its revised
direction prioritizes readable controls, discoverability and efficient space
while retaining the restrained Bit Wrecked identity.

Options for a future source pass: expose a concise last-start summary while
disclosing technical details, make maintenance buttons recognizable, reduce
excess Standard-mode space, and explain disabled actions using existing gate
state. Preserve result freshness distinctions, failure messages, callbacks and
the trader notice. These refinements are proposed, not implemented or verified.
This research checkpoint changes documentation only and does not supersede the
current source verification. Use the forum review's relevant acceptance criteria
when a future task selects a refinement for implementation.

The owner's subsequent forum recount is recorded in the same review: three
initial themes, nine distinct UX concern categories across the four reviewed
thread pages, and four specific HRS corrections. These are category counts,
not numbers of complainants or independently verified HRS defects.

## Picture-only logo — 2026-10-03

The owner requested the picture alone, with no name below it in the logo. The
existing picture-only `Assets/i0141.png` supplies the artwork for regenerated
16/24/32/48/64/128/256-pixel frames in source `logo.ico`. The manager header now
shows that picture with an accessible name in place of the visible brand
wordmark. Main-window and weight-dialog icons use the same picture-only icon.
Native icon drawing avoids a Windows PowerShell 5.1 bitmap-conversion problem
with PNG-compressed ICO frames. No new image design was generated.

The logo verification
records Windows PowerShell 5.1 parsing, the real manager/weight-editor smoke
path, visual inspection of both captures, and Standard Cancel/Apply callback
fixtures. All twelve existing click/selection/activation callback expressions
match the preserved source baseline. A synthetic 100% capture pass checks
mode settings, retained preferences, keyboard order, details and scrolling,
including a narrow window. All ten protected-file hashes still match.

The other callback scenarios and higher synthetic scales retain their earlier
source evidence; they were not rerun for this logo change. Actual Windows
display-scale and success-popup checks remain pending. The prior verification
files retain their original source hashes. The old icon is preserved as
`ux-polish/picture-only-logo/before-logo.ico`. Frozen candidate bytes and the
41 Pending independent QA cases remain unchanged; this source/icon update
requires a new candidate before publication.

## Concise confirmation copy — 2026-10-03

The owner supplied a screenshot of the pre-Apply confirmation and asked for
less wording. Its title is now **Apply settings?**. It lists exact Game Name,
biome choice or weights, and starting-biome protection, followed by short notes
about normal-start fallback, existing characters and separate launch. Standard
omits the Random landing fallback. The untested-build notice appears only for
an unverified build and keeps the best-effort/normal-start boundary.

The Chosen description no longer repeats the fallback sentence. Any still
describes equal chances among eligible biomes; Weighted still lists all five
configured values. These descriptions also make the verified success summary
shorter. The approved Random trader-session warning remains verbatim, including
the opening-task cue, Journey to Settlement marker and early-logout limitation.
The confirmation/verification/acknowledgement/Launch order is unchanged.

The screenshot's Wasteland/protection-On/untested-build example decreased from
80 to 43 whitespace-delimited words (46.2% fewer), using the same Game Name.
The copy comparison
records both bodies evaluated from source; the
short example
is available for review. The existing callback fixture now captures the full
confirmation body as well as its build notice; its compatibility assertion
uses the revised notice wording.

The current verification
records Windows PowerShell 5.1 parsing and the real manager/weight-editor smoke
path. All 28 existing disposable callback cases passed: Standard Apply/cancel,
eight Any/Chosen/Weighted cases, failed readback/rollback, Steam refresh and
sixteen launch guards including untested builds. The Apply callback matches the
preceding source outside the confirmation copy and title. All ten protected
file hashes still match. Real modal display-scale review remains pending;
captured text is not a live-popup legibility pass. No gameplay, export or
publication occurred. Prior verification records retain their original source
hashes, and the frozen candidate's 41 independent cases remain Pending.

## First-time-user UX review — 2026-10-03

The owner requested a once-over as a new user. This is a heuristic walkthrough
of the current manager, weight editor, README and public-copy draft, supported
by source inspection and isolated Windows PowerShell 5.1 captures. It is not
an independent participant study or customer gameplay QA. The findings below
are proposed follow-ups; this review does not implement them or select all nine
forum options for implementation.

The picture-only logo, restrained accent, native controls, mode-specific settings
and readable weight editor give the manager a clear visual identity. Public copy
names the product and game naturally without obvious keyword repetition. The
largest remaining friction is knowing which settings are saved, what action is
available, and whether HRS completed the intended start.

Priority below indicates the suggested order of a future UX pass, not a new
release gate or an observed runtime failure.

| ID | Priority | New-user friction and evidence | Proposed treatment |
| --- | --- | --- | --- |
| N01 | High | Edited fields have no clear unapplied state. In the isolated saved-policy simulation, changing `Applied Save` to `Different Save` leaves the old readiness text and Launch enabled. Changing Standard to Random replaces the text with generic readiness while the installed policy remains Standard. The Launch callback reads the installed policy; it does not compare it with current form inputs. There is no Game Name `TextChanged` binding. | Compare all editable settings with the verified applied policy. Show **Changes not applied** when they differ and require a successful Apply plus acknowledgement before launching those settings. Reverting fields should restore readiness only when the installed policy remains valid. |
| N02 | High | Fresh setup says **Ready to apply settings** and enables Apply with a blank required name. With the simulated Steam process running, Launch is also enabled despite no installed policy; the existing `BeforeApply` callback fixture confirms that clicking it is safely rejected. With Steam closed, Launch is disabled without an adjacent reason. Apply reports invalid names through a modal containing codes such as `GAME_NAME_REQUIRED`. Changing a selection also replaces a simulated failure message with generic readiness. | Guide the current step: **Enter a Game Name**, **Apply settings**, **Open Steam to launch**, or a specific blocked reason. Use inline name validation and align button availability with actual prerequisites. Keep errors until resolved or deliberately dismissed, and retain the fail-closed callback checks. |
| N03 | Medium; product choice | First launch selects **Standard start**, although the product introduction promises a random beginning. A user who accepts defaults receives the usual start. The Standard explanation is accurate, so this is an expectation mismatch rather than a binding defect. | Consider Random / Any as the fresh-install default, or make the need to select Random explicit. Preserve loaded settings and the optional protection preference. A future implementation should resolve this product choice explicitly rather than silently changing saved policies. |
| N04 | Medium | The answer to **Did it work?** is hidden with the game folder under **Game details**. Current-result text joins raw outcome and reason values with `/`; a newcomer must find the disclosure and interpret the codes. | Show one concise last-start summary outside technical details. Keep current, earlier-settings, no-result and invalid-result distinctions truthful; translate outcomes for players and retain codes and paths in details. Do not equate **Settings Applied** with a completed in-game landing. |
| N05 | Medium | **Restore Previous** and **Uninstall Mod** look like plain text at rest. Both are enabled on a fresh screen with no installed policy or recovery history. **Restore Previous** can also imply restoring a save or character, although the confirmation and README correctly describe settings recovery. | Use recognizable quiet actions and label the restore action **Restore previous settings**. Reflect whether restoration is available, and explain unavailable actions using known state without obscuring verification errors. Keep existing confirmation and ownership checks. |
| N06 | Medium | The main Game Name helper explains exact matching but omits the README's distinction between the save's Game Name and the generated world's name. The README leads with several compatibility and implementation paragraphs before the setup steps. The trader reminder is available after Apply and in the README, but has no discoverable route from the manager after dismissal. | Use a short save-name example or helper such as **Use your new save's Game Name, not the world name.** Put the quick-start path near the top of the README while keeping actionable compatibility requirements visible. Offer a quiet route to setup and first-session help; preserve the approved trader-session modal verbatim. |
| N07 | Low | Standard leaves substantial blank space below its controls. At a 424 × 520 client area in Weighted mode, primary actions are below the initial viewport; vertical scrolling reaches them and no horizontal scrolling was observed. | Tighten the content and initial window height where practical. Consider keeping the current next action visible on smaller work areas while preserving wrapped text, normal scrolling, native keyboard order and user resizing. Verify actual Windows DPI settings before declaring the layout complete. |

Recommended next source pass: address N01 and N02 first, then N04 and N05.
N03 remains a product-default choice. N06 and N07 can accompany a later copy
and spacing pass. Relevant optional forum references are F02, F03, F04, F05,
F06 and F07; their original nine-category count is unchanged.

Evidence is under
`new-user-review`:

- Fresh screen, Steam running,
  Random / Any,
  narrow initial view
  and actions reached by scrolling.
- Edited name after simulated applied state
  and all eleven state observations.
- Capture method:
  staged final smoke driver, controlled process state and an inert disposable
  game folder. The applied-readiness and error texts were simulated for UI
  inspection; no Apply, Launch, Restore or Uninstall callback was invoked.
  Existing callback verification is cited rather than rerun for this review.

The reviewed manager hash remains
`FAAF40BBD2EECA106FE73F3BD366797404C5E6FF686809486411B2448CE2E9E6`.
No manager, logo, launcher or customer-copy source changed during this review.
The current 28-case callback evidence retains its original hash and scope.
Actual Windows display-scale and native-modal legibility checks remain pending,
along with all 41 independent frozen-candidate QA cases. No live game operation,
candidate export or publication occurred.

The owner's subsequent repeat review request was checked against the same
manager hash and existing captures. The seven findings and their priorities
still apply; no duplicate findings or QA passes were added. Their accompanying
contrast reference is recorded in **Highlight style** above. A stronger focal
highlight could support N02's next action and N04's result summary once their
state text is accurate. Current source and verification remain unchanged.

## Clearer state and contrast — 2026-10-03

The owner requested continuation after the review and contrast reference. The
manager now uses one compact charcoal panel with white state text and a lime
next-action line. Bit Wrecked's picture-only logo and orange primary action
remain the identity cues. Buttons distinguish enabled and disabled states from
initial display onward; maintenance actions have subtle borders and the restore
label is **Restore previous settings**.

Fresh setup asks for the save's exact Game Name and disables Apply until the
name and active weights are valid. It distinguishes the save name from the world
name. Edits to name, mode, protection, method, chosen biome or active weights
show **Changes not applied** and disable Launch. Comparison uses the effective
policy, including case-sensitive name matching, while ignoring remembered
controls that are inactive in the current mode. Reverting to matching settings
restores availability only when installation, game/Steam state and the existing
Apply latch permit it. Edits themselves do not write policy or advance revisions.

Launch requires matching v2 settings and verified installed files. The callback
also checks matching fields and the failure/acknowledgement latch, independently
of button availability. Activation refreshes current process and installation
state without clearing an unresolved error. A confirmed failed Apply stays
blocked even after edits, reverts and activation; success clears the latch only
after the existing **Settings Applied** acknowledgement. The trader warning is
verbatim, Random-only, and does not imply an in-game landing has completed.
Verified-package reopen can use intact saved settings; DEV still requires Apply
in that manager session. Restore plans reuse the existing validated history
path. Fresh/missing history disables Restore, and uninstall clears cached state.
Cancel, Restore and Uninstall confirmations survive activation; deliberate form
edits clear informational notices so they cannot mask unapplied changes. Errors
remain separate and survive ordinary edits and activation.

**Last start** is visible above maintenance actions, with plain descriptions of
completed, pending, skipped, failed and incompatible outcomes. Earlier-settings,
missing and invalid results remain distinct. Raw outcome/reason codes and the
game folder stay under **Game details**. An unconfirmed runtime lane is not
incorrectly described as a game-build mismatch. Installation-integrity errors
take priority over a simultaneous recovery-history error.

The README brings setup forward while keeping target build, platform, map scope,
EAC-off and supplied Harmony requirements visible. It explains reapplying edits,
the last-start summary and settings-only restoration. Detailed compatibility
follows the setup path. Updated release notes describe this source behavior.

The verification
records 55 disposable callback scenarios on the final manager hash, including
nine new UX state scenarios, plus Windows PowerShell 5.1 parser/manager smoke
and synthetic 100/150/200/225% layout checks. Captures show real controls after
disposable fixture Apply and edits, with codec-generated synthetic result states.
Process state is controlled, game binaries are inert, modal text is intercepted
and launch requests are captured. This is offline DEV
evidence, not independent customer gameplay or native-popup legibility proof.
The protected-byte check
keeps all ten frozen/reference files unchanged.

The reviewed first-launch Standard default remains (N03). N01, N02, N04 and N05
are addressed in source; N06's name/README improvements are implemented while
a dedicated help route remains an option. A compact Standard window or retained
action footer (N07), actual Windows DPI/modal checks and independent QA remain
future work. The nine forum categories remain optional references. All 41
frozen-candidate independent cases remain Pending, and this source needs a new
candidate before publication. No live game operation, export or upload occurred.

## Light surface and orange highlights — 2026-10-03

After reviewing the manager screenshot, the owner selected **Light surface with
small orange highlights**. The `UPDATE / 3.3.0 EXP` banner remains a hierarchy
reference. The manager's dark status block and lime text have been removed.
The release label and primary Apply action use the existing Bit Wrecked orange;
status and next-action text sit directly on the light surface. The picture-only
logo remains intact. Status labels use the available content width after the
old panel padding was removed.

The screenshot also exposed contradictory wording for a reopened DEV policy.
Matching loaded settings now say **Saved settings**, followed by **Apply
Settings to verify before launching** when the current session has not verified
them. **Settings ready** requires verified installation and a cleared Apply
latch. Steam and game-process restrictions still have their own next-action
instructions. The earlier-settings result summary is shortened to **Last start:
earlier settings**; its full freshness explanation stays under Game details.

This follow-up changes presentation and state wording. Apply, acknowledgement,
Launch, recovery and uninstall callbacks retain the previous checkpoint's
behavior. The required first-session warning remains verbatim. The charcoal/lime
reference remains an optional future treatment; the current manager direction
is the owner's explicit light/orange choice.

The current verification
records 64 passing offline callback scenarios on final manager SHA256
`B739D7CF396B24C6F8C4313E6E21FAFDF0D002EAE410C2BBFDA3FC93EE2FED67`:
the previous 55-case set rerun on this source plus nine DEV UX scenarios.
Both nine-scenario UX branches passed 69 assertions, including explicit saved
versus ready wording on reopening. Windows PowerShell 5.1 parsing, the real
manager/weight-editor smoke check and synthetic 100/150/200/225% layout checks
also passed. Native fixture captures show verified settings
and loaded DEV settings.

The protected-byte check
confirms all ten frozen/reference files are unchanged. Results remain isolated
offline evidence, with controlled process states, intercepted modals, captured
launch requests and synthetic result fixtures. Actual Windows DPI/popup review
and all 41 independent customer QA cases remain pending. No live game operation,
candidate export or publication occurred; this source still requires a new
candidate before release.

## Unshaded Apply button — 2026-10-03

The owner asked to remove the filled background from **Apply Settings**. It now
uses the same secondary treatment as **Launch Game**: a white background, dark
text and a subtle gray outline. On the main form, orange is limited to the release
label and Game details interaction. This changes the button's presentation only; its enabled
state, callbacks, confirmation and verified acknowledgement flow are preserved.

The previous light/orange checkpoint and its 64-case evidence retain their
original source hash. The polished source remains outside frozen
`1.2.6-qa.001` and requires a new candidate and independent QA before publication.

The verification
confirms the source differs from the prior checkpoint only in the Apply styling
call. Windows PowerShell 5.1 parsing and the existing seven-state native preview,
navigation and layout check passed. The updated preview
was visually inspected. All ten protected files remain unchanged. The prior
64-case callback suite was not rerun for this presentation-only change.

## Native graphics workbench — 2026-10-03

The owner authorized local presentation tools using existing native facilities,
without downloads or a paid graphics suite. Windows PowerShell 5.1 successfully
loaded .NET Framework WinForms, System.Drawing and WPF on this box. The selected
implementation uses additive WinForms custom drawing with ordinary native
inputs. Production manager source remains at the unshaded Apply checkpoint.

The tool directory and instructions
provide `Open-Workbench.cmd`, an interactive manager study, reusable component
palette and Light/Contrast release-card studies. Shared controls render rounded
surfaces, outlined buttons, compact badges and six code-drawn vector glyphs.
`theme.json` provides colors, spacing, font and initial corner settings; toolbar
choices preview corners and text size. Apply/Launch in the study only update
preview state. They do not call HRS installation, policy or launch functions.

Export tools produce native-control PNG captures, 1440 x 810 composition studies,
30 transparent glyph PNGs at five independently drawn sizes, and a seven-size
picture-only ICO. Export receipts bind tool/theme bytes to output hashes. The
launcher uses installed Windows PowerShell 5.1 in STA with a hidden console.
PowerShell Core receives a clear compatibility message. No SDK build, dependency
restore, download, installation or external service is used.

The workflow verification
passed eight check groups: PowerShell parsing, actual workbench transitions and
display settings, all 37 exported assets and hashes, decoded PNG/glyph content,
ICO frames/loading, all three CLI export modes, invalid export/theme refusal,
native Space/Enter and disabled-button behavior, accessibility state, and
preserved source/release bytes. The count groups related checks rather than
claiming eight customer QA cases. The manager study,
components and
contrast card
were visually inspected; initial button clipping and truncated toolbar choices
were corrected before the final run. The hidden-tab activation probe, child-font
preview and dynamic badge accessibility were also corrected during review.

The production manager and all ten frozen/reference files match the prior
checkpoint. The 41 customer QA cases remain Pending. These tools are reusable
DEV options and are not incorporated into the customer package. Actual operator
keyboard/Narrator, Windows high-contrast and monitor DPI checks remain distinct
from offscreen event probes and simulated custom-control color rendering.
Raster preview enlargement is not a DPI rerender. Future manager integration
must retain current behavior and receive its own source/candidate verification.

## Recipe-driven rework — 2026-10-03

The owner's requested rework is available in the native graphics workbench.
Two named JSON recipes replace fixed presentation choices:
Bit Wrecked Quiet
for the manager and light release card, and
Bit Wrecked Contrast
for charcoal/white/lime release graphics. The
recipe guide records intent,
target-specific values and an optional Mermaid map of the real Apply contract.
Mermaid is documentation; JSON and renderer code produce the graphics.

The manager study has one light column, a picture-only logo, a small orange
version label, white outlined actions and compact status text. Standard hides
Random-only choices and reduces the panel height. Any, Chosen and Weighted
provide real preview controls: Chosen has a biome dropdown; Weighted has a
native numeric editor, normalized shares, zero-total refusal and Cancel/Use
handling. Mode switches remember the preview weights. Safe-landing fallback
and the environmental protection boundary remain visible. Last-start text,
disabled maintenance actions and disclosed Game details complete the proposed
layout. These are simulated design states, without policy loading, installation,
readback, HRS confirmation or a live result.

Review the full Standard study,
Any study,
Chosen study,
Weighted study
and contrast release card.
All were inspected for hierarchy and clipping at the exported size. The
release reference informs text-left/art-right composition and contrast; its
character artwork was not used. Existing artwork can be supplied separately
through the CLI. Default geometry is a code-drawn route study.

The strict recipe loader accepts presentation data and rejects unknown fields,
unsupported layouts/targets, invalid values and missing required invariants.
The workbench consumes relevant manager palette, type, spacing, geometry and
copy values. Card rendering consumes its recipe's palette, font, composition
dimensions and copy. Copied/custom recipe files are loaded by their actual
paths in the release preview. Export receipts bind recipe, renderer, logo,
supplied artwork and output hashes; temporary card receipts are cleaned up.
`theme.json` is retained as a legacy helper, outside the current appearance path.

The verification record
passes nine workflow groups, including actual Windows PowerShell 5.1 workbench
and CLI entry points, 41 decoded and hash-matched graphics, card input receipts,
preview choices/states, native keyboard/accessibility probes, invalid-input
refusal and protected-byte checks. A modified recipe was rendered through both
consumers: the manager width changed to 576 pixels and its glyphs became teal;
the supplied-artwork card changed to 1280 x 720 with a different background.
Release-only Contrast was refused for the Manager target before output. Counts
refer to developer workflow groups, not independent customer QA cases.

The production manager remains SHA256
`5161ED60A0F65020327BCA2F6AF6CC998A50EDA6C89C2BA17F0F6681D2F35896`;
all ten frozen/reference files match the unshaded Apply checkpoint. The earlier
native-graphics evidence retains its original 37-asset inventory and source
hashes. No dependency downloads, game actions, candidate export or publication
occurred. All 41 independent frozen-candidate QA cases remain Pending.

This is a reviewable DEV rework. Integration into the manager must retain its
real confirmations, exact Random trader notice, acknowledgement, failed-Apply
latch and launch gates, and receive new source/candidate verification. Actual
operator keyboard/Narrator, OS high contrast and monitor DPI remain pending.
Changed recipe geometry, fonts or copy require regenerated text-fit review;
the default release cards are 1440 x 810. Use
Open-Workbench.cmd
to review or modify the proposed styles locally.

## Integrated native graphics — 2026-10-03

The owner authorized applying the workbench tooling to the whole real manager.
The working manager source now embeds the validated
Quiet recipe and shared native C# controls generated by
Sync-ManagerDesign.ps1.
Edit the recipe or shared controls, synchronize the generated region, then
verify the resulting source. The `-Check` entry reports stale generated content
without writing. Customer execution consumes the embedded source; it requires
no new downloads, graphics module files or JSON files alongside the manager.

The real manager and weights dialog use light rounded surfaces, Segoe UI,
picture-only branding, small orange highlights and white outlined actions.
**Apply Settings** remains unshaded. Standard hides Random-only controls and
fits a shorter window; Any, Chosen and Weighted reveal their existing bound
controls. Weighted shows normalized shares and its native numeric editor retains
zero-total refusal, Cancel and Use Weights. Short help preserves eligible-biome
odds, safe-landing fallback, exact Game Name and the environmental protection
boundary. Plain saved/unapplied/ready status, next-action and last-start text
remain visible; paths and full result detail stay under Game details.

The layout uses the recipe's padding once, explicit rounded-panel heights that
contain the current native layout, wrapped text and vertical scrolling at narrow
widths. Automatic height fitting stays within the work area, respects manual
resizing and preserves maximized windows. The ordinary inputs, labels and custom
controls respond to Windows system colors; buttons keep native keyboard,
accessibility, disabled and default-button behavior. Owned fonts and the manager
icon are disposed with their owner. Required confirmation, error and success
messages remain native Windows MessageBoxes.

The source and visual review
confirms exact AST text equality for all four Apply/Launch/Restore/Uninstall
callback bodies and ten backend/state functions against the preserved
previous manager.
Confirmed Apply still verifies writes and policy readback before its required
**Settings Applied** acknowledgement. Random and RandomSafe retain the exact
first-session trader notice; Standard omits it. Failed or incomplete Apply keeps
the Launch latch blocked. Launch still requires matching settings, verified
installation, the completed acknowledgement, a closed game and running Steam.
The integration does not repair the runtime trader limitation or infer a live
landing from manager success.

The aggregate verification
links the offline evidence:

- Callback replay:
  64 scenarios passed across 12 groups on the final source, covering selection,
  failure, DEV/verified dispatch, results, restore, uninstall, Steam refresh,
  startup and UX state. Process states and game binaries are inert fixtures;
  modal text is intercepted and launch requests are captured.
- Native presentation checks passed 285 assertions across synthetic 100%, 150%,
  200% and 225% layout runs (87 + 66 + 66 + 66). They verify recipe/control
  binding, actual control types, unshaded Apply, mode visibility, weights binding,
  contained layout, scroll reachability and keyboard/accessibility probes. The
  100% run also checks narrow scrolling, simulated high contrast and maximized
  window preservation. The source-bound records are
  100%,
  150%,
  200%
  and 225%.
- Customer-layout smoke:
  the actual unchanged START.bat exercised the transformed customer manager and
  weights editor in Windows PowerShell 5.1. All 14 checks passed with exactly the
  existing 12 allowed files, no extra graphics dependencies and an unchanged
  inert game root. This disposable layout used only the existing DEV-flag and
  release-label transformations; it is not a new candidate export.
- Embedding tool verification:
  28 checks passed for native compilation, idempotent synchronization, encoding
  and surrounding-source preservation, read-only stale checks, literal recipe
  data and invalid-input refusal. The workbench regression passed nine workflow
  groups and 41 graphics exports against the final manager source under the
  post-integration record.

Final working manager SHA256:
`7843AA09AC7C0AC336497BD2BEEE083B9582A6885028B31351E61DB06DD0731A`.
Embedded Quiet recipe source SHA256:
`D809E4B45A7B419C8EFBDEF75280DA153235B366A31B8EF05A09C9229F038D7E`.
Embedded shared C# source SHA256:
`9FAE344A0A9CEF75C2A4B18402DB2D8AAE2666C169181E878398CFFF4CD39D63`.
The previous manager snapshot retains its unshaded Apply SHA256
`5161ED60A0F65020327BCA2F6AF6CC998A50EDA6C89C2BA17F0F6681D2F35896`.
Earlier tool/callback records retain their own source hashes and inventories.

Reviewed native captures include the
Chosen manager,
weights editor,
narrow actions
and 225% actions.
The earlier clipped-link capture records a resolved pre-final failure and is
not final acceptance evidence. `Form.Scale` changes geometry while font points
remain unchanged; these captures verify synthetic layout, not actual Windows
DPI typography. Forced high-contrast rendering likewise does not change the OS
theme. Actual monitor DPI, OS high contrast, physical keyboard/Narrator, native
popup readability and operator visual review remain pending.

The protected-byte check
preserves all ten frozen/reference hashes, including the registry, public-release
map, frozen 1.2.5/1.2.6 artifacts, QA contracts and verified runtime payload.
All 41 independent `1.2.6-qa.001` QA cases remain Pending. No runtime changes,
live game installation or launch, new candidate export or publication occurred.
This integrated source differs from the frozen ZIP and requires a new candidate
and independent QA before publication.

## Polished QA candidate 002 — 2026-10-03

The owner authorized continuing from the integrated manager to a review package.
Frozen `1.2.6-qa.002` now includes that manager and weights editor, the
picture-only icon and polished customer README. The
readiness record identifies the exact
customer ZIP and its separate receipt and engineering companion. QA tests the
customer ZIP; after independent QA and release-owner approval, customers, Nexus
and the site receive those exact same archive bytes. Publication remains pending.

Customer ZIP: `qa_cycle/candidates/1.2.6-qa.002.zip`, **208,801 bytes**, SHA-256
`F578291FBC41E87F2C06C82CB9F4157C7F46BC66B8D2DC0D1D734F63CA385FA5`.
Receipt SHA-256:
`26E28374D4451C0425625BB93F5F7607CF1FF79E38A2BF143B1B62D17C32C3DA`.
Companion SHA-256:
`2CDF9275656DF05F7136892FD4975EB267EFE361381211F21FA1F8CB854FC8AB`.
Working manager source remains SHA-256
`7843AA09AC7C0AC336497BD2BEEE083B9582A6885028B31351E61DB06DD0731A`;
the customer transformation adds the candidate header, selects the verified
branch and replaces the DEV release label. Its exported SHA-256 is
`5886C75BEF29F29E374A0B61D2F323A9FD86A7E3C610D92AF367A4CF7C8D4FA3`.
The package still uses the existing 12 customer files plus package manifest.
Embedded native controls and recipe data require no additional graphics files.

The installed game's assembly fingerprint changed after the qualified build.
The generator's explicit `-ReuseCandidateArchive` mode authenticated frozen
`1.2.6-qa.001` through its registry/receipt/customer ZIP and companion/context
manifest. It proved exact equality for all 15 runtime source files, DLL, ModInfo
and the copied deterministic build record before retaining the original b17
target. Reuse verification
passed 77 PowerShell 5.1 assertions, including altered archive/receipt/companion,
build record, source and payload rejection. The original `-GameRoot` route still
requires the real pinned inputs; the two routes are mutually exclusive. No
runtime rebuild, fake game-root substitution or pin change occurred.

The unchanged qualified build record
has SHA-256 `D0A4BF534D275A39DBD0A4D531E91EC5E7C72AD39640EA30B90819C27A582FDE`.
Active release/QA contracts now identify 002 and record reuse provenance. Their
prior bytes and the pre-export registry are preserved under
`dev/qa/ux-polish/qa002-packaging/before/`. Frozen 001 transport files and its
build record, frozen 1.2.5-qa.002 transport files and the public-release map
retain their hashes.

Package verification
passed 144 checks on the actual exported archive and independent extraction:
registry/receipt/archive/companion bindings, exact allowlist/file hashes,
customer transformation and source-bound identity, contract/build provenance,
text privacy scan and preservation boundaries. Source and extracted release
gates report `readyForQa=True`, zero errors and warnings. The extracted
customer's actual START.bat smoke exercised the native manager and weights
editor in Windows PowerShell 5.1, with screenshots outside the customer tree.
The customer tree and inert fixture remained unchanged; no mod installation or
game launch occurred. The 14
protected checkpoint files
match their pre-packaging hashes.

All **41 independent 002 QA cases remain Pending**. The existing manager case
now has **17 checks**, retaining saved-selection/weight/confirmation/keyboard
and actual 100/150/200/225% scaling checks while explicitly adding rounded
action/weights-dialog readability, focus/disabled appearance, OS High Contrast,
Narrator, scroll reachability and native popup readability. The 64 callback and
285 synthetic layout assertions remain DEV evidence, not substitutes for those
operator checks or live gameplay.

Formal QA remains V3.3.0 b17 with assembly SHA-256
`AA4275991736D276EC75BB4047E45F76E0242AA47D9895890F3761098D4CC146`.
The read-only installed environment observation
recorded assembly SHA-256
`FCEEC27300FFD3A1F97B097E43B60F3B07597F441E7ECBC6E1B59EEBB234C705`.
This mismatch is not compatibility evidence; independent gameplay QA needs the
matching target environment. The early-logout known issue remains unchanged.
No installed game files, saves or unrelated mods were altered, and no QA case
was marked Pass from packaging checks.

The portable transfer
is built and independently extracted, entered through `qa-002/START-HERE.md`
after local extraction outside synced/linked folders. Its 602,291 bytes have
SHA-256 `CCA017B469A8B6314481F0B8B9741CE307404F1A4FFB91FF937D5E4AFC6A9F9F`.
The transfer verification
checks all 59 manifested files plus the manifest, exact nested customer ZIP,
and the extraction using its own frozen tools/registry. The portable workspace
check and release gate passed with zero errors/warnings. The transfer carries
engineering support; it is separate from the exact customer distribution ZIP.

The post-candidate workbench regression
passed nine workflow groups and 41 graphics exports. Its protected-byte check
records the current mutable registry/contracts at invocation while keeping
frozen static inputs pinned. Historical workbench and integration receipts
retain their original hashes and evidence scope. These tooling and transport
checks do not pass any independent customer QA case.
