import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
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

  // Widget settings - matching MediaMini pattern
  readonly property bool showIcon: (widgetSettings.showIcon !== undefined) ? widgetSettings.showIcon : widgetMetadata.showIcon
  readonly property string hideMode: (widgetSettings.hideMode !== undefined) ? widgetSettings.hideMode : widgetMetadata.hideMode
  readonly property string scrollingMode: (widgetSettings.scrollingMode !== undefined) ? widgetSettings.scrollingMode : (widgetMetadata.scrollingMode !== undefined ? widgetMetadata.scrollingMode : "hover")
  readonly property int widgetWidth: (widgetSettings.width !== undefined) ? widgetSettings.width : Math.max(widgetMetadata.width, screen.width * 0.06)

  readonly property bool isVerticalBar: (Settings.data.bar.position === "left" || Settings.data.bar.position === "right")
  readonly property bool hasFocusedWindow: CompositorService.getFocusedWindow() !== null
  readonly property string windowTitle: CompositorService.getFocusedWindowTitle() || "No active window"
  readonly property string fallbackIcon: "user-desktop"

  implicitHeight: visible ? (isVerticalBar ? calculatedVerticalDimension() : Style.barHeight) : 0
  implicitWidth: visible ? (isVerticalBar ? calculatedVerticalDimension() : widgetWidth) : 0

  // "visible": Always Visible, "hidden": Hide When Empty, "transparent": Transparent When Empty
  visible: hideMode !== "hidden" || hasFocusedWindow
  opacity: hideMode !== "transparent" || hasFocusedWindow ? 1.0 : 0
  Behavior on opacity {
    NumberAnimation {
      duration: Style.animationNormal
      easing.type: Easing.OutCubic
    }
  }

  function calculatedVerticalDimension() {
    const ratio = (Settings.data.bar.density === "mini") ? 0.67 : 0.8
    return Math.round(Style.baseWidgetSize * ratio)
  }

  function getAppIcon() {
    try {
      // Try CompositorService first
      const focusedWindow = CompositorService.getFocusedWindow()
      if (focusedWindow && focusedWindow.appId) {
        try {
          const idValue = focusedWindow.appId
          const normalizedId = (typeof idValue === 'string') ? idValue : String(idValue)
          const iconResult = ThemeIcons.iconForAppId(normalizedId.toLowerCase())
          if (iconResult && iconResult !== "") {
            return iconResult
          }
        } catch (iconError) {
          Logger.w("ActiveWindow", "Error getting icon from CompositorService:", iconError)
        }
      }

      if (CompositorService.isHyprland) {
        // Fallback to ToplevelManager
        if (ToplevelManager && ToplevelManager.activeToplevel) {
          try {
            const activeToplevel = ToplevelManager.activeToplevel
            if (activeToplevel.appId) {
              const idValue2 = activeToplevel.appId
              const normalizedId2 = (typeof idValue2 === 'string') ? idValue2 : String(idValue2)
              const iconResult2 = ThemeIcons.iconForAppId(normalizedId2.toLowerCase())
              if (iconResult2 && iconResult2 !== "") {
                return iconResult2
              }
            }
          } catch (fallbackError) {
            Logger.w("ActiveWindow", "Error getting icon from ToplevelManager:", fallbackError)
          }
        }
      }

      return ThemeIcons.iconFromName(fallbackIcon)
    } catch (e) {
      Logger.w("ActiveWindow", "Error in getAppIcon:", e)
      return ThemeIcons.iconFromName(fallbackIcon)
    }
  }

  // Hidden text element to measure full title width
  NText {
    id: fullTitleMetrics
    visible: false
    text: windowTitle
    pointSize: Style.fontSizeS
    applyUiScale: false
    font.weight: Style.fontWeightMedium
  }

  // ALIGNMENT STRATEGY:
  // - Bar.qml parent layout provides Layout.alignment (AlignVCenter for horizontal, AlignHCenter for vertical)
  // - Root Item has implicit dimensions and NO position anchors (let parent layout handle positioning)
  // - Rectangle uses centerIn to align within root, not left anchor
  // - This ensures consistent vertical/horizontal centering regardless of bar position
  Rectangle {
    id: windowActiveRect
    visible: root.visible
    anchors.centerIn: parent
    width: (barPosition === "left" || barPosition === "right") ? Math.round(Style.baseWidgetSize * 0.8) : (widgetWidth)
    height: (barPosition === "left" || barPosition === "right") ? Math.round(Style.baseWidgetSize * 0.8) : Style.capsuleHeight
    radius: (barPosition === "left" || barPosition === "right") ? width / 2 : Style.radiusM
    color: Settings.data.bar.showCapsule ? Color.mSurfaceVariant : Color.transparent

    Item {
      id: mainContainer
      anchors.fill: parent
      anchors.leftMargin: isVerticalBar ? 0 : Style.marginS
      anchors.rightMargin: isVerticalBar ? 0 : Style.marginS

      // Horizontal layout for top/bottom bars
      RowLayout {
        id: rowLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.marginS
        visible: !isVerticalBar
        z: 1

        // Window icon
        Item {
          Layout.preferredWidth: 18
          Layout.preferredHeight: 18
          Layout.alignment: Qt.AlignVCenter
          visible: showIcon

          IconImage {
            id: windowIcon
            anchors.fill: parent
            source: getAppIcon()
            asynchronous: true
            smooth: true
            visible: source !== ""

            // Apply dock shader to active window icon (always themed)
            layer.enabled: widgetSettings.colorizeIcons !== false
            layer.effect: ShaderEffect {
              property color targetColor: Color.mOnSurface
              property real colorizeMode: 0.0 // Dock mode (grayscale)

              fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/appicon_colorize.frag.qsb")
            }
          }
        }

        // Title container with scrolling
        Item {
          id: titleContainer
          Layout.preferredWidth: {
            // Calculate available width based on other elements
            var iconWidth = (showIcon && windowIcon.visible ? (18 + Style.marginS) : 0)
            var totalMargins = Style.marginXXS * 2
            var availableWidth = mainContainer.width - iconWidth - totalMargins
            return Math.max(20, availableWidth)
          }
          Layout.maximumWidth: Layout.preferredWidth
          Layout.alignment: Qt.AlignVCenter
          Layout.preferredHeight: titleText.height

          clip: true

          property bool isScrolling: false
          property bool isResetting: false
          property real textWidth: fullTitleMetrics.contentWidth
          property real containerWidth: width
          property bool needsScrolling: textWidth > containerWidth

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

          onWidthChanged: updateScrollingState()
          Component.onCompleted: updateScrollingState()

          // React to hover changes
          Connections {
            target: mouseArea
            function onContainsMouseChanged() {
              titleContainer.updateScrollingState()
            }
          }

          // Scrolling content with seamless loop
          Item {
            id: scrollContainer
            height: parent.height
            width: childrenRect.width

            property real scrollX: 0
            x: scrollX

            RowLayout {
              spacing: 50 // Gap between text copies

              NText {
                id: titleText
                text: windowTitle
                pointSize: Style.fontSizeS
                applyUiScale: false
                font.weight: Style.fontWeightMedium
                verticalAlignment: Text.AlignVCenter
                color: Color.mOnSurface
              }

              // Second copy for seamless scrolling
              NText {
                text: windowTitle
                font: titleText.font
                pointSize: Style.fontSizeS
                applyUiScale: false
                verticalAlignment: Text.AlignVCenter
                color: Color.mOnSurface
                visible: titleContainer.needsScrolling && titleContainer.isScrolling
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
              to: -(titleContainer.textWidth + 50)
              duration: Math.max(4000, windowTitle.length * 100)
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
        visible: isVerticalBar
        z: 1

        // Window icon
        Item {
          width: Style.baseWidgetSize * 0.5
          height: width
          anchors.centerIn: parent
          visible: windowTitle !== ""

          IconImage {
            id: windowIconVertical
            anchors.fill: parent
            source: getAppIcon()
            asynchronous: true
            smooth: true
            visible: source !== ""

            // Apply dock shader to active window icon (always themed)
            layer.enabled: widgetSettings.colorizeIcons !== false
            layer.effect: ShaderEffect {
              property color targetColor: Color.mOnSurface
              property real colorizeMode: 0.0 // Dock mode (grayscale)

              fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/appicon_colorize.frag.qsb")
            }
          }
        }
      }

      // Mouse area for hover detection
      MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onEntered: {
          if ((windowTitle !== "") && isVerticalBar || (scrollingMode === "never")) {
            TooltipService.show(Screen, root, windowTitle, BarService.getTooltipDirection())
          }
        }
        onExited: {
          TooltipService.hide()
        }
      }
    }
  }

  Connections {
    target: CompositorService
    function onActiveWindowChanged() {
      try {
        windowIcon.source = Qt.binding(getAppIcon)
        windowIconVertical.source = Qt.binding(getAppIcon)
      } catch (e) {
        Logger.w("ActiveWindow", "Error in onActiveWindowChanged:", e)
      }
    }
    function onWindowListChanged() {
      try {
        windowIcon.source = Qt.binding(getAppIcon)
        windowIconVertical.source = Qt.binding(getAppIcon)
      } catch (e) {
        Logger.w("ActiveWindow", "Error in onWindowListChanged:", e)
      }
    }
  }
}
