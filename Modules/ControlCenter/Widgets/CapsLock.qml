import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

NIconButtonHot {
  property ShellScreen screen

  enabled: KeyboardIndicatorService.isAvailable
  icon: "caps-lock"
  hot: KeyboardIndicatorService.capsLockEnabled
  tooltipText: KeyboardIndicatorService.isAvailable
    ? I18n.tr("quickSettings.capsLock.tooltip.action")
    : I18n.tr("quickSettings.capsLock.tooltip.unavailable")

  onClicked: {
    if (KeyboardIndicatorService.toggleCapsLock()) {
      // Toggle successful - state will update via service
      const newState = !KeyboardIndicatorService.capsLockEnabled
      ToastService.showNotice(
        I18n.tr("keyboardIndicator.capsLock"),
        newState
          ? I18n.tr("toast.capsLock.enabled")
          : I18n.tr("toast.capsLock.disabled")
      )
    }
  }
}
