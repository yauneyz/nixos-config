import QtQuick
import Quickshell
import ".."

Item {
    id: root
    property string icon: ""
    property bool resolveIcon: true
    property string fallbackText: "?"
    property string tooltip: ""
    property color accent: Theme.text
    property bool checked: false
    signal clicked(int button)
    signal wheel(real delta)

    implicitWidth: Metrics.hitTarget
    implicitHeight: Metrics.hitTarget
    opacity: enabled ? 1 : 0.45
    scale: mouse.pressed ? 0.94 : mouse.containsMouse ? 1.05 : 1

    Behavior on scale {
        NumberAnimation {
            duration: Motion.fast
            easing.type: Motion.outCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Metrics.radius - 3
        color: root.checked ? Theme.alpha(root.accent, 0.2) : mouse.containsMouse ? Theme.alpha(Theme.surfaceHover, 0.65) : "transparent"
        Behavior on color {
            ColorAnimation {
                duration: Motion.fast
            }
        }
    }

    Image {
        id: image
        anchors.centerIn: parent
        width: 19
        height: 19
        source: root.icon ? (root.resolveIcon ? Quickshell.iconPath(root.icon, true) : root.icon) : ""
        sourceSize.width: width * 2
        sourceSize.height: height * 2
        visible: status === Image.Ready
    }

    Text {
        anchors.centerIn: parent
        visible: !image.visible
        text: root.fallbackText
        color: root.accent
        font.pixelSize: 17
        font.bold: true
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        enabled: root.enabled
        onClicked: event => root.clicked(event.button)
        onWheel: event => root.wheel(event.angleDelta.y)
    }
}
