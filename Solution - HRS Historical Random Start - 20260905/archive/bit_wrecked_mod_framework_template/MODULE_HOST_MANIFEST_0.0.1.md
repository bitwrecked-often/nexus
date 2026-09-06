# Bit Wrecked Module Host Manifest 0.0.1

**Status:** Planned architecture. No universal host implementation exists yet.

**Working concept:** One familiar Bit Wrecked interface can host multiple
independent mod tools. A dropdown selects the active module. The host supplies
the familiar shell and continuous activity log; each module retains its own
payload, rules, validation, ownership, installation, removal, and release
boundary.

This is not a plan to merge all mods into one payload or one universal set of
game changes.

## Player-facing promise

Players see one consistent interface:

1. Choose a 7 Days to Die game folder.
2. Choose a supported module from a visible dropdown.
3. See only that module's controls in the center workspace.
4. Validate, configure, install, remove, or recover only through the active
   module's explicit controls.
5. Read one continuous, labeled activity log across the whole session.

The host must make the active module obvious at all times. Switching modules
must never write files, install a mod, remove a mod, alter a global setting, or
silently reuse an action intended for another module.

## Spirit of the host

This host is meant to feel like a trustworthy local management console for the
Bit Wrecked mod family: one place to see what is selected, what has been
checked, what is possible, and what has not been approved yet.

It is not meant to feel like a website, launcher storefront, account system, or
an opaque universal mod manager. It should feel immediate and grounded:

* A real Windows tool opens locally and works without a web service.
* The familiar outer shell remains steady while the center workspace changes
  for the selected module.
* The activity log carries the story of the session forward instead of making
  the player remember what happened on a previous page.
* The selected module remains the specialist. The host is the front desk, not
  the author of every gameplay decision.

The useful iDRAC-style similarity is the movement between management pages:
the player changes context through a selector, sees the relevant status and
controls, and keeps the surrounding console and history. The difference is
equally important. This host is local player tooling, not remote hardware
management. It has no required website, cloud account, remote inventory, or
browser session.

## Origin story

The idea grew out of the completed Wasteland Animal Population Tuning 4.1.1
work. That project looked like one animal-tuning mod on the surface, but the
audit showed that it carried a repeatable operational framework beneath it:
choose a game folder, validate, select behavior, install/reinstall, remove
selectively, restore safely, log clearly, package, and recover after a
disaster.

The recipe archive named eleven such repeatable practices. That changed the
question from “how do we make the next mod?” to “how do we preserve the
kitchen, not only the last meal?” The reusable template, frozen reference,
blank working example, release materials, and recovery artifacts were created
to answer that question.

The Offense Weapons workspace then made the next step visible. It began with
the same frame but deliberately empty center rows. The polished Wasteland-like
layout proved that a player can recognize the tool before any new payload is
present. It also made a second insight clear: the familiar shell could remain
stable while different feature sets occupy the center.

The module host is the architectural expression of that insight. It does not
erase the independent mod solutions. It lets independent solutions present
themselves through one learned, calm, explainable control surface.

## Native-window model

The host uses local Windows controls rather than a web page. In practice, the
module dropdown changes the center workspace in the same way a management
console changes pages, but the application itself stays open:

```text
Stable shell: header | folder | module selector | activity log
                              |
                              +-- selected module changes only this workspace
```

The host keeps its in-session log and selected game-folder context while the
module workspace is swapped. It reads module definitions from local framework
or mod files. It need not store project data on a website, call a remote
service, or require a player account.

Optional persistent logging remains a deliberate exception: it writes only to
a local file path the player selected. That preserves the existing rule that
the normal log is runtime-only by default.

## Trust and engagement principles

Consistency is not only visual polish. It is player support.

* A returning player already knows where status, validation, actions, and the
  log live.
* A new module does not require learning a new control philosophy from zero.
* The center tells the truth about its state: empty means no rows exist;
  disabled means a boundary has not been earned; design state means no payload
  is being represented as playable.
* Clear module tags in the log turn a multi-mod session into a readable story
  rather than a pile of unexplained actions.
* A familiar interface can invite curiosity without hiding risk. The user sees
  the selected module, its scope, and its available actions before choosing
  anything consequential.

The intended feeling is: “I know this tool. I know which mod I am looking at.
I can see what it will and will not do.”

## Local-first safety posture

The host must remain faster and more dependable because it is direct local
window tooling, not because it makes unchecked promises. Its reliability comes
from small boundaries:

* No required network connection or remote dependency.
* No automatic download, telemetry, account, or cloud synchronization path.
* No background action when a module is selected.
* No shared action that guesses a module's file ownership.
* No persistent game change without the selected module's own explicit handler
  and confirmation rules.
* No claim that the host makes an unfinished module safe or complete.

The player may move quickly between modules. The code must move slowly and
explicitly when a write, restore, install, or removal is involved.

## Candidate modules

| Module | Initial role | Current safety state |
| --- | --- | --- |
| Blank Framework | Demonstrates the empty shell and module contract. | Read-only; no payload. |
| Wasteland Animal Population Tuning 4.1.1 | First reference adapter and parity target. | Existing proven standalone tool; not yet an adapter. |
| Offense Weapons | Design workspace and future module. | Empty rows; no payload or installer. |
| Future Bit Wrecked mods | Additional independent modules. | Not defined until their own line-item maps exist. |

