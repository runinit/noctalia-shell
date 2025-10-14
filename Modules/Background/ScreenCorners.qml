import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Widgets

Loader {
  active: Settings.data.general.showScreenCorners

  sourceComponent: Variants {
    model: Quickshell.screens

    PanelWindow {
      id: root

      required property ShellScreen modelData
      screen: modelData

      property color cornerColor: Settings.data.general.forceBlackScreenCorners ? Qt.rgba(0, 0, 0, 1) : Qt.alpha(Color.mSurface, Settings.data.bar.backgroundOpacity)
      property real cornerRadius: Style.screenRadius
      property real cornerSize: Style.screenRadius

      // PERF: Cache complex margin calculation values to reduce binding evaluations
      readonly property bool barVisibleOnThisScreen: BarService.isVisible && ((modelData && Settings.data.bar.monitors.includes(modelData.name)) || (Settings.data.bar.monitors.length === 0))
      readonly property bool barHasBackground: Settings.data.bar.backgroundOpacity > 0
      readonly property bool barIsFloating: Settings.data.bar.floating
      readonly property string barPos: Settings.data.bar.position

      color: Color.transparent

      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "quickshell-corner"
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      margins {
        // PERF: Simplified bindings using cached properties
        // When bar is floating, corners should be at screen edges (no margins)
        // When bar is not floating, respect bar margins as before
        top: !barIsFloating && barVisibleOnThisScreen && barPos === "top" && barHasBackground ? Style.barHeight : 0
        bottom: !barIsFloating && barVisibleOnThisScreen && barPos === "bottom" && barHasBackground ? Style.barHeight : 0
        left: !barIsFloating && barVisibleOnThisScreen && barPos === "left" && barHasBackground ? Style.barHeight : 0
        right: !barIsFloating && barVisibleOnThisScreen && barPos === "right" && barHasBackground ? Style.barHeight : 0
      }

      mask: Region {}

      // Top-left concave corner
      Canvas {
        id: topLeftCorner
        anchors.top: parent.top
        anchors.left: parent.left
        width: cornerSize
        height: cornerSize
        antialiasing: true
        renderTarget: Canvas.FramebufferObject
        smooth: false

        onPaint: {
          const ctx = getContext("2d")
          if (!ctx)
            return

          ctx.reset()
          ctx.clearRect(0, 0, width, height)

          // Fill the entire area with the corner color
          ctx.fillStyle = root.cornerColor
          ctx.fillRect(0, 0, width, height)

          // Cut out the rounded corner using destination-out
          ctx.globalCompositeOperation = "destination-out"
          ctx.fillStyle = "#ffffff"
          ctx.beginPath()
          ctx.arc(width, height, root.cornerRadius, 0, 2 * Math.PI)
          ctx.fill()
        }

        onWidthChanged: if (available)
                          requestPaint()
        onHeightChanged: if (available)
                           requestPaint()

        Connections {
          target: root
          function onCornerColorChanged() {
            if (topLeftCorner.available)
              topLeftCorner.requestPaint()
          }
          function onCornerRadiusChanged() {
            if (topLeftCorner.available)
              topLeftCorner.requestPaint()
          }
        }
      }

      // Top-right concave corner
      Canvas {
        id: topRightCorner
        anchors.top: parent.top
        anchors.right: parent.right
        width: cornerSize
        height: cornerSize
        antialiasing: true
        renderTarget: Canvas.FramebufferObject
        smooth: true

        onPaint: {
          const ctx = getContext("2d")
          if (!ctx)
            return

          ctx.reset()
          ctx.clearRect(0, 0, width, height)

          ctx.fillStyle = root.cornerColor
          ctx.fillRect(0, 0, width, height)

          ctx.globalCompositeOperation = "destination-out"
          ctx.fillStyle = "#ffffff"
          ctx.beginPath()
          ctx.arc(0, height, root.cornerRadius, 0, 2 * Math.PI)
          ctx.fill()
        }

        onWidthChanged: if (available)
                          requestPaint()
        onHeightChanged: if (available)
                           requestPaint()

        Connections {
          target: root
          function onCornerColorChanged() {
            if (topRightCorner.available)
              topRightCorner.requestPaint()
          }
          function onCornerRadiusChanged() {
            if (topRightCorner.available)
              topRightCorner.requestPaint()
          }
        }
      }

      // Bottom-left concave corner
      Canvas {
        id: bottomLeftCorner
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: cornerSize
        height: cornerSize
        antialiasing: true
        renderTarget: Canvas.FramebufferObject
        smooth: true

        onPaint: {
          const ctx = getContext("2d")
          if (!ctx)
            return

          ctx.reset()
          ctx.clearRect(0, 0, width, height)

          ctx.fillStyle = root.cornerColor
          ctx.fillRect(0, 0, width, height)

          ctx.globalCompositeOperation = "destination-out"
          ctx.fillStyle = "#ffffff"
          ctx.beginPath()
          ctx.arc(width, 0, root.cornerRadius, 0, 2 * Math.PI)
          ctx.fill()
        }

        onWidthChanged: if (available)
                          requestPaint()
        onHeightChanged: if (available)
                           requestPaint()

        Connections {
          target: root
          function onCornerColorChanged() {
            if (bottomLeftCorner.available)
              bottomLeftCorner.requestPaint()
          }
          function onCornerRadiusChanged() {
            if (bottomLeftCorner.available)
              bottomLeftCorner.requestPaint()
          }
        }
      }

      // Bottom-right concave corner
      Canvas {
        id: bottomRightCorner
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: cornerSize
        height: cornerSize
        antialiasing: true
        renderTarget: Canvas.FramebufferObject
        smooth: true

        onPaint: {
          const ctx = getContext("2d")
          if (!ctx)
            return

          ctx.reset()
          ctx.clearRect(0, 0, width, height)

          ctx.fillStyle = root.cornerColor
          ctx.fillRect(0, 0, width, height)

          ctx.globalCompositeOperation = "destination-out"
          ctx.fillStyle = "#ffffff"
          ctx.beginPath()
          ctx.arc(0, 0, root.cornerRadius, 0, 2 * Math.PI)
          ctx.fill()
        }

        onWidthChanged: if (available)
                          requestPaint()
        onHeightChanged: if (available)
                           requestPaint()

        Connections {
          target: root
          function onCornerColorChanged() {
            if (bottomRightCorner.available)
              bottomRightCorner.requestPaint()
          }
          function onCornerRadiusChanged() {
            if (bottomRightCorner.available)
              bottomRightCorner.requestPaint()
          }
        }
      }
    }
  }
}
