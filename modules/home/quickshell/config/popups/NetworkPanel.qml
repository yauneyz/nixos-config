import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import ".."
import "../components"
import "../services"

PanelFrame {
    id: root
    title: "Network"
    property string password: ""

    ColumnLayout {
        anchors.fill: parent
        spacing: 9
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                Text {
                    text: NetworkService.name
                    color: Theme.text
                    font.pixelSize: 17
                    font.bold: true
                }
                Text {
                    text: NetworkService.connected ? "Connected" : "Offline"
                    color: NetworkService.connected ? Theme.success : Theme.warning
                }
            }
            Toggle {
                checked: Networking.wifiEnabled
                enabled: Networking.wifiHardwareEnabled
                onToggled: value => Networking.wifiEnabled = value
            }
        }

        Repeater {
            model: Networking.devices
            delegate: ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                visible: modelData.networks !== undefined
                Component.onCompleted: {
                    if (modelData.scannerEnabled !== undefined)
                        modelData.scannerEnabled = true;
                }
                Component.onDestruction: {
                    if (modelData.scannerEnabled !== undefined)
                        modelData.scannerEnabled = false;
                }
                SectionHeader {
                    text: modelData.name || "Wireless"
                }
                Repeater {
                    model: modelData.networks || null
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 48
                        radius: 10
                        color: modelData.connected ? Theme.alpha(Theme.network, 0.17) : Theme.surfaceRaised
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: Theme.text
                                elide: Text.ElideRight
                            }
                            Text {
                                text: modelData.signalStrength !== undefined ? Math.round(modelData.signalStrength * 100) + "%" : ""
                                color: Theme.textMuted
                            }
                            IconButton {
                                icon: modelData.connected ? "network-disconnect-symbolic" : "network-connect-symbolic"
                                fallbackText: modelData.connected ? "×" : "+"
                                onClicked: {
                                    if (modelData.connected)
                                        modelData.disconnect();
                                    else if (modelData.known)
                                        modelData.connect();
                                    else if (modelData.security === WifiSecurityType.Open)
                                        modelData.connect();
                                    else if (root.password) {
                                        modelData.connectWithPsk(root.password);
                                        root.password = "";
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 44
            radius: 10
            color: Theme.surfaceRaised
            TextInput {
                anchors.fill: parent
                anchors.margins: 12
                color: Theme.text
                echoMode: TextInput.Password
                text: root.password
                onTextChanged: root.password = text
                clip: true
                Text {
                    visible: parent.text.length === 0
                    text: "Password for a new secured network"
                    color: Theme.textDisabled
                }
            }
        }
        Item {
            Layout.fillHeight: true
        }
        Text {
            text: "Credentials are passed directly to NetworkManager and cleared after submission."
            color: Theme.textMuted
            font.pixelSize: 10
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }
    Component.onDestruction: password = ""
}
