import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import ".."
import "../components"
import "../services"

PanelFrame {
    title: "Power"
    ColumnLayout {
        anchors.fill: parent
        spacing: 14
        Text {
            text: PowerService.available ? PowerService.percentage + "%" : "No battery detected"
            color: Theme.battery
            font.pixelSize: 48
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }
        Text {
            text: PowerService.available ? UPowerDeviceState.toString(PowerService.battery.state) : "Desktop power"
            color: Theme.textMuted
            Layout.alignment: Qt.AlignHCenter
        }
        Text {
            visible: PowerService.available && PowerService.battery.healthSupported
            text: "Battery health: " + Math.round(PowerService.battery.healthPercentage) + "%"
            color: Theme.text
            Layout.alignment: Qt.AlignHCenter
        }
        SectionHeader {
            text: "Power profile"
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Repeater {
                model: [
                    {
                        label: "Saver",
                        profile: PowerProfile.PowerSaver
                    },
                    {
                        label: "Balanced",
                        profile: PowerProfile.Balanced
                    },
                    {
                        label: "Performance",
                        profile: PowerProfile.Performance
                    }
                ]
                delegate: Rectangle {
                    required property var modelData
                    implicitWidth: profileLabel.implicitWidth + 22
                    implicitHeight: 36
                    radius: 10
                    opacity: modelData.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile ? 1 : 0.4
                    color: PowerProfiles.profile === modelData.profile ? Theme.primary : Theme.surfaceRaised
                    Text {
                        id: profileLabel
                        anchors.centerIn: parent
                        text: modelData.label
                        color: PowerProfiles.profile === modelData.profile ? Theme.background : Theme.text
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: modelData.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                        onClicked: PowerProfiles.profile = modelData.profile
                    }
                }
            }
        }
        Item {
            Layout.fillHeight: true
        }
        Text {
            text: "Power profile controls remain available through the system power settings."
            color: Theme.textMuted
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }
}
