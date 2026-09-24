# Copy as PNG (context menu)

## Summary

Add a "Copy as PNG" submenu directly below "Export screenshot…" in the display-item right-click context menu, letting the user copy the selected item's screenshot to the pasteboard at 1x/2x/3x pixel density. Applies to both places this context menu exists: the hierarchy outline view and the preview canvas.

## Menu placement & UI

- New menu item "Copy as PNG" added right below "Export screenshot…" in both `LKHierarchyView.m`'s and `LKPreviewController.m`'s context menus, gated by the same condition already used for "Export screenshot…" (only shown when the display item has a `groupScreenshot`).
- "Copy as PNG" has a submenu with three items, each titled with its scale and the resulting pixel dimensions, e.g. `3x (100x200)`.

## Scale semantics

Lookin's iOS-side capture renders each screenshot at the device's native screen scale (`UIScreen.mainScreen.scale`, typically 2x or 3x depending on device), but that scale is never transmitted as metadata to the Mac client — only the raw bitmap crosses the wire. The native capture scale for a given screenshot is derived on the Mac side from data already available, rather than assumed:

```
nativeScale = round(groupScreenshot pixel width / displayItem.frame width)
```

(`displayItem.frame` is in points; the screenshot's actual pixel width comes from its bitmap representation, not `NSImage.size`.)

- A submenu item for scale N is enabled only if N <= nativeScale; otherwise it's disabled (visible but greyed out, not removed from the menu).
- When N == nativeScale, the original captured bitmap is copied as-is, with no resampling.
- When N < nativeScale, the bitmap is downsampled to `displayItem.frame.size * N` using high-quality interpolation before being copied.
- `nativeScale` is computed per screenshot rather than assumed globally, so it naturally accounts for the existing capture-time fallbacks on the iOS side (a 16384px safety cap, and a low-quality mode that can force 1x) without needing any new data from that side.

## Output

Copying writes actual PNG bytes to the general pasteboard (not a generic `NSImage` handoff), so pasting into any other app yields a real PNG at the exact target pixel dimensions.

## Out of scope

- No changes to the iOS-side (LookinServer) capture code.
- No change to the existing "Export screenshot…" file-save flow — this is a separate, pasteboard-only action.
