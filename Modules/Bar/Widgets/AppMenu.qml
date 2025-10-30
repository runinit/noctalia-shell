import QtQuick
import Quickshell
import Quickshell.Widgets
import QtQuick.Effects
import qs.Commons
import qs.Widgets
import qs.Services

NIconButton {
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

  readonly property string customIcon: widgetSettings.icon || widgetMetadata.icon || "applications-other"
  readonly property bool useDistroLogo: (widgetSettings.useDistroLogo !== undefined) ? widgetSettings.useDistroLogo : (widgetMetadata.useDistroLogo || false)
  readonly property string customIconPath: widgetSettings.customIconPath || ""

  // Icon mode: "icon", "distro", "text", "custom"
  readonly property string iconMode: widgetSettings.iconMode || "icon"

  // If we have text, distro logo, or custom path, don't use the theme icon.
  icon: {
    if (iconMode === "text") return ""
    if (iconMode === "custom" && customIconPath !== "") return ""
    if (iconMode === "distro") return ""
    return customIcon
  }

  tooltipText: I18n.tr("tooltips.open-app-menu")
  tooltipDirection: BarService.getTooltipDirection()
  baseSize: Style.capsuleHeight
  applyUiScale: false
  density: Settings.data.bar.density
  colorBg: (Settings.data.bar.showCapsule ? Color.mSurfaceVariant : Color.transparent)
  colorFg: Color.mOnSurface
  colorBgHover: Color.mPrimary
  colorBorder: Color.transparent
  colorBorderHover: Color.mPrimary

  onClicked: {
    const panel = PanelService.getPanel("appMenuPanel")
    if (panel) {
      panel.toggle(this)
    } else {
      Logger.w("AppMenu", "appMenuPanel not found")
    }
  }

  // Right click could open settings or compositor overview
  onRightClicked: {
    // Open compositor overview if available
    if (CompositorService.isHyprland) {
      try {
        Quickshell.execDetached(["hyprctl", "dispatch", "overview:toggle"])
      } catch (e) {
        Logger.w("AppMenu", "Failed to toggle Hyprland overview:", e)
      }
    } else if (CompositorService.isNiri) {
      try {
        Quickshell.execDetached(["niri", "msg", "action", "show-overview"])
      } catch (e) {
        Logger.w("AppMenu", "Failed to show Niri overview:", e)
      }
    }
  }

  // Text mode - show "Apps"
  NText {
    id: appsText
    anchors.centerIn: parent
    text: "Apps"
    visible: iconMode === "text"
    font.weight: Style.fontWeightMedium
    pointSize: Style.fontSizeS
    color: root.colorFg
  }

  // Custom icon or distro logo
  IconImage {
    id: customOrDistroLogo
    anchors.centerIn: parent
    width: root.width * 0.8
    height: width
    source: {
      if (iconMode === "custom" && customIconPath !== "") {
        return customIconPath.startsWith("file://") ? customIconPath : "file://" + customIconPath
      }
      if (iconMode === "distro") {
        return DistroService.osLogo
      }
      return ""
    }
    visible: source !== ""
    smooth: true
    asynchronous: true
  }

}
