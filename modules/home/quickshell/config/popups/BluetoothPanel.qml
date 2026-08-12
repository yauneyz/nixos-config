import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import ".."
import "../bluetooth"
import "../components"
import "../services"

PanelFrame {
    id: root
    title: "Bluetooth"
    property var selectedDevice: null
    readonly property var adapter: BluetoothService.adapter

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                Text {
                    text: root.adapter ? root.adapter.name : "No Bluetooth adapter"
                    color: Theme.text
                    font.bold: true
                }
                Text {
                    text: BluetoothService.connectedCount + " connected"
                    color: Theme.textMuted
                    font.pixelSize: 11
                }
            }
            Toggle {
                checked: BluetoothService.enabled
                enabled: BluetoothService.available
                onToggled: BluetoothService.togglePower()
            }
            IconButton {
                icon: "view-refresh-symbolic"
                fallbackText: "↻"
                checked: BluetoothService.discovering
                enabled: BluetoothService.enabled
                onClicked: BluetoothService.toggleScan()
                RotationAnimation on rotation {
                    running: BluetoothService.discovering && !ShellState.reducedMotion && !ShellState.performanceMode
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: Motion.ambient
                }
            }
            IconButton {
                icon: "preferences-system-bluetooth-symbolic"
                fallbackText: "UI"
                onClicked: Quickshell.execDetached(["overskride"])
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: BluetoothService.adapters.length > 1
            Repeater {
                model: Bluetooth.adapters
                delegate: Rectangle {
                    required property var modelData
                    implicitWidth: adapterLabel.implicitWidth + 20
                    implicitHeight: 32
                    radius: 9
                    color: modelData === root.adapter ? Theme.primary : Theme.surfaceRaised
                    Text {
                        id: adapterLabel
                        anchors.centerIn: parent
                        text: modelData.name || modelData.adapterId
                        color: modelData === root.adapter ? Theme.background : Theme.text
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: BluetoothService.selectedAdapter = modelData
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 52
            radius: 12
            visible: !BluetoothService.available
            color: Theme.alpha(Theme.warning, 0.14)
            Text {
                anchors.centerIn: parent
                text: "No adapter detected. Open Overskride for diagnostics."
                color: Theme.warning
            }
        }

        SectionHeader {
            text: "Connected devices"
            visible: BluetoothService.connectedCount > 0
        }
        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: BluetoothService.connectedCount > 0 ? Math.min(150, contentHeight) : 0
            visible: height > 0
            clip: true
            spacing: 6
            model: Bluetooth.devices
            delegate: DeviceCard {
                required property var modelData
                width: ListView.view.width
                device: modelData
                onDetailsRequested: device => root.selectedDevice = device
            }
        }

        SectionHeader {
            text: "Paired devices"
            visible: BluetoothService.available
        }
        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(145, contentHeight)
            clip: true
            spacing: 6
            model: ScriptModel {
                values: root.adapter ? root.adapter.devices.values.filter(device => device.paired && !device.connected) : []
            }
            delegate: DeviceCard {
                required property var modelData
                width: ListView.view.width
                device: modelData
                onDetailsRequested: device => root.selectedDevice = device
            }
        }

        SectionHeader {
            text: BluetoothService.discovering ? "Available · scanning" : "Available"
            visible: BluetoothService.enabled
        }
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: ScriptModel {
                values: root.adapter ? root.adapter.devices.values.filter(device => !device.paired && !device.connected) : []
            }
            delegate: DeviceCard {
                required property var modelData
                width: ListView.view.width
                device: modelData
                onDetailsRequested: device => root.selectedDevice = device
            }
        }

        DeviceDetails {
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? implicitHeight : 0
            implicitHeight: 230
            device: root.selectedDevice
            onCloseRequested: root.selectedDevice = null
        }
    }
}
