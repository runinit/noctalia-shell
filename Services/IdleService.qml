pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services

Singleton {
  id: root

  // Monitor instances (created dynamically in init)
  property var monitorOffMonitor: null
  property var lockMonitor: null
  property var suspendMonitor: null
  property var hibernateMonitor: null

  // Power state detection
  readonly property bool isOnBattery: (BatteryService.batteryAvailable || false) && !(BatteryService.isPluggedIn || false)

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

  function init() {
    try {
      Logger.d("IdleService", "Idle service initializing...")

      // Create monitors dynamically after Settings is guaranteed to be loaded
      createMonitors()
      logConfiguration()

      Logger.d("IdleService", "Idle service started successfully")
    } catch (e) {
      Logger.e("IdleService", "Failed to initialize:", e, e.stack)
    }
  }

  function createMonitors() {
    Logger.d("IdleService", "Creating monitors - monitorTimeout: " + monitorTimeout + "s, lockTimeout: " + lockTimeout + "s")

    // Monitor off monitor
    if (monitorTimeout > 0) {
      Logger.d("IdleService", "Creating monitor off monitor with timeout: " + monitorTimeout + "s")
      monitorOffMonitor = Qt.createQmlObject(`
        import Quickshell.Wayland
        IdleMonitor {
          enabled: true
          respectInhibitors: ${respectInhibitors}
          timeout: ${monitorTimeout}
        }
      `, root, "monitorOffMonitor")

      monitorOffMonitor.isIdleChanged.connect(() => {
        if (monitorOffMonitor.isIdle) {
          Logger.d("IdleService", "Monitor off triggered (idle for " + monitorOffMonitor.timeout + "s)")
          requestMonitorOff()
        }
      })
    } else {
      Logger.d("IdleService", "Skipping monitor off monitor (timeout is 0)")
    }

    // Lock monitor
    if (lockTimeout > 0) {
      Logger.d("IdleService", "Creating lock monitor with timeout: " + lockTimeout + "s")
      lockMonitor = Qt.createQmlObject(`
        import Quickshell.Wayland
        IdleMonitor {
          enabled: true
          respectInhibitors: ${respectInhibitors}
          timeout: ${lockTimeout}
        }
      `, root, "lockMonitor")

      lockMonitor.isIdleChanged.connect(() => {
        if (lockMonitor.isIdle) {
          Logger.d("IdleService", "Lock triggered (idle for " + lockMonitor.timeout + "s)")
          requestLock()
        }
      })
    } else {
      Logger.d("IdleService", "Skipping lock monitor (timeout is 0)")
    }

    // Suspend monitor
    if (suspendTimeout > 0) {
      Logger.d("IdleService", "Creating suspend monitor with timeout: " + suspendTimeout + "s")
      suspendMonitor = Qt.createQmlObject(`
        import Quickshell.Wayland
        IdleMonitor {
          enabled: true
          respectInhibitors: ${respectInhibitors}
          timeout: ${suspendTimeout}
        }
      `, root, "suspendMonitor")

      suspendMonitor.isIdleChanged.connect(() => {
        if (suspendMonitor.isIdle) {
          Logger.d("IdleService", "Suspend triggered (idle for " + suspendMonitor.timeout + "s)")
          requestSuspend()
        }
      })
    } else {
      Logger.d("IdleService", "Skipping suspend monitor (timeout is 0)")
    }

    // Hibernate monitor
    if (hibernateTimeout > 0) {
      Logger.d("IdleService", "Creating hibernate monitor with timeout: " + hibernateTimeout + "s")
      hibernateMonitor = Qt.createQmlObject(`
        import Quickshell.Wayland
        IdleMonitor {
          enabled: true
          respectInhibitors: ${respectInhibitors}
          timeout: ${hibernateTimeout}
        }
      `, root, "hibernateMonitor")

      hibernateMonitor.isIdleChanged.connect(() => {
        if (hibernateMonitor.isIdle) {
          Logger.d("IdleService", "Hibernate triggered (idle for " + hibernateMonitor.timeout + "s)")
          requestHibernate()
        }
      })
    } else {
      Logger.d("IdleService", "Skipping hibernate monitor (timeout is 0)")
    }

    Logger.d("IdleService", "Monitor creation complete")
  }

  function destroyMonitors() {
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
  }

  function logConfiguration() {
    const state = isOnBattery ? "battery" : "AC"
    Logger.d("IdleService", `Power state: ${state}`)
    Logger.d("IdleService", `Monitor timeout: ${monitorTimeout}s (enabled: ${monitorOffMonitor !== null})`)
    Logger.d("IdleService", `Lock timeout: ${lockTimeout}s (enabled: ${lockMonitor !== null})`)
    Logger.d("IdleService", `Suspend timeout: ${suspendTimeout}s (enabled: ${suspendMonitor !== null})`)
    Logger.d("IdleService", `Hibernate timeout: ${hibernateTimeout}s (enabled: ${hibernateMonitor !== null})`)
    Logger.d("IdleService", `Respect inhibitors: ${respectInhibitors}`)
  }

  // Watch for power state changes - recreate monitors with new timeouts
  onIsOnBatteryChanged: {
    Logger.d("IdleService", `Power state changed to: ${isOnBattery ? "battery" : "AC"}`)
    destroyMonitors()
    createMonitors()
    logConfiguration()
  }

  // Watch for timeout changes in settings - recreate monitors
  onMonitorTimeoutChanged: {
    if (monitorOffMonitor !== null || monitorTimeout > 0) {
      Logger.d("IdleService", "Monitor timeout changed, recreating monitors")
      destroyMonitors()
      createMonitors()
    }
  }

  onLockTimeoutChanged: {
    if (lockMonitor !== null || lockTimeout > 0) {
      Logger.d("IdleService", "Lock timeout changed, recreating monitors")
      destroyMonitors()
      createMonitors()
    }
  }

  onSuspendTimeoutChanged: {
    if (suspendMonitor !== null || suspendTimeout > 0) {
      Logger.d("IdleService", "Suspend timeout changed, recreating monitors")
      destroyMonitors()
      createMonitors()
    }
  }

  onHibernateTimeoutChanged: {
    if (hibernateMonitor !== null || hibernateTimeout > 0) {
      Logger.d("IdleService", "Hibernate timeout changed, recreating monitors")
      destroyMonitors()
      createMonitors()
    }
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

    // Use noctalia's built-in lock screen
    if (typeof PanelService !== 'undefined' && PanelService.lockScreen) {
      if (!PanelService.lockScreen.active) {
        PanelService.lockScreen.active = true
      }
    } else {
      Logger.w("IdleService", "PanelService.lockScreen not available, falling back to SessionService")
      if (typeof SessionService !== 'undefined') {
        SessionService.lock()
      }
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
