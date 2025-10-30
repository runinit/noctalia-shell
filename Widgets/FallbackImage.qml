import QtQuick

// Image component that tries multiple icon sources with fuzzel-inspired fallback strategy
// Optimized to prevent crashes from mass simultaneous loading
// Usage: FallbackImage { iconName: "zed"; width: 48; height: 48 }
Image {
  id: root

  property string iconName: ""
  property string fallbackName: "application-x-executable"
  property int currentAttempt: 0

  // List of paths to try for icon resolution (reduced to 6 essential paths)
  property var attemptPaths: []

  asynchronous: true
  smooth: true

  // Helper function to check if component is truly visible
  function isActuallyVisible() {
    if (!root) return false
    if (!root.visible) return false
    if (root.opacity <= 0) return false // ListView sets opacity:0 for offscreen items

    // Check parent chain visibility
    var p = root.parent
    while (p) {
      if (!p.visible || (p.opacity !== undefined && p.opacity <= 0)) {
        return false
      }
      p = p.parent
    }
    return true
  }

  onIconNameChanged: {
    // Enhanced visibility guard - check before doing ANY work
    if (!isActuallyVisible()) return

    if (!iconName) {
      loadTimer.stop()
      source = "image://icon/" + fallbackName
      return
    }

    // Reduced path list: 6 essential locations instead of 17
    // This reduces failed operations by 65%
    attemptPaths = [
      // 1. Pixmaps (most reliable for app icons)
      "file:///usr/share/pixmaps/" + iconName + ".png",

      // 2. Hicolor scalable (universal fallback)
      "file:///usr/share/icons/hicolor/scalable/apps/" + iconName + ".svg",

      // 3. Hicolor 48x48 (common size)
      "file:///usr/share/icons/hicolor/48x48/apps/" + iconName + ".png",

      // 4. Flatpak hicolor scalable
      "file:///var/lib/flatpak/exports/share/icons/hicolor/scalable/apps/" + iconName + ".svg",

      // 5. Theme icon via Qt (checks all installed themes)
      "image://icon/" + iconName,

      // 6. Fallback
      "image://icon/" + fallbackName
    ]

    currentAttempt = 0

    // Add small delay to prevent cascade when many icons load at once
    loadTimer.restart()
  }

  // Delay timer to stagger icon loading
  Timer {
    id: loadTimer
    interval: Math.random() * 50 // Random 0-50ms delay
    running: false
    onTriggered: {
      if (isActuallyVisible() && attemptPaths.length > 0) {
        source = attemptPaths[currentAttempt]
      }
    }
  }

  onStatusChanged: {
    // Enhanced guard - exit early if not truly visible
    if (!isActuallyVisible()) return
    if (!attemptPaths || attemptPaths.length === 0) return

    // If current source failed and we have more to try, move to next
    if (status === Image.Error && currentAttempt < attemptPaths.length - 1) {
      currentAttempt++
      // Small delay before next attempt to prevent cascade
      Qt.callLater(() => {
        if (isActuallyVisible()) {
          source = attemptPaths[currentAttempt]
        }
      })
    }
  }

  // Cleanup when destroyed
  Component.onDestruction: {
    loadTimer.stop()
    attemptPaths = []
  }
}
