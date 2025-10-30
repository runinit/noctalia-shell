import QtQuick
import qs.Commons
import Quickshell


Item {
    property var now
    anchors.fill: parent

    // Digital clock's seconds circular progress
    Canvas {
        id: secondsProgress
        visible: !Settings.data.location.analogClockInCalendar
        anchors.fill: parent
        property real progress: now.getSeconds() / 60
        onProgressChanged: requestPaint()
        Connections {
            target: Time
            function onDateChanged() {
                const total = now.getSeconds() * 1000 + now.getMilliseconds()
                secondsProgress.progress = total / 60000
            }
        }
        onPaint: {
            var ctx = getContext("2d")
            var centerX = width / 2
            var centerY = height / 2
            var radius = Math.min(width, height) / 2 - 3
            ctx.reset()

            // Background circle
            ctx.beginPath()
            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI)
            ctx.lineWidth = 2.5
            ctx.strokeStyle = Qt.alpha(Color.mOnPrimary, 0.15)
            ctx.stroke()

            // Progress arc
            ctx.beginPath()
            ctx.arc(centerX, centerY, radius, -Math.PI / 2, -Math.PI / 2 + progress * 2 * Math.PI)
            ctx.lineWidth = 2.5
            ctx.strokeStyle = Color.mOnPrimary
            ctx.lineCap = "round"
            ctx.stroke()
        }
    }

    // Digital clock
    ColumnLayout {
        visible: !Settings.data.location.analogClockInCalendar
        anchors.centerIn: parent
        spacing: -Style.marginXXS

        NText {
            text: {
                var t = Settings.data.location.use12hourFormat ? Qt.locale().toString(now, "hh AP") : Qt.locale().toString(now, "HH")
                return t.split(" ")[0]
            }

            pointSize: Style.fontSizeXS
            font.weight: Style.fontWeightBold
            color: Color.mOnPrimary
            family: Settings.data.ui.fontFixed
            Layout.alignment: Qt.AlignHCenter
        }

        NText {
            text: Qt.formatTime(now, "mm")
            pointSize: Style.fontSizeXXS
            font.weight: Style.fontWeightBold
            color: Color.mOnPrimary
            family: Settings.data.ui.fontFixed
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
