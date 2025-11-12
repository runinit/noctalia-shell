import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Power
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root

  spacing: Style.marginL

  // ===== Header & Master Toggle =====
  NHeader {
    label: I18n.tr("settings.idle-management.section.label")
    description: I18n.tr("settings.idle-management.section.description")
  }

  NToggle {
    label: I18n.tr("settings.idle-management.enabled.label")
    description: I18n.tr("settings.idle-management.enabled.description")
    checked: Settings.data.idleManagement.enabled
    onToggled: checked => Settings.data.idleManagement.enabled = checked
  }

  NToggle {
    label: I18n.tr("settings.idle-management.respect-keep-awake.label")
    description: I18n.tr("settings.idle-management.respect-keep-awake.description")
    checked: Settings.data.idleManagement.respectKeepAwake
    onToggled: checked => Settings.data.idleManagement.respectKeepAwake = checked
    visible: Settings.data.idleManagement.enabled
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginL
    Layout.bottomMargin: Style.marginL
    visible: Settings.data.idleManagement.enabled
  }

  // ===== Configuration Sections (visible when enabled) =====
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginL
    visible: Settings.data.idleManagement.enabled

    // ===== AC Power Mode =====
    NCollapsible {
      Layout.fillWidth: true
      label: I18n.tr("settings.idle-management.ac-mode.label")
      description: I18n.tr("settings.idle-management.ac-mode.description")
      defaultExpanded: true

      ColumnLayout {
        spacing: Style.marginM

        // Dim Brightness Timeout
        NSpinBox {
          Layout.fillWidth: true
          label: I18n.tr("settings.idle-management.dim-timeout.label")
          description: I18n.tr("settings.idle-management.dim-timeout.description") + " " + I18n.tr("settings.idle-management.zero-disables")
          minimum: 0
          maximum: 120
          value: Settings.data.idleManagement.acMode.dimTimeout / 60
          stepSize: 1
          suffix: " min"
          onValueChanged: Settings.data.idleManagement.acMode.dimTimeout = value * 60
        }

        // Dim Brightness Level
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginL
          visible: Settings.data.idleManagement.acMode.dimTimeout > 0

          NText {
            text: I18n.tr("settings.idle-management.dim-brightness.label")
            Layout.preferredWidth: 120
            Layout.alignment: Qt.AlignVCenter
          }

          NValueSlider {
            id: acDimBrightnessSlider
            from: 5
            to: 100
            value: Settings.data.idleManagement.acMode.dimBrightness
            stepSize: 5
            text: Math.round(value) + "%"
            onMoved: value => Settings.data.idleManagement.acMode.dimBrightness = value
            Layout.fillWidth: true
          }
        }

        // Screen Off Timeout
        NSpinBox {
          Layout.fillWidth: true
          label: I18n.tr("settings.idle-management.screen-off-timeout.label")
          description: I18n.tr("settings.idle-management.screen-off-timeout.description")
          minimum: 0
          maximum: 120
          value: Settings.data.idleManagement.acMode.screenOffTimeout / 60
          stepSize: 1
          suffix: " min"
          onValueChanged: Settings.data.idleManagement.acMode.screenOffTimeout = value * 60
        }

        // Lock Timeout
        NSpinBox {
          Layout.fillWidth: true
          label: I18n.tr("settings.idle-management.lock-timeout.label")
          description: I18n.tr("settings.idle-management.lock-timeout.description")
          minimum: 0
          maximum: 120
          value: Settings.data.idleManagement.acMode.lockTimeout / 60
          stepSize: 1
          suffix: " min"
          onValueChanged: Settings.data.idleManagement.acMode.lockTimeout = value * 60
        }

        // Suspend Timeout
        NSpinBox {
          Layout.fillWidth: true
          label: I18n.tr("settings.idle-management.suspend-timeout.label")
          description: I18n.tr("settings.idle-management.suspend-timeout.description")
          minimum: 0
          maximum: 240
          value: Settings.data.idleManagement.acMode.suspendTimeout / 60
          stepSize: 1
          suffix: " min"
          onValueChanged: Settings.data.idleManagement.acMode.suspendTimeout = value * 60
        }
      }
    }

    // ===== Battery Power Mode =====
    NCollapsible {
      Layout.fillWidth: true
      label: I18n.tr("settings.idle-management.battery-mode.label")
      description: I18n.tr("settings.idle-management.battery-mode.description")
      defaultExpanded: false

      ColumnLayout {
        spacing: Style.marginM

        // Dim Brightness Timeout
        NSpinBox {
          Layout.fillWidth: true
          label: I18n.tr("settings.idle-management.dim-timeout.label")
          description: I18n.tr("settings.idle-management.dim-timeout.description")
          minimum: 0
          maximum: 120
          value: Settings.data.idleManagement.batteryMode.dimTimeout / 60
          stepSize: 1
          suffix: " min"
          onValueChanged: Settings.data.idleManagement.batteryMode.dimTimeout = value * 60
        }

        // Dim Brightness Level
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginL
          visible: Settings.data.idleManagement.batteryMode.dimTimeout > 0

          NText {
            text: I18n.tr("settings.idle-management.dim-brightness.label")
            Layout.preferredWidth: 120
            Layout.alignment: Qt.AlignVCenter
          }

          NValueSlider {
            id: batteryDimBrightnessSlider
            from: 5
            to: 100
            value: Settings.data.idleManagement.batteryMode.dimBrightness
            stepSize: 5
            text: Math.round(value) + "%"
            onMoved: value => Settings.data.idleManagement.batteryMode.dimBrightness = value
            Layout.fillWidth: true
          }
        }

        // Screen Off Timeout
        NSpinBox {
          Layout.fillWidth: true
          label: I18n.tr("settings.idle-management.screen-off-timeout.label")
          description: I18n.tr("settings.idle-management.screen-off-timeout.description")
          minimum: 0
          maximum: 120
          value: Settings.data.idleManagement.batteryMode.screenOffTimeout / 60
          stepSize: 1
          suffix: " min"
          onValueChanged: Settings.data.idleManagement.batteryMode.screenOffTimeout = value * 60
        }

        // Lock Timeout
        NSpinBox {
          Layout.fillWidth: true
          label: I18n.tr("settings.idle-management.lock-timeout.label")
          description: I18n.tr("settings.idle-management.lock-timeout.description")
          minimum: 0
          maximum: 120
          value: Settings.data.idleManagement.batteryMode.lockTimeout / 60
          stepSize: 1
          suffix: " min"
          onValueChanged: Settings.data.idleManagement.batteryMode.lockTimeout = value * 60
        }

        // Suspend Timeout
        NSpinBox {
          Layout.fillWidth: true
          label: I18n.tr("settings.idle-management.suspend-timeout.label")
          description: I18n.tr("settings.idle-management.suspend-timeout.description")
          minimum: 0
          maximum: 240
          value: Settings.data.idleManagement.batteryMode.suspendTimeout / 60
          stepSize: 1
          suffix: " min"
          onValueChanged: Settings.data.idleManagement.batteryMode.suspendTimeout = value * 60
        }
      }
    }

    NDivider {
      Layout.fillWidth: true
      Layout.topMargin: Style.marginL
      Layout.bottomMargin: Style.marginL
    }

    // ===== Advanced Settings =====
    NHeader {
      label: I18n.tr("settings.idle-management.advanced.label")
      description: I18n.tr("settings.idle-management.advanced.description")
    }

    // Debounce Duration
    NSpinBox {
      Layout.fillWidth: true
      label: I18n.tr("settings.idle-management.debounce.label")
      description: I18n.tr("settings.idle-management.debounce.description")
      minimum: 0
      maximum: 60
      value: Settings.data.idleManagement.debounceSeconds
      stepSize: 1
      suffix: " sec"
      onValueChanged: Settings.data.idleManagement.debounceSeconds = value
    }

    // Inhibitor Apps Section
    NLabel {
      label: I18n.tr("settings.idle-management.inhibitor-apps.label")
      description: I18n.tr("settings.idle-management.inhibitor-apps.description")
    }

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: inhibitorAppsColumn.implicitHeight + Style.marginL * 2
      radius: Style.radiusM
      color: Color.mSurfaceVariant
      border.color: Color.mOutline
      border.width: Style.borderS

      ColumnLayout {
        id: inhibitorAppsColumn
        width: parent.width - 2 * Style.marginL
        x: Style.marginL
        y: Style.marginL
        spacing: Style.marginS

        // List of current inhibitor apps
        Repeater {
          model: Settings.data.idleManagement.inhibitApps

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            NText {
              text: modelData
              Layout.fillWidth: true
            }

            NIconButton {
              icon: "trash"
              onClicked: {
                var apps = Settings.data.idleManagement.inhibitApps.slice()
                apps.splice(index, 1)
                Settings.data.idleManagement.inhibitApps = apps
              }
              tooltipText: I18n.tr("settings.idle-management.inhibitor-apps.remove")
            }
          }
        }

        // Add new app
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginM

          NTextInput {
            id: newAppInput
            Layout.fillWidth: true
            placeholderText: I18n.tr("settings.idle-management.inhibitor-apps.placeholder")
            onEditingFinished: {
              if (text.trim().length > 0) {
                var apps = Settings.data.idleManagement.inhibitApps.slice()
                if (!apps.includes(text.trim())) {
                  apps.push(text.trim())
                  Settings.data.idleManagement.inhibitApps = apps
                  text = ""
                }
              }
            }
          }

          NIconButton {
            icon: "plus"
            enabled: newAppInput.text.trim().length > 0
            onClicked: {
              if (newAppInput.text.trim().length > 0) {
                var apps = Settings.data.idleManagement.inhibitApps.slice()
                if (!apps.includes(newAppInput.text.trim())) {
                  apps.push(newAppInput.text.trim())
                  Settings.data.idleManagement.inhibitApps = apps
                  newAppInput.text = ""
                }
              }
            }
            tooltipText: I18n.tr("settings.idle-management.inhibitor-apps.add")
          }
        }

        // Hint text
        NText {
          text: I18n.tr("settings.idle-management.inhibitor-apps.hint")
          wrapMode: Text.WordWrap
          Layout.fillWidth: true
          opacity: 0.7
          font.pointSize: Style.fontSizeXS
        }
      }
    }

    // Current Status Display (for debugging/feedback)
    Rectangle {
      Layout.fillWidth: true
      implicitHeight: statusColumn.implicitHeight + Style.marginL * 2
      radius: Style.radiusM
      color: Color.mSurfaceContainerLowest
      border.color: Color.mOutline
      border.width: Style.borderS
      visible: Settings.isDebug

      ColumnLayout {
        id: statusColumn
        width: parent.width - 2 * Style.marginL
        x: Style.marginL
        y: Style.marginL
        spacing: Style.marginXS

        NText {
          text: "Status (Debug)"
          font.weight: Font.DemiBold
          color: Color.mPrimary
        }

        NText {
          text: "Power Mode: " + (IdleManagementService.onAcPower ? "AC" : "Battery")
          font.pointSize: Style.fontSizeS
        }

        NText {
          text: "Laptop: " + (IdleManagementService.isLaptop ? "Yes" : "No")
          font.pointSize: Style.fontSizeS
        }

        NText {
          text: "Screen Dimmed: " + (IdleManagementService.isDimmed ? "Yes" : "No")
          font.pointSize: Style.fontSizeS
        }

        NText {
          text: "Screen Off: " + (IdleManagementService.isScreenOff ? "Yes" : "No")
          font.pointSize: Style.fontSizeS
        }

        NText {
          text: "Locked: " + (IdleManagementService.isLocked ? "Yes" : "No")
          font.pointSize: Style.fontSizeS
        }
      }
    }
  }

  // Spacer at the end
  Item {
    Layout.fillHeight: true
  }
}
