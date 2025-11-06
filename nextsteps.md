# Next Steps: Fix Process Creation in Theme Services

## Current Status

The theming feature implementation is **95% complete**. All architecture, UI, and settings are in place, but the service files have broken Process instantiation code.

### What's Working ✅
- `Commons/Settings.qml` - appearance section added with all properties
- `Modules/Settings/Tabs/GeneralTab.qml` - Complete UI for icon/GTK/Qt theme selection
- `shell.qml` - Service initialization configured
- Overall architecture and design is solid

### What's Broken ❌
- `Services/IconThemeService.qml` - Uses non-existent `Process.createTemporary()`
- `Services/GtkThemeService.qml` - Uses non-existent `Process.createTemporary()`
- `Services/QtStyleService.qml` - Uses non-existent `Process.createTemporary()`
- `Services/FontService.qml` - Uses non-existent `Process.createTemporary()` in helper functions

## The Problem

**Quickshell has NO synchronous process execution.** All Process execution is asynchronous.

The services currently try to use `Process.createTemporary({...})` which doesn't exist in Quickshell's API.

## Research Findings: Proper Quickshell Process Patterns

### Pattern 1: Static Process Declaration (Most Common in Codebase)
```qml
Process {
    id: myProcess
    running: false

    stdout: StdioCollector {
        onStreamFinished: {
            var result = text.trim()
            // Handle result
        }
    }
}

// Later, trigger execution:
myProcess.command = ["some-command", "arg"]
myProcess.running = true
```

**Examples in codebase:**
- BrightnessService.qml (lines 88-94, 97-122, 158-184)
- NiriService.qml (lines 50-96, 99-143)
- ClipboardService.qml (lines 58-77, 100-152)

### Pattern 2: Qt.createQmlObject for Dynamic Creation
```qml
var processString = `
    import QtQuick
    import Quickshell.Io
    Process {
        command: ["find", "` + directory + `", "-type", "f"]
        stdout: StdioCollector {}
    }
`
var proc = Qt.createQmlObject(processString, root, "UniqueName")

// Store reference to prevent GC
this.myProcess = proc

// Connect signals
proc.exited.connect(function(exitCode) {
    // Handle completion
    proc.destroy()
})

proc.running = true
```

**Example in codebase:**
- WallpaperService.qml (lines 420-468)

### Pattern 3: Quickshell.execDetached (Fire-and-Forget)
```qml
// For commands where you don't need output
Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", themeName])
Quickshell.execDetached(["mkdir", "-p", configDir])
```

**Examples in codebase:**
- BrightnessService.qml (lines 321, 324, 327)
- NiriService.qml (lines 397, 405, 412, 421)
- ClipboardService.qml (lines 319, 329)

## Recommended Solution

### Option A: Quickshell.execDetached (SIMPLEST) ⭐ **RECOMMENDED**

Since most operations don't actually need to capture output, use `Quickshell.execDetached()` for everything:

**Benefits:**
- Simplest to implement
- No async complexity
- Follows existing codebase patterns
- Works for: mkdir, gsettings, flatpak override, file writes (via shell redirection)

**Operations that need it:**
- File scanning (find commands) - Only needs output
- File reading (cat) - Only needs output
- File writing - Can use shell redirection: `sh -c "cat > file"` with stdin

**Example transformations:**
```javascript
// OLD (broken):
let proc = Process.createTemporary({
    running: true,
    command: ["mkdir", "-p", configDir]
})
proc.waitForExit()
proc.destroy()

// NEW (working):
Quickshell.execDetached(["mkdir", "-p", configDir])
```

```javascript
// OLD (broken):
let proc = Process.createTemporary({
    running: true,
    command: ["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", themeName]
})
proc.waitForExit()
proc.destroy()

// NEW (working):
Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", themeName])
```

**For file reading/writing that NEED output:**
```qml
// Declare static Process at service level
Process {
    id: fileReader
    running: false
    property var callback: null

    stdout: StdioCollector {
        onStreamFinished: {
            if (callback) {
                callback(text)
                callback = null
            }
        }
    }
}

// Use with callback
function readFile(filePath, callback) {
    fileReader.callback = callback
    fileReader.command = ["cat", filePath]
    fileReader.running = true
}

// Call it
readFile("/path/to/file", function(content) {
    // Use content
})
```

