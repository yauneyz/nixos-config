import QtQuick
import Quickshell
import ".."
import "../components"

IconButton {
    id: root
    required property var trayItem
    required property var barWindow
    icon: trayItem.icon
    fallbackText: "•"
    tooltip: trayItem.tooltipTitle || trayItem.title
    opacity: 0
    property bool entered: false
    implicitWidth: entered ? Metrics.hitTarget : 0

    Component.onCompleted: {
        entered = true;
        insertion.start();
    }
    ParallelAnimation {
        id: insertion
        NumberAnimation {
            target: root
            property: "opacity"
            to: 1
            duration: Motion.fast
        }
    }

    QsMenuAnchor {
        id: menuAnchor
        menu: root.trayItem.menu
        anchor.item: root
        anchor.edges: Edges.Top
        anchor.gravity: Edges.Top
    }

    onClicked: button => {
        if (button === Qt.RightButton || trayItem.onlyMenu) {
            if (trayItem.hasMenu)
                menuAnchor.open();
        } else if (button === Qt.MiddleButton) {
            trayItem.secondaryActivate();
        } else {
            trayItem.activate();
        }
    }
    onWheel: delta => trayItem.scroll(delta, false)

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Motion.normal
            easing.type: Motion.outCubic
        }
    }
}
