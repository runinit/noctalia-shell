pragma Singleton

import QtQuick
import Quickshell
import qs.Services

Singleton {
  id: root

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
