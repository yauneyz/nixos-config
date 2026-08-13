import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../components"

BarCapsule {
    id: root
    required property var barWindow
    required property var shellScreen
    implicitWidth: sessionRow.implicitWidth + 12

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    RowLayout {
        id: sessionRow
        anchors.centerIn: parent
        spacing: 2

        Text {
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.text
            font.pixelSize: 16
            font.bold: true
            leftPadding: 4
            rightPadding: 4
            MouseArea {
                anchors.fill: parent
                onClicked: ShellState.togglePanel("calendar", root.shellScreen, root.barWindow, parent)
            }
        }
        IconButton {
            icon: "system-shutdown-symbolic"
            fallbackText: ""
            accent: Theme.danger
            onClicked: ShellState.togglePanel("session", root.shellScreen, root.barWindow, this)
        }
    }
}
