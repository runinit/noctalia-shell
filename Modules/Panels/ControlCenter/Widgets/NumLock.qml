import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

NIconButtonHot {
  property ShellScreen screen

  enabled: KeyboardIndicatorService.isAvailable
  icon: "num-lock"
  hot: KeyboardIndicatorService.numLockEnabled
  tooltipText: KeyboardIndicatorService.isAvailable
    ? I18n.tr("quickSettings.numLock.tooltip.action")
    : I18n.tr("quickSettings.numLock.tooltip.unavailable")

  onClicked: {
    if (KeyboardIndicatorService.toggleNumLock()) {
      // Toggle successful - state will update via service
      const newState = !KeyboardIndicatorService.numLockEnabled
      ToastService.showNotice(
        I18n.tr("keyboardIndicator.numLock"),
        newState
          ? I18n.tr("toast.numLock.enabled")
          : I18n.tr("toast.numLock.disabled")
      )
    }
  }
}
