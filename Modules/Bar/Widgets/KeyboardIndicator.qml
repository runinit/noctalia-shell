import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.Bar.Extras

Item {
  id: root

  property ShellScreen screen

  // Widget properties passed from Bar.qml for per-instance settings
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId]
  property var widgetSettings: {
    if (section && sectionWidgetIndex >= 0) {
      var widgets = Settings.data.bar.widgets[section]
      if (widgets && sectionWidgetIndex < widgets.length) {
        return widgets[sectionWidgetIndex]
      }
    }
    return {}
  }

  readonly property string displayMode: (widgetSettings.displayMode !== undefined) ? widgetSettings.displayMode : widgetMetadata.displayMode

  // Get the list of active indicators
  readonly property var activeIndicators: {
    var indicators = []
    if (KeyboardIndicatorService.capsLockEnabled) indicators.push("CAPS")
    if (KeyboardIndicatorService.numLockEnabled) indicators.push("NUM")
    if (KeyboardIndicatorService.scrollLockEnabled) indicators.push("SCROLL")
    return indicators
  }

  readonly property string indicatorText: activeIndicators.join(" ")
  readonly property bool hasActiveIndicators: activeIndicators.length > 0

  // Show widget only when there are active indicators (unless forced)
  visible: hasActiveIndicators || displayMode === "forceOpen"
  implicitWidth: visible ? pill.width : 0
  implicitHeight: visible ? Style.barHeight : 0

  BarPill {
    id: pill

    anchors.verticalCenter: parent.verticalCenter
    compact: Settings.data.bar.density === "compact"
    rightOpen: BarService.getPillDirection(root)
    icon: "keyboard"
    autoHide: false
    text: indicatorText
    tooltipText: {
      if (!KeyboardIndicatorService.isAvailable) {
        return I18n.tr("keyboardIndicator.unavailable")
      }
      var active = []
      if (KeyboardIndicatorService.capsLockEnabled) {
        active.push(I18n.tr("keyboardIndicator.capsLock"))
      }
      if (KeyboardIndicatorService.numLockEnabled) {
        active.push(I18n.tr("keyboardIndicator.numLock"))
      }
      if (KeyboardIndicatorService.scrollLockEnabled) {
        active.push(I18n.tr("keyboardIndicator.scrollLock"))
      }

      if (active.length === 0) {
        return I18n.tr("keyboardIndicator.none-active")
      }

      return I18n.tr("keyboardIndicator.active") + ": " + active.join(", ")
    }
    forceOpen: root.displayMode === "forceOpen"
    forceClose: root.displayMode === "alwaysHide"

    onClicked: {
      // Could open a panel or control center here
      // For now, we'll just do nothing - users can toggle via control center
    }
  }

  // Color indicator based on state (optional visual enhancement)
  Behavior on opacity {
    NumberAnimation {
      duration: Style.animationFast
      easing.type: Easing.InOutQuad
    }
  }
}
