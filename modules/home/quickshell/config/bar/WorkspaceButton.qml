import QtQuick
import Quickshell.Hyprland
import ".."

Item {
    id: root
    required property int workspaceId
    property var workspace: null
    readonly property bool active: workspace && workspace.active
    readonly property bool focused: workspace && workspace.focused
    readonly property bool occupied: workspace && workspace.toplevels.values.length > 0
    readonly property bool urgent: workspace && workspace.urgent

    implicitWidth: 36
    implicitHeight: 34

    function labelFor(id) {
        const names = {
            11: "w",
            12: "y",
            13: "u",
            14: "o",
            15: "p"
        };
        return names[id] || String(id);
    }

    Text {
        anchors.centerIn: parent
        text: root.labelFor(root.workspaceId)
        color: root.urgent ? Theme.danger : root.focused ? Theme.background : root.occupied ? Theme.text : Theme.textMuted
        font.bold: root.active || root.occupied
        font.pixelSize: 13
        z: 2
    }

    Rectangle {
        visible: root.workspace && root.workspace.hasFullscreen
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 5
        width: 5
        height: 5
        radius: 3
        color: Theme.warning
        z: 3
    }

    SequentialAnimation on opacity {
        running: root.urgent && !ShellState.reducedMotion
        loops: 2
        NumberAnimation {
            to: 0.45
            duration: 250
        }
        NumberAnimation {
            to: 1
            duration: 250
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (root.workspace)
                root.workspace.activate();
            else
                Hyprland.dispatch("workspace " + root.workspaceId);
        }
    }
}
