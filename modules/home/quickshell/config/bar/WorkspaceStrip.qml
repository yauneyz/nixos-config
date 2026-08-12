import QtQuick
import Quickshell
import Quickshell.Hyprland
import ".."

BarCapsule {
    id: root
    required property var shellScreen
    readonly property var monitor: Hyprland.monitorFor(shellScreen)
    readonly property var preferred: RuntimeConfig.preferredWorkspaces[shellScreen.name] || RuntimeConfig.preferredWorkspaces["*"] || []
    readonly property var runtimeIds: [...Hyprland.workspaces.values].filter(ws => ws.id > 0 && ws.monitor === monitor).map(ws => ws.id)
    readonly property var ids: Array.from(new Set(preferred.concat(runtimeIds))).sort((a, b) => a - b)
    readonly property int activeIndex: monitor && monitor.activeWorkspace ? ids.indexOf(monitor.activeWorkspace.id) : -1
    property real indicatorLeft: 6
    property real indicatorRight: 42
    property int previousActiveIndex: -1

    implicitWidth: workspaceRow.width + 12

    function animateIndicator() {
        if (activeIndex < 0)
            return;
        const nextLeft = 6 + activeIndex * 38;
        const nextRight = nextLeft + 36;
        if (previousActiveIndex < 0 || ShellState.reducedMotion) {
            indicatorLeft = nextLeft;
            indicatorRight = nextRight;
        } else {
            const movingRight = activeIndex > previousActiveIndex;
            leftAnimation.stop();
            rightAnimation.stop();
            leftAnimation.to = nextLeft;
            rightAnimation.to = nextRight;
            leftAnimation.duration = movingRight ? Motion.normal : Motion.fast;
            rightAnimation.duration = movingRight ? Motion.fast : Motion.normal;
            leftAnimation.start();
            rightAnimation.start();
        }
        previousActiveIndex = activeIndex;
    }

    onActiveIndexChanged: animateIndicator()
    Component.onCompleted: animateIndicator()

    NumberAnimation {
        id: leftAnimation
        target: root
        property: "indicatorLeft"
        easing.type: Motion.outQuint
    }
    NumberAnimation {
        id: rightAnimation
        target: root
        property: "indicatorRight"
        easing.type: Motion.outQuint
    }

    Rectangle {
        id: indicator
        x: root.indicatorLeft
        y: 4
        width: root.activeIndex >= 0 ? Math.max(0, root.indicatorRight - root.indicatorLeft) : 0
        height: parent.height - 8
        radius: 10
        color: Theme.workspace
        opacity: root.activeIndex >= 0 ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.fast
            }
        }
    }

    Row {
        id: workspaceRow
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.ids
            WorkspaceButton {
                required property var modelData
                workspaceId: Number(modelData)
                workspace: {
                    const all = Hyprland.workspaces.values;
                    for (let i = 0; i < all.length; ++i) {
                        if (all[i].id === workspaceId && all[i].monitor === root.monitor)
                            return all[i];
                    }
                    return null;
                }
            }
        }
    }
}
