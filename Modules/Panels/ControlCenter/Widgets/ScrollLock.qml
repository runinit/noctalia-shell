import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

NIconButtonHot {
  property ShellScreen screen

  enabled: KeyboardIndicatorService.isAvailable
  icon: "scroll-lock"
  hot: KeyboardIndicatorService.scrollLockEnabled
  tooltipText: KeyboardIndicatorService.isAvailable
    ? I18n.tr("quickSettings.scrollLock.tooltip.action")
    : I18n.tr("quickSettings.scrollLock.tooltip.unavailable")

  onClicked: {
    if (KeyboardIndicatorService.toggleScrollLock()) {
      // Toggle successful - state will update via service
      const newState = !KeyboardIndicatorService.scrollLockEnabled
      ToastService.showNotice(
        I18n.tr("keyboardIndicator.scrollLock"),
        newState
          ? I18n.tr("toast.scrollLock.enabled")
          : I18n.tr("toast.scrollLock.disabled")
      )
    }
  }
}
