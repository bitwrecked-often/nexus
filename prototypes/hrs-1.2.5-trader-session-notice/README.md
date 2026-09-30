# Historical Random Start 1.2.5

Historical Random Start brings back the uneasy first question of a new game:
*where did I end up?* It moves a new Random-mode character to a placed location
in the active world, then lets the normal opening journey continue.

This QA candidate targets 7 Days to Die V3.3.0 (b17), local single-player on
Windows with PowerShell 5.1. On another game build, HRS attempts to work when
the required game hooks are available. If those hooks are incompatible, HRS
leaves the normal start alone. Other builds still need their own compatibility
testing. The manager continues to verify its own files and the installed mod.
The intended map scope is Navezgane and Random Gen worlds
of at least 8K; bundled pregens and custom maps are outside this version's
tested scope. Start the game with anti-cheat disabled and keep its supplied
`0_TFP_Harmony` installation. The package does not replace game DLLs.

## Install and start

1. Extract the complete ZIP into a writable local folder outside OneDrive or
   other synced or linked folders. Keep its folders together; recovery settings
   are stored beside the manager. HRS checks this location before changing game files.
2. Close 7 Days to Die, keep Steam open, and run `START.bat`.
3. Select the game installation if the manager asks.
4. Enter the **exact Game Name** you will use for a new save. The generated
   world's name can be chosen later in the game; it is not the HRS policy key.
5. Choose Standard or Random. For Random, choose Any biome, Choose a biome,
   or Set custom weights. Set optional starting-biome protection independently. Select **Apply Settings**, then launch the game from the manager
   or Steam.
6. Create the new game with that exact Game Name. You may generate a new world
   or choose an existing supported world.

For Random starts, finish the starter tasks and the opening Journey to Settlement
trader visit before leaving the world. If you log out first, the trader quest
may point to Pine Forest when you return. Your random landing remains saved and
will not repeat.

Standard leaves the usual start alone. Random selects from actual placed POIs
in the active world, with a five-attempt limit using distinct instances in the
chosen biome. An unsafe attempt rolls back to the original start before the
next try. If no safe destination can be completed, the character stays at the
ordinary start. A completed start is one-shot: reloads and normal respawns do
not choose a new location. The historical catalog has 80 selected entries
represented by 79 distinct prefab names; any one generated world may contain
fewer eligible placements.

The opening trader objective uses a real trader placed in the active world.
HRS prefers one in the landing biome. If none exists there, it can point to an
existing trader in another biome; it does not create or move a trader. If no
usable trader is available anywhere, HRS keeps the vanilla start and does not
claim a new intro route. Normal trader jobs resume after the opening journey.

Optional protection applies to recognized environmental hazards of the
**starting biome**. It does not promise immunity to every debuff or to hazards
in other biomes.

For an existing HRS installation, use this manager's **Apply Settings** action.
It verifies ownership before upgrading and verifies the installed payload
afterward. If an ownership or package hash check fails, keep the diagnostic
and do not replace files manually. To remove HRS, close the game and choose
**Uninstall Mod**; the manager preserves saves and unrelated files.

Any gives each eligible biome equal odds. Choose a biome tries only that biome;
if no safe start is available there, HRS keeps the normal start. Custom weights
are integers from 0 to 100: zero excludes a biome, and at least one value must
be positive. The dialog previews configured proportions; the game excludes
absent biomes and normalizes the remaining weights. Unsafe landings can still
fall back to the normal start. A trader in a different biome does not redraw
your starting biome.

When upgrading from 1.2.4, Apply Settings preserves the previous Game Name,
start mode and protection by default, using Any biome until you choose another
method. Review the confirmation before applying. Changing settings does not
give an already started character a second HRS start. This is a QA candidate;
independent gameplay and actual Windows display-scaling QA are pending.