## Ownership boundary

### Host owns

* Bit Wrecked visual shell, header, game-folder selector, module dropdown, and
  expandable activity-log panel.
* In-session selected-module state.
* One runtime activity log, plus optional user-selected persistent log storage.
* Module labels on every log entry.
* The rule that switching modules is read-only.
* The module-contract check that prevents an incomplete module from exposing a
  dangerous action.

### Each module owns

* Its display name, description, version, supported game build, and status.
* Its center-workspace row schema and renderer.
* Its line-item map, baseline evidence, settings, validation, and previews.
* Its own install, reinstall, selective removal, full removal, restore, and
  packaging behavior where applicable.
* Its exact file-write boundary, dependencies, backups, and recovery notes.
* Its own release identity and source/payload folders.

The host must never invent a module's target path, XML row, effect, or action.

## Module contract

Every selectable module requires a manifest or adapter definition containing at
least:

```text
Module ID and display name
Version and supported game build
Design / read-only / release state
Center-row schema and data source
Read-only validation handler
Explicit action handlers, if any
File-write and backup boundary
Install/remove dependency model
Line-item-map reference
Recovery and release-document references
```

A module in `design` state may render its workspace and validate a game folder,
but cannot expose Install or Remove. A module becomes actionable only after its
own evidence, payload, tests, and release approval are complete.

## Continuous-log model

The host keeps one session log. Each entry starts with the active module label:

```text
[Host] Selected game folder: C:\...\7 Days To Die
[Wasteland Animals] Validation completed: installed 4.1.1 settings found.
[Offense Weapons] Loaded design workspace: no approved feature rows yet.
```

The log remains visible when the dropdown changes. A module change adds a
clear `Host` entry. Persistent logging remains off by default and can write
only to a location chosen by the user.

## Wasteland Animals as the first adapter

The 4.1.1 animal tool is the right first parity target because it already proves
the recipes: validation, row selection, install/reinstall, selective removal,
global-cap handling, restore, logging, packaging, and recovery.

It cannot simply be dropped into a dropdown as its existing monolithic GUI.
Its proven logic must be extracted behind the module contract while its current
standalone tool remains intact as the reference and fallback.

The first host adapter must initially be read-only:

* Load the animal module label and its current rows into the host center panel.
* Validate the selected game folder using the adapter's read-only checks.
* Compare displayed states and validation output against the standalone 4.1.1
  tool.
* Do not enable host-driven install, removal, cap changes, or restoration until
  parity and write boundaries are separately approved.

## Interaction rules

| Event | Required result |
| --- | --- |
| Host starts | Blank Framework is active; no writes occur. |
| User selects a module | Host logs the change and renders that module only. |
| User changes game folder | Active module may revalidate; no module writes. |
| User switches modules | Module-specific selections remain in session unless the module states otherwise; no cross-module action occurs. |
| User requests an action | Host delegates only to the active module's declared handler. |
| Module is design-only | Install and Remove remain visibly disabled with a reason. |
| Persistent log is enabled | Only the chosen log file is written; game files remain outside the log boundary. |

## Engagement design

The consistent shell is intentional player support, not cosmetic excess. It
reduces re-learning between releases, gives each mod a familiar starting point,
and lets the activity log explain what is happening in plain language.

The dropdown must stay small and honest. Do not list unfinished modules as if
they are playable products. A design module may be shown only when it is
visibly marked `Design - no payload`.

## Delivery sequence

1. **Host contract:** Define the adapter object/manifest shape and safe default
   behavior without moving any existing payload logic.
2. **Host shell:** Add the dropdown and module-loading area to the generic
   template shell with Blank Framework as the only selectable module.
3. **Animal read-only adapter:** Render the 4.1.1 animal module through the
   host and compare it against the existing standalone GUI.
4. **Parity review:** Confirm all visible rows, validation messages, log tags,
   state transitions, and user-facing warnings match the approved behavior.
5. **Action gating:** Decide, one recipe at a time, whether an animal action can
   safely move behind the host. Keep the standalone tool as fallback until all
   approved actions pass parity tests.
6. **Weapons design adapter:** Add the empty Offense Weapons workspace through
   the same contract. Populate it only from approved weapon line-item entries.
7. **Release process:** Give each module independent package/release and
   recovery materials; do not force all modules into one release cadence.

## Non-goals for 0.0.1

* No universal payload archive.
* No shared install/remove logic that guesses module ownership.
* No automatic migration from the standalone animal tool.
* No host-driven global game setting changes.
* No weapon rows or gameplay behavior.
* No public promise that every future mod will use the host.

## Success criteria for the first planning milestone

* The module boundary is understood by both player and maintainer.
* The host can display Blank Framework and Wasteland Animals as visibly
  different modules without writing files.
* The log remains continuous and correctly labeled across module changes.
* The standalone 4.1.1 animal tool remains runnable and unchanged.
* The host cannot expose actions for a module that has not met its own
  line-item, validation, and recovery requirements.
