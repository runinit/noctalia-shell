import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services

ColumnLayout {
  id: root
  spacing: Style.marginM

  // Properties to receive data from parent
  property var widgetData: null
  property var widgetMetadata: null

  // Local state
  property string valueIcon: widgetData.icon !== undefined ? widgetData.icon : (widgetMetadata.icon || "view-app-grid")
  property string valueIconMode: widgetData.iconMode !== undefined ? widgetData.iconMode : "apps"
  property string valueCustomIconPath: widgetData.customIconPath !== undefined ? widgetData.customIconPath : ""

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {})
    settings.icon = valueIcon
    settings.iconMode = valueIconMode
    settings.customIconPath = valueCustomIconPath
    return settings
  }

  NLabel {
    label: I18n.tr("bar.widget-settings.app-menu.icon-mode.label")
    description: I18n.tr("bar.widget-settings.app-menu.icon-mode.description")
  }

  // Icon mode selection
  RowLayout {
    spacing: Style.marginM

    NButton {
      text: I18n.tr("bar.widget-settings.app-menu.icon-mode.apps")
      highlighted: valueIconMode === "apps"
      onClicked: {
        valueIconMode = "apps"
        valueIcon = "view-app-grid"
        valueCustomIconPath = ""
      }
    }

    NButton {
      text: I18n.tr("bar.widget-settings.app-menu.icon-mode.distro")
      highlighted: valueIconMode === "distro"
      onClicked: {
        valueIconMode = "distro"
        valueCustomIconPath = ""
      }
    }

    NButton {
      text: I18n.tr("bar.widget-settings.app-menu.icon-mode.custom")
      highlighted: valueIconMode === "custom"
      onClicked: {
        valueIconMode = "custom"
      }
    }
  }

  // Icon preview
  RowLayout {
    spacing: Style.marginM
    visible: valueIconMode !== "apps" || valueIcon !== "view-app-grid"

    NLabel {
      label: I18n.tr("bar.widget-settings.app-menu.icon-preview.label")
    }

    NImageCircled {
      Layout.preferredWidth: Style.fontSizeXL * 2
      Layout.preferredHeight: Style.fontSizeXL * 2
      Layout.alignment: Qt.AlignVCenter
      imagePath: valueCustomIconPath
      visible: valueCustomIconPath !== ""
    }

    NIcon {
      Layout.alignment: Qt.AlignVCenter
      icon: valueIcon
      pointSize: Style.fontSizeXXL * 1.5
      visible: valueIcon !== "" && valueCustomIconPath === "" && valueIconMode !== "distro"
    }

    IconImage {
      Layout.preferredWidth: Style.fontSizeXL * 2
      Layout.preferredHeight: Style.fontSizeXL * 2
      Layout.alignment: Qt.AlignVCenter
      source: DistroService.osLogo
      visible: valueIconMode === "distro"
      smooth: true
    }
  }

  // Icon selection buttons (for custom mode)
  RowLayout {
    spacing: Style.marginM
    visible: valueIconMode === "custom"

    NButton {
      text: I18n.tr("bar.widget-settings.app-menu.browse-library")
      onClicked: iconPicker.open()
    }

    NButton {
      text: I18n.tr("bar.widget-settings.app-menu.browse-file")
      onClicked: imagePicker.openFilePicker()
    }
  }

  // Reset button
  NButton {
    text: I18n.tr("bar.widget-settings.app-menu.reset-to-default")
    onClicked: {
      valueIconMode = "apps"
      valueIcon = "view-app-grid"
      valueCustomIconPath = ""
    }
  }

  NIconPicker {
    id: iconPicker
    initialIcon: valueIcon
    onIconSelected: iconName => {
      valueIcon = iconName
      valueCustomIconPath = ""
    }
  }

  NFilePicker {
    id: imagePicker
    title: I18n.tr("bar.widget-settings.app-menu.select-custom-icon")
    selectionMode: "files"
    nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.gif", "*.pnm", "*.bmp"]
    initialPath: Quickshell.env("HOME")
    onAccepted: paths => {
      if (paths.length > 0) {
        valueCustomIconPath = paths[0]
      }
    }
  }
}
