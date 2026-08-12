import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root
    property string title: ""
    default property alias content: body.data

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Metrics.space4
        spacing: Metrics.space3

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: root.title
                color: Theme.text
                font.pixelSize: 21
                font.bold: true
                Layout.fillWidth: true
            }
            IconButton {
                icon: "window-close-symbolic"
                fallbackText: "×"
                onClicked: ShellState.closePanel()
            }
        }

        Item {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
