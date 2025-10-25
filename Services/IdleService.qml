pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services

Singleton {
  id: root

  // Monitor instances (created dynamically to allow re-arming)
  property var monitorOffMonitor: null
  property var lockMonitor: null
  property var suspendMonitor: null
  property var hibernateMonitor: null

  // Enable gate - used to force re-creation when timeouts change
  property bool _enableGate: true

  // Power state detection
  readonly property bool isOnBattery: BatteryService.batteryAvailable && !BatteryService.isPluggedIn

  // Dynamic timeout selection based on power state
  readonly property int monitorTimeout: {
    if (!Settings.data.power) return 0
    return isOnBattery ?
      (Settings.data.power.batteryMonitorTimeout || 0) :
      (Settings.data.power.acMonitorTimeout || 0)
  }

  readonly property int lockTimeout: {
    if (!Settings.data.power) return 0
    return isOnBattery ?
      (Settings.data.power.batteryLockTimeout || 0) :
      (Settings.data.power.acLockTimeout || 0)
  }

  readonly property int suspendTimeout: {
    if (!Settings.data.power) return 0
    return isOnBattery ?
      (Settings.data.power.batterySuspendTimeout || 0) :
      (Settings.data.power.acSuspendTimeout || 0)
  }

  readonly property int hibernateTimeout: {
    if (!Settings.data.power) return 0
    return isOnBattery ?
      (Settings.data.power.batteryHibernateTimeout || 0) :
      (Settings.data.power.acHibernateTimeout || 0)
  }

  readonly property bool respectInhibitors: Settings.data.power ? (Settings.data.power.respectInhibitors !== false) : true
  readonly property bool lockBeforeSuspend: Settings.data.power ? (Settings.data.power.lockBeforeSuspend !== false) : true

  Component.onCompleted: {
    createMonitors()
  }

  function init() {
    Logger.d("IdleService", "Service started")
    logConfiguration()
  }

  function logConfiguration() {
    const state = isOnBattery ? "battery" : "AC"
    Logger.d("IdleService", `Power state: ${state}`)
    Logger.d("IdleService", `Monitor timeout: ${monitorTimeout}s`)
    Logger.d("IdleService", `Lock timeout: ${lockTimeout}s`)
    Logger.d("IdleService", `Suspend timeout: ${suspendTimeout}s`)
    Logger.d("IdleService", `Hibernate timeout: ${hibernateTimeout}s`)
    Logger.d("IdleService", `Respect inhibitors: ${respectInhibitors}`)
  }

  // Create all idle monitors
  function createMonitors() {
    Logger.d("IdleService", "Creating idle monitors")

    // Clean up existing monitors
    if (monitorOffMonitor) {
      monitorOffMonitor.destroy()
      monitorOffMonitor = null
    }
    if (lockMonitor) {
      lockMonitor.destroy()
      lockMonitor = null
    }
    if (suspendMonitor) {
      suspendMonitor.destroy()
      suspendMonitor = null
    }
    if (hibernateMonitor) {
      hibernateMonitor.destroy()
      hibernateMonitor = null
    }

    // Create monitors dynamically
    try {
      monitorOffMonitor = createIdleMonitor("MonitorOff", monitorTimeout, requestMonitorOff)
      lockMonitor = createIdleMonitor("Lock", lockTimeout, requestLock)
      suspendMonitor = createIdleMonitor("Suspend", suspendTimeout, requestSuspend)
      hibernateMonitor = createIdleMonitor("Hibernate", hibernateTimeout, requestHibernate)

      Logger.d("IdleService", "Idle monitors created successfully")
    } catch (e) {
      Logger.e("IdleService", "Failed to create idle monitors:", e)
    }
  }

  // Create a single idle monitor
  function createIdleMonitor(name, timeout, callback) {
    const qmlString = `
      import QtQuick
      import Quickshell.Wayland

      IdleMonitor {
        id: monitor
        enabled: false
        respectInhibitors: ${respectInhibitors}
        timeout: 0

        onIsIdleChanged: {
          if (isIdle) {
            // Callback will be connected externally
          }
        }
      }
    `

    const monitor = Qt.createQmlObject(qmlString, root, `IdleService.${name}Monitor`)

    // Connect callback
    monitor.isIdleChanged.connect(() => {
      if (monitor.isIdle) {
        Logger.d("IdleService", `${name} monitor triggered (idle for ${monitor.timeout}s)`)
        callback()
      }
    })

    // Configure monitor
    updateMonitor(monitor, timeout)

    return monitor
  }

  // Update a monitor's configuration
  function updateMonitor(monitor, timeout) {
    if (!monitor) return

    // Disable monitor if timeout is 0 (Never)
    if (timeout === 0) {
      monitor.enabled = false
      monitor.timeout = 0
      return
    }

    // Update timeout and enable
    monitor.timeout = timeout
    monitor.enabled = _enableGate
  }

  // Re-arm monitors when settings change
  function rearmMonitors() {
    Logger.d("IdleService", "Re-arming monitors due to settings change")

    // Toggle enable gate to force re-arm
    _enableGate = false
    Qt.callLater(() => {
      _enableGate = true

      // Update each monitor
      updateMonitor(monitorOffMonitor, monitorTimeout)
      updateMonitor(lockMonitor, lockTimeout)
      updateMonitor(suspendMonitor, suspendTimeout)
      updateMonitor(hibernateMonitor, hibernateTimeout)

      logConfiguration()
    })
  }

  // Watch for timeout changes
  onMonitorTimeoutChanged: rearmMonitors()
  onLockTimeoutChanged: rearmMonitors()
  onSuspendTimeoutChanged: rearmMonitors()
  onHibernateTimeoutChanged: rearmMonitors()
  onIsOnBatteryChanged: {
    Logger.d("IdleService", `Power state changed to: ${isOnBattery ? "battery" : "AC"}`)
    rearmMonitors()
  }

  // Action handlers
  function requestMonitorOff() {
    Logger.d("IdleService", "Turning off monitors")

    if (typeof CompositorService !== 'undefined' && CompositorService.powerOffMonitors) {
      CompositorService.powerOffMonitors()
    } else {
      Logger.w("IdleService", "CompositorService.powerOffMonitors not available")
    }
  }

  function requestLock() {
    Logger.d("IdleService", "Locking session")

    if (typeof SessionService !== 'undefined') {
      SessionService.lock()
    } else {
      Logger.w("IdleService", "SessionService not available")
    }
  }

  function requestSuspend() {
    Logger.d("IdleService", "Suspending system")

    if (typeof SessionService !== 'undefined') {
      SessionService.suspend(lockBeforeSuspend)
    } else {
      Logger.w("IdleService", "SessionService not available")
    }
  }

  function requestHibernate() {
    Logger.d("IdleService", "Hibernating system")

    if (typeof SessionService !== 'undefined') {
      SessionService.hibernate(lockBeforeSuspend)
    } else {
      Logger.w("IdleService", "SessionService not available")
    }
  }
}
