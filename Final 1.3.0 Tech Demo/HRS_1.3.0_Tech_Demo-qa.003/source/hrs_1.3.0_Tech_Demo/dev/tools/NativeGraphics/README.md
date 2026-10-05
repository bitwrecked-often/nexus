> HRS 1.2.7 DEV carries this workbench from the completed 1.2.6 native UX round. Frozen 1.2.6 references below retain their historical identity; new-version build and QA status are recorded in the lane README and HRS_1.2.7_LANE_WORK_MANIFEST.md.

# Bit Wrecked native graphics workbench

Open **Open-Workbench.cmd** to try the local graphics tools. This uses existing
Windows PowerShell 5.1, .NET Framework, WinForms and System.Drawing. It installs
nothing, downloads nothing and needs no paid graphics application.

The workbench now renders named [design recipes](recipes/README.md):

- **Bit Wrecked Quiet**: light manager and release card, short copy, picture-only
  logo, restrained orange accents and a white outlined Apply button.
- **Bit Wrecked Contrast**: charcoal, white and lime release card with text on
  the left and artwork on the right. This recipe is for release cards only.
- A manager study with Standard, Any, Chosen and Weighted presentation states.
- Smooth outlined buttons, surfaces, status badges and six code-drawn icons.
- PNG exports, transparent icons at five sizes and a seven-size Windows ICO.

Apply and Launch in the study are demonstrations. They only change preview
state: edits show **Changes not applied**, and Apply shows **Preview ready**.
Saved-policy loading, verified installation, confirmations and real Launch gates
belong to the production manager contract, not this simulation. The tool does
not import that manager, install the mod, write its settings or start the game.
The real manager now embeds the Quiet recipe and native controls through the
sync tool below. Its real callbacks remain separate from the study's simulated
actions. Frozen `1.2.6-qa.001` remains unchanged; the integrated source requires
a new candidate and independent QA before publication.

## Run and export

Use **Windows PowerShell 5.1**, `powershell.exe`, with `-STA`. The default
`pwsh` terminal uses a different runtime and the module gives a clear refusal.

From this directory:

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\Show-GraphicsWorkbench.ps1
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\Show-GraphicsWorkbench.ps1 -SmokeTest -ExportDirectory .\out
```

The Export previews button asks for a destination folder. It exports **41 graphic
files**: three workbench views, one components contrast view, four full manager
states, two release cards, a picture-only ICO and 30 transparent glyph PNGs.
The default cards are 1440 x 810. An `export.json` receipt records recipe, tool
and output hashes; each card also has a `.png.recipe.json` receipt. Existing
files of those names in the selected folder are replaced.

To try a variation, copy the Quiet recipe, edit its values and open it:

```powershell
Copy-Item .\recipes\bitwrecked-quiet.json .\recipes\my-quiet.json
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\Show-GraphicsWorkbench.ps1 -RecipePath .\recipes\my-quiet.json
```

`-RecipeId bitwrecked-quiet` selects the named manager recipe; `-RecipePath`
loads an explicit JSON file instead. Contrast is refused for the Manager target.

Individual assets can also be generated from the command line:

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\Export-Graphics.ps1 -RecipeId bitwrecked-quiet -OutputPath .\out\release.png
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\Export-Graphics.ps1 -RecipeId bitwrecked-contrast -OutputPath .\out\release-contrast.png
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\Export-Graphics.ps1 -Glyphs -OutputPath .\out\glyphs
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\Export-Graphics.ps1 -IconSource ..\..\ui\Assets\i0141.png -OutputPath .\out\picture-only.ico
```

For a custom card, use `-RecipePath .\recipes\my-quiet.json`. Add
`-ArtworkPath` with the path to your existing PNG or other supported bitmap;
the renderer preserves its aspect ratio within the right-hand artwork area.
Without artwork it draws a simple route study. `-CardStyle Light|Contrast`
remains a shorthand for selecting the corresponding named recipe.

The ICO contains 16, 24, 32, 48, 64, 128 and 256 pixel PNG frames. Its source
image keeps its aspect ratio; the exporter does not add lettering. Six glyphs
are redrawn at 16, 24, 32, 48 and 64 pixels: Check, Info, ArrowRight,
ChevronDown, Shield and Settings.

## Reuse in future UX work

### Embed the real manager's presentation

