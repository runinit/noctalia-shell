pragma Singleton

import QtQuick
import Quickshell
import qs.Services

/**
 * ThemeIcons - Icon resolution utilities
 *
 * RECOMMENDED PATTERN:
 * Use Qt's IconImage with the 'name' property for icon theme resolution:
 *
 *   import QtQuick.Controls
 *   import qs.Commons
 *
 *   IconImage {
 *     width: 40
 *     height: 40
 *     name: modelData.icon || "application-x-executable"
 *     asynchronous: true
 *   }
 *
 * This pattern:
 * - Follows XDG Icon Theme Specification (modern Linux desktop conventions)
 * - Uses Qt's native icon theme system for robust resolution
 * - Searches standard icon paths (/usr/share/icons, /usr/share/pixmaps, etc.)
 * - Respects the active icon theme and inheritance chains
 * - Handles SVG and PNG formats
 * - Properly scales icons to requested sizes
 * - Provides automatic fallback to specified fallback icon
 *
 * LEGACY/SPECIAL CASES:
 * The functions below provide icon resolution helpers for special cases:
 * - NotificationService (uses Image component, not IconImage)
 * - Custom icon resolution logic
 * - Absolute path handling
 */

Singleton {
  id: root

  function iconFromName(iconName, fallbackName) {
    const fallback = fallbackName || "application-x-executable"

    // Validate and trim input
    const name = (iconName || "").trim()
    if (!name) {
      // Empty or whitespace - use fallback immediately
      return iconFromName(fallback, "application-x-executable")
    }

    // Handle absolute paths - return directly per XDG spec
    // Desktop entries may use Icon=/absolute/path/to/icon.png
    if (name.startsWith("/")) {
      return name
    }

    // Strip file extensions per XDG Icon Theme Specification
    // Icon names should not include extensions, but some desktop files do
    const baseName = name.replace(/\.(png|svg|xpm)$/i, "")

    // Use Quickshell's icon resolution
    try {
      if (typeof Quickshell !== 'undefined' && Quickshell.iconPath) {
        const result = Quickshell.iconPath(baseName, fallback)
        if (result && result !== "") {
          // Strip Quickshell's internal ?fallback= syntax if present
          if (result.includes("?fallback=")) {
            const primary = result.split("?fallback=")[0]
            if (primary && primary !== "") {
              return primary
            }
          }
          return result
        }
      }
    } catch (e) {
      Logger.w("ThemeIcons", `Icon resolution failed for "${baseName}":`, e)
    }

    // Fallback to fallback icon (avoid infinite recursion)
    if (fallback !== baseName && fallback !== name) {
      return iconFromName(fallback, "application-x-executable")
    }

    // Final fallback - return empty string
    return ""
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
