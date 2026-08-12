import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

Rectangle {
    id: root
    property var device: null
    signal closeRequested
    radius: 14
    color: Theme.surfaceRaised
    visible: device !== null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: root.device ? root.device.name : "Device"
                color: Theme.text
                font.pixelSize: 17
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            IconButton {
                fallbackText: "×"
                onClicked: root.closeRequested()
            }
        }
        Text {
            text: root.device ? root.device.address : ""
            color: Theme.textMuted
            font.family: "monospace"
        }
        Text {
            text: root.device ? "Paired: " + root.device.paired + "   Bonded: " + root.device.bonded : ""
            color: Theme.text
        }
        RowLayout {
            Text {
                text: "Trusted"
                color: Theme.text
                Layout.fillWidth: true
            }
            Toggle {
                checked: root.device ? root.device.trusted : false
                enabled: root.device !== null
                onToggled: value => root.device.trusted = value
            }
        }
        RowLayout {
            Text {
                text: "Blocked"
                color: Theme.text
                Layout.fillWidth: true
            }
            Toggle {
                checked: root.device ? root.device.blocked : false
                enabled: root.device !== null
                onToggled: value => root.device.blocked = value
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Item {
                Layout.fillWidth: true
            }
            Rectangle {
                implicitWidth: forgetText.implicitWidth + 20
                implicitHeight: 34
                radius: 10
                color: confirmArea.containsMouse ? Theme.danger : Theme.alpha(Theme.danger, 0.25)
                Text {
                    id: forgetText
                    anchors.centerIn: parent
                    text: "Forget device"
                    color: Theme.text
                }
                MouseArea {
                    id: confirmArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: confirm.visible = true
                }
            }
        }
        Rectangle {
            id: confirm
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 10
            color: Theme.alpha(Theme.danger, 0.18)
            visible: false
            RowLayout {
                anchors.fill: parent
                anchors.margins: 7
                Text {
                    text: "Forget permanently?"
                    color: Theme.text
                    Layout.fillWidth: true
                }
                IconButton {
                    fallbackText: "No"
                    implicitWidth: 42
                    onClicked: confirm.visible = false
                }
                IconButton {
                    fallbackText: "Yes"
                    implicitWidth: 46
                    accent: Theme.danger
                    onClicked: {
                        root.device.forget();
                        root.closeRequested();
                    }
                }
            }
        }
    }
}
