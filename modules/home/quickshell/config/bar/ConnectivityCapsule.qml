import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../services"

BarCapsule {
    id: root
    required property var barWindow
    required property var shellScreen
    implicitWidth: controls.implicitWidth + 10

    RowLayout {
        id: controls
        anchors.centerIn: parent
        spacing: 2

        IconButton {
            icon: NetworkService.connected ? "network-wireless-signal-excellent-symbolic" : "network-wireless-offline-symbolic"
            fallbackText: NetworkService.connected ? "󰖩" : "󰖪"
            accent: Theme.network
            onClicked: ShellState.togglePanel("network", root.shellScreen, root.barWindow, this)
        }
        IconButton {
            icon: BluetoothService.enabled ? "bluetooth-active-symbolic" : "bluetooth-disabled-symbolic"
            fallbackText: ""
            accent: Theme.bluetooth
            onClicked: ShellState.togglePanel("bluetooth", root.shellScreen, root.barWindow, this)
            Text {
                visible: BluetoothService.connectedCount > 0
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 1
                text: BluetoothService.connectedCount
                color: Theme.background
                font.pixelSize: 9
                font.bold: true
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    radius: 7
                    color: Theme.bluetooth
                    z: -1
                }
            }
        }
        IconButton {
            icon: AudioService.muted ? "audio-volume-muted-symbolic" : AudioService.percent > 55 ? "audio-volume-high-symbolic" : "audio-volume-medium-symbolic"
            fallbackText: AudioService.muted ? "󰖁" : ""
            accent: Theme.audio
            onClicked: button => {
                if (button === Qt.LeftButton)
                    AudioService.changeVolume("mute");
                else
                    ShellState.togglePanel("audio", root.shellScreen, root.barWindow, this);
            }
            onWheel: delta => AudioService.changeVolume(delta > 0 ? "0.02" : "-0.02")
        }
        Text {
            text: AudioService.available ? AudioService.percent + "%" : "--"
            color: Theme.text
            font.pixelSize: 11
            font.family: "monospace"
        }
        RowLayout {
            visible: PowerService.available
            spacing: 3
            IconButton {
                icon: PowerService.charging ? "battery-good-charging-symbolic" : "battery-good-symbolic"
                fallbackText: PowerService.charging ? "" : ""
                accent: PowerService.percentage < 10 ? Theme.danger : Theme.battery
                onClicked: ShellState.togglePanel("power", root.shellScreen, root.barWindow, this)
            }
            Text {
                text: PowerService.percentage + "%"
                color: Theme.text
                font.pixelSize: 11
            }
        }
    }
}
