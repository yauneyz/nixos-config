import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../components"

PanelFrame {
    id: root
    title: "Calendar"
    property date shownMonth: new Date(new Date().getFullYear(), new Date().getMonth(), 1)
    readonly property date today: new Date()

    function cells() {
        const first = new Date(shownMonth.getFullYear(), shownMonth.getMonth(), 1);
        const start = new Date(first);
        start.setDate(first.getDate() - ((first.getDay() + 6) % 7));
        const result = [];
        for (let i = 0; i < 42; ++i) {
            const d = new Date(start);
            d.setDate(start.getDate() + i);
            result.push(d);
        }
        return result;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        Text {
            Layout.fillWidth: true
            text: Qt.formatDateTime(new Date(), "dddd, d MMMM yyyy")
            color: Theme.textMuted
            horizontalAlignment: Text.AlignHCenter
        }
        Text {
            Layout.fillWidth: true
            text: Qt.formatDateTime(new Date(), "HH:mm")
            color: Theme.primary
            font.pixelSize: 48
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
        }
        RowLayout {
            Layout.fillWidth: true
            IconButton {
                fallbackText: "‹"
                onClicked: root.shownMonth = new Date(root.shownMonth.getFullYear(), root.shownMonth.getMonth() - 1, 1)
            }
            Text {
                Layout.fillWidth: true
                text: Qt.formatDateTime(root.shownMonth, "MMMM yyyy")
                color: Theme.text
                font.pixelSize: 18
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }
            IconButton {
                fallbackText: "›"
                onClicked: root.shownMonth = new Date(root.shownMonth.getFullYear(), root.shownMonth.getMonth() + 1, 1)
            }
        }
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: 4
            columnSpacing: 4
            Repeater {
                model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                Text {
                    required property var modelData
                    Layout.fillWidth: true
                    text: modelData
                    color: Theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 11
                }
            }
            Repeater {
                model: root.cells()
                Rectangle {
                    required property var modelData
                    readonly property bool isToday: modelData.toDateString() === root.today.toDateString()
                    Layout.fillWidth: true
                    implicitHeight: 42
                    radius: 10
                    color: isToday ? Theme.primary : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData.getDate()
                        color: parent.isToday ? Theme.background : parent.modelData.getMonth() === root.shownMonth.getMonth() ? Theme.text : Theme.textDisabled
                        font.bold: parent.isToday
                    }
                }
            }
        }
        Item {
            Layout.fillHeight: true
        }
    }
}
