import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../components"
import "../services"

PanelFrame {
    title: "System"
    ColumnLayout {
        anchors.fill: parent
        spacing: 14
        Repeater {
            model: [
                {
                    label: "CPU",
                    value: SystemStatsService.cpu,
                    color: Theme.success
                },
                {
                    label: "Memory",
                    value: SystemStatsService.memory,
                    color: Theme.tertiary
                },
                {
                    label: "Disk /",
                    value: SystemStatsService.disk,
                    color: Theme.warning
                }
            ]
            delegate: ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: modelData.label
                        color: Theme.text
                        Layout.fillWidth: true
                    }
                    Text {
                        text: modelData.value + "%"
                        color: modelData.color
                        font.family: "monospace"
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 8
                    radius: 4
                    color: Theme.surfaceRaised
                    Rectangle {
                        width: parent.width * modelData.value / 100
                        height: parent.height
                        radius: parent.radius
                        color: modelData.color
                        Behavior on width {
                            NumberAnimation {
                                duration: Motion.normal
                            }
                        }
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Reduced motion"
                color: Theme.text
                Layout.fillWidth: true
            }
            Toggle {
                checked: ShellState.reducedMotion
                onToggled: value => ShellState.reducedMotion = value
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Performance mode"
                color: Theme.text
                Layout.fillWidth: true
            }
            Toggle {
                checked: ShellState.performanceMode
                onToggled: value => ShellState.performanceMode = value
            }
        }
        Item {
            Layout.fillHeight: true
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            IconButton {
                fallbackText: "btop"
                implicitWidth: 58
                onClicked: Quickshell.execDetached(["ghostty", "--title=float_ghostty", "-e", "btop"])
            }
            IconButton {
                fallbackText: "diag"
                implicitWidth: 58
                onClicked: Quickshell.execDetached(["ghostty", "-e", "zac-shell-diagnostics"])
            }
        }
    }
}
