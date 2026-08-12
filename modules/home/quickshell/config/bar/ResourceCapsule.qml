import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../services"

BarCapsule {
    id: root
    required property var barWindow
    required property var shellScreen
    implicitWidth: resources.implicitWidth + 18

    RowLayout {
        id: resources
        anchors.centerIn: parent
        spacing: 8
        Text {
            text: "CPU " + SystemStatsService.cpu + "%"
            color: Theme.success
            font.pixelSize: 11
            font.family: "monospace"
        }
        Text {
            text: "MEM " + SystemStatsService.memory + "%"
            color: Theme.tertiary
            font.pixelSize: 11
            font.family: "monospace"
        }
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.RightButton)
                Quickshell.execDetached(["ghostty", "--title=float_ghostty", "-e", "btop"]);
            else
                ShellState.togglePanel("system", root.shellScreen, root.barWindow, root);
        }
    }
}
