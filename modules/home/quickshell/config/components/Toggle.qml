import QtQuick
import ".."

Item {
    id: root
    property bool checked: false
    signal toggled(bool checked)
    implicitWidth: 44
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.primary : Theme.surfaceRaised
        opacity: root.enabled ? 1 : 0.45
        Behavior on color {
            ColorAnimation {
                duration: Motion.fast
            }
        }
    }
    Rectangle {
        y: 4
        x: root.checked ? root.width - width - 4 : 4
        width: 18
        height: 18
        radius: 9
        color: Theme.text
        Behavior on x {
            NumberAnimation {
                duration: Motion.fast
                easing.type: Motion.outCubic
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        onClicked: root.toggled(!root.checked)
    }
}
