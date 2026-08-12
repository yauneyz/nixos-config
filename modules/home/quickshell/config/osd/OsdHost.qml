import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: root
    required property var modelData
    screen: modelData
    color: "transparent"
    visible: false
    implicitWidth: 310
    implicitHeight: 76
    anchors.bottom: true
    margins.bottom: Metrics.barHeight + 38
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "zac-shell-osd"
    WlrLayershell.layer: WlrLayer.Overlay

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: Theme.alpha(Theme.surface, 0.96)
        border.width: 1
        border.color: Theme.outline
        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12
            Text {
                text: root.iconFor(ShellState.osdKind)
                color: Theme.primary
                font.pixelSize: 24
            }
            ColumnLayout {
                Layout.fillWidth: true
                Text {
                    text: ShellState.osdLabel
                    color: Theme.text
                    font.bold: true
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 6
                    visible: ShellState.osdValue >= 0
                    radius: 3
                    color: Theme.surfaceRaised
                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, ShellState.osdValue))
                        height: parent.height
                        radius: parent.radius
                        color: Theme.primary
                        Behavior on width {
                            NumberAnimation {
                                duration: Motion.instant
                            }
                        }
                    }
                }
            }
        }
    }

    function iconFor(kind) {
        if (kind === "brightness")
            return "☀";
        if (kind === "volume")
            return ShellState.osdLabel === "Muted" ? "󰖁" : "";
        if (kind === "microphone")
            return "";
        if (kind === "caps")
            return "⇪";
        if (kind === "num")
            return "№";
        if (kind === "scroll")
            return "⇳";
        if (kind === "bluetooth")
            return "";
        return "•";
    }

    Connections {
        target: ShellState
        function onOsdSerialChanged() {
            if (ShellState.osdScreen === root.screen) {
                root.visible = true;
                hideTimer.restart();
            }
        }
    }
    Timer {
        id: hideTimer
        interval: 1400
        onTriggered: root.visible = false
    }
}
