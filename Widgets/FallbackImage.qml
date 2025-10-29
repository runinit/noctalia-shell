import QtQuick

// Image component that tries multiple icon sources with fuzzel-inspired fallback strategy
// Mimics fuzzel's icon resolution: theme -> pixmaps -> hicolor -> fallback
// Usage: FallbackImage { iconName: "zed"; width: 48; height: 48 }
Image {
  id: root

  property string iconName: ""
  property string fallbackName: "application-x-executable"
  property int currentAttempt: 0

  // List of paths to try for icon resolution (fuzzel-inspired)
  property var attemptPaths: []

  asynchronous: true
  smooth: true

  onIconNameChanged: {
    if (!root || !root.visible) return // Guard: don't process if not visible

    if (!iconName) {
      source = "image://icon/" + fallbackName
      return
    }

    // Build list of paths to try - FILE PATHS FIRST, then image://icon/
    // Reason: image://icon/ always returns Ready status (even for missing icons),
    // but file:// returns Error when file doesn't exist, allowing fallback to work
    attemptPaths = [
      // 1. Try common non-theme locations FIRST (what Qt misses but fuzzel finds)
      //    These will fail fast with Image.Error if file doesn't exist
      "file:///usr/share/icons/" + iconName + ".png",
      "file:///usr/share/icons/" + iconName + ".svg",

      // 2. Try pixmaps directories (Qt doesn't search these!)
      "file:///usr/share/pixmaps/" + iconName + ".png",
      "file:///usr/share/pixmaps/" + iconName + ".svg",

      // 3. Try hicolor theme explicitly (universal fallback theme)
      "file:///usr/share/icons/hicolor/scalable/apps/" + iconName + ".svg",
      "file:///usr/share/icons/hicolor/128x128/apps/" + iconName + ".png",
      "file:///usr/share/icons/hicolor/64x64/apps/" + iconName + ".png",
      "file:///usr/share/icons/hicolor/48x48/apps/" + iconName + ".png",

      // 3b. Try flatpak hicolor theme (flatpak applications)
      "file:///var/lib/flatpak/exports/share/icons/hicolor/scalable/apps/" + iconName + ".svg",
      "file:///var/lib/flatpak/exports/share/icons/hicolor/128x128/apps/" + iconName + ".png",
      "file:///var/lib/flatpak/exports/share/icons/hicolor/64x64/apps/" + iconName + ".png",
      "file:///var/lib/flatpak/exports/share/icons/hicolor/48x48/apps/" + iconName + ".png",

      // 4. Try Breeze theme (many icons exist here but not in other themes)
      "file:///usr/share/icons/breeze/apps/48/" + iconName + ".svg",
      "file:///usr/share/icons/breeze/preferences/32/" + iconName + ".svg",
      "file:///usr/share/icons/breeze/actions/22/" + iconName + ".svg",
      "file:///usr/share/icons/breeze/actions/24/" + iconName + ".svg",

      // 5. Try theme icon via image://icon/ (Qt's QIcon::fromTheme)
      //    This comes AFTER file checks because it always returns Ready
      "image://icon/" + iconName,

      // 6. Finally try fallback icon
      "image://icon/" + fallbackName
    ]

    currentAttempt = 0
    source = attemptPaths[0]
  }

  onStatusChanged: {
    // If current source failed and we have more to try, move to next
    // This is non-blocking: Qt Image loads async, we just react to failures
    if (!root || !attemptPaths || attemptPaths.length === 0) return // Guard against invalid state

    if (status === Image.Error && currentAttempt < attemptPaths.length - 1) {
      currentAttempt++
      source = attemptPaths[currentAttempt]
    }
  }
}
