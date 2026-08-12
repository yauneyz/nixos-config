import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import ".."
import "../components"

Rectangle {
    id: root
    required property var notification
    signal dismissRequested
    implicitHeight: cardColumn.implicitHeight + 20
    radius: 14
    color: Theme.surfaceRaised
    border.width: notification.urgency === NotificationUrgency.Critical ? 1 : 0
    border.color: Theme.danger

    ColumnLayout {
        id: cardColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 5
        RowLayout {
            Layout.fillWidth: true
            Image {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                source: root.notification.appIcon ? Quickshell.iconPath(root.notification.appIcon, true) : ""
                visible: status === Image.Ready
            }
            Text {
                Layout.fillWidth: true
                text: root.notification.appName || "Notification"
                color: Theme.textMuted
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            IconButton {
                implicitWidth: 28
                implicitHeight: 28
                fallbackText: "×"
                onClicked: root.dismissRequested()
            }
        }
        Text {
            Layout.fillWidth: true
            text: root.notification.summary
            color: Theme.text
            font.bold: true
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
        }
        Text {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.notification.body
            color: Theme.textMuted
            wrapMode: Text.Wrap
            maximumLineCount: 5
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }
        RowLayout {
            visible: root.notification.actions.length > 0
            Layout.fillWidth: true
            Repeater {
                model: root.notification.actions
                delegate: Rectangle {
                    required property var modelData
                    implicitWidth: actionText.implicitWidth + 18
                    implicitHeight: 30
                    radius: 9
                    color: actionMouse.containsMouse ? Theme.alpha(Theme.primary, 0.3) : Theme.alpha(Theme.primary, 0.15)
                    Text {
                        id: actionText
                        anchors.centerIn: parent
                        text: modelData.text
                        color: Theme.text
                        font.pixelSize: 11
                    }
                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: modelData.invoke()
                    }
                }
            }
        }
    }
}
