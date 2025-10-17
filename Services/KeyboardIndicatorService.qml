pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services

Singleton {
  id: root

  // Keyboard LED states
  property bool capsLockEnabled: false
  property bool numLockEnabled: false
  property bool scrollLockEnabled: false

  // Detection method being used
  property string detectionMethod: "unknown" // "xset", "sysfs", "evtest", "unknown"
  property bool isAvailable: false

  property int updateInterval: 500 // Update every 500ms

  // Signals for state changes
  signal capsLockChanged(bool enabled)
  signal numLockChanged(bool enabled)
  signal scrollLockChanged(bool enabled)

  Component.onCompleted: {
    Logger.i("KeyboardIndicator", "Service started")
    detectMethod()
    updateStates()
  }

  // Timer to periodically update keyboard states
  Timer {
    id: updateTimer
    interval: root.updateInterval
    running: root.isAvailable
    repeat: true
    onTriggered: updateStates()
  }

  // Detect which method to use for keyboard state detection
  function detectMethod() {
    // Try X11 first (xset)
    if (tryDetectXset()) {
      detectionMethod = "xset"
      isAvailable = true
      Logger.i("KeyboardIndicator", "Using xset for keyboard LED detection")
      return
    }

    // Try sysfs LED interface
    if (tryDetectSysfs()) {
      detectionMethod = "sysfs"
      isAvailable = true
      Logger.i("KeyboardIndicator", "Using sysfs for keyboard LED detection")
      return
    }

    Logger.w("KeyboardIndicator", "No suitable detection method found")
    isAvailable = false
  }

  // Try to detect if xset is available
  function tryDetectXset() {
    try {
      // Check if xset is available
      xsetProcess.running = true
      return true
    } catch (e) {
      Logger.d("KeyboardIndicator", "xset not available:", e)
      return false
    }
  }

  // Try to detect if sysfs LED interface is available
  function tryDetectSysfs() {
    try {
      // Check if /sys/class/leds exists
      sysfsCheckProcess.running = true
      return true
    } catch (e) {
      Logger.d("KeyboardIndicator", "sysfs LED interface not available:", e)
      return false
    }
  }

  // Update keyboard states based on detection method
  function updateStates() {
    if (!isAvailable) return

    if (detectionMethod === "xset") {
      xsetProcess.running = true
    } else if (detectionMethod === "sysfs") {
      updateSysfsStates()
    }
  }

  // Process for checking xset availability
  Process {
    id: xsetProcess
    running: false
    command: ["xset", "q"]
    stdout: StdioCollector {
      onStreamFinished: {
        parseXsetOutput(text)
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0 && detectionMethod === "unknown") {
        // xset failed, try next method
        tryDetectSysfs()
      }
    }
  }

  // Parse xset output to extract LED states
  function parseXsetOutput(output) {
    try {
      const lines = output.split('\n')
      for (const line of lines) {
        // Look for LED mask line like: "LED mask:  00000002"
        // Or the more descriptive: "Caps Lock:   off    Num Lock:    on     Scroll Lock: off"
        if (line.includes("Caps Lock")) {
          const capsMatch = line.match(/Caps Lock:\s*(\w+)/)
          const numMatch = line.match(/Num Lock:\s*(\w+)/)
          const scrollMatch = line.match(/Scroll Lock:\s*(\w+)/)

          if (capsMatch) updateCapsLock(capsMatch[1].toLowerCase() === "on")
          if (numMatch) updateNumLock(numMatch[1].toLowerCase() === "on")
          if (scrollMatch) updateScrollLock(scrollMatch[1].toLowerCase() === "on")
          return
        } else if (line.includes("LED mask")) {
          // Parse hex LED mask (bit 0 = Scroll Lock, bit 1 = Num Lock, bit 2 = Caps Lock)
          const match = line.match(/LED mask:\s*([0-9a-fA-F]+)/)
          if (match) {
            const mask = parseInt(match[1], 16)
            updateScrollLock((mask & 0x01) !== 0)
            updateNumLock((mask & 0x02) !== 0)
            updateCapsLock((mask & 0x04) !== 0)
            return
          }
        }
      }
    } catch (e) {
      Logger.e("KeyboardIndicator", "Error parsing xset output:", e)
    }
  }

  // Process for checking sysfs LED directory
  Process {
    id: sysfsCheckProcess
    running: false
    command: ["test", "-d", "/sys/class/leds"]
    onExited: function(exitCode) {
      if (exitCode === 0) {
        // Directory exists, sysfs is available
        Logger.d("KeyboardIndicator", "sysfs LED interface found")
      } else if (detectionMethod === "unknown") {
        // sysfs not available
        Logger.w("KeyboardIndicator", "No keyboard LED detection method available")
        isAvailable = false
      }
    }
  }

  // Update states from sysfs
  function updateSysfsStates() {
    // Read individual LED files
    sysfsReadCapsLock.running = true
    sysfsReadNumLock.running = true
    sysfsReadScrollLock.running = true
  }

  // Sysfs process for Caps Lock
  Process {
    id: sysfsReadCapsLock
    running: false
    command: ["cat", "/sys/class/leds/input0::capslock/brightness"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const brightness = parseInt(text.trim())
          updateCapsLock(brightness > 0)
        } catch (e) {
          // LED file might not exist for this keyboard
        }
      }
    }
  }

  // Sysfs process for Num Lock
  Process {
    id: sysfsReadNumLock
    running: false
    command: ["cat", "/sys/class/leds/input0::numlock/brightness"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const brightness = parseInt(text.trim())
          updateNumLock(brightness > 0)
        } catch (e) {
          // LED file might not exist for this keyboard
        }
      }
    }
  }

  // Sysfs process for Scroll Lock
  Process {
    id: sysfsReadScrollLock
    running: false
    command: ["cat", "/sys/class/leds/input0::scrolllock/brightness"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const brightness = parseInt(text.trim())
          updateScrollLock(brightness > 0)
        } catch (e) {
          // LED file might not exist for this keyboard
        }
      }
    }
  }

  // Update functions that emit signals on change
  function updateCapsLock(enabled) {
    if (capsLockEnabled !== enabled) {
      capsLockEnabled = enabled
      capsLockChanged(enabled)
      Logger.d("KeyboardIndicator", "Caps Lock:", enabled ? "ON" : "OFF")
    }
  }

  function updateNumLock(enabled) {
    if (numLockEnabled !== enabled) {
      numLockEnabled = enabled
      numLockChanged(enabled)
      Logger.d("KeyboardIndicator", "Num Lock:", enabled ? "ON" : "OFF")
    }
  }

  function updateScrollLock(enabled) {
    if (scrollLockEnabled !== enabled) {
      scrollLockEnabled = enabled
      scrollLockChanged(enabled)
      Logger.d("KeyboardIndicator", "Scroll Lock:", enabled ? "ON" : "OFF")
    }
  }

  // Toggle functions (require xdotool or similar)
  function toggleCapsLock() {
    if (!ProgramCheckerService.xdotoolAvailable) {
      Logger.w("KeyboardIndicator", "xdotool not available for toggling Caps Lock")
      ToastService.showWarning(
        I18n.tr("keyboardIndicator.title"),
        I18n.tr("keyboardIndicator.xdotool-required")
      )
      return false
    }
    toggleProcess.command = ["xdotool", "key", "Caps_Lock"]
    toggleProcess.running = true
    return true
  }

  function toggleNumLock() {
    if (!ProgramCheckerService.xdotoolAvailable) {
      Logger.w("KeyboardIndicator", "xdotool not available for toggling Num Lock")
      ToastService.showWarning(
        I18n.tr("keyboardIndicator.title"),
        I18n.tr("keyboardIndicator.xdotool-required")
      )
      return false
    }
    toggleProcess.command = ["xdotool", "key", "Num_Lock"]
    toggleProcess.running = true
    return true
  }

  function toggleScrollLock() {
    if (!ProgramCheckerService.xdotoolAvailable) {
      Logger.w("KeyboardIndicator", "xdotool not available for toggling Scroll Lock")
      ToastService.showWarning(
        I18n.tr("keyboardIndicator.title"),
        I18n.tr("keyboardIndicator.xdotool-required")
      )
      return false
    }
    toggleProcess.command = ["xdotool", "key", "Scroll_Lock"]
    toggleProcess.running = true
    return true
  }

  // Process for toggling keys
  Process {
    id: toggleProcess
    running: false
    onExited: function(exitCode) {
      if (exitCode === 0) {
        // Force an immediate update after toggle
        Qt.callLater(updateStates)
      } else {
        Logger.w("KeyboardIndicator", "Failed to toggle key, exit code:", exitCode)
      }
    }
  }
}
