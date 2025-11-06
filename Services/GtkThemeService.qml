pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Commons

Singleton {
  id: root

  // Available GTK themes
  property ListModel availableGtkThemes: ListModel {}

  // Current GTK theme
  property string currentGtkTheme: Settings.data.appearance ? Settings.data.appearance.gtkTheme : "Adwaita"

  // Scan paths for GTK themes
  readonly property var gtkThemePaths: [
    Quickshell.env("HOME") + "/.themes",
    Quickshell.env("HOME") + "/.local/share/themes",
    "/usr/share/themes",
    "/usr/local/share/themes"
  ]

  // Ready state
  property bool ready: false

  // Current dark mode state (from ColorSchemeService)
  property bool isDarkMode: false

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
    Logger.i("GtkThemeService", "Initializing GTK theme service...")
    scanGtkThemes()
    ready = true
    Logger.i("GtkThemeService", `Found ${availableGtkThemes.count} GTK themes`)
  }

  // Monitor dark mode changes if sync is enabled
  Connections {
    target: Settings.data.colorSchemes
    function onDarkModeChanged() {
      if (Settings.data.appearance.syncGtkThemeWithDarkMode) {
        isDarkMode = Settings.data.colorSchemes.darkMode
        autoSwitchThemeVariant()
      }
    }
  }

  // Scan system for available GTK themes
  function scanGtkThemes() {
    availableGtkThemes.clear()

    // Scan all paths in a single command, looking for actual GTK theme files
    let pathsStr = gtkThemePaths.join(" ")

    scanner.callback = function(output) {
      let foundThemes = new Map()

      if (output) {
        let themeFiles = output.trim().split("\n")
        for (let themeFile of themeFiles) {
          if (!themeFile) continue

          // Extract theme name from path
          // Path format: /path/to/themes/ThemeName/gtk-3.0/gtk.css
          let parts = themeFile.split("/")
          let themeIdx = -1

          // Find the theme name (directory before gtk-3.0 or gtk-4.0)
          for (let i = parts.length - 1; i >= 0; i--) {
            if (parts[i] === "gtk-3.0" || parts[i] === "gtk-4.0") {
              themeIdx = i - 1
              break
            }
          }

          if (themeIdx < 0) continue
          let themeName = parts[themeIdx]

          if (!themeName || themeName.startsWith(".")) continue

          // Get or create theme entry
          let themeInfo = foundThemes.get(themeName)
          if (!themeInfo) {
            themeInfo = {
              hasGtk3: false,
              hasGtk4: false,
              hasDark: false,
              hasLight: false
            }
            foundThemes.set(themeName, themeInfo)
          }

          // Update theme info based on file found
          if (themeFile.includes("/gtk-3.0/")) {
            themeInfo.hasGtk3 = true
            if (themeFile.includes("gtk-dark.css")) {
              themeInfo.hasDark = true
            } else if (themeFile.includes("gtk.css")) {
              themeInfo.hasLight = true
            }
          }
          if (themeFile.includes("/gtk-4.0/")) {
            themeInfo.hasGtk4 = true
            if (themeFile.includes("gtk-dark.css")) {
              themeInfo.hasDark = true
            } else if (themeFile.includes("gtk.css")) {
              themeInfo.hasLight = true
            }
          }

          // Also check theme name for dark/light hints
          if (themeName.toLowerCase().includes("dark")) {
            themeInfo.hasDark = true
          }
          if (themeName.toLowerCase().includes("light") || !themeName.toLowerCase().includes("dark")) {
            themeInfo.hasLight = true
          }
        }
      }

      // Populate model with sorted themes
      let themeArray = Array.from(foundThemes.entries()).sort((a, b) => a[0].localeCompare(b[0]))
      for (let [themeName, themeInfo] of themeArray) {
        availableGtkThemes.append({
          key: themeName,
          name: themeName,
          displayName: themeName.replace(/-/g, " ").replace(/_/g, " "),
          hasGtk3: themeInfo.hasGtk3,
          hasGtk4: themeInfo.hasGtk4,
          hasDarkVariant: themeInfo.hasDark,
          hasLightVariant: themeInfo.hasLight
        })
      }

      Logger.i("GtkThemeService", `Found ${availableGtkThemes.count} GTK themes after scan`)
    }

    // Find actual GTK CSS files to determine which themes are GTK themes
    scanner.command = ["sh", "-c", `for dir in ${pathsStr}; do [ -d "$dir" ] && find "$dir" -maxdepth 3 \\( -path "*/gtk-3.0/gtk.css" -o -path "*/gtk-3.0/gtk-dark.css" -o -path "*/gtk-4.0/gtk.css" -o -path "*/gtk-4.0/gtk-dark.css" \\) 2>/dev/null; done | sort -u`]
    scanner.running = true
  }

  // Apply GTK theme to all supported applications
  function applyGtkTheme(themeName) {
    if (!themeName) {
      Logger.w("GtkThemeService", "No theme name provided")
      return false
    }

    Logger.i("GtkThemeService", `Applying GTK theme: ${themeName}`)

    // Update settings (auto-saves after 1 second)
    Settings.data.appearance.gtkTheme = themeName

    // Apply to GTK 3
    applyGtk3Theme(themeName)

    // Apply to GTK 4
    applyGtk4Theme(themeName)

    // Apply via gsettings for GNOME/GTK apps
    applyGsettingsTheme(themeName)

    // Apply to Flatpak if enabled
    if (Settings.data.appearance.applyToFlatpak) {
      applyFlatpakTheme(themeName)
    }

    currentGtkTheme = themeName
    Logger.i("GtkThemeService", "GTK theme applied successfully")
    return true
  }

  // Auto-switch between light and dark theme variants
  function autoSwitchThemeVariant() {
    let baseName = currentGtkTheme.replace(/-dark$/i, "").replace(/-light$/i, "")
    let newTheme = ""

    if (isDarkMode) {
      // Try to find dark variant
      newTheme = findThemeVariant(baseName, "dark")
    } else {
      // Try to find light variant
      newTheme = findThemeVariant(baseName, "light")
    }

    if (newTheme && newTheme !== currentGtkTheme) {
      Logger.i("GtkThemeService", `Auto-switching theme to ${newTheme}`)
      applyGtkTheme(newTheme)
    }
  }

  // Find a theme variant (dark or light)
  function findThemeVariant(baseName, variant) {
    // Try common naming patterns
    let patterns = []
    if (variant === "dark") {
      patterns = [
        baseName + "-dark",
        baseName + "-Dark",
        baseName + "-DARK",
        baseName + "Dark"
      ]
    } else {
      patterns = [
        baseName + "-light",
        baseName + "-Light",
        baseName + "-LIGHT",
        baseName + "Light",
        baseName // Base theme is often the light variant
      ]
    }

    // Check if any pattern exists in available themes
    for (let pattern of patterns) {
      for (let i = 0; i < availableGtkThemes.count; i++) {
        let theme = availableGtkThemes.get(i)
        if (theme.name === pattern) {
          return pattern
        }
      }
    }

    return ""
  }

  // Apply GTK 3 theme
  function applyGtk3Theme(themeName) {
    let configDir = Quickshell.env("HOME") + "/.config/gtk-3.0"
    let configFile = configDir + "/settings.ini"

    // Ensure directory exists
    Quickshell.execDetached(["mkdir", "-p", configDir])

    // Read and update config
    readAndUpdateConfig(configFile, "gtk-theme-name", themeName, "[Settings]")
  }

  // Apply GTK 4 theme
  function applyGtk4Theme(themeName) {
    let configDir = Quickshell.env("HOME") + "/.config/gtk-4.0"
    let configFile = configDir + "/settings.ini"

    // Ensure directory exists
    Quickshell.execDetached(["mkdir", "-p", configDir])

    // Read and update config
    readAndUpdateConfig(configFile, "gtk-theme-name", themeName, "[Settings]")
  }

  // Apply theme via gsettings
  function applyGsettingsTheme(themeName) {
    Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", themeName])
  }

  // Apply theme to Flatpak apps
  function applyFlatpakTheme(themeName) {
    Quickshell.execDetached(["flatpak", "override", "--user", `--env=GTK_THEME=${themeName}`])
    Quickshell.execDetached(["flatpak", "override", "--user", `--filesystem=~/.themes:ro`])
    Quickshell.execDetached(["flatpak", "override", "--user", `--filesystem=/usr/share/themes:ro`])
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
        if (lines.length === 0 || !lines.some(l => l.trim() === section)) {
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
