pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Commons

Singleton {
  id: root

  // Available icon themes
  property ListModel availableIconThemes: ListModel {}

  // Current icon theme
  property string currentIconTheme: Settings.data.appearance ? Settings.data.appearance.iconTheme : "Adwaita"

  // Scan paths for icon themes
  readonly property var iconThemePaths: [
    Quickshell.env("HOME") + "/.local/share/icons",
    Quickshell.env("HOME") + "/.icons",
    "/usr/share/icons",
    "/usr/local/share/icons"
  ]

  // Ready state
  property bool ready: false

  // Process for scanning directories (needs output)
  Process {
    id: scanner
    running: false
    property var callback: null
    property var outputLines: []

    stdout: SplitParser {
      id: scannerCollector
      onRead: data => {
        if (data) {
          scanner.outputLines.push(data)
        }
      }
    }

    onExited: (exitCode, exitStatus) => {
      if (scanner.callback) {
        let fullOutput = scanner.outputLines.join("\n")
        scanner.callback(fullOutput)
        scanner.callback = null
        scanner.outputLines = []
      }
    }
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

  Component.onCompleted: {
    Logger.i("IconThemeService", "Initializing icon theme service...")
    scanIconThemes()
    ready = true
    Logger.i("IconThemeService", `Found ${availableIconThemes.count} icon themes`)
  }

  // Scan system for available icon themes
  function scanIconThemes() {
    availableIconThemes.clear()

    // Scan all paths in a single command
    let pathsStr = iconThemePaths.join(" ")

    scanner.callback = function(output) {
      let foundThemes = new Set()

      if (output) {
        let themeDirs = output.trim().split("\n")
        for (let themeDir of themeDirs) {
          if (!themeDir) continue

          let themeName = themeDir.split("/").pop()

          // Filter out cursor themes and invalid entries
          if (themeName &&
              !themeName.toLowerCase().includes("cursor") &&
              !themeName.startsWith(".") &&
              themeName !== "default") {
            foundThemes.add(themeName)
          }
        }
      }

      // Populate model with sorted themes
      let themeArray = Array.from(foundThemes).sort()
      for (let theme of themeArray) {
        availableIconThemes.append({
          key: theme,
          name: theme,
          displayName: theme.replace(/-/g, " ").replace(/_/g, " ")
        })
      }

      Logger.i("IconThemeService", `Found ${availableIconThemes.count} icon themes after scan`)
    }

    // Use a single find command for all paths
    let cmd = `for dir in ${pathsStr}; do [ -d "$dir" ] && find "$dir" -maxdepth 2 -name "index.theme" 2>/dev/null | xargs -I {} dirname {}; done | sort -u`
    scanner.command = ["sh", "-c", cmd]
    scanner.running = true
  }

  // Apply icon theme to all supported applications
  function applyIconTheme(themeName) {
    if (!themeName) {
      Logger.w("IconThemeService", "No theme name provided")
      return false
    }

    Logger.i("IconThemeService", `Applying icon theme: ${themeName}`)

    // Update settings (auto-saves after 1 second)
    Settings.data.appearance.iconTheme = themeName

    // Apply to GTK 3
    applyGtk3IconTheme(themeName)

    // Apply to GTK 4
    applyGtk4IconTheme(themeName)

    // Apply to Qt5
    applyQt5IconTheme(themeName)

    // Apply to Qt6
    applyQt6IconTheme(themeName)

    // Apply via gsettings for GNOME/GTK apps
    applyGsettingsIconTheme(themeName)

    // Apply to Flatpak if enabled
    if (Settings.data.appearance.applyToFlatpak) {
      applyFlatpakIconTheme(themeName)
    }

    currentIconTheme = themeName
    Logger.i("IconThemeService", "Icon theme applied successfully")
    return true
  }

  // Apply icon theme to GTK 3
  function applyGtk3IconTheme(themeName) {
    let configDir = Quickshell.env("HOME") + "/.config/gtk-3.0"
    let configFile = configDir + "/settings.ini"

    // Ensure directory exists
    Quickshell.execDetached(["mkdir", "-p", configDir])

    // Read existing config
    readAndUpdateConfig(configFile, "gtk-icon-theme-name", themeName, "[Settings]")
  }

  // Apply icon theme to GTK 4
  function applyGtk4IconTheme(themeName) {
    let configDir = Quickshell.env("HOME") + "/.config/gtk-4.0"
    let configFile = configDir + "/settings.ini"

    // Ensure directory exists
    Quickshell.execDetached(["mkdir", "-p", configDir])

    // Read existing config
    readAndUpdateConfig(configFile, "gtk-icon-theme-name", themeName, "[Settings]")
  }

  // Apply icon theme to Qt5
  function applyQt5IconTheme(themeName) {
    let configDir = Quickshell.env("HOME") + "/.config/qt5ct"
    let configFile = configDir + "/qt5ct.conf"

    // Ensure directory exists
    Quickshell.execDetached(["mkdir", "-p", configDir])

    // Read existing config
    readAndUpdateConfig(configFile, "icon_theme", themeName, "[Appearance]")
  }

  // Apply icon theme to Qt6
  function applyQt6IconTheme(themeName) {
    let configDir = Quickshell.env("HOME") + "/.config/qt6ct"
    let configFile = configDir + "/qt6ct.conf"

    // Ensure directory exists
    Quickshell.execDetached(["mkdir", "-p", configDir])

    // Read existing config
    readAndUpdateConfig(configFile, "icon_theme", themeName, "[Appearance]")
  }

  // Apply icon theme via gsettings
  function applyGsettingsIconTheme(themeName) {
    Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", themeName])
  }

  // Apply icon theme to Flatpak apps
  function applyFlatpakIconTheme(themeName) {
    // Override for all Flatpak apps
    Quickshell.execDetached(["flatpak", "override", "--user", `--filesystem=~/.local/share/icons:ro`])
    Quickshell.execDetached(["flatpak", "override", "--user", `--filesystem=/usr/share/icons:ro`])
  }

  // Helper to read config file and update a setting
  function readAndUpdateConfig(filePath, key, value, section) {
    fileReader.callback = function(content) {
      // Update or add setting
      // Handle empty content (file doesn't exist or is empty)
      let lines = content && content.trim() !== "" ? content.split("\n") : []
      let updated = false
      let inSection = false

      for (let i = 0; i < lines.length; i++) {
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
        if (!inSection && lines.length > 0) {
          // Add section if it doesn't exist
          lines.unshift(section)
        }
        // Find section and add after it
        for (let i = 0; i < lines.length; i++) {
          if (lines[i].trim() === section) {
            lines.splice(i + 1, 0, `${key}=${value}`)
            break
          }
        }
      }

      // Write back
      writeFile(filePath, lines.join("\n"))
    }

    // Use 'cat' with error suppression - if file doesn't exist, callback gets empty string
    fileReader.command = ["sh", "-c", `cat "${filePath}" 2>/dev/null || true`]
    fileReader.running = true
  }

  // Helper to write file
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
}
