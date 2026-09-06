# Module Host UX and Performance Guidance 0.0.1

**Status:** Build requirement for the Module Host, not optional polish.

**Audience:** The implementation-focused AI that builds the local native Module
Host described in `MODULE_HOST_INFRASTRUCTURE_BUILD_HANDOFF_0.0.1.md`.

## Purpose

Make the host feel quick, quiet, trustworthy, and familiar to a player using a
Windows desktop tool. The interface must make the likely next action obvious,
keep the current module clear, and never make the user wait for work that was
not requested.

This is a local PowerShell/WinForms management console. It is not a website,
remote console, cloud service, telemetry client, account system, or a rewrite
of the tools into another UI technology.

## Research interpretation

### What we borrow from Broadcom

Broadcom's public vSphere Client SDK presents UI extensions as plug-ins with a
manifest/schema and calls out testing against every supported vCenter version.
That is useful as an architectural pattern, not as a deployment model.

Borrow for this project:

- An explicit local module registry rather than scanning arbitrary scripts.
- Small module manifests/contracts that state identity, version, capability,
  required reads, and hooks.
- Isolated adapters: a selected module supplies its center workspace; it does
  not own the host's safety rules, game-folder state, or global history.
- A declared compatibility matrix and repeatable test cases for each supported
  game/tool state.

Do **not** borrow remote plug-in delivery, browser pages, accounts, networking,
or enterprise infrastructure. Our equivalent is a local, reviewed set of
PowerShell module adapters in the repository.

