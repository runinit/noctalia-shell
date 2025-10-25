import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import qs.Services

ColumnLayout {
  id: root
  spacing: Style.marginM

  // Properties to receive data from parent
  property var widgetData: null
  property var widgetMetadata: null

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {})
    settings.labelMode = labelModeCombo.currentKey
    settings.hideUnoccupied = hideUnoccupiedToggle.checked
    settings.characterCount = characterCountSpinBox.value
    settings.showAllDisplays = showAllDisplaysToggle.checked
    return settings
  }

  NComboBox {
    id: labelModeCombo

    label: I18n.tr("bar.widget-settings.workspace.label-mode.label")
    description: I18n.tr("bar.widget-settings.workspace.label-mode.description")
    model: [{
        "key": "none",
        "name": I18n.tr("options.workspace-labels.none")
      }, {
        "key": "index",
        "name": I18n.tr("options.workspace-labels.index")
      }, {
        "key": "name",
        "name": I18n.tr("options.workspace-labels.name")
      }]
    currentKey: widgetData.labelMode || widgetMetadata.labelMode
    onSelected: key => labelModeCombo.currentKey = key
    minimumWidth: 200
  }

  NToggle {
    id: hideUnoccupiedToggle
    label: I18n.tr("bar.widget-settings.workspace.hide-unoccupied.label")
    description: I18n.tr("bar.widget-settings.workspace.hide-unoccupied.description")
    checked: widgetData.hideUnoccupied
    onToggled: checked => hideUnoccupiedToggle.checked = checked
  }

  NSpinBox {
    id: characterCountSpinBox
    label: I18n.tr("bar.widget-settings.workspace.character-count.label")
    description: I18n.tr("bar.widget-settings.workspace.character-count.description")
    from: 1
    to: 10
    value: {
      if (widgetData && widgetData.characterCount !== undefined) {
        return widgetData.characterCount
      }
      if (widgetMetadata && widgetMetadata.characterCount !== undefined) {
        return widgetMetadata.characterCount
      }
      return 2
    }
    visible: labelModeCombo.currentKey === "name"
  }

  NToggle {
    id: showAllDisplaysToggle
    label: I18n.tr("bar.widget-settings.workspace.show-all-displays.label")
    description: I18n.tr("bar.widget-settings.workspace.show-all-displays.description")
    checked: widgetData.showAllDisplays !== undefined ? widgetData.showAllDisplays : false
    onToggled: checked => showAllDisplaysToggle.checked = checked
  }
}
