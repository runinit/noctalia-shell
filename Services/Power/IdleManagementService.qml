pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower
import qs.Commons
import qs.Services.UI
import qs.Services.Compositor
import qs.Services.Hardware
import qs.Services.Power

Singleton {
  id: root

  // ===== Properties =====
  property bool enabled: Settings.data.idleManagement.enabled
  property bool respectKeepAwake: Settings.data.idleManagement.respectKeepAwake
  property bool onAcPower: true
  property bool isLaptop: false

  // Current mode configuration
  property var currentMode: onAcPower
    ? Settings.data.idleManagement.acMode
    : Settings.data.idleManagement.batteryMode

  // State tracking
  property var originalBrightnesses: ({})  // Store per-monitor brightness by screen name
  property bool isDimmed: false
  property bool isScreenOff: false
  property bool isLocked: false
  property var lastWakeTime: null
  property var lastActivityTime: Date.now()

  // Inhibitor tracking
  property bool inhibitorCheckRunning: false

  // ===== Service Initialization =====
  function init() {
    Logger.i("IdleManagement", "Service started")
    Logger.i("IdleManagement", "Enabled:", enabled)

    // Detect if we're on a laptop
    detectLaptop()

    // Detect initial power state
    updatePowerMode()

    // Log current configuration
    logConfiguration()
  }

  // ===== Power Mode Detection =====
  function detectLaptop() {
    const battery = UPower.displayDevice
    isLaptop = battery && battery.ready && battery.isLaptopBattery && battery.isPresent
    Logger.d("IdleManagement", "Laptop detected:", isLaptop)
  }

  function updatePowerMode() {
    if (!isLaptop) {
      onAcPower = true
      return
    }

    const battery = UPower.displayDevice
    if (battery && battery.ready) {
      const wasOnAc = onAcPower
      onAcPower = battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged

      if (wasOnAc !== onAcPower) {
        Logger.i("IdleManagement", "Power mode changed:", onAcPower ? "AC" : "Battery")
        logConfiguration()

        // Reset all idle states when mode changes
        resetAllMonitors()
      }
    }
  }

  // Monitor UPower for power state changes
  Connections {
    target: isLaptop && UPower.displayDevice ? UPower.displayDevice : null
    function onStateChanged() {
      updatePowerMode()
    }
  }

  // ===== Idle Monitors =====

  // Dim brightness monitor
  IdleMonitor {
    id: dimMonitor
    enabled: root.enabled && currentMode.dimTimeout > 0 && !isScreenOff
      && !(respectKeepAwake && IdleInhibitorService.isInhibited)
    timeout: currentMode.dimTimeout
    respectInhibitors: true

    onIsIdleChanged: {
      if (isIdle) {
        handleDim()
      } else {
        handleUndim()
      }
    }
  }

  // Screen off (DPMS) monitor
  IdleMonitor {
    id: dpmsMonitor
    enabled: root.enabled && currentMode.screenOffTimeout > 0
      && !(respectKeepAwake && IdleInhibitorService.isInhibited)
    timeout: currentMode.screenOffTimeout
    respectInhibitors: true

    onIsIdleChanged: {
      if (isIdle) {
        handleScreenOff()
      } else {
        handleScreenOn()
      }
    }
  }

  // Lock screen monitor
  IdleMonitor {
    id: lockMonitor
    enabled: root.enabled && currentMode.lockTimeout > 0
      && !(respectKeepAwake && IdleInhibitorService.isInhibited)
    timeout: currentMode.lockTimeout
    respectInhibitors: true

    onIsIdleChanged: {
      if (isIdle) {
        handleLock()
      } else {
        // Note: We don't auto-unlock
        lastWakeTime = Date.now()
      }
    }
  }

  // Suspend monitor
  IdleMonitor {
    id: suspendMonitor
    enabled: root.enabled && currentMode.suspendTimeout > 0
      && !(respectKeepAwake && IdleInhibitorService.isInhibited)
    timeout: currentMode.suspendTimeout
    respectInhibitors: true

    onIsIdleChanged: {
      if (isIdle) {
        handleSuspend()
      } else {
        lastWakeTime = Date.now()
      }
    }
  }

  // ===== Action Handlers =====

  function handleDim() {
    if (isDimmed) return

    Logger.i("IdleManagement", "Dimming brightness")
    const targetBrightness = currentMode.dimBrightness / 100.0

    // Save current brightness for each monitor and dim them
    originalBrightnesses = {}
    BrightnessService.monitors.forEach((monitor) => {
      const monitorId = monitor.modelData.name
      originalBrightnesses[monitorId] = monitor.brightness
      Logger.d("IdleManagement", `Saving brightness for ${monitorId}: ${monitor.brightness}`)
      monitor.setBrightness(targetBrightness)
    })

    isDimmed = true
  }

  function handleUndim() {
    if (!isDimmed) return

    Logger.i("IdleManagement", "Restoring brightness")

    // Restore original brightness for each monitor
    BrightnessService.monitors.forEach((monitor) => {
      const monitorId = monitor.modelData.name
      const savedBrightness = originalBrightnesses[monitorId]
      if (savedBrightness !== undefined) {
        Logger.d("IdleManagement", `Restoring brightness for ${monitorId}: ${savedBrightness}`)
        monitor.setBrightness(savedBrightness)
      } else {
        Logger.w("IdleManagement", `No saved brightness for ${monitorId}, skipping`)
      }
    })

    isDimmed = false
  }

  function handleScreenOff() {
    if (isScreenOff) return

    // Check inhibitor apps before turning off screen
    if (hasInhibitorApps()) {
      checkInhibitorsAndRun(function() {
        doScreenOff()
      })
    } else {
      doScreenOff()
    }
  }

  function doScreenOff() {
    Logger.i("IdleManagement", "Turning off displays")
    turnOffDisplays()
    isScreenOff = true
  }

  function handleScreenOn() {
    if (!isScreenOff) return

    Logger.i("IdleManagement", "Turning on displays")
    turnOnDisplays()
    isScreenOff = false
    lastWakeTime = Date.now()

    // Also restore brightness if it was dimmed
    if (isDimmed) {
      handleUndim()
    }
  }

  function handleLock() {
    if (isLocked) return

    // Check inhibitor apps before locking
    if (hasInhibitorApps()) {
      checkInhibitorsAndRun(function() {
        doLock()
      })
    } else {
      doLock()
    }
  }

  function doLock() {
    Logger.i("IdleManagement", "Locking screen")

    // Remember if screen was off before locking
    const wasScreenOff = isScreenOff

    try {
      if (PanelService.lockScreen && !PanelService.lockScreen.active) {
        PanelService.lockScreen.active = true
        isLocked = true

        // If screen was off, turn it back off after lock screen renders
        if (wasScreenOff) {
          Logger.i("IdleManagement", "Screen was off before lock, re-applying DPMS")
          postLockDpmsTimer.start()
        }
      }
    } catch (e) {
      Logger.e("IdleManagement", "Failed to lock screen:", e)
    }
  }

  function handleSuspend() {
    // Check debounce
    if (!shouldSuspend()) {
      Logger.i("IdleManagement", "Suspend blocked by debounce (recently woke up)")
      return
    }

    // Check inhibitor apps before suspending
    if (hasInhibitorApps()) {
      checkInhibitorsAndRun(function() {
        doSuspend()
      })
    } else {
      doSuspend()
    }
  }

  function doSuspend() {
    Logger.i("IdleManagement", "Suspending system")

    // Lock screen first if not already locked
    if (Settings.data.general.lockOnSuspend && !isLocked) {
      CompositorService.lockAndSuspend()
    } else {
      CompositorService.suspend()
    }
  }

  // ===== Debounce Logic =====
  function shouldSuspend() {
    if (!lastWakeTime) return true

    const elapsed = (Date.now() - lastWakeTime) / 1000
    const debounce = Settings.data.idleManagement.debounceSeconds

    return elapsed >= debounce
  }

  // ===== Inhibitor Apps Checking =====

  // SECURITY: Validate process names to prevent command injection (VULN-002)
  function isValidProcessName(name) {
    if (!name || typeof name !== 'string') return false

    // Process names should only contain alphanumeric, dash, underscore, dot
    const validPattern = /^[a-zA-Z0-9._-]+$/

    // Limit length to prevent abuse
    if (name.length > 255) {
      Logger.w("IdleManagement", "Process name too long (>255 chars), rejected:", name.substring(0, 50) + "...")
      return false
    }

    // Check pattern
    if (!validPattern.test(name)) {
      Logger.w("IdleManagement", "Invalid process name rejected (invalid characters):", name)
      return false
    }

    return true
  }

  function hasInhibitorApps() {
    const apps = Settings.data.idleManagement.inhibitApps
    return apps && apps.length > 0
  }

  function checkInhibitorsAndRun(callback) {
    if (inhibitorCheckRunning) {
      Logger.d("IdleManagement", "Inhibitor check already running")
      return
    }

    inhibitorCheckRunning = true
    inhibitorCheckProcess.callback = callback

    // SECURITY: Validate and filter app names (VULN-002)
    const apps = Settings.data.idleManagement.inhibitApps
    const validatedApps = apps.filter(app => isValidProcessName(app))

    if (validatedApps.length === 0) {
      Logger.d("IdleManagement", "No valid inhibitor apps configured")
      inhibitorCheckRunning = false
      if (callback) callback()
      return
    }

    // SECURITY: Pass apps as separate arguments instead of comma-joined string
    inhibitorCheckProcess.command = [
      "bash",
      Quickshell.shellDir + "/Bin/idle-management/check-inhibitors.sh",
      ...validatedApps  // Spread as separate arguments
    ]

    Logger.d("IdleManagement", "Checking for inhibitor apps:", validatedApps.join(", "))
    inhibitorCheckProcess.running = true
  }

  Process {
    id: inhibitorCheckProcess
    property var callback: null

    running: false
    command: []  // Will be set dynamically in checkInhibitorsAndRun()

    onExited: function(exitCode, exitStatus) {
      root.inhibitorCheckRunning = false

      if (exitCode === 0) {
        // At least one inhibitor app is running
        Logger.i("IdleManagement", "Action blocked by running inhibitor app")
      } else {
        // No inhibitor apps running, proceed with action
        Logger.d("IdleManagement", "No inhibitor apps running, proceeding")
        if (callback) {
          callback()
        }
      }

      callback = null
    }
  }

  // Timer to re-apply DPMS after lock screen shows
  Timer {
    id: postLockDpmsTimer
    interval: 100  // 100ms delay to let lock screen render
    repeat: false

    onTriggered: {
      if (isLocked && isScreenOff) {
        Logger.d("IdleManagement", "Re-applying DPMS after lock")
        turnOffDisplays()
      }
    }
  }

  // ===== DPMS Control =====
  function turnOffDisplays() {
    const compositor = CompositorService.compositor

    switch (compositor) {
      case "hyprland":
        Quickshell.execDetached(["hyprctl", "dispatch", "dpms", "off"])
        break
      case "sway":
        Quickshell.execDetached(["swaymsg", "output * dpms off"])
        break
      case "niri":
        Quickshell.execDetached(["niri", "msg", "action", "power-off-monitors"])
        break
      default:
        Logger.w("IdleManagement", "DPMS not supported for compositor:", compositor)
        // Fallback: try to use BrightnessService to set brightness to 0
        if (BrightnessService && BrightnessService.monitors.length > 0) {
          originalBrightnesses = {}
          BrightnessService.monitors.forEach((monitor) => {
            const monitorId = monitor.modelData.name
            originalBrightnesses[monitorId] = monitor.brightness
            Logger.d("IdleManagement", `Fallback: Saving brightness for ${monitorId}: ${monitor.brightness}`)
            monitor.setBrightness(0)
          })
        }
        break
    }
  }

  function turnOnDisplays() {
    const compositor = CompositorService.compositor

    switch (compositor) {
      case "hyprland":
        Quickshell.execDetached(["hyprctl", "dispatch", "dpms", "on"])
        break
      case "sway":
        Quickshell.execDetached(["swaymsg", "output * dpms on"])
        break
      case "niri":
        // Niri doesn't have a direct "power on" command, activity should wake it
        Logger.d("IdleManagement", "Niri monitors should wake on activity")
        break
      default:
        Logger.w("IdleManagement", "DPMS not supported for compositor:", compositor)
        // Fallback: restore brightness
        if (BrightnessService && BrightnessService.monitors.length > 0) {
          BrightnessService.monitors.forEach((monitor) => {
            const monitorId = monitor.modelData.name
            const savedBrightness = originalBrightnesses[monitorId]
            if (savedBrightness !== undefined && savedBrightness > 0) {
              Logger.d("IdleManagement", `Fallback: Restoring brightness for ${monitorId}: ${savedBrightness}`)
              monitor.setBrightness(savedBrightness)
            } else {
              Logger.w("IdleManagement", `Fallback: No saved brightness for ${monitorId}`)
            }
          })
        }
        break
    }
  }

  // ===== Utility Functions =====
  function resetAllMonitors() {
    // Reset all state
    isDimmed = false
    isScreenOff = false
    // Note: We don't reset isLocked as that should be done manually
    lastWakeTime = Date.now()

    // Restore screen if it was off
    if (isScreenOff) {
      turnOnDisplays()
    }

    // Restore brightness if it was dimmed
    if (isDimmed) {
      handleUndim()
    }
  }

  function logConfiguration() {
    const mode = onAcPower ? "AC" : "Battery"
    Logger.i("IdleManagement", `Configuration (${mode} mode):`)
    Logger.i("IdleManagement", "  Dim timeout:", currentMode.dimTimeout, "sec (" + currentMode.dimBrightness + "% brightness)")
    Logger.i("IdleManagement", "  Screen off timeout:", currentMode.screenOffTimeout, "sec")
    Logger.i("IdleManagement", "  Lock timeout:", currentMode.lockTimeout, "sec")
    Logger.i("IdleManagement", "  Suspend timeout:", currentMode.suspendTimeout, "sec")
    Logger.i("IdleManagement", "  Debounce:", Settings.data.idleManagement.debounceSeconds, "sec")

    if (hasInhibitorApps()) {
      Logger.i("IdleManagement", "  Inhibitor apps:", Settings.data.idleManagement.inhibitApps.join(", "))
    }
  }

  // ===== Settings Change Handlers =====
  Connections {
    target: Settings.data.idleManagement

    function onEnabledChanged() {
      Logger.i("IdleManagement", "Service enabled:", Settings.data.idleManagement.enabled)
      if (!enabled) {
        resetAllMonitors()
      }
    }
  }

  Connections {
    target: Settings.data.idleManagement.acMode
    function onDimTimeoutChanged() { if (onAcPower) logConfiguration() }
    function onScreenOffTimeoutChanged() { if (onAcPower) logConfiguration() }
    function onLockTimeoutChanged() { if (onAcPower) logConfiguration() }
    function onSuspendTimeoutChanged() { if (onAcPower) logConfiguration() }
  }

  Connections {
    target: Settings.data.idleManagement.batteryMode
    function onDimTimeoutChanged() { if (!onAcPower) logConfiguration() }
    function onScreenOffTimeoutChanged() { if (!onAcPower) logConfiguration() }
    function onLockTimeoutChanged() { if (!onAcPower) logConfiguration() }
    function onSuspendTimeoutChanged() { if (!onAcPower) logConfiguration() }
  }

  // ===== Lock Screen State Tracking =====
  Connections {
    target: PanelService.lockScreen
    function onActiveChanged() {
      isLocked = PanelService.lockScreen.active
      if (!isLocked) {
        // Screen was unlocked, reset wake time
        lastWakeTime = Date.now()
      }
    }
  }

  // ===== Keep Awake State Tracking =====
  Connections {
    target: IdleInhibitorService
    function onIsInhibitedChanged() {
      if (respectKeepAwake) {
        Logger.i("IdleManagement", "Keep Awake state changed:", IdleInhibitorService.isInhibited ? "Inhibited" : "Active")
        if (!IdleInhibitorService.isInhibited) {
          // Keep Awake was disabled, reset monitors
          resetAllMonitors()
        }
      }
    }
  }

  // ===== Monitor Configuration Change Handling =====
  Connections {
    target: BrightnessService
    function onMonitorsChanged() {
      Logger.i("IdleManagement", "Monitor configuration changed, resetting state")
      handleMonitorConfigurationChange()
    }
  }

  function handleMonitorConfigurationChange() {
    const currentMonitorCount = BrightnessService.monitors.length
    Logger.i("IdleManagement", "Monitor configuration changed - new count:", currentMonitorCount)

    // Reset state to known-good if monitors changed while in modified state
    if (isDimmed) {
      Logger.w("IdleManagement", "Monitors changed while dimmed, clearing brightness data")
      originalBrightnesses = {}
      isDimmed = false
    }

    if (isScreenOff) {
      Logger.w("IdleManagement", "Monitors changed while screen off, resetting screen state")
      isScreenOff = false
    }

    // Note: Don't reset isLocked - lock screen should persist across monitor changes
    // User must unlock manually

    Logger.d("IdleManagement", "Monitor configuration change handled successfully")
  }
}
