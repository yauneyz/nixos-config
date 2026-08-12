import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../components"
import "../popups"

PanelWindow {
    id: root
    required property var modelData
    screen: modelData
    color: "transparent"
    implicitHeight: Metrics.barHeight + Metrics.bottomMargin
    exclusiveZone: implicitHeight
    anchors {
        left: true
        right: true
        bottom: true
    }
    WlrLayershell.namespace: "zac-shell-bar"
    WlrLayershell.layer: WlrLayer.Top

    property bool compact: width < 1500

    Item {
        id: barArea
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.bottomMargin: Metrics.bottomMargin

        RowLayout {
            id: leftGroup
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: Metrics.capsuleHeight
            spacing: 7
            opacity: 0
            transform: Translate {
                id: leftTravel
                y: Motion.travel
            }

            LauncherCapsule {
                barWindow: root
                shellScreen: root.screen
            }
            BarCapsule {
                visible: tray.implicitWidth > 0
                implicitWidth: tray.implicitWidth + 8
                Tray {
                    id: tray
                    anchors.centerIn: parent
                    barWindow: root
                }
            }
        }

        WorkspaceStrip {
            id: workspaces
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            shellScreen: root.screen
            opacity: 0
            transform: Translate {
                id: workspaceTravel
                y: Motion.travel
            }
        }

        RowLayout {
            id: rightGroup
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: Metrics.capsuleHeight
            spacing: 7
            opacity: 0
            transform: Translate {
                id: rightTravel
                x: Motion.travel
            }

            MediaCapsule {
                visible: !root.compact && implicitWidth > 0
                barWindow: root
                shellScreen: root.screen
            }
            ResourceCapsule {
                visible: !root.compact
                barWindow: root
                shellScreen: root.screen
            }
            ConnectivityCapsule {
                barWindow: root
                shellScreen: root.screen
            }
            ClockCapsule {
                barWindow: root
                shellScreen: root.screen
            }
        }

        Component.onCompleted: entrance.start()
        SequentialAnimation {
            id: entrance
            ParallelAnimation {
                NumberAnimation {
                    target: leftGroup
                    property: "opacity"
                    to: 1
                    duration: Motion.expressive
                }
                NumberAnimation {
                    target: leftTravel
                    property: "y"
                    to: 0
                    duration: Motion.expressive
                    easing.type: Motion.outQuint
                }
            }
            PauseAnimation {
                duration: ShellState.reducedMotion ? 0 : 45
            }
            ParallelAnimation {
                NumberAnimation {
                    target: workspaces
                    property: "opacity"
                    to: 1
                    duration: Motion.normal
                }
                NumberAnimation {
                    target: workspaceTravel
                    property: "y"
                    to: 0
                    duration: Motion.normal
                    easing.type: Motion.outQuint
                }
                NumberAnimation {
                    target: rightGroup
                    property: "opacity"
                    to: 1
                    duration: Motion.expressive
                }
                NumberAnimation {
                    target: rightTravel
                    property: "x"
                    to: 0
                    duration: Motion.expressive
                    easing.type: Motion.outQuint
                }
            }
        }
    }

    mask: Region {
        item: barArea
    }

    PopupHost {
        barWindow: root
        shellScreen: root.screen
    }
}
