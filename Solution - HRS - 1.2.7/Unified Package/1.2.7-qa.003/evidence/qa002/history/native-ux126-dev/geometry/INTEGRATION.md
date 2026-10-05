# Geometry integration

Replace the current `Update-HrsTextWidths` and `Fit-HrsManagerWindow` with the functions in `ManagerGeometry.ps1`, including the two helpers. Embed the text in the existing manager; this snippet is DEV evidence, not an extra shipped dependency.

Replace the old unconditional `ResizeBegin` handler with `Initialize-HrsManagerGeometryEvents`. Keep the existing `managerLayout.SizeChanged` hook. It remains protected by the update guard. Remove the separate Shown-event height clamp: `Fit-HrsManagerWindow` owns final outer height and work-area bounds. Do not copy client width into any manager height-fit assignment.

The presentation supplies `managerWrapLabels`, `managerChoiceWrapLabels`, `managerHeader` and `managerHeaderTitle`. Missing values retain legacy layout compatibility. Removed explanatory labels are ignored when their Parent is null. Header title wrapping uses the remaining column width.

Automatic fits preserve outer width and clamp normal size/location to the monitor working area. A completed native resize sets `managerUserResized` only when outer Size actually changed. Subsequent fits preserve that chosen size, subject to the work-area boundary. Minimized/maximized windows are not altered. Resize completion and activation re-evaluate the current monitor working area. No automatic fit relies on timers, nested event pumping, or an animation.

The extent update restores the prior scroll position after layout, because WinForms AutoSize layout can otherwise bring the focused textbox back into view. The event helper also records the last normal outer bounds: this host's .NET Framework restoration from maximized state otherwise lost one 17-unit scrollbar width. A single `BeginInvoke` after the native window-state transition restores those recorded outer bounds. It is bounded geometry work, not an operation, timer, animation or nested message pump.

## Weights dialog

Replace its Shown-event fitting block with the following. `Limit-HrsNormalWindowBounds` is the embedded helper above. Preserve the existing centering and disposal logic.

```powershell
$dialog.Add_Shown({
    $dialog.PerformLayout()
    $column.PerformLayout()
    $surface.Height = $column.Bottom + $surface.Padding.Bottom
    $frame.PerformLayout()
    $dialog.AutoScrollMinSize = New-Object Drawing.Size(0,($frame.Height+$dialog.AutoScrollMargin.Height))
    $workArea = [Windows.Forms.Screen]::FromControl($dialog).WorkingArea
    $chrome = $dialog.Height - $dialog.ClientSize.Height
    $dialog.Height = [Math]::Min($frame.Height+$chrome+4,$workArea.Height)
    Limit-HrsNormalWindowBounds -Window $dialog
    $dialog.PerformLayout()
    $column.PerformLayout()
    $surface.Height = $column.Bottom + $surface.Padding.Bottom
    $frame.PerformLayout()
    $dialog.AutoScrollMinSize = New-Object Drawing.Size(0,($frame.Height+$dialog.AutoScrollMargin.Height))
})
```

The repaired manager's direct smoke fixture and measured native geometry are separate from independent customer QA. In particular, synthetic `Form.Scale` changes do not qualify actual Windows 100/150/200/225% compatibility scaling, physical mouse resizing, secondary 300% behavior, or readability.
