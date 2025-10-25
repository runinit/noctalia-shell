pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services

Singleton {
  id: root

  // Session state
  property bool locked: false

  // Capability detection
  property bool canLock: true
  property bool canSuspend: false
  property bool canHibernate: false

  // Lock screen availability
  property bool hasLockScreen: false

  // Signals
  signal sessionLocked()
  signal sessionUnlocked()
  signal sessionSuspending()
  signal sessionHibernating()

  Component.onCompleted: {
    checkCapabilities()
    detectLockScreen()
  }

  function init() {
    Logger.d("SessionService", "Service started")
  }

  // Check system capabilities
  function checkCapabilities() {
    // Check if systemd-logind is available for suspend/hibernate
    try {
      const result = Quickshell.execDetached(["systemctl", "status"])
      canSuspend = true
      canHibernate = true
      Logger.d("SessionService", "systemd detected, suspend/hibernate available")
    } catch (e) {
      Logger.w("SessionService", "systemd not available, suspend/hibernate disabled")
    }
  }

  // Detect available lock screen command
  function detectLockScreen() {
    const lockCommands = [
      "hyprlock",
      "swaylock",
      "gtklock",
      "waylock"
    ]

    for (let i = 0; i < lockCommands.length; i++) {
      try {
        Quickshell.execDetached(["which", lockCommands[i]])
        hasLockScreen = true
        Logger.d("SessionService", `Lock screen found: ${lockCommands[i]}`)
        return
      } catch (e) {
        // Try next
      }
    }

    Logger.w("SessionService", "No lock screen command found")
  }

  // Lock the session
  function lock() {
    Logger.d("SessionService", "Locking session")

    // Try compositor-specific lock first
    if (CompositorService.isHyprland) {
      try {
        Quickshell.execDetached(["hyprlock"])
        locked = true
        sessionLocked()
        return true
      } catch (e) {
        Logger.w("SessionService", "hyprlock failed:", e)
      }
    } else if (CompositorService.isSway) {
      try {
        Quickshell.execDetached(["swaylock"])
        locked = true
        sessionLocked()
        return true
      } catch (e) {
        Logger.w("SessionService", "swaylock failed:", e)
      }
    }

    // Try generic lock screen commands
    const lockCommands = ["hyprlock", "swaylock", "gtklock", "waylock"]
    for (let i = 0; i < lockCommands.length; i++) {
      try {
        Quickshell.execDetached([lockCommands[i]])
        locked = true
        sessionLocked()
        return true
      } catch (e) {
        // Try next
      }
    }

    // Fallback to loginctl
    try {
      Quickshell.execDetached(["loginctl", "lock-session"])
      locked = true
      sessionLocked()
      return true
    } catch (e) {
      Logger.e("SessionService", "Failed to lock session:", e)
      return false
    }
  }

  // Unlock the session (called by lock screen)
  function unlock() {
    Logger.d("SessionService", "Session unlocked")
    locked = false
    sessionUnlocked()
  }

  // Suspend the system
  function suspend(lockFirst = false) {
    if (!canSuspend) {
      Logger.w("SessionService", "Suspend not available")
      return false
    }

    Logger.d("SessionService", "Suspending system", lockFirst ? "(locking first)" : "")

    if (lockFirst) {
      lock()
    }

    sessionSuspending()

    // Try compositor-specific suspend commands first
    if (CompositorService.isHyprland) {
      try {
        Quickshell.execDetached(["systemctl", "suspend"])
        return true
      } catch (e) {
        Logger.w("SessionService", "Hyprland suspend failed:", e)
      }
    }

    // Fallback to standard systemctl
    try {
      Quickshell.execDetached(["systemctl", "suspend"])
      return true
    } catch (e) {
      Logger.e("SessionService", "Failed to suspend:", e)
      return false
    }
  }

  // Hibernate the system
  function hibernate(lockFirst = false) {
    if (!canHibernate) {
      Logger.w("SessionService", "Hibernate not available")
      return false
    }

    Logger.d("SessionService", "Hibernating system", lockFirst ? "(locking first)" : "")

    if (lockFirst) {
      lock()
    }

    sessionHibernating()

    // Try systemctl
    try {
      Quickshell.execDetached(["systemctl", "hibernate"])
      return true
    } catch (e) {
      Logger.e("SessionService", "Failed to hibernate:", e)
      return false
    }
  }

  // Shutdown the system
  function shutdown() {
    Logger.d("SessionService", "Shutting down system")
    try {
      Quickshell.execDetached(["systemctl", "poweroff"])
      return true
    } catch (e) {
      Logger.e("SessionService", "Failed to shutdown:", e)
      return false
    }
  }

  // Reboot the system
  function reboot() {
    Logger.d("SessionService", "Rebooting system")
    try {
      Quickshell.execDetached(["systemctl", "reboot"])
      return true
    } catch (e) {
      Logger.e("SessionService", "Failed to reboot:", e)
      return false
    }
  }

  // Logout (compositor-specific)
  function logout() {
    Logger.d("SessionService", "Logging out")

    if (CompositorService.isHyprland) {
      try {
        Quickshell.execDetached(["hyprctl", "dispatch", "exit"])
        return true
      } catch (e) {
        Logger.e("SessionService", "Hyprland logout failed:", e)
      }
    } else if (CompositorService.isNiri) {
      try {
        Quickshell.execDetached(["niri", "msg", "action", "quit"])
        return true
      } catch (e) {
        Logger.e("SessionService", "Niri logout failed:", e)
      }
    } else if (CompositorService.isSway) {
      try {
        Quickshell.execDetached(["swaymsg", "exit"])
        return true
      } catch (e) {
        Logger.e("SessionService", "Sway logout failed:", e)
      }
    }

    // Generic fallback
    try {
      Quickshell.execDetached(["loginctl", "terminate-user", Quickshell.env("USER")])
      return true
    } catch (e) {
      Logger.e("SessionService", "Failed to logout:", e)
      return false
    }
  }
}
