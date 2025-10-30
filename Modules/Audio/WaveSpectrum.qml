import QtQuick
import qs.Commons

Item {
  id: root
  property color fillColor: Color.mPrimary
  property color strokeColor: Color.mOnSurface
  property int strokeWidth: 0
  property var values: []

  // Minimum signal properties
  property bool showMinimumSignal: false
  property real minimumSignalValue: 0.05 // Default to 5% of height

  // Redraw when necessary
  onWidthChanged: canvas.requestPaint()
  onHeightChanged: canvas.requestPaint()
  onValuesChanged: canvas.requestPaint()
  onFillColorChanged: canvas.requestPaint()
  onStrokeColorChanged: canvas.requestPaint()
  onShowMinimumSignalChanged: canvas.requestPaint()
  onMinimumSignalValueChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.fill: parent
    antialiasing: true

    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()

      if (values.length === 0) {
        return
      }

      // Apply minimum signal if enabled
      var processedValues = values.map(function (v) {
        return (root.showMinimumSignal && v === 0) ? root.minimumSignalValue : v
      })

      // Create the mirrored values
      const partToMirror = processedValues.slice(1).reverse()
      const mirroredValues = partToMirror.concat(processedValues)

      if (mirroredValues.length < 2) {
        return
      }

      ctx.fillStyle = root.fillColor
      ctx.strokeStyle = root.strokeColor
      ctx.lineWidth = root.strokeWidth

      const count = mirroredValues.length
      const stepX = width / (count - 1)
      const centerY = height / 2
      const amplitude = height / 2

      ctx.beginPath()

      // Draw the top half of the waveform from left to right
      // Use the calculated offset for the first point
      var yOffset = mirroredValues[0] * amplitude
      ctx.moveTo(0, centerY - yOffset)

      for (var i = 1; i < count; i++) {
        const x = i * stepX
        yOffset = mirroredValues[i] * amplitude
        const y = centerY - yOffset
        ctx.lineTo(x, y)
      }

      // Draw the bottom half of the waveform from right to left to create a closed shape
      for (var i = count - 1; i >= 0; i--) {
        const x = i * stepX
        yOffset = mirroredValues[i] * amplitude
        const y = centerY + yOffset // Mirrored across the center
        ctx.lineTo(x, y)
      }

      ctx.closePath()

      // --- Render the path ---
      if (root.fillColor.a > 0) {
        ctx.fill()
      }
      if (root.strokeWidth > 0) {
        ctx.stroke()
      }
    }
  }
}
