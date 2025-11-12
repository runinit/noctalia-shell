pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

Singleton {
  id: root

  function iconFromName(iconName, fallbackName) {
    const fallback = fallbackName || "application-x-executable"

    Logger.d("ThemeIcons", "iconFromName requested:", iconName, "fallback:", fallback)

    try {
      if (iconName && typeof Quickshell !== 'undefined' && Quickshell.iconPath) {
        const p = Quickshell.iconPath(iconName, fallback)
        Logger.d("ThemeIcons", "  Quickshell.iconPath('" + iconName + "', '" + fallback + "') returned:", p)
        if (p && p !== "") {
          Logger.d("ThemeIcons", "  ✓ Resolved to:", p)
          return p
        }
      }
    } catch (e) {
      Logger.w("ThemeIcons", "  Error calling iconPath:", e)
      // ignore and fall back
    }

    try {
      const fallbackPath = Quickshell.iconPath ? Quickshell.iconPath(fallback, true) : ""
      Logger.d("ThemeIcons", "  Trying fallback:", fallback, "->", fallbackPath)
      if (fallbackPath) {
        Logger.d("ThemeIcons", "  ✓ Fallback resolved to:", fallbackPath)
      } else {
        Logger.w("ThemeIcons", "  ✗ Icon not found for:", iconName, "(fallback also failed)")
      }
      return fallbackPath
    } catch (e2) {
      Logger.e("ThemeIcons", "  Error on fallback:", e2)
      return ""
    }
  }

  // Resolve icon path for a DesktopEntries appId - safe on missing entries
  function iconForAppId(appId, fallbackName) {
    const fallback = fallbackName || "application-x-executable"

    Logger.d("ThemeIcons", "iconForAppId requested for appId:", appId)

    if (!appId) {
      Logger.d("ThemeIcons", "  No appId provided, using fallback")
      return iconFromName(fallback, fallback)
    }

    try {
      if (typeof DesktopEntries === 'undefined' || !DesktopEntries.byId) {
        Logger.w("ThemeIcons", "  DesktopEntries not available")
        return iconFromName(fallback, fallback)
      }

      const entry = (DesktopEntries.heuristicLookup) ? DesktopEntries.heuristicLookup(appId) : DesktopEntries.byId(appId)

      if (!entry) {
        Logger.w("ThemeIcons", "  No desktop entry found for appId:", appId)
        return iconFromName(fallback, fallback)
      }

      const name = entry && entry.icon ? entry.icon : ""
      Logger.d("ThemeIcons", "  Desktop entry icon name:", name)

      return iconFromName(name || fallback, fallback)
    } catch (e) {
      Logger.e("ThemeIcons", "  Error looking up appId:", appId, "error:", e)
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
