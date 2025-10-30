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
  preferredHeight: 650 * Style.uiScaleRatio
  panelKeyboardFocus: true

  // View mode setting
  property string viewMode: Settings.data.appMenu ? (Settings.data.appMenu.viewMode || "list") : "list"

  // Show categories
  property bool showCategories: Settings.data.appMenu ? (Settings.data.appMenu.showCategories !== false) : true

  panelContent: Item {
    ColumnLayout {
      x: Style.marginL
      y: Style.marginL
      width: parent.width - (Style.marginL * 2)
      height: parent.height - (Style.marginL * 2)
      spacing: Style.marginM

      // Header in a card
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: headerRow.implicitHeight + Style.marginM * 2

        RowLayout {
          id: headerRow
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          NText {
            text: "📱"
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

            NButton {
              text: "☰"
              tooltipText: I18n.tr("app-menu.list-view")
              fontSize: Style.fontSizeL
              backgroundColor: viewMode === "list" ? Color.mPrimary : Color.mSurfaceVariant
              textColor: viewMode === "list" ? Color.mOnPrimary : Color.mOnSurfaceVariant
              onClicked: {
                viewMode = "list"
                if (!Settings.data.appMenu) {
                  Settings.data.appMenu = {}
                }
                Settings.data.appMenu.viewMode = "list"
              }
            }

            NButton {
              text: "▦"
              tooltipText: I18n.tr("app-menu.grid-view")
              fontSize: Style.fontSizeL
              backgroundColor: viewMode === "grid" ? Color.mPrimary : Color.mSurfaceVariant
              textColor: viewMode === "grid" ? Color.mOnPrimary : Color.mOnSurfaceVariant
              onClicked: {
                viewMode = "grid"
                if (!Settings.data.appMenu) {
                  Settings.data.appMenu = {}
                }
                Settings.data.appMenu.viewMode = "grid"
              }
            }
          }

          NButton {
            text: "×"
            tooltipText: I18n.tr("tooltips.close")
            fontSize: Style.fontSizeL
            backgroundColor: Color.transparent
            textColor: Color.mOnSurface
            onClicked: root.close()
          }
        }
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

    // Handle panel opened/closed signals safely after appLauncher is defined
    Connections {
      target: root

      function onOpened() {
        // Refresh apps when panel opens
        if (AppSearchService.loaded) {
          AppSearchService.refresh()
        }
        // Focus search field
        Qt.callLater(() => {
          if (appLauncher) {
            appLauncher.focusSearch()
          }
        })
      }

      function onClosed() {
        // Clear search when closing
        if (appLauncher) {
          appLauncher.clearSearch()
        }
      }
    }
  }
}
