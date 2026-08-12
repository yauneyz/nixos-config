import QtQuick
import ".."

Item {
    id: root
    property real value: 0
    property color accent: Theme.primary
    signal moved(real value)

    implicitHeight: Metrics.hitTarget

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.surfaceRaised

        Rectangle {
            width: Math.max(6, parent.width * Math.max(0, Math.min(1, root.value)))
            height: parent.height
            radius: parent.radius
            color: root.accent
            Behavior on width {
                NumberAnimation {
                    duration: Motion.instant
                    easing.type: Motion.outCubic
                }
            }
        }
    }

    Rectangle {
        x: Math.max(0, Math.min(parent.width - width, root.value * parent.width - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        radius: 8
        color: Theme.text
        border.color: root.accent
        border.width: 3
    }

    MouseArea {
        anchors.fill: parent
        onPressed: event => root.moved(event.x / width)
        onPositionChanged: event => {
            if (pressed)
                root.moved(event.x / width);
        }
    }
}
