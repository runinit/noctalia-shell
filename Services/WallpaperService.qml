pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.Commons

Singleton {
  id: root

  readonly property ListModel fillModeModel: ListModel {}
  readonly property string defaultDirectory: Settings.preprocessPath(Settings.data.wallpaper.directory)

  // All available wallpaper transitions
  readonly property ListModel transitionsModel: ListModel {}

  // All transition keys but filter out "none" and "random" so we are left with the real transitions
  readonly property var allTransitions: Array.from({
                                                     "length": transitionsModel.count
                                                   }, (_, i) => transitionsModel.get(i).key).filter(key => key !== "random" && key != "none")

  property var wallpaperLists: ({})
  property int scanningCount: 0
  readonly property bool scanning: (scanningCount > 0)

  // Cache for current wallpapers - can be updated directly since we use signals for notifications
  property var currentWallpapers: ({})

  // PERF: Cache FolderListModel instances by directory path to share between monitors
  property var folderModelCache: ({})

  property bool isInitialized: false

  // Signals for reactive UI updates
  signal wallpaperChanged(string screenName, string path)
  // Emitted when a wallpaper changes
  signal wallpaperDirectoryChanged(string screenName, string directory)
  // Emitted when a monitor's directory changes
  signal wallpaperListChanged(string screenName, int count)

  // Emitted when available wallpapers list changes
  Connections {
    target: Settings.data.wallpaper
    function onDirectoryChanged() {
      root.refreshWallpapersList()
      // Emit directory change signals for monitors using the default directory
      if (!Settings.data.wallpaper.enableMultiMonitorDirectories) {
        // All monitors use the main directory
        for (var i = 0; i < Quickshell.screens.length; i++) {
          root.wallpaperDirectoryChanged(Quickshell.screens[i].name, root.defaultDirectory)
        }
      } else {
        // Only monitors without custom directories are affected
        for (var i = 0; i < Quickshell.screens.length; i++) {
          var screenName = Quickshell.screens[i].name
          var monitor = root.getMonitorConfig(screenName)
          if (!monitor || !monitor.directory) {
            root.wallpaperDirectoryChanged(screenName, root.defaultDirectory)
          }
        }
      }
    }
    function onEnableMultiMonitorDirectoriesChanged() {
      root.refreshWallpapersList()
      // Notify all monitors about potential directory changes
      for (var i = 0; i < Quickshell.screens.length; i++) {
        var screenName = Quickshell.screens[i].name
        root.wallpaperDirectoryChanged(screenName, root.getMonitorDirectory(screenName))
      }
    }
    function onRandomEnabledChanged() {
      root.toggleRandomWallpaper()
    }
    function onRandomIntervalSecChanged() {
      root.restartRandomWallpaperTimer()
    }
  }

  // -------------------------------------------------
  function init() {
    Logger.log("Wallpaper", "Service started")

    translateModels()

    // Rebuild cache from settings
    currentWallpapers = ({})
    var monitors = Settings.data.wallpaper.monitors || []
    for (var i = 0; i < monitors.length; i++) {
      if (monitors[i].name && monitors[i].wallpaper) {
        currentWallpapers[monitors[i].name] = monitors[i].wallpaper
      }
    }

    isInitialized = true
  }

  // -------------------------------------------------
  function translateModels() {
    // Wait for i18n to be ready by retrying every time
    if (!I18n.isLoaded) {
      Qt.callLater(translateModels)
      return
    }

    // Populate fillModeModel with translated names
    fillModeModel.append({
                           "key": "center",
                           "name": I18n.tr("wallpaper.fill-modes.center"),
                           "uniform": 0.0
                         })
    fillModeModel.append({
                           "key": "crop",
                           "name": I18n.tr("wallpaper.fill-modes.crop"),
                           "uniform": 1.0
                         })
    fillModeModel.append({
                           "key": "fit",
                           "name": I18n.tr("wallpaper.fill-modes.fit"),
                           "uniform": 2.0
                         })
    fillModeModel.append({
                           "key": "stretch",
                           "name": I18n.tr("wallpaper.fill-modes.stretch"),
                           "uniform": 3.0
                         })

    // Populate transitionsModel with translated names
    transitionsModel.append({
                              "key": "none",
                              "name": I18n.tr("wallpaper.transitions.none")
                            })
    transitionsModel.append({
                              "key": "random",
                              "name": I18n.tr("wallpaper.transitions.random")
                            })
    transitionsModel.append({
                              "key": "fade",
                              "name": I18n.tr("wallpaper.transitions.fade")
                            })
    transitionsModel.append({
                              "key": "disc",
                              "name": I18n.tr("wallpaper.transitions.disc")
                            })
    transitionsModel.append({
                              "key": "stripes",
                              "name": I18n.tr("wallpaper.transitions.stripes")
                            })
    transitionsModel.append({
                              "key": "wipe",
                              "name": I18n.tr("wallpaper.transitions.wipe")
                            })
  }

  // -------------------------------------------------------------------
  function getFillModeUniform() {
    for (var i = 0; i < fillModeModel.count; i++) {
      const mode = fillModeModel.get(i)
      if (mode.key === Settings.data.wallpaper.fillMode) {
        return mode.uniform
      }
    }
    // Fallback to crop
    return 1.0
  }

  // -------------------------------------------------------------------
  // Get specific monitor wallpaper data
  function getMonitorConfig(screenName) {
    var monitors = Settings.data.wallpaper.monitors
    if (monitors !== undefined) {
      for (var i = 0; i < monitors.length; i++) {
        if (monitors[i].name !== undefined && monitors[i].name === screenName) {
          return monitors[i]
        }
      }
    }
  }

  // -------------------------------------------------------------------
  // Get specific monitor directory
  function getMonitorDirectory(screenName) {
    if (!Settings.data.wallpaper.enableMultiMonitorDirectories) {
      return root.defaultDirectory
    }

    var monitor = getMonitorConfig(screenName)
    if (monitor !== undefined && monitor.directory !== undefined) {
      return Settings.preprocessPath(monitor.directory)
    }

    // Fall back to the main/single directory
    return root.defaultDirectory
  }

  // -------------------------------------------------------------------
  // Set specific monitor directory
  function setMonitorDirectory(screenName, directory) {
    var monitors = Settings.data.wallpaper.monitors || []
    var found = false

    // Create a new array with updated values
    var newMonitors = monitors.map(function (monitor) {
      if (monitor.name === screenName) {
        found = true
        return {
          "name": screenName,
          "directory": directory,
          "wallpaper": monitor.wallpaper || ""
        }
      }
      return monitor
    })

    if (!found) {
      newMonitors.push({
                         "name": screenName,
                         "directory": directory,
                         "wallpaper": ""
                       })
    }

    // Update Settings with new array to ensure proper persistence
    Settings.data.wallpaper.monitors = newMonitors.slice()
    root.wallpaperDirectoryChanged(screenName, Settings.preprocessPath(directory))
  }

  // -------------------------------------------------------------------
  // Get specific monitor wallpaper - now from cache
  function getWallpaper(screenName) {
    return currentWallpapers[screenName] || Settings.data.wallpaper.defaultWallpaper
  }

  // -------------------------------------------------------------------
  function changeWallpaper(path, screenName) {
    if (screenName !== undefined) {
      _setWallpaper(screenName, path)
    } else {
      // If no screenName specified change for all screens
      for (var i = 0; i < Quickshell.screens.length; i++) {
        _setWallpaper(Quickshell.screens[i].name, path)
      }
    }
  }

  // -------------------------------------------------------------------
  function _setWallpaper(screenName, path) {
    if (path === "" || path === undefined) {
      return
    }

    if (screenName === undefined) {
      Logger.warn("Wallpaper", "setWallpaper", "no screen specified")
      return
    }

    //Logger.log("Wallpaper", "setWallpaper on", screenName, ": ", path)

    // Check if wallpaper actually changed
    var oldPath = currentWallpapers[screenName] || ""
    var wallpaperChanged = (oldPath !== path)

    if (!wallpaperChanged) {
      // No change needed
      return
    }

    // Update cache directly
    currentWallpapers[screenName] = path

    // Update Settings - still need immutable update for Settings persistence
    // The slice() ensures Settings detects the change and saves properly
    var monitors = Settings.data.wallpaper.monitors || []
    var found = false

    var newMonitors = monitors.map(function (monitor) {
      if (monitor.name === screenName) {
        found = true
        return {
          "name": screenName,
          "directory": Settings.preprocessPath(monitor.directory) || getMonitorDirectory(screenName),
          "wallpaper": path
        }
      }
      return monitor
    })

    if (!found) {
      newMonitors.push({
                         "name": screenName,
                         "directory": getMonitorDirectory(screenName),
                         "wallpaper": path
                       })
    }

    Settings.data.wallpaper.monitors = newMonitors.slice()

    // Emit signal for this specific wallpaper change
    root.wallpaperChanged(screenName, path)

    // Restart the random wallpaper timer
    if (randomWallpaperTimer.running) {
      randomWallpaperTimer.restart()
    }
  }

  // -------------------------------------------------------------------
  function setRandomWallpaper() {
    Logger.log("Wallpaper", "setRandomWallpaper")

    if (Settings.data.wallpaper.enableMultiMonitorDirectories) {
      // Pick a random wallpaper per screen
      for (var i = 0; i < Quickshell.screens.length; i++) {
        var screenName = Quickshell.screens[i].name
        var wallpaperList = getWallpapersList(screenName)

        if (wallpaperList.length > 0) {
          var randomIndex = Math.floor(Math.random() * wallpaperList.length)
          var randomPath = wallpaperList[randomIndex]
          changeWallpaper(randomPath, screenName)
        }
      }
    } else {
      // Pick a random wallpaper common to all screens
      // We can use any screenName here, so we just pick the primary one.
      if (Quickshell.screens.length > 0) {
        var wallpaperList = getWallpapersList(Quickshell.screens[0].name)
        if (wallpaperList.length > 0) {
          var randomIndex = Math.floor(Math.random() * wallpaperList.length)
          var randomPath = wallpaperList[randomIndex]
          changeWallpaper(randomPath, undefined)
        }
      }
    }
  }

  // -------------------------------------------------------------------
  function toggleRandomWallpaper() {
    Logger.log("Wallpaper", "toggleRandomWallpaper")
    if (Settings.data.wallpaper.randomEnabled) {
      restartRandomWallpaperTimer()
      setRandomWallpaper()
    }
  }

  // -------------------------------------------------------------------
  function restartRandomWallpaperTimer() {
    if (Settings.data.wallpaper.isRandom) {
      randomWallpaperTimer.restart()
    }
  }

  // -------------------------------------------------------------------
  function getWallpapersList(screenName) {
    if (screenName != undefined && wallpaperLists[screenName] != undefined) {
      return wallpaperLists[screenName]
    }
    return []
  }

  // -------------------------------------------------------------------
  function refreshWallpapersList() {
    Logger.log("Wallpaper", "refreshWallpapersList")
    scanningCount = 0

    // PERF: Force refresh on all cached FolderListModels
    for (var directory in folderModelCache) {
      var model = folderModelCache[directory]
      if (model) {
        var currentFolder = model.folder
        model.folder = ""
        model.folder = currentFolder
      }
    }
  }

  // PERF: Get or create a FolderListModel for a directory
  // This allows sharing the same model between multiple monitors using the same directory
  function getOrCreateFolderModel(directory) {
    if (folderModelCache[directory]) {
      return folderModelCache[directory]
    }

    // Create new FolderListModel
    var component = Qt.createComponent("Qt.labs.folderlistmodel", "FolderListModel")
    if (component.status === Component.Error) {
      Logger.error("Wallpaper", "Error creating FolderListModel:", component.errorString())
      return null
    }

    var model = component.createObject(root, {
                                         "folder": "file://" + directory,
                                         "nameFilters": ["*.jpg", "*.jpeg", "*.png", "*.gif", "*.pnm", "*.bmp"],
                                         "showDirs": false,
                                         "sortField": 0 // FolderListModel.Name
                                       })

    if (!model) {
      Logger.error("Wallpaper", "Failed to create FolderListModel")
      return null
    }

    // Cache it
    folderModelCache[directory] = model

    // Setup status handler
    model.statusChanged.connect(function () {
      handleFolderModelStatus(model, directory)
    })

    return model
  }

  // PERF: Handle FolderListModel status changes for all screens using this directory
  function handleFolderModelStatus(model, directory) {
    if (model.status === 0) {
      // Null
      for (var i = 0; i < Quickshell.screens.length; i++) {
        var screenName = Quickshell.screens[i].name
        if (root.getMonitorDirectory(screenName) === directory) {
          root.wallpaperLists[screenName] = []
          root.wallpaperListChanged(screenName, 0)
        }
      }
    } else if (model.status === 1) {
      // Loading
      for (var i = 0; i < Quickshell.screens.length; i++) {
        var screenName = Quickshell.screens[i].name
        if (root.getMonitorDirectory(screenName) === directory) {
          root.wallpaperLists[screenName] = []
        }
      }
      scanningCount++
    } else if (model.status === 2) {
      // Ready
      var files = []
      for (var i = 0; i < model.count; i++) {
        var filepath = directory + "/" + model.get(i, "fileName")
        files.push(filepath)
      }

      // Update all screens using this directory
      for (var i = 0; i < Quickshell.screens.length; i++) {
        var screenName = Quickshell.screens[i].name
        if (root.getMonitorDirectory(screenName) === directory) {
          root.wallpaperLists[screenName] = files
          root.wallpaperListChanged(screenName, files.length)
        }
      }

      scanningCount--
      Logger.log("Wallpaper", "List refreshed for directory", directory, "count:", files.length)
    }
  }

  // -------------------------------------------------------------------
  // -------------------------------------------------------------------
  // -------------------------------------------------------------------
  Timer {
    id: randomWallpaperTimer
    interval: Settings.data.wallpaper.randomIntervalSec * 1000
    running: Settings.data.wallpaper.randomEnabled
    repeat: true
    onTriggered: setRandomWallpaper()
    triggeredOnStart: false
  }

  // PERF: Instantiator creates monitor watchers that reference shared FolderListModels
  // Multiple monitors using the same directory will share a single FolderListModel
  Instantiator {
    id: wallpaperScanners
    model: Quickshell.screens
    delegate: QtObject {
      id: monitorWatcher
      property string screenName: modelData.name
      property string currentDirectory: root.getMonitorDirectory(screenName)
      property var folderModel: null

      Component.onCompleted: {
        // Get or create the shared FolderListModel for this directory
        folderModel = root.getOrCreateFolderModel(currentDirectory)

        // Connect to directory change signal
        root.wallpaperDirectoryChanged.connect(function (screen, directory) {
          if (screen === screenName) {
            currentDirectory = directory
            // Switch to the FolderListModel for the new directory
            folderModel = root.getOrCreateFolderModel(directory)
          }
        })
      }
    }
  }
}
