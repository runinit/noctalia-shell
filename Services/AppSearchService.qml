pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services

Singleton {
  id: root

  // Application categories
  readonly property var categoryMap: ({
    "AudioVideo": I18n.tr("category.media"),
    "Audio": I18n.tr("category.media"),
    "Video": I18n.tr("category.media"),
    "Development": I18n.tr("category.development"),
    "Education": I18n.tr("category.education"),
    "Game": I18n.tr("category.games"),
    "Graphics": I18n.tr("category.graphics"),
    "Network": I18n.tr("category.network"),
    "Office": I18n.tr("category.productivity"),
    "Science": I18n.tr("category.science"),
    "Settings": I18n.tr("category.settings"),
    "System": I18n.tr("category.system"),
    "Utility": I18n.tr("category.utilities")
  })

  // Cached applications list
  property var applications: []
  property bool loaded: false

  // Category-filtered lists (cached)
  property var categorizedApps: ({})

  signal applicationsLoaded()
  signal applicationsChanged()

  function init() {
    Logger.d("AppSearchService", "Service started")
    loadApplications()
  }

  // Load all applications from DesktopEntries
  function loadApplications() {
    if (typeof DesktopEntries === 'undefined') {
      Logger.w("AppSearchService", "DesktopEntries service not available")
      loaded = false
      return
    }

    const allApps = DesktopEntries.applications.values || []
    applications = allApps.filter(app => app && !app.noDisplay).map(app => {
      // Enhance app object with additional properties
      return enrichApp(app)
    })

    Logger.d("AppSearchService", `Loaded ${applications.length} applications`)

    // Build category cache
    categorizeApplications()

    loaded = true
    applicationsLoaded()
    applicationsChanged()
  }

  // Enrich app with additional search-friendly properties
  function enrichApp(app) {
    if (!app) return null

    // Extract executable name
    let executableName = ""
    if (app.command && Array.isArray(app.command) && app.command.length > 0) {
      const cmd = app.command[0]
      const parts = cmd.split('/')
      const executable = parts[parts.length - 1]
      executableName = executable.split(' ')[0]
    } else if (app.exec) {
      const parts = app.exec.split('/')
      const executable = parts[parts.length - 1]
      executableName = executable.split(' ')[0]
    }

    // Determine primary category
    let primaryCategory = "Other"
    if (app.categories && app.categories.length > 0) {
      for (let i = 0; i < app.categories.length; i++) {
        const cat = app.categories[i]
        if (categoryMap[cat]) {
          primaryCategory = cat
          break
        }
      }
    }

    return {
      ...app,
      executableName: executableName,
      primaryCategory: primaryCategory,
      categoryName: categoryMap[primaryCategory] || I18n.tr("category.other"),
      searchableText: `${app.name} ${app.comment || ''} ${app.genericName || ''} ${executableName}`.toLowerCase()
    }
  }

  // Organize apps by category
  function categorizeApplications() {
    const cats = {
      "All": applications
    }

    for (let i = 0; i < applications.length; i++) {
      const app = applications[i]
      const category = app.primaryCategory

      if (!cats[category]) {
        cats[category] = []
      }
      cats[category].push(app)
    }

    categorizedApps = cats
  }

  // Get all applications
  function getAllApplications() {
    if (!loaded) {
      loadApplications()
    }
    return applications
  }

  // Get applications by category
  function getApplicationsByCategory(category) {
    if (!loaded) {
      loadApplications()
    }

    if (category === "All" || !category) {
      return applications
    }

    return categorizedApps[category] || []
  }

  // Get list of categories with counts
  function getCategories() {
    const categories = [
      { name: "All", displayName: I18n.tr("category.all"), count: applications.length }
    ]

    const categoryKeys = Object.keys(categorizedApps).filter(key => key !== "All").sort()
    for (let i = 0; i < categoryKeys.length; i++) {
      const key = categoryKeys[i]
      const apps = categorizedApps[key]
      if (apps && apps.length > 0) {
        categories.push({
          name: key,
          displayName: categoryMap[key] || key,
          count: apps.length
        })
      }
    }

    return categories
  }

  // Execute an application
  function executeApp(app) {
    if (!app) {
      Logger.w("AppSearchService", "Cannot execute null app")
      return false
    }

    Logger.d("AppSearchService", `Launching: ${app.name}`)

    try {
      if (Settings.data.appLauncher && Settings.data.appLauncher.useApp2Unit && app.id) {
        Logger.d("AppSearchService", `Using app2unit for: ${app.id}`)
        if (app.runInTerminal) {
          Quickshell.execDetached(["app2unit", "--", app.id + ".desktop"])
        } else {
          Quickshell.execDetached(["app2unit", "--"].concat(app.command))
        }
      } else {
        // Fallback execution
        if (app.runInTerminal) {
          const terminal = (Settings.data.appLauncher && Settings.data.appLauncher.terminalCommand) ?
            Settings.data.appLauncher.terminalCommand.split(" ") : ["xterm", "-e"]
          const command = terminal.concat(app.command)
          Quickshell.execDetached(command)
        } else if (app.execute) {
          app.execute()
        } else {
          Logger.w("AppSearchService", `Could not launch: ${app.name}. No valid launch method.`)
          return false
        }
      }
      return true
    } catch (e) {
      Logger.e("AppSearchService", `Failed to launch ${app.name}:`, e)
      return false
    }
  }

  // Get app key for usage tracking
  function getAppKey(app) {
    if (!app) return "unknown"
    if (app.id) return String(app.id)
    if (app.command && app.command.join) return app.command.join(" ")
    return String(app.name || "unknown")
  }

  // Refresh applications (e.g., when system installs/removes apps)
  function refresh() {
    Logger.d("AppSearchService", "Refreshing applications")
    loadApplications()
  }

  // Watch for desktop entry changes
  Timer {
    interval: 30000 // Refresh every 30 seconds
    running: true
    repeat: true
    onTriggered: {
      if (typeof DesktopEntries !== 'undefined') {
        const currentCount = applications.length
        const newCount = (DesktopEntries.applications.values || []).filter(app => app && !app.noDisplay).length

        if (currentCount !== newCount) {
          Logger.d("AppSearchService", `Application count changed: ${currentCount} -> ${newCount}`)
          loadApplications()
        }
      }
    }
  }
}
