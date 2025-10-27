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

  preferredWidth: 600 * Style.uiScaleRatio
  preferredHeight: 700 * Style.uiScaleRatio
  panelKeyboardFocus: true

  // View mode setting
  property string viewMode: Settings.data.appMenu ? (Settings.data.appMenu.viewMode || "list") : "list"

  // Show categories
  property bool showCategories: Settings.data.appMenu ? (Settings.data.appMenu.showCategories !== false) : true

  onOpened: {
    // Refresh apps when panel opens
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
          icon: "view-app-grid"
          pointSize: Style.fontSizeXXL
          color: Color.mPrimary
        }

        NText {
          text: I18n.tr("app-menu.title")
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
            tooltipText: I18n.tr("app-menu.list-view")
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: {
              viewMode = "list"
              if (!Settings.data.appMenu) {
                Settings.data.appMenu = {}
              }
              Settings.data.appMenu.viewMode = "list"
            }
          }

          NIconButton {
            icon: "view-grid"
            tooltipText: I18n.tr("app-menu.grid-view")
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: {
              viewMode = "grid"
              if (!Settings.data.appMenu) {
                Settings.data.appMenu = {}
              }
              Settings.data.appMenu.viewMode = "grid"
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
          Logger.d("AppMenuPopout", `App launched: ${appKey}`)
          root.close()
        }

        onClosed: {
          root.close()
        }
      }
    }
  }
}
