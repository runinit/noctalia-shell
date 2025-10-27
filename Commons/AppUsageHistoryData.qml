pragma Singleton

import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Services

Item {
  id: root

  // Usage data structure:
  // {
  //   "app.id.desktop": {
  //     count: 42,
  //     lastLaunch: 1234567890,
  //     launches: [timestamp1, timestamp2, ...]  // Last 10 launches
  //   }
  // }

  property string usageFilePath: Settings.cacheDir + "app_usage_history.json"

  // Debounced saver
  Timer {
    id: saveTimer
    interval: 1000
    repeat: false
    onTriggered: usageFile.writeAdapter()
  }

  FileView {
    id: usageFile
    path: usageFilePath
    printErrors: false
    watchChanges: false

    onLoadFailed: function (error) {
      if (error.toString().includes("No such file") || error === 2) {
        Logger.d("AppUsageHistory", "Creating new usage history file")
        writeAdapter()
      }
    }

    onAdapterUpdated: saveTimer.start()

    JsonAdapter {
      id: usageAdapter
      property var history: ({})
    }
  }

  function init() {
    Logger.d("AppUsageHistory", "Service started")
  }

  // Record app launch
  function recordLaunch(appKey) {
    if (!appKey) return

    if (!usageAdapter.history) {
      usageAdapter.history = {}
    }

    const now = Date.now()
    let appData = usageAdapter.history[appKey]

    if (!appData) {
      appData = {
        count: 0,
        lastLaunch: now,
        launches: []
      }
    }

    // Increment count
    appData.count = (appData.count || 0) + 1
    appData.lastLaunch = now

    // Track last 10 launches
    if (!appData.launches) {
      appData.launches = []
    }
    appData.launches.push(now)
    if (appData.launches.length > 10) {
      appData.launches = appData.launches.slice(-10)
    }

    usageAdapter.history[appKey] = appData

    // Trigger save
    saveTimer.restart()

    Logger.d("AppUsageHistory", `Recorded launch: ${appKey} (total: ${appData.count})`)
  }

  // Get usage count for an app
  function getUsageCount(appKey) {
    if (!appKey || !usageAdapter.history) return 0

    const appData = usageAdapter.history[appKey]
    return appData ? (appData.count || 0) : 0
  }

  // Get last launch timestamp
  function getLastLaunch(appKey) {
    if (!appKey || !usageAdapter.history) return 0

    const appData = usageAdapter.history[appKey]
    return appData ? (appData.lastLaunch || 0) : 0
  }

  // Calculate recency score (higher = more recent)
  function getRecencyScore(appKey) {
    const lastLaunch = getLastLaunch(appKey)
    if (lastLaunch === 0) return 0

    const now = Date.now()
    const ageMs = now - lastLaunch

    // Score based on age
    const oneDay = 86400000 // ms
    if (ageMs < oneDay) {
      return 1500 // Launched today
    } else if (ageMs < oneDay * 7) {
      return 1000 // Launched this week
    } else if (ageMs < oneDay * 30) {
      return 500  // Launched this month
    }
    return 0
  }

  // Calculate usage frequency score
  function getFrequencyScore(appKey) {
    const count = getUsageCount(appKey)
    // Cap at 2000 to prevent one app from dominating
    return Math.min(count * 10, 2000)
  }

  // Get combined usage score for ranking
  function getUsageScore(appKey) {
    return getFrequencyScore(appKey) + getRecencyScore(appKey)
  }

  // Get most used apps
  function getMostUsedApps(limit = 10) {
    if (!usageAdapter.history) return []

    const apps = Object.keys(usageAdapter.history).map(key => {
      const data = usageAdapter.history[key]
      return {
        appKey: key,
        count: data.count,
        lastLaunch: data.lastLaunch,
        launches: data.launches,
        score: getUsageScore(key)
      }
    })

    apps.sort((a, b) => b.score - a.score)
    return apps.slice(0, limit).map(app => app.appKey)
  }

  // Get recently used apps
  function getRecentlyUsedApps(limit = 10) {
    if (!usageAdapter.history) return []

    const apps = Object.keys(usageAdapter.history).map(key => {
      const data = usageAdapter.history[key]
      return {
        appKey: key,
        count: data.count,
        lastLaunch: data.lastLaunch,
        launches: data.launches
      }
    })

    apps.sort((a, b) => b.lastLaunch - a.lastLaunch)
    return apps.slice(0, limit).map(app => app.appKey)
  }

  // Clear all usage data
  function clearHistory() {
    Logger.d("AppUsageHistory", "Clearing all usage history")
    usageAdapter.history = {}
    saveTimer.restart()
  }

  // Clear usage data for specific app
  function clearApp(appKey) {
    if (!appKey || !usageAdapter.history) return

    delete usageAdapter.history[appKey]
    saveTimer.restart()
    Logger.d("AppUsageHistory", `Cleared history for: ${appKey}`)
  }
}
