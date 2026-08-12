import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../components"
import "../notifications"

PanelWindow {
    id: root
    required property var barWindow
    required property var shellScreen
    readonly property bool active: ShellState.activePanel !== "" && ShellState.targetScreen === shellScreen
    visible: active
    color: "transparent"
    screen: shellScreen
    focusable: true
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "zac-shell-popup"
    WlrLayershell.layer: WlrLayer.Overlay

    readonly property rect sourceRect: ShellState.targetWindow === barWindow && ShellState.targetItem ? barWindow.itemRect(ShellState.targetItem) : Qt.rect(width / 2 - 1, 0, 2, 2)
    readonly property int popupWidth: Math.min(preferredWidth(), width - 24)
    readonly property int popupHeight: Math.min(preferredHeight(), height - Metrics.barHeight - 36)

    function preferredWidth() {
        if (ShellState.activePanel === "bluetooth")
            return 620;
        if (ShellState.activePanel === "notifications")
            return 560;
        if (ShellState.activePanel === "calendar")
            return 500;
        return Metrics.popupWidth;
    }

    function preferredHeight() {
        if (ShellState.activePanel === "calendar")
            return 570;
        if (ShellState.activePanel === "session")
            return 460;
        return Metrics.popupHeight;
    }

    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.closePanel()
    }

    Rectangle {
        id: surface
        x: Math.max(12, Math.min(root.width - width - 12, root.sourceRect.x + root.sourceRect.width / 2 - width / 2))
        y: root.height - root.popupHeight - Metrics.barHeight - Metrics.bottomMargin - 12
        width: root.popupWidth
        height: root.popupHeight
        radius: Metrics.popupRadius
        color: Theme.alpha(Theme.surface, 0.97)
        border.width: 1
        border.color: Theme.outline
        opacity: root.active ? 1 : 0
        scale: root.active ? 1 : 0.96
        transformOrigin: Item.Bottom

        Behavior on x {
            NumberAnimation {
                duration: Motion.normal
                easing.type: Motion.outQuint
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: Motion.normal
                easing.type: Motion.outQuint
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: Motion.normal
                easing.type: Motion.outQuint
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: Motion.normal
                easing.type: Motion.outQuint
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.normal
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Motion.normal
                easing.type: Motion.outQuint
            }
        }

        Loader {
            id: panelLoader
            anchors.fill: parent
            sourceComponent: {
                switch (ShellState.activePanel) {
                case "audio":
                    return audioPanel;
                case "bluetooth":
                    return bluetoothPanel;
                case "network":
                    return networkPanel;
                case "media":
                    return mediaPanel;
                case "calendar":
                    return calendarPanel;
                case "notifications":
                    return notificationPanel;
                case "system":
                    return systemPanel;
                case "power":
                    return powerPanel;
                case "session":
                    return sessionPanel;
                default:
                    return null;
                }
            }
        }
    }

    Keys.onEscapePressed: ShellState.closePanel()

    Component {
        id: audioPanel
        AudioPanel {}
    }
    Component {
        id: bluetoothPanel
        BluetoothPanel {}
    }
    Component {
        id: networkPanel
        NetworkPanel {}
    }
    Component {
        id: mediaPanel
        MediaPanel {}
    }
    Component {
        id: calendarPanel
        CalendarPanel {}
    }
    Component {
        id: notificationPanel
        NotificationCenter {}
    }
    Component {
        id: systemPanel
        SystemPanel {}
    }
    Component {
        id: powerPanel
        PowerPanel {}
    }
    Component {
        id: sessionPanel
        SessionPanel {}
    }
}
