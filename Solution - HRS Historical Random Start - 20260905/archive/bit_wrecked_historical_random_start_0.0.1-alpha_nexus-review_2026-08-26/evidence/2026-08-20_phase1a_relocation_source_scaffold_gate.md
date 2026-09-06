# Phase 1A Relocation Probe — Source Scaffold Gate

Date: 2026-08-20  
Decision: Source/static tests PASS; compile/install/run NO-GO

The owner authorized a separate relocation source scaffold after the marker-only
proof passed. The scaffold is isolated from the installed marker probe and
contains six C# files plus `ModInfo.xml`.

The exact source sequence is:

1. exact build/target/EAC/authority/local/NewGame/entity/absent-marker guards;
2. write/read-back Reserved using the proven `AddCustomVar` path;
3. obtain the native spawn list and call
   `GetRandomSpawnPosition(world, null, 0, 0)` exactly once;
4. reject undefined, invalid, out-of-bounds, unloaded, or unsafe candidates;
5. call `Entity.SetPosition(candidate, true)` exactly once;
6. begin verification no earlier than later tick 2 and stop by tick 120;
7. revalidate target, world, entity, bounds, loaded chunk, native spawn safety,
   and a 0.25-unit final-position tolerance; and
8. only then write/read-back Completed through `AddCustomVar`.

Every post-reservation failure leaves Reserved. Selection and placement never
repeat. The source contains no teleport, respawn, direct network helper, marker
removal, console, Harmony, file-write/delete, process-launch, or external
network-client path.

Static tests passed under PowerShell 7 and Windows PowerShell 5.1 with exactly
one selection and one placement call. The 22-case pure contract suite also
remained 22/22 in both shells. Read-only API inspection confirmed
`SpawnPosition` is a value type and `Vector3.Distance(Vector3, Vector3)` exists;
the impossible null comparison discovered during review was removed before the
manifest was pinned.

Seven-file source aggregate SHA-256:
`861F5699B465351D857559EC35BA03BCE2B1897E9924F8E4861ED07C7CA5A53D`

No compiler ran and no relocation DLL/payload/live folder exists. The existing
marker probe remains installed, and its exact test save remains present with a
persistent Reserved marker. Before any relocation runtime authorization, the
semantic state-delta harness must be pinned, the marker probe must be handled as
an explicit coexistence/removal gate, and a fresh absent-marker target must be
prepared. Compilation remains a separate authorization gate.
