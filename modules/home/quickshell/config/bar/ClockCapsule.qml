import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../components"
import "../services"

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

        IconButton {
            icon: ShellState.dnd ? "notifications-disabled-symbolic" : "notifications-symbolic"
            fallbackText: ShellState.dnd ? "" : ""
            accent: NotificationService.count > 0 ? Theme.warning : Theme.textMuted
            onClicked: ShellState.togglePanel("notifications", root.shellScreen, root.barWindow, this)
            Text {
                visible: NotificationService.count > 0
                anchors.right: parent.right
                anchors.top: parent.top
                text: Math.min(99, NotificationService.count)
                color: Theme.background
                font.pixelSize: 8
                font.bold: true
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    radius: 7
                    color: Theme.warning
                    z: -1
                }
            }
        }
        Text {
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.text
            font.pixelSize: 13
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
