pragma Singleton

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons

Singleton {
  id: root

  property ListModel availableFonts: ListModel {}
  property ListModel monospaceFonts: ListModel {}
  property ListModel displayFonts: ListModel {}
  property bool fontsLoaded: false
  property bool isLoading: false

  // Use objects for O(1) lookup instead of arrays
  property var fontconfigMonospaceFonts: ({})

  // Cache for font classification to avoid repeated checks
  property var fontCache: ({})

  // Chunk size for async processing
  readonly property int chunkSize: 100

  // -------------------------------------------
  function init() {
    Logger.i("Font", "Service started")
    loadFontconfigMonospaceFonts()
  }

  function loadFontconfigMonospaceFonts() {
    fontconfigProcess.command = ["fc-list", ":mono", "family"]
    fontconfigProcess.running = true
  }

  function loadSystemFonts() {
    if (isLoading)
      return

    Logger.d("Font", "Loading system fonts...")
    isLoading = true

    var fontFamilies = Qt.fontFamilies()

    // Pre-sort fonts before processing to ensure consistent order
    fontFamilies.sort(function (a, b) {
      return a.localeCompare(b)
    })

    // Clear existing models
    availableFonts.clear()
    monospaceFonts.clear()
    displayFonts.clear()
    fontCache = {}

    // Process fonts in chunks to avoid blocking
    processFontsAsync(fontFamilies, 0)
  }

  function processFontsAsync(fontFamilies, startIndex) {
    var endIndex = Math.min(startIndex + chunkSize, fontFamilies.length)
    var hasMore = endIndex < fontFamilies.length

    // Batch arrays to append all at once (much faster than individual appends)
    var availableBatch = []
    var monospaceBatch = []
    var displayBatch = []

    for (var i = startIndex; i < endIndex; i++) {
      var fontName = fontFamilies[i]
      if (!fontName || fontName.trim() === "")
        continue

      // Add to available fonts
      var fontObj = {
        "key": fontName,
        "name": fontName
      }
      availableBatch.push(fontObj)

      // Check monospace (with caching)
      if (isMonospaceFont(fontName)) {
        monospaceBatch.push(fontObj)
      }

      // Check display font (with caching)
      if (isDisplayFont(fontName)) {
        displayBatch.push(fontObj)
      }
    }

    // Batch append to models
    batchAppendToModel(availableFonts, availableBatch)
    batchAppendToModel(monospaceFonts, monospaceBatch)
    batchAppendToModel(displayFonts, displayBatch)

    if (hasMore) {
      // Continue processing in next frame
      Qt.callLater(function () {
        processFontsAsync(fontFamilies, endIndex)
      })
    } else {
      // Finished loading all fonts
      finalizeFontLoading()
    }
  }

  function batchAppendToModel(model, items) {
    for (var i = 0; i < items.length; i++) {
      model.append(items[i])
    }
  }

  function finalizeFontLoading() {
    // Add fallbacks if needed (models are already sorted)
    if (monospaceFonts.count === 0) {
      addFallbackFonts(monospaceFonts, ["DejaVu Sans Mono"])
    }

    if (displayFonts.count === 0) {
      addFallbackFonts(displayFonts, ["Inter", "Roboto", "DejaVu Sans"])
    }

    fontsLoaded = true
    isLoading = false
    Logger.d("Font", "Loaded", availableFonts.count, "fonts:", monospaceFonts.count, "monospace,", displayFonts.count, "display")
  }

  function isMonospaceFont(fontName) {
    // Check cache first
    if (fontCache.hasOwnProperty(fontName)) {
      return fontCache[fontName].isMonospace
    }

    var result = false

    // O(1) lookup using object instead of indexOf
    if (fontconfigMonospaceFonts.hasOwnProperty(fontName)) {
      result = true
    } else {
      // Fallback: check for basic monospace patterns
      var lowerFontName = fontName.toLowerCase()
      if (lowerFontName.includes("mono") || lowerFontName.includes("monospace")) {
        result = true
      }
    }

    // Cache the result
    if (!fontCache[fontName]) {
      fontCache[fontName] = {}
    }
    fontCache[fontName].isMonospace = result

    return result
  }

  function isDisplayFont(fontName) {
    // Check cache first
    if (fontCache.hasOwnProperty(fontName) && fontCache[fontName].hasOwnProperty('isDisplay')) {
      return fontCache[fontName].isDisplay
    }

    var result = false
    var lowerFontName = fontName.toLowerCase()

    if (lowerFontName.includes("display") || lowerFontName.includes("headline") || lowerFontName.includes("title")) {
      result = true
    }

    // Essential fallback fonts only
    var essentialFonts = ["Inter", "Roboto", "DejaVu Sans"]
    if (essentialFonts.indexOf(fontName) !== -1) {
      result = true
    }

    // Cache the result
    if (!fontCache[fontName]) {
      fontCache[fontName] = {}
    }
    fontCache[fontName].isDisplay = result

    return result
  }

  function sortModel(model) {
    // Convert to array
    var fontsArray = []
    for (var i = 0; i < model.count; i++) {
      fontsArray.push({
                        "key": model.get(i).key,
                        "name": model.get(i).name
                      })
    }

    // Sort
    fontsArray.sort(function (a, b) {
      return a.name.localeCompare(b.name)
    })

    // Clear and rebuild
    model.clear()
    batchAppendToModel(model, fontsArray)
  }

  function addFallbackFonts(model, fallbackFonts) {
    // Build a set of existing fonts for O(1) lookup
    var existingFonts = {}
    for (var i = 0; i < model.count; i++) {
      existingFonts[model.get(i).name] = true
    }

    var toAdd = []
    for (var j = 0; j < fallbackFonts.length; j++) {
      var fontName = fallbackFonts[j]
      if (!existingFonts[fontName]) {
        toAdd.push({
                     "key": fontName,
                     "name": fontName
                   })
      }
    }

    if (toAdd.length > 0) {
      batchAppendToModel(model, toAdd)
      sortModel(model)
    }
  }

  function searchFonts(query) {
    if (!query || query.trim() === "")
      return availableFonts

    var results = []
    var lowerQuery = query.toLowerCase()

    for (var i = 0; i < availableFonts.count; i++) {
      var font = availableFonts.get(i)
      if (font.name.toLowerCase().includes(lowerQuery)) {
        results.push(font)
      }
    }

    return results
  }

  // Apply fonts to GTK and Qt applications
  function applyFonts() {
    Logger.i("Font", "Applying fonts to GTK and Qt applications...")

    // Apply to GTK 3
    applyGtk3Fonts()

    // Apply to GTK 4
    applyGtk4Fonts()

    // Apply to Qt5
    applyQt5Fonts()

    // Apply to Qt6
    applyQt6Fonts()

    // Apply via gsettings
    applyGsettingsFonts()

    Logger.i("Font", "Fonts applied successfully")
  }

  // Apply fonts to GTK 3
  function applyGtk3Fonts() {
    var configDir = Quickshell.env("HOME") + "/.config/gtk-3.0"
    var configFile = configDir + "/settings.ini"

    // Ensure directory exists
    runCommand(["mkdir", "-p", configDir])

    // Read and update config
    readAndUpdateConfigFont(configFile, "gtk-font-name",
      `${Settings.data.ui.fontDefault} ${Settings.data.ui.fontDefaultSize}`, "[Settings]")
  }

  // Helper to read config file and update a font setting
  function readAndUpdateConfigFont(filePath, key, value, section) {
    readFile(filePath, function(content) {
      // Handle empty content (file doesn't exist or is empty)
      var lines = content && content.trim() !== "" ? content.split("\n") : []
      var updated = false
      var inSection = false

      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trim() === section) {
          inSection = true
        } else if (lines[i].trim().startsWith("[")) {
          inSection = false
        }

        if (inSection && lines[i].startsWith(key + "=")) {
          lines[i] = `${key}=${value}`
          updated = true
        }
      }

      // If not found, add it
      if (!updated) {
        if (lines.length === 0 || !lines.some(l => l.trim() === section)) {
          lines.unshift(section)
        }
        for (var j = 0; j < lines.length; j++) {
          if (lines[j].trim() === section) {
            lines.splice(j + 1, 0, `${key}=${value}`)
            break
          }
        }
      }

      writeFile(filePath, lines.join("\n"))
    })
  }

  // Apply fonts to GTK 4
  function applyGtk4Fonts() {
    var configDir = Quickshell.env("HOME") + "/.config/gtk-4.0"
    var configFile = configDir + "/settings.ini"

    // Ensure directory exists
    runCommand(["mkdir", "-p", configDir])

    // Read and update config
    readAndUpdateConfigFont(configFile, "gtk-font-name",
      `${Settings.data.ui.fontDefault} ${Settings.data.ui.fontDefaultSize}`, "[Settings]")
  }

  // Apply fonts to Qt5
  function applyQt5Fonts() {
    var configDir = Quickshell.env("HOME") + "/.config/qt5ct"
    var configFile = configDir + "/qt5ct.conf"

    // Ensure directory exists
    runCommand(["mkdir", "-p", configDir])

    // Read and update config with both general and fixed fonts
    readFile(configFile, function(content) {
      // Handle empty content (file doesn't exist or is empty)
      var lines = content && content.trim() !== "" ? content.split("\n") : []
      var generalUpdated = false
      var fixedUpdated = false
      var inFonts = false

      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trim() === "[Fonts]") {
          inFonts = true
        } else if (lines[i].trim().startsWith("[")) {
          inFonts = false
        }

        if (inFonts) {
          if (lines[i].startsWith("general=")) {
            lines[i] = `general="${Settings.data.ui.fontDefault}",${Settings.data.ui.fontDefaultSize},-1,5,50,0,0,0,0,0`
            generalUpdated = true
          } else if (lines[i].startsWith("fixed=")) {
            lines[i] = `fixed="${Settings.data.ui.fontFixed}",${Settings.data.ui.fontFixedSize},-1,5,50,0,0,0,0,0`
            fixedUpdated = true
          }
        }
      }

      // If not found, add them
      if (!generalUpdated || !fixedUpdated) {
        if (lines.length === 0 || !lines.some(l => l.trim() === "[Fonts]")) {
          lines.push("[Fonts]")
        }
        for (var j = 0; j < lines.length; j++) {
          if (lines[j].trim() === "[Fonts]") {
            if (!generalUpdated) {
              lines.splice(j + 1, 0, `general="${Settings.data.ui.fontDefault}",${Settings.data.ui.fontDefaultSize},-1,5,50,0,0,0,0,0`)
              j++
            }
            if (!fixedUpdated) {
              lines.splice(j + 1, 0, `fixed="${Settings.data.ui.fontFixed}",${Settings.data.ui.fontFixedSize},-1,5,50,0,0,0,0,0`)
            }
            break
          }
        }
      }

      writeFile(configFile, lines.join("\n"))
    })
  }

  // Apply fonts to Qt6
  function applyQt6Fonts() {
    var configDir = Quickshell.env("HOME") + "/.config/qt6ct"
    var configFile = configDir + "/qt6ct.conf"

    // Ensure directory exists
    runCommand(["mkdir", "-p", configDir])

    // Read and update config with both general and fixed fonts
    readFile(configFile, function(content) {
      // Handle empty content (file doesn't exist or is empty)
      var lines = content && content.trim() !== "" ? content.split("\n") : []
      var generalUpdated = false
      var fixedUpdated = false
      var inFonts = false

      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trim() === "[Fonts]") {
          inFonts = true
        } else if (lines[i].trim().startsWith("[")) {
          inFonts = false
        }

        if (inFonts) {
          if (lines[i].startsWith("general=")) {
            lines[i] = `general="${Settings.data.ui.fontDefault}",${Settings.data.ui.fontDefaultSize},-1,5,50,0,0,0,0,0`
            generalUpdated = true
          } else if (lines[i].startsWith("fixed=")) {
            lines[i] = `fixed="${Settings.data.ui.fontFixed}",${Settings.data.ui.fontFixedSize},-1,5,50,0,0,0,0,0`
            fixedUpdated = true
          }
        }
      }

      // If not found, add them
      if (!generalUpdated || !fixedUpdated) {
        if (lines.length === 0 || !lines.some(l => l.trim() === "[Fonts]")) {
          lines.push("[Fonts]")
        }
        for (var j = 0; j < lines.length; j++) {
          if (lines[j].trim() === "[Fonts]") {
            if (!generalUpdated) {
              lines.splice(j + 1, 0, `general="${Settings.data.ui.fontDefault}",${Settings.data.ui.fontDefaultSize},-1,5,50,0,0,0,0,0`)
              j++
            }
            if (!fixedUpdated) {
              lines.splice(j + 1, 0, `fixed="${Settings.data.ui.fontFixed}",${Settings.data.ui.fontFixedSize},-1,5,50,0,0,0,0,0`)
            }
            break
          }
        }
      }

      writeFile(configFile, lines.join("\n"))
    })
  }

  // Apply fonts via gsettings
  function applyGsettingsFonts() {
    // Interface font
    runCommand(["gsettings", "set", "org.gnome.desktop.interface", "font-name", `${Settings.data.ui.fontDefault} ${Settings.data.ui.fontDefaultSize}`])

    // Document font
    runCommand(["gsettings", "set", "org.gnome.desktop.interface", "document-font-name", `${Settings.data.ui.fontDefault} ${Settings.data.ui.fontDefaultSize}`])

    // Monospace font
    runCommand(["gsettings", "set", "org.gnome.desktop.interface", "monospace-font-name", `${Settings.data.ui.fontFixed} ${Settings.data.ui.fontFixedSize}`])

    // Text scaling factor
    if (Settings.data.appearance && Settings.data.appearance.textScaling) {
      runCommand(["gsettings", "set", "org.gnome.desktop.interface", "text-scaling-factor", Settings.data.appearance.textScaling.toString()])
    }
  }

  // Apply text scaling separately (can be called independently)
  function applyTextScaling(scaling) {
    if (!scaling) {
      scaling = Settings.data.appearance && Settings.data.appearance.textScaling ? Settings.data.appearance.textScaling : 1.0
    }

    Logger.i("Font", `Applying text scaling: ${scaling}`)

    // Update settings (auto-saves after 1 second)
    if (Settings.data.appearance) {
      Settings.data.appearance.textScaling = scaling
    }

    // Apply to gsettings (GTK)
    runCommand(["gsettings", "set", "org.gnome.desktop.interface", "text-scaling-factor", scaling.toString()])

    // Apply to Qt5 (using font DPI)
    applyQt5TextScaling(scaling)

    // Apply to Qt6 (using font DPI)
    applyQt6TextScaling(scaling)

    Logger.i("Font", "Text scaling applied successfully")
  }

  // Apply text scaling to Qt5 via DPI
  function applyQt5TextScaling(scaling) {
    var configDir = Quickshell.env("HOME") + "/.config/qt5ct"
    var configFile = configDir + "/qt5ct.conf"

    // Ensure directory exists
    runCommand(["mkdir", "-p", configDir])

    // Calculate DPI based on scaling (base DPI = 96)
    var dpi = Math.round(96 * scaling)

    // Read and update config
    readAndUpdateConfigFont(configFile, "dpi", dpi.toString(), "[Fonts]")
  }

  // Apply text scaling to Qt6 via DPI
  function applyQt6TextScaling(scaling) {
    var configDir = Quickshell.env("HOME") + "/.config/qt6ct"
    var configFile = configDir + "/qt6ct.conf"

    // Ensure directory exists
    runCommand(["mkdir", "-p", configDir])

    // Calculate DPI based on scaling (base DPI = 96)
    var dpi = Math.round(96 * scaling)

    // Read and update config
    readAndUpdateConfigFont(configFile, "dpi", dpi.toString(), "[Fonts]")
  }

  // Process for reading files (needs output)
  Process {
    id: fileReader
    running: false
    property var callback: null
    property var outputLines: []

    stdout: SplitParser {
      id: fileReaderCollector
      onRead: data => {
        if (data) {
          fileReader.outputLines.push(data)
        }
      }
    }

    onExited: (exitCode, exitStatus) => {
      if (fileReader.callback) {
        let fullOutput = fileReader.outputLines.join("\n")
        fileReader.callback(fullOutput)
        fileReader.callback = null
        fileReader.outputLines = []
      }
    }
  }

  // Helper function to run a command (fire-and-forget)
  function runCommand(command) {
    Quickshell.execDetached(command)
  }

  // Helper function to read a file asynchronously
  function readFile(filePath, callback) {
    fileReader.callback = callback
    // Use 'cat' with error suppression - if file doesn't exist, callback gets empty string
    fileReader.command = ["sh", "-c", `cat "${filePath}" 2>/dev/null || true`]
    fileReader.running = true
  }

  // Helper function to write a file
  function writeFile(filePath, content) {
    let qml = `
      import QtQuick
      import Quickshell.Io
      Process {
        running: true
        command: ["sh", "-c", "cat > '${filePath}'"]
        property string data: \`${content.replace(/`/g, '\\`').replace(/\$/g, '\\$')}\`
        Component.onCompleted: {
          stdin = data
        }
        onExited: destroy()
      }
    `
    Qt.createQmlObject(qml, root, "fileWriter")
  }

  // Process for fontconfig commands
  Process {
    id: fontconfigProcess
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        if (this.text !== "") {
          var lines = this.text.split('\n')
          // Use object for O(1) lookup instead of array
          var monospaceLookup = {}

          for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line && line !== "") {
              monospaceLookup[line] = true
            }
          }

          fontconfigMonospaceFonts = monospaceLookup
        }
        loadSystemFonts()
      }
    }

    onExited: function (exitCode, exitStatus) {
      if (exitCode !== 0) {
        fontconfigMonospaceFonts = {}
      }
      loadSystemFonts()
    }
  }
}
