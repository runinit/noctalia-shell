import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

NPanel {
  id: root

  preferredWidth: 550 * Style.uiScaleRatio
  preferredHeight: 700 * Style.uiScaleRatio
  preferredWidthRatio: 0.4
  preferredHeightRatio: 0.6
  panelKeyboardFocus: true

  // Center positioning
  panelAnchorHorizontalCenter: true
  panelAnchorVerticalCenter: true

  // View mode setting
  property string viewMode: Settings.data.spotlight ? (Settings.data.spotlight.viewMode || "list") : "list"

  // Show categories
  property bool showCategories: Settings.data.spotlight ? (Settings.data.spotlight.showCategories || false) : false

  // Public API for IPC
  function setSearchQuery(query) {
    appLauncher.searchQuery = query
  }

  onOpened: {
    // Refresh apps when modal opens
    if (AppSearchService.loaded) {
      AppSearchService.refresh()
    }
    // Focus search field
    Qt.callLater(() => appLauncher.focusSearch())
  }

  onClosed: {
    // Clear search when closing
    appLauncher.clearSearch()
  }

  panelContent: Rectangle {
    color: Color.transparent

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      // Header
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NIcon {
          icon: "search"
          pointSize: Style.fontSizeXXL
          color: Color.mPrimary
        }

        NText {
          text: I18n.tr("spotlight.title")
          pointSize: Style.fontSizeL
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
          Layout.fillWidth: true
        }

        // View mode toggle
        Row {
          spacing: 4

          NIconButton {
            icon: "view-list"
            tooltipText: I18n.tr("spotlight.list-view")
            baseSize: Style.baseWidgetSize * 0.8
            highlighted: viewMode === "list"
            onClicked: {
              viewMode = "list"
              if (Settings.data.spotlight) {
                Settings.data.spotlight.viewMode = "list"
              }
            }
          }

          NIconButton {
            icon: "view-grid"
            tooltipText: I18n.tr("spotlight.grid-view")
            baseSize: Style.baseWidgetSize * 0.8
            highlighted: viewMode === "grid"
            onClicked: {
              viewMode = "grid"
              if (Settings.data.spotlight) {
                Settings.data.spotlight.viewMode = "grid"
              }
            }
          }
        }

        NIconButton {
          icon: "close"
          tooltipText: I18n.tr("tooltips.close")
          baseSize: Style.baseWidgetSize * 0.8
          onClicked: root.close()
        }
      }

      NDivider {
        Layout.fillWidth: true
      }

      // App Launcher
      AppLauncher {
        id: appLauncher
        Layout.fillWidth: true
        Layout.fillHeight: true

        viewMode: root.viewMode
        showCategories: root.showCategories

        onAppLaunched: (appKey) => {
          Logger.d("SpotlightModal", `App launched: ${appKey}`)
          root.close()
        }

        onClosed: {
          root.close()
        }
      }

      // Keyboard hint
      NText {
        Layout.fillWidth: true
        text: I18n.tr("spotlight.keyboard-hint")
        font.pixelSize: Style.fontSizeXS
        color: Color.mOnSurfaceVariant
        horizontalAlignment: Text.AlignCenter
        opacity: 0.7
      }
    }
  }
}
