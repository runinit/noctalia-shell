pragma Singleton

import QtQuick
import Quickshell
import qs.Services

/**
 * ThemeIcons - Icon resolution utilities
 *
 * STANDARD ICON PATTERN (Recommended):
 * Use Qt's IconImage with ThemeIcons.iconFromName() for icon theme resolution:
 *
 *   import QtQuick.Controls
 *   import qs.Commons
 *
 *   IconImage {
 *     width: 40
 *     height: 40
 *     source: modelData.icon ? ThemeIcons.iconFromName(modelData.icon, "application-x-executable") : ""
 *     asynchronous: true
 *   }
 *
 * This pattern:
 * - Follows XDG Icon Theme Specification (modern Linux desktop conventions)
 * - Uses Quickshell's icon path resolution via Quickshell.iconPath()
 * - Searches standard icon paths (/usr/share/icons, /usr/share/pixmaps, etc.)
 * - Respects the active icon theme
 * - Handles SVG and PNG formats
 * - Provides automatic fallback to specified fallback icon
 *
 * HELPER FUNCTIONS:
 * The functions below provide icon resolution helpers.
 */

Singleton {
  id: root

  /**
   * Get icon URL using Qt's icon theme provider
   * Returns: "image://icon/{iconName}" URL for use with Image components
   *
   * Prefer using IconImage's 'name' property instead of this function.
   */
  function iconUrl(iconName, fallbackName) {
    const name = iconName || fallbackName || "application-x-executable"
    return `image://icon/${name}`
  }

  function iconFromName(iconName, fallbackName) {
    const fallback = fallbackName || "application-x-executable"
    try {
      if (iconName && typeof Quickshell !== 'undefined' && Quickshell.iconPath) {
        const p = Quickshell.iconPath(iconName, fallback)
        if (p && p !== "") {
          // Strip ?fallback= syntax if present (QuickShell's internal format)
          // IconImage doesn't understand this syntax
          if (p.includes("?fallback=")) {
            const primary = p.split("?fallback=")[0]
            if (primary && primary !== "") {
              return primary
            }
          } else {
            return p
          }
        }
      }
    } catch (e) {
      // ignore and fall back
    }

    // Try fallback icon
    try {
      const fallbackResult = Quickshell.iconPath ? (Quickshell.iconPath(fallback, true) || "") : ""
      if (fallbackResult && fallbackResult.includes("?fallback=")) {
        return fallbackResult.split("?fallback=")[0] || ""
      }
      return fallbackResult
    } catch (e2) {
      return ""
    }
  }

  // Resolve icon path for a DesktopEntries appId - safe on missing entries
  function iconForAppId(appId, fallbackName) {
    const fallback = fallbackName || "application-x-executable"
    if (!appId)
      return iconFromName(fallback, fallback)
    try {
      if (typeof DesktopEntries === 'undefined' || !DesktopEntries.byId)
        return iconFromName(fallback, fallback)
      const entry = (DesktopEntries.heuristicLookup) ? DesktopEntries.heuristicLookup(appId) : DesktopEntries.byId(appId)
      const name = entry && entry.icon ? entry.icon : ""
      return iconFromName(name || fallback, fallback)
    } catch (e) {
      return iconFromName(fallback, fallback)
    }
  }

  // Distro logo helper (absolute path or empty string)
  function distroLogoPath() {
    try {
      return (typeof OSInfo !== 'undefined' && OSInfo.distroIconPath) ? OSInfo.distroIconPath : ""
    } catch (e) {
      return ""
    }
  }
}
