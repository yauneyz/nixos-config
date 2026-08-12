import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../popups"
import "../services"

PanelFrame {
    id: root
    title: "Notifications"
    property string search: ""
    readonly property var filteredHistory: NotificationService.history.filter(notification => {
        const needle = search.toLowerCase();
        return needle.length === 0 || (notification.appName + " " + notification.summary + " " + notification.body).toLowerCase().indexOf(needle) >= 0;
    })
    ColumnLayout {
        anchors.fill: parent
        spacing: 9
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Do not disturb"
                color: Theme.text
                Layout.fillWidth: true
            }
            Toggle {
                checked: ShellState.dnd
                onToggled: value => ShellState.dnd = value
            }
            IconButton {
                icon: "edit-clear-all-symbolic"
                fallbackText: "Clear"
                implicitWidth: 52
                enabled: NotificationService.count > 0
                onClicked: NotificationService.clearAll()
            }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 40
            radius: 10
            color: Theme.surfaceRaised
            TextInput {
                anchors.fill: parent
                anchors.margins: 10
                text: root.search
                color: Theme.text
                clip: true
                onTextChanged: root.search = text
                Text {
                    visible: parent.text.length === 0
                    text: "Search notifications"
                    color: Theme.textDisabled
                }
            }
        }
        Text {
            visible: NotificationService.count === 0
            text: "You’re all caught up"
            color: Theme.textMuted
            font.pixelSize: 18
            Layout.alignment: Qt.AlignCenter
            Layout.fillHeight: true
        }
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: NotificationService.count > 0
            clip: true
            spacing: 8
            model: root.filteredHistory
            delegate: NotificationCard {
                required property var modelData
                width: ListView.view.width
                notification: modelData
                onDismissRequested: NotificationService.remove(notification)
            }
        }
    }
    Component.onDestruction: search = ""
}
