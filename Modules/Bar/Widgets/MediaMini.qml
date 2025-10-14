import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Modules.Audio
import qs.Commons
import qs.Services
import qs.Widgets

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

  readonly property string barPosition: Settings.data.bar.position
  readonly property bool density: Settings.data.bar.density

  readonly property string hideMode: (widgetSettings.hideMode !== undefined) ? widgetSettings.hideMode : "hidden" // "visible", "hidden", "transparent"
  readonly property bool showAlbumArt: (widgetSettings.showAlbumArt !== undefined) ? widgetSettings.showAlbumArt : widgetMetadata.showAlbumArt
  readonly property bool showVisualizer: (widgetSettings.showVisualizer !== undefined) ? widgetSettings.showVisualizer : widgetMetadata.showVisualizer
  readonly property string visualizerType: (widgetSettings.visualizerType !== undefined && widgetSettings.visualizerType !== "") ? widgetSettings.visualizerType : widgetMetadata.visualizerType
  readonly property string scrollingMode: (widgetSettings.scrollingMode !== undefined) ? widgetSettings.scrollingMode : widgetMetadata.scrollingMode

  // Fixed width - no expansion
  readonly property real widgetWidth: Math.max(145, screen.width * 0.06)

  readonly property bool hasActivePlayer: MediaService.currentPlayer !== null
  readonly property string placeholderText: I18n.tr("bar.widget-settings.media-mini.no-active-player")

  readonly property string tooltipText: {
    var title = getTitle()
    var controls = ""
    if (MediaService.canGoNext) {
      controls += "Right click for next.\n"
    }
    if (MediaService.canGoPrevious) {
      controls += "Middle click for previous."
    }
    if (controls !== "") {
      return title + "\n\n" + controls
    }
    return title
  }

  implicitHeight: visible ? ((barPosition === "left" || barPosition === "right") ? calculatedVerticalHeight() : Style.barHeight) : 0
  implicitWidth: visible ? ((barPosition === "left" || barPosition === "right") ? Math.round(Style.baseWidgetSize * 0.8) : (widgetWidth)) : 0

  // "visible": Always Visible, "hidden": Hide When Empty, "transparent": Transparent When Empty
  visible: hideMode !== "hidden" || hasActivePlayer
  opacity: hideMode !== "transparent" || hasActivePlayer ? 1.0 : 0
  Behavior on opacity {
    NumberAnimation {
      duration: Style.animationNormal
      easing.type: Easing.OutCubic
    }
  }

  function getTitle() {
    return MediaService.trackTitle + (MediaService.trackArtist !== "" ? ` - ${MediaService.trackArtist}` : "")
  }

  function calculatedVerticalHeight() {
    return Math.round(Style.baseWidgetSize * 0.8)
  }

  //  A hidden text element to safely measure the full title width
  NText {
    id: fullTitleMetrics
    visible: false
    text: titleText.text
    font: titleText.font
    applyUiScale: false
  }

  Rectangle {
    id: mediaMini
    visible: root.visible
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: (barPosition === "left" || barPosition === "right") ? Math.round(Style.baseWidgetSize * 0.8) : (widgetWidth)
    height: (barPosition === "left" || barPosition === "right") ? Math.round(Style.baseWidgetSize * 0.8) : Style.capsuleHeight
    radius: (barPosition === "left" || barPosition === "right") ? width / 2 : Style.radiusM
    color: Settings.data.bar.showCapsule ? Color.mSurfaceVariant : Color.transparent

    Item {
      id: mainContainer
      anchors.fill: parent
      anchors.leftMargin: (barPosition === "left" || barPosition === "right") ? 0 : Style.marginS
      anchors.rightMargin: (barPosition === "left" || barPosition === "right") ? 0 : Style.marginS

      Loader {
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        active: showVisualizer && visualizerType == "linear"
        z: 0

        sourceComponent: LinearSpectrum {
          width: mainContainer.width - Style.marginS
          height: 20
          values: CavaService.values
          fillColor: Color.mPrimary
          opacity: 0.4
        }
      }

      Loader {
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        active: showVisualizer && visualizerType == "mirrored"
        z: 0

        sourceComponent: MirroredSpectrum {
          width: mainContainer.width - Style.marginS
          height: mainContainer.height - Style.marginS
          values: CavaService.values
          fillColor: Color.mPrimary
          opacity: 0.4
        }
      }

      Loader {
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        active: showVisualizer && visualizerType == "wave"
        z: 0

        sourceComponent: WaveSpectrum {
          width: mainContainer.width - Style.marginS
          height: mainContainer.height - Style.marginS
          values: CavaService.values
          fillColor: Color.mPrimary
          opacity: 0.4
        }
      }

      // Horizontal layout for top/bottom bars
      RowLayout {
        id: rowLayout

        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.marginS
        visible: (barPosition === "top" || barPosition === "bottom")
        z: 1 // Above the visualizer

        NIcon {
          id: windowIcon
          icon: hasActivePlayer ? (MediaService.isPlaying ? "media-pause" : "media-play") : "disc"
          color: hasActivePlayer ? Color.mOnSurface : Color.mOnSurfaceVariant
          pointSize: Style.fontSizeL
          verticalAlignment: Text.AlignVCenter
          Layout.alignment: Qt.AlignVCenter
          visible: !hasActivePlayer || (!showAlbumArt && !trackArt.visible)
        }

        ColumnLayout {
          Layout.alignment: Qt.AlignVCenter
          visible: showAlbumArt && hasActivePlayer
          spacing: 0

          Item {
            Layout.preferredWidth: Math.round(21 * Style.uiScaleRatio)
            Layout.preferredHeight: Math.round(21 * Style.uiScaleRatio)

            NImageCircled {
              id: trackArt
              anchors.fill: parent
              imagePath: MediaService.trackArtUrl
              fallbackIcon: MediaService.isPlaying ? "media-pause" : "media-play"
              fallbackIconSize: 10
              borderWidth: 0
              border.color: Color.transparent
            }
          }
        }

        Item {
          id: titleContainer
          Layout.preferredWidth: {
            // Calculate available width based on other elements in the row
            var iconWidth = (windowIcon.visible ? (Style.fontSizeL + Style.marginS) : 0)
            var albumArtWidth = (hasActivePlayer && showAlbumArt ? (18 + Style.marginS) : 0)
            var totalMargins = Style.marginXXS * 2
            var availableWidth = mainContainer.width - iconWidth - albumArtWidth - totalMargins
            return Math.max(20, availableWidth)
          }
          Layout.maximumWidth: Layout.preferredWidth
          Layout.alignment: Qt.AlignVCenter
          Layout.preferredHeight: titleText.height

          clip: true

          property bool isScrolling: false
          property bool isResetting: false
          property real textWidth: fullTitleMetrics.contentWidth
          property real containerWidth: 0
          property bool needsScrolling: textWidth > containerWidth && MediaService.isPlaying

          // Timer for "always" mode with delay
          Timer {
            id: scrollStartTimer
            interval: 1000
            repeat: false
            onTriggered: {
              if (scrollingMode === "always" && titleContainer.needsScrolling) {
                titleContainer.isScrolling = true
                titleContainer.isResetting = false
              }
            }
          }

          // Update scrolling state based on mode
          property var updateScrollingState: function () {
            if (scrollingMode === "never") {
              isScrolling = false
              isResetting = false
            } else if (scrollingMode === "always") {
              if (needsScrolling) {
                if (mouseArea.containsMouse) {
                  isScrolling = false
                  isResetting = true
                } else {
                  scrollStartTimer.restart()
                }
              } else {
                scrollStartTimer.stop()
                isScrolling = false
                isResetting = false
              }
            } else if (scrollingMode === "hover") {
              if (mouseArea.containsMouse && needsScrolling) {
                isScrolling = true
                isResetting = false
              } else {
                isScrolling = false
                if (needsScrolling) {
                  isResetting = true
                }
              }
            }
          }

          onWidthChanged: {
            containerWidth = width
            updateScrollingState()
          }

          Component.onCompleted: {
            containerWidth = width
            updateScrollingState()
          }

          Connections {
            target: mouseArea
            function onContainsMouseChanged() {
              titleContainer.updateScrollingState()
            }
          }

          // Scrolling content
          Item {
            id: scrollContainer
            height: parent.height
            width: parent.width

            property real scrollX: 0
            x: scrollX

            RowLayout {
              spacing: 50 // Gap between text copies

              NText {
                id: titleText
                text: hasActivePlayer ? getTitle() : placeholderText
                pointSize: Style.fontSizeS
                applyUiScale: false
                font.weight: Style.fontWeightMedium
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: hasActivePlayer ? Text.AlignLeft : Text.AlignHCenter
                color: hasActivePlayer ? Color.mOnSurface : Color.mOnSurfaceVariant
              }

              NText {
                text: hasActivePlayer ? getTitle() : placeholderText
                font: titleText.font
                applyUiScale: false
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: hasActivePlayer ? Text.AlignLeft : Text.AlignHCenter
                color: hasActivePlayer ? Color.mOnSurface : Color.mOnSurfaceVariant
                visible: hasActivePlayer && titleContainer.needsScrolling && titleContainer.isScrolling
              }
            }

            // Reset animation
            NumberAnimation on scrollX {
              running: titleContainer.isResetting
              to: 0
              duration: 300
              easing.type: Easing.OutQuad
              onFinished: {
                titleContainer.isResetting = false
              }
            }

            // Seamless infinite scroll
            NumberAnimation on scrollX {
              id: infiniteScroll
              running: titleContainer.isScrolling && !titleContainer.isResetting
              from: 0
              to: -(titleContainer.textWidth + 50) // Scroll one complete text width + gap
              duration: Math.max(4000, getTitle().length * 120)
              loops: Animation.Infinite
              easing.type: Easing.Linear
            }
          }

          Behavior on Layout.preferredWidth {
            NumberAnimation {
              duration: Style.animationSlow
              easing.type: Easing.InOutCubic
            }
          }
        }
      }

      // Vertical layout for left/right bars - icon only
      Item {
        id: verticalLayout
        anchors.centerIn: parent
        width: parent.width - Style.marginM * 2
        height: parent.height - Style.marginM * 2
        visible: barPosition === "left" || barPosition === "right"
        z: 1 // Above the visualizer

        // Media icon
        Item {
          width: Style.baseWidgetSize * 0.5
          height: Style.baseWidgetSize * 0.5
          anchors.centerIn: parent

          NIcon {
            id: mediaIconVertical
            anchors.fill: parent
            icon: hasActivePlayer ? (MediaService.isPlaying ? "media-pause" : "media-play") : "disc"
            color: hasActivePlayer ? Color.mOnSurface : Color.mOnSurfaceVariant
            pointSize: Style.fontSizeL
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
          }
        }
      }

      // Mouse area for hover detection
      MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: hasActivePlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => {
                     if (!hasActivePlayer || !MediaService.currentPlayer || !MediaService.canPlay) {
                       return
                     }

                     if (mouse.button === Qt.LeftButton) {
                       MediaService.playPause()
                     } else if (mouse.button == Qt.RightButton) {
                       MediaService.next()
                       TooltipService.hide()
                     } else if (mouse.button == Qt.MiddleButton) {
                       MediaService.previous()
                       TooltipService.hide()
                     }
                   }

        onEntered: {
          var textToShow = hasActivePlayer ? tooltipText : placeholderText
          if ((textToShow !== "") && (barPosition === "left" || barPosition === "right") || (scrollingMode === "never")) {
            TooltipService.show(Screen, root, textToShow, BarService.getTooltipDirection())
          }
        }
        onExited: {
          TooltipService.hide()
        }
      }
    }
  }
}