Source: [Broadcom vSphere Client SDK](https://developer.broadcom.com/sdks/vsphere-client-sdk/latest).

### What we borrow from Microsoft desktop guidance

Microsoft's desktop guidance prioritizes perceived productivity over a long
feature list: present probable tasks, combine essential work, and keep uncommon
or hypothetical choices out of the primary path. Its performance guidance
emphasizes a responsive UI thread, on-demand view creation, measured targets,
and moving non-trivial work away from the UI thread. Its WinForms and
accessibility guidance requires safe cross-thread UI access and usable keyboard,
focus, high-contrast, and assistive-technology behavior.

Sources: [desktop UX design](https://learn.microsoft.com/en-us/windows/win32/uxguide/how-to-design-desktop-ux), [responsive UI thread](https://learn.microsoft.com/en-us/windows/apps/develop/performance/keep-ui-thread-responsive), [performance planning and measurement](https://learn.microsoft.com/en-us/windows/apps/develop/performance/planning-measuring-performance), [WinForms thread-safe calls](https://learn.microsoft.com/en-us/dotnet/desktop/winforms/controls/how-to-make-thread-safe-calls), and [Windows accessibility best practices](https://learn.microsoft.com/en-us/windows/win32/winauto/accessibility-best-practices).

## Product rule: low drag, not flashy

The player should be able to open the host, recognize the selected module,
confirm the selected game folder, choose a deliberate validation/action, and
read the outcome without hunting through decorative controls.

Keep the successful visual language: Bit Wrecked identity, plain module title,
short status card, visible game-folder field, five-column center workspace,
one purposeful action area, and expandable activity log. Do not add panels
just because a module *might* need them later.

The existing generic shell's `Reserved capability` row is a design reference,
not a required host feature. The host shows a capability only when the active
module declares a real, approved capability for the current build.

## Measured interaction targets

These are local engineering targets, not a public guarantee. Record actual
results during development on the normal supported machine. If the host cannot
meet a target, preserve correctness, show honest progress, and record the
reason rather than pretending it is instant.

| Interaction | Target | Maximum before visible feedback | Rule |
| --- | ---: | ---: | --- |
| Cold launch to usable shell | 1 second | 3 seconds | Register module metadata only; do not pre-render every module. |
| Opening module dropdown | 200 ms | 500 ms | Metadata is already available; do not scan/validate game files. |
| Switching cached module page | 200 ms | 500 ms | Swap center workspace and log selection only. |
| First render of module page | 200 ms for initial status | 1 second | Render skeleton/real known state first; defer expensive reads. |
| Explicit validation click acknowledgement | 200 ms | 500 ms | Disable only the relevant action and say what is being checked. |
| Longer read-only validation | N/A | 1 second | Run read work off the UI thread and marshal results back safely. |
| Adding a normal activity-log entry | 100 ms | 500 ms | Bound the visible log; no repeated full-text repaint. |

Do not perform validation, disk enumeration, module import, payload detection,
or `Mods` folder creation merely because the host launched or a dropdown value
changed. A switch is a navigation event, never an action request.

## Rendering and work model

1. Build the fixed host shell first.
2. Load only the reviewed registry metadata needed to populate the dropdown.
3. Render the initially selected module only.
4. Construct other module views on demand; retain a view only if measurement
   shows it helps and its state is safe to reuse.
5. On selection change, update the selected-module label, replace the center
   workspace, and add one tagged log event. Do not validate automatically.
6. Run slow, explicit read-only work outside the UI thread. Capture its inputs
   before it starts; use `BeginInvoke`/`Invoke` to update WinForms controls;
   discard a result if the user changed module or game folder while it ran.
7. Keep initial release sequential unless measurement proves a specific
   background task is needed. Do not add speculative concurrency.

Never access WinForms controls directly from a background worker. Keep all
game-file mutations out of the initial host entirely; the above background rule
is only for explicit, permitted reads.

## Information architecture and wording

- The dropdown lists only shipped, reviewed modules. No arbitrary `*.ps1`
  discovery and no disabled mystery entries.
- The selected module name and its state are visible together: for example,
  `Wasteland Animal Population Tuning 4.1.1 — Read-only adapter`.
- The header describes the selected module; the stable shell retains Bit
  Wrecked identity and the running log.
- Show a short status sentence before a table. It must distinguish: valid
  folder, invalid/missing folder, no payload by design, validation in progress,
  read-only result, and action result.
- Make one next step primary. Use module wording, not generic promises. For
  example: `Validate Current Game Settings` is valid for Wasteland; `Design
  Rows First` is valid for the empty weapons design module.
- Do not expose install/remove/reinstall controls unless that active module has
  a implemented, approved action. Disabled controls are less clear than absent
  controls when no capability exists.
- Use direct outcomes: `Validated`, `No payload configured`, `No changes made`,
  `Folder not recognized`, and `Read-only comparison complete`.

## Activity log: persistent human context, not noise

The log is the cross-module thread that helps a returning user understand what
happened. It must survive page changes in memory and use clear tags, for
example:

```text
[Host] Selected module: Offense Weapons 0.0.1 (design-only)
[Weapons] No payload configured; no game files inspected.
[Host] Selected module: Wasteland Animals 4.1.1 (read-only)
[Animals] Validation completed; no changes made.
```

Rules:

- Log meaningful user-requested events, inputs at a safe summary level,
  results, exceptions, cancelled/stale work, and explicitly confirmed writes
  when writes are added in a future version.
- Do not log an event for every repaint, dropdown focus change, or internal
  helper call.
- Keep a bounded number of recent entries in the visible RichTextBox/list so
  the UI remains fast. Document the bound in the host README.
- Persistent logging remains opt-in. When off, write no file. When on, write
  only to the user-selected location described in the infrastructure handoff.
- Do not place secrets, unredacted tokens, or unnecessary personal paths in
  the log. The game-folder path may be logged only when the user has chosen or
  explicitly validated it.

## Accessibility and Windows fit

The host must work without a mouse and must not make color the only state cue.

- Give every interactive control a useful `AccessibleName` and, where useful,
  `AccessibleDescription`; especially module dropdown, game-folder picker,
  primary action, log expander, and any dynamically created row control.
- Define a logical `TabIndex` in reading/action order. The initial focus must
  land on an intelligible, useful control, not a decorative image.
- Supply text/icon/state together: green is never the sole indicator of a
  recognized folder or success; red is never the sole failure signal.
- Respect high contrast (`SystemInformation.HighContrast`), usable system
  fonts, keyboard focus visibility, and Windows display scaling. Do not rely
  on hard-coded text clipping at a single DPI.
- Keep confirmation/error messages close to their relevant control and also
  place the outcome in the activity log.
- Test tab navigation, Enter/Space activation, Esc behavior where appropriate,
  dropdown selection, log expansion, focus return after a module switch, high
  contrast, and 100%/150% DPI.

## Development-only measurement

Add a small local timing helper enabled for development/testing only. Measure:

- shell creation;
- registry load;
- initial module render;
- each module switch;
- explicit validation start-to-acknowledgement and completion;
- number of visible log entries.

Record measurements in the local test output or a development log only. No
analytics, network call, telemetry service, or account is permitted. Diagnose
slow paths before adding caching or background work.

## Required test additions

| Area | Evidence required |
| --- | --- |
| Startup | Cold-start timing, usable shell before any optional page work, no automatic game scan/write. |
| Navigation | Each module selection changes only the center page and adds a labeled log entry. |
| Responsiveness | Dropdown and normal page switch meet targets under a normal log size; slow validation keeps UI responsive. |
| Stale results | Change folder/module during a deliberately delayed validation; old result cannot overwrite new page state. |
| Information design | Every visible control maps to a real active-module capability; no speculative or misleading controls. |
| Accessibility | Keyboard-only path, focus order, non-color status, high-contrast and DPI checks, accessible dynamic rows. |
| Local-only boundary | No network, account, telemetry, automatic plug-in discovery, or write action introduced. |

## Compatibility discipline

Use the required comparison matrix to define what each adapter supports. Treat
the standalone Wasteland tool as the behavioral reference, then verify its
read-only host view against the same supported game/tool versions. A mismatch
must be named in the matrix, logged during testing, and either fixed or kept in
the standalone tool; it must not be hidden by a generic host label.

## Non-goals for 0.0.1

- No migration to a browser, web dashboard, remote appliance, or cloud store.
- No runtime downloading or installing modules.
- No generic payload engine or automatic action inference.
- No animated loading theater or artificial delays.
- No background work except a measured, explicit read that needs it.
- No accessibility claim without the required manual checks.

## Build decision rule

When choosing between two designs, choose the one that preserves the player's
place, explains the current state in one sentence, responds to the requested
action quickly, and does less without hiding meaningful information. If it
would confuse a returning player or make an unrequested game-file change, it
does not belong in this host release.