### Option B: Static Process Pool with Callbacks

Add reusable Process objects at service root:

```qml
Process {
    id: commandRunner
    running: false
    property var callback: null

    stdout: StdioCollector {
        onStreamFinished: {
            if (callback) {
                callback({
                    exitCode: commandRunner.exitCode,
                    stdout: text,
                    stderr: ""
                })
                callback = null
            }
        }
    }

    onExited: (code) => {
        if (callback && !stdout.collector) {
            callback({exitCode: code, stdout: "", stderr: ""})
            callback = null
        }
    }
}

function execCommand(cmd, cb) {
    commandRunner.callback = cb
    commandRunner.command = cmd
    commandRunner.running = true
}
```

**Then refactor all functions to use callbacks:**
```javascript
// OLD synchronous style (broken):
function applyIconTheme(themeName) {
    applyGtk3IconTheme(themeName)
    applyGtk4IconTheme(themeName)
    applyQt5IconTheme(themeName)
    Logger.i("Done")
}

// NEW async style (working):
function applyIconTheme(themeName) {
    applyGtk3IconTheme(themeName, function() {
        applyGtk4IconTheme(themeName, function() {
            applyQt5IconTheme(themeName, function() {
                Logger.i("Done")
            })
        })
    })
}
```

## Implementation Steps

### Step 1: Fix IconThemeService.qml
1. Replace all `Process.createTemporary` with `Quickshell.execDetached`
2. For scanDirectory (needs output), add static Process with callback
3. For readFile/writeFile helpers, use static Process or shell redirection

### Step 2: Fix GtkThemeService.qml
1. Same approach as IconThemeService
2. Fix scanDirectory, checkFileExists
3. Fix all apply functions

### Step 3: Fix QtStyleService.qml
1. Same approach as above
2. Fix scanPluginDirectory
3. Fix all apply functions

### Step 4: Fix FontService.qml
1. Fix runCommand, readFile, writeFile helpers
2. Use Quickshell.execDetached for commands that don't need output

### Step 5: Test
```bash
cd /home/chris/src/noctalia-shell
timeout 10 qs -p .
```

Look for:
- No "TypeError: Property 'createTemporary' of object" errors
- Services initialize successfully
- Settings panel opens without errors

## Files Needing Changes

1. **Services/IconThemeService.qml** (~400 lines)
   - Functions to fix: scanDirectory, applyGtk3/4IconTheme, applyQt5/6IconTheme, applyGsettings, applyFlatpak, readFile, writeFile

2. **Services/GtkThemeService.qml** (~420 lines)
   - Functions to fix: scanDirectory, checkFileExists, applyGtk3/4Theme, applyGsettings, applyFlatpak, readFile, writeFile

3. **Services/QtStyleService.qml** (~340 lines)
   - Functions to fix: scanPluginDirectory, applyQt5/6Style, setEnvironmentVariables, readFile, writeFile

4. **Services/FontService.qml** (~530 lines)
   - Functions to fix: runCommand, readFile, writeFile

## Key Principles

1. **Quickshell Process execution is ALWAYS asynchronous** - no blocking/synchronous API exists
2. **Use Quickshell.execDetached()** when you don't need output (most cases)
3. **Use static Process + callbacks** when you need output
4. **Use Qt.createQmlObject()** only for highly dynamic scenarios
5. **Always store Process references** to prevent garbage collection
6. **Connect to exited signal** for cleanup

## Additional Notes

- The UI is already complete and ready
- Settings persistence works
- The only issue is Process instantiation in the service layer
- Once fixed, users can immediately select themes from Settings → General
- Auto-dark/light theme switching will work
- Flatpak integration will work if enabled

## Alternative: Delete and Recreate

If fixing is too complex, could also:
1. Delete the three broken service files
2. Recreate them from scratch using proper Quickshell patterns from the start
3. Use existing services as templates (BrightnessService, NiriService)

This might be faster than fixing 30+ broken Process calls across 4 files.
