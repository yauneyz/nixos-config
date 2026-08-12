import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../components"

PanelFrame {
    id: root
    title: "Session"
    property string pendingAction: ""

    function runAction(action) {
        if (action === "suspend")
            Quickshell.execDetached(["systemctl", "suspend"]);
        else if (action === "logout")
            Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
        else if (action === "reboot")
            Quickshell.execDetached(["systemctl", "reboot"]);
        else if (action === "shutdown")
            Quickshell.execDetached(["systemctl", "poweroff"]);
        ShellState.closePanel();
    }

    GridLayout {
        anchors.fill: parent
        columns: 2
        rowSpacing: 12
        columnSpacing: 12
        Repeater {
            model: [
                {
                    name: "Suspend",
                    action: "suspend",
                    icon: "weather-clear-night-symbolic"
                },
                {
                    name: "Log out",
                    action: "logout",
                    icon: "system-log-out-symbolic"
                },
                {
                    name: "Reboot",
                    action: "reboot",
                    icon: "system-reboot-symbolic"
                },
                {
                    name: "Shut down",
                    action: "shutdown",
                    icon: "system-shutdown-symbolic"
                }
            ]
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16
                color: actionMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceRaised
                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 30
                        height: 30
                        source: Quickshell.iconPath(modelData.icon, true)
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.name
                        color: Theme.text
                        font.bold: true
                    }
                }
                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.pendingAction = modelData.action;
                        confirmTimer.restart();
                    }
                }
            }
        }

        Rectangle {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            implicitHeight: 58
            visible: root.pendingAction !== ""
            radius: 12
            color: Theme.alpha(Theme.danger, 0.2)
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                Text {
                    text: "Confirm " + root.pendingAction + "?"
                    color: Theme.text
                    Layout.fillWidth: true
                }
                IconButton {
                    fallbackText: "Cancel"
                    implicitWidth: 58
                    onClicked: root.pendingAction = ""
                }
                IconButton {
                    fallbackText: "Confirm"
                    implicitWidth: 65
                    accent: Theme.danger
                    onClicked: root.runAction(root.pendingAction)
                }
            }
        }
    }
    Timer {
        id: confirmTimer
        interval: 10000
        onTriggered: root.pendingAction = ""
    }
}
