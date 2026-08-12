import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../components"
import "../services"

Rectangle {
    id: root
    required property var device
    property string operation: ""
    property string error: ""
    signal detailsRequested(var device)
    implicitHeight: 66
    radius: 12
    color: device.connected ? Theme.alpha(Theme.bluetooth, 0.15) : Theme.surfaceRaised
    border.width: device.connected ? 1 : 0
    border.color: Theme.bluetooth

    function connectDevice() {
        error = "";
        operation = device.paired ? "Connecting…" : "Pairing…";
        operationTimeout.restart();
        if (device.paired)
            device.connect();
        else
            device.pair();
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8
        Image {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            source: Quickshell.iconPath(BluetoothService.iconFor(root.device), true)
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text {
                Layout.fillWidth: true
                text: root.device.name || root.device.deviceName || root.device.address
                color: Theme.text
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                text: root.error || root.operation || (root.device.connected ? "Connected" : root.device.paired ? "Paired" : "Available")
                color: root.error ? Theme.danger : Theme.textMuted
                font.pixelSize: 11
            }
        }
        Text {
            visible: root.device.batteryAvailable
            text: Math.round(root.device.battery * 100) + "%"
            color: root.device.battery < 0.15 ? Theme.danger : Theme.battery
        }
        IconButton {
            enabled: root.operation === ""
            icon: root.device.connected ? "network-disconnect-symbolic" : "network-connect-symbolic"
            fallbackText: root.device.connected ? "×" : "+"
            accent: root.device.connected ? Theme.danger : Theme.success
            onClicked: {
                root.operation = root.device.connected ? "Disconnecting…" : (root.device.paired ? "Connecting…" : "Pairing…");
                operationTimeout.restart();
                if (root.device.connected)
                    root.device.disconnect();
                else
                    root.connectDevice();
            }
        }
        IconButton {
            icon: "emblem-system-symbolic"
            fallbackText: "⋯"
            onClicked: root.detailsRequested(root.device)
        }
    }

    Connections {
        target: root.device
        function onConnectedChanged() {
            root.operation = "";
            operationTimeout.stop();
        }
        function onPairedChanged() {
            if (root.device.paired && !root.device.connected) {
                root.operation = "Connecting…";
                root.device.connect();
            }
        }
    }
    Timer {
        id: operationTimeout
        interval: 20000
        onTriggered: {
            root.operation = "";
            root.error = "Operation timed out";
        }
    }
}