`Sync-ManagerDesign.ps1` embeds the validated Quiet Manager recipe and the
native controls source into a marked region in `dev/ui/p0158.ps1`. The customer
manager can then use `$script:hrsDesignRecipe` and the native control types
without loading this DEV tools directory or shipping additional modules. The
existing customer file allowlist remains unchanged.

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\Sync-ManagerDesign.ps1
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\Sync-ManagerDesign.ps1 -Check
```

`-Check` returns `Current`, `Stale` or `Missing` without writing. Use
`-ManagerPath` for a disposable manager copy and `-RecipePath` for an explicit
validated Manager recipe. Release-only recipes are refused. The generated
region includes the recipe and controls source SHA-256 values, contains no
timestamp, preserves the manager's encoding and surrounding source, and is
unchanged by another sync when its inputs are unchanged. Recipe copy stays
literal JSON data. The helper parses the resulting PowerShell before writing;
it does not run the manager, install the mod or start the game.

After editing a recipe or `NativeControls.cs`, sync again and verify the real
manager's layout and behavior. This helper embeds the presentation sources;
the manager's own UI code decides how its real controls use them.

`Recipes.psm1` loads and validates JSON through `Get-DesignRecipe` and
`Get-DesignRecipeList`. Palette, typography, geometry, copy and target settings
feed their relevant renderers. Manager-only fields do not style a release card;
card composition settings do not rearrange the manager. Toolbar choices override
corners and text size for that session. `theme.json` remains a legacy helper for
`Get-WorkbenchTheme`; it no longer supplies the manager study's appearance.

```powershell
Import-Module .\Recipes.psm1
Get-DesignRecipeList
$recipe = Get-DesignRecipe -Id bitwrecked-quiet -Target Manager
```

After changing geometry, fonts or copy, regenerate the previews and check text
fit, wrapping and visible controls. The recipes are editable sources; exported
PNGs are references. Mermaid in the [recipe guide](recipes/README.md) is an
optional flow diagram and requires no local installation.

```powershell
Import-Module .\NativeGraphics.psm1
Import-NativeGraphics
$panel = New-NativeSurface -Width 400 -Height 160 -CornerRadius 8
$button = New-NativeOutlineButton -Text 'Apply Settings'
$badge = New-NativeBadge -Text 'Changes not applied' -Accent
$glyph = New-NativeGlyph -Glyph Shield -Size 24
```

The surface hosts ordinary native controls. The optional outlined button derives
from Windows' Button class, preserving native Click, keyboard/default-button
behavior and accessibility. Future integration must retain HRS confirmations,
acknowledgement, Launch gates and result wording. Custom painting does not
replace those contracts. A fresh PowerShell process is needed after changing the
C# source because an already loaded V1 type cannot be replaced in that process.

PNG drawing is useful for composing type, simple geometry and existing artwork.
It is not a full photo retouching or illustration editor. The tools render small
UI graphics crisply without an external font or icon pack.

## Verification limits

Contrast preview forces the custom controls' system-color rendering path. It
does not change Windows high-contrast settings or simulate an entire OS theme.
Actual high-contrast/Narrator and monitor DPI behavior still need operator
review before using these controls in a customer build.

`Export-WorkbenchControl -Scale` enlarges a raster preview. It is not a native
DPI rerender. Code-drawn glyphs are rendered independently at every requested
size. The workbench respects the host's existing scaling; it does not change
process DPI awareness or Windows settings.

Microsoft documents [custom WinForms painting](https://learn.microsoft.com/en-us/dotnet/desktop/winforms/controls/custom-painting-drawing),
[double buffering](https://learn.microsoft.com/en-us/dotnet/desktop/winforms/advanced/how-to-reduce-graphics-flicker-with-double-buffering-for-forms-and-controls)
and [Framework DPI configuration](https://learn.microsoft.com/en-us/dotnet/desktop/winforms/high-dpi-support-in-windows-forms).
This toolkit uses the .NET Framework libraries verified on this dev box;
it does not run an SDK build, restore packages or use the network.

Run the following to verify the actual workbench/CLI consumers, decoded
exports, keyboard and accessibility probes, invalid-input refusal and preserved
manager/release hashes. The current record is under
`dev/qa/ux-polish/workbench-after-qa002/`; earlier integration, recipe and
native-graphics evidence is retained. This checks that the workbench leaves the
manager bytes present at invocation unchanged, rather than pinning a historical
manager revision. The active registry and release/QA contracts are snapshotted
at invocation because authorized candidate exports advance them; frozen
reference hashes are still checked against their preserved baseline. Real
manager integration evidence is separately recorded in
`dev/qa/ux-polish/design-integration/`.

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\Test-GraphicsTools.ps1
```
