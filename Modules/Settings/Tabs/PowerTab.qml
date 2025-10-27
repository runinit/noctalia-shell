import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets

 ColumnLayout {
  id: root
  spacing: Style.marginL

  // Helper function to format timeout values
  function formatTimeout(seconds) {
    if (seconds === 0) return I18n.tr("Never")
    if (seconds < 60) return seconds + "s"
    const minutes = Math.floor(seconds / 60)
    return minutes + " min"
  }

  // AC Power Section
  NHeader {
    label: I18n.tr("settings.power.ac.section.label")
    description: I18n.tr("settings.power.ac.section.description")
  }

  // Monitor timeout (AC)
  ColumnLayout {
    spacing: Style.marginS
    Layout.fillWidth: true

    NLabel {
      label: I18n.tr("settings.power.monitor-timeout.label")
      description: I18n.tr("settings.power.monitor-timeout.description")
    }

    NValueSlider {
      Layout.fillWidth: true
      from: 0
      to: 3600
      stepSize: 60
      value: Settings.data.power.acMonitorTimeout
      text: formatTimeout(value)
      onMoved: value => Settings.data.power.acMonitorTimeout = value
    }
  }

  // Lock timeout (AC)
  ColumnLayout {
    spacing: Style.marginS
    Layout.fillWidth: true

    NLabel {
      label: I18n.tr("settings.power.lock-timeout.label")
      description: I18n.tr("settings.power.lock-timeout.description")
    }

    NValueSlider {
      Layout.fillWidth: true
      from: 0
      to: 3600
      stepSize: 60
      value: Settings.data.power.acLockTimeout
      text: formatTimeout(value)
      onMoved: value => Settings.data.power.acLockTimeout = value
    }
  }

  // Suspend timeout (AC)
  ColumnLayout {
    spacing: Style.marginS
    Layout.fillWidth: true

    NLabel {
      label: I18n.tr("settings.power.suspend-timeout.label")
      description: I18n.tr("settings.power.suspend-timeout.description")
    }

    NValueSlider {
      Layout.fillWidth: true
      from: 0
      to: 7200
      stepSize: 300
      value: Settings.data.power.acSuspendTimeout
      text: formatTimeout(value)
      onMoved: value => Settings.data.power.acSuspendTimeout = value
    }
  }

  // Hibernate timeout (AC)
  ColumnLayout {
    spacing: Style.marginS
    Layout.fillWidth: true

    NLabel {
      label: I18n.tr("settings.power.hibernate-timeout.label")
      description: I18n.tr("settings.power.hibernate-timeout.description")
    }

    NValueSlider {
      Layout.fillWidth: true
      from: 0
      to: 14400
      stepSize: 600
      value: Settings.data.power.acHibernateTimeout
      text: formatTimeout(value)
      onMoved: value => Settings.data.power.acHibernateTimeout = value
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL
    Layout.bottomMargin: Style.marginXL
  }

  // Battery Power Section
  NHeader {
    label: I18n.tr("settings.power.battery.section.label")
    description: I18n.tr("settings.power.battery.section.description")
  }

  // Monitor timeout (Battery)
  ColumnLayout {
    spacing: Style.marginS
    Layout.fillWidth: true

    NLabel {
      label: I18n.tr("settings.power.monitor-timeout.label")
      description: I18n.tr("settings.power.monitor-timeout.description")
    }

    NValueSlider {
      Layout.fillWidth: true
      from: 0
      to: 1800
      stepSize: 60
      value: Settings.data.power.batteryMonitorTimeout
      text: formatTimeout(value)
      onMoved: value => Settings.data.power.batteryMonitorTimeout = value
    }
  }

  // Lock timeout (Battery)
  ColumnLayout {
    spacing: Style.marginS
    Layout.fillWidth: true

    NLabel {
      label: I18n.tr("settings.power.lock-timeout.label")
      description: I18n.tr("settings.power.lock-timeout.description")
    }

    NValueSlider {
      Layout.fillWidth: true
      from: 0
      to: 1800
      stepSize: 60
      value: Settings.data.power.batteryLockTimeout
      text: formatTimeout(value)
      onMoved: value => Settings.data.power.batteryLockTimeout = value
    }
  }

  // Suspend timeout (Battery)
  ColumnLayout {
    spacing: Style.marginS
    Layout.fillWidth: true

    NLabel {
      label: I18n.tr("settings.power.suspend-timeout.label")
      description: I18n.tr("settings.power.suspend-timeout.description")
    }

    NValueSlider {
      Layout.fillWidth: true
      from: 0
      to: 3600
      stepSize: 300
      value: Settings.data.power.batterySuspendTimeout
      text: formatTimeout(value)
      onMoved: value => Settings.data.power.batterySuspendTimeout = value
    }
  }

  // Hibernate timeout (Battery)
  ColumnLayout {
    spacing: Style.marginS
    Layout.fillWidth: true

    NLabel {
      label: I18n.tr("settings.power.hibernate-timeout.label")
      description: I18n.tr("settings.power.hibernate-timeout.description")
    }

    NValueSlider {
      Layout.fillWidth: true
      from: 0
      to: 7200
      stepSize: 600
      value: Settings.data.power.batteryHibernateTimeout
      text: formatTimeout(value)
      onMoved: value => Settings.data.power.batteryHibernateTimeout = value
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL
    Layout.bottomMargin: Style.marginXL
  }

  // Options Section
  NHeader {
    label: I18n.tr("settings.power.options.section.label")
    description: I18n.tr("settings.power.options.section.description")
  }

  NToggle {
    label: I18n.tr("settings.power.lock-before-suspend.label")
    description: I18n.tr("settings.power.lock-before-suspend.description")
    checked: Settings.data.power.lockBeforeSuspend
    onToggled: (checked) => {
      Settings.data.power.lockBeforeSuspend = checked
    }
  }

  NToggle {
    label: I18n.tr("settings.power.respect-inhibitors.label")
    description: I18n.tr("settings.power.respect-inhibitors.description")
    checked: Settings.data.power.respectInhibitors
    onToggled: (checked) => {
      Settings.data.power.respectInhibitors = checked
    }
  }

  NToggle {
    label: I18n.tr("settings.power.loginctl-lock.label")
    description: I18n.tr("settings.power.loginctl-lock.description")
    checked: Settings.data.power.loginctlLockIntegration
    onToggled: (checked) => {
      Settings.data.power.loginctlLockIntegration = checked
    }
  }

  // Current status info
  Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: statusColumn.implicitHeight + Style.marginM * 2
    color: Color.mSurfaceVariant
    radius: Style.radiusM
    border.color: Color.mOutline
    border.width: Style.borderS

    ColumnLayout {
      id: statusColumn
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginS

      NText {
        text: I18n.tr("Current power state: ") + (BatteryService.batteryAvailable && !BatteryService.isPluggedIn ? "Battery" : "AC Power")
        font.weight: Font.Medium
        color: Color.mOnSurfaceVariant
      }

      NText {
        text: I18n.tr("Idle monitoring: ") + (IdleService && IdleService.monitorTimeout > 0 ? "Enabled" : "Disabled")
        font.pixelSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
        opacity: 0.8
      }
    }
  }
}
