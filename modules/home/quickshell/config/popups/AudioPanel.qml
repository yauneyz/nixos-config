import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import ".."
import "../components"
import "../services"

PanelFrame {
    id: root
    title: "Audio"

    ColumnLayout {
        anchors.fill: parent
        spacing: Metrics.space3

        SectionHeader {
            text: "Master output"
        }
        RowLayout {
            Layout.fillWidth: true
            IconButton {
                icon: AudioService.muted ? "audio-volume-muted-symbolic" : "audio-volume-high-symbolic"
                fallbackText: AudioService.muted ? "󰖁" : ""
                accent: Theme.audio
                onClicked: AudioService.changeVolume("mute")
            }
            Slider {
                Layout.fillWidth: true
                value: AudioService.volume
                accent: Theme.audio
                onMoved: value => AudioService.setVolume(value)
            }
            Text {
                text: AudioService.available ? AudioService.percent + "%" : "--"
                color: Theme.text
                font.family: "monospace"
            }
        }
        Text {
            text: AudioService.sink ? (AudioService.sink.description || AudioService.sink.name) : "No audio device"
            color: Theme.textMuted
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        SectionHeader {
            text: "Output devices"
        }
        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(150, contentHeight)
            clip: true
            spacing: 5
            model: ScriptModel {
                values: Pipewire.nodes.values.filter(node => node.ready && node.isSink && !node.isStream)
            }
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                height: 42
                radius: 10
                color: modelData === AudioService.sink ? Theme.alpha(Theme.audio, 0.18) : Theme.surfaceRaised
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 24
                    text: modelData.description || modelData.name
                    color: Theme.text
                    elide: Text.ElideRight
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: Pipewire.preferredDefaultAudioSink = modelData
                }
            }
        }

        SectionHeader {
            text: "Microphone"
        }
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: AudioService.source ? (AudioService.source.description || AudioService.source.name) : "No input device"
                color: Theme.text
            }
            IconButton {
                enabled: AudioService.source !== null
                icon: AudioService.source && AudioService.source.audio.muted ? "microphone-sensitivity-muted-symbolic" : "audio-input-microphone-symbolic"
                fallbackText: ""
                accent: Theme.danger
                onClicked: if (AudioService.source)
                    AudioService.source.audio.muted = !AudioService.source.audio.muted
            }
        }
        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(96, contentHeight)
            clip: true
            spacing: 5
            model: ScriptModel {
                values: Pipewire.nodes.values.filter(node => node.ready && !node.isSink && !node.isStream)
            }
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                height: 38
                radius: 9
                color: modelData === AudioService.source ? Theme.alpha(Theme.danger, 0.14) : Theme.surfaceRaised
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 24
                    text: modelData.description || modelData.name
                    color: Theme.text
                    elide: Text.ElideRight
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: Pipewire.preferredDefaultAudioSource = modelData
                }
            }
        }

        SectionHeader {
            text: "Application streams"
        }
        ListView {
            id: streams
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 5
            model: ScriptModel {
                values: Pipewire.nodes.values.filter(node => node.ready && node.isStream && node.isSink)
            }
            delegate: Rectangle {
                id: streamRow
                required property var modelData
                width: ListView.view.width
                height: 68
                radius: 10
                color: Theme.surfaceRaised
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    width: parent.width - 82
                    text: modelData.description || modelData.name
                    color: Theme.text
                    elide: Text.ElideRight
                }
                Slider {
                    anchors.left: parent.left
                    anchors.right: muteButton.left
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    value: streamRow.modelData.audio ? streamRow.modelData.audio.volume : 0
                    onMoved: value => {
                        if (streamRow.modelData.audio)
                            streamRow.modelData.audio.volume = value;
                    }
                }
                IconButton {
                    id: muteButton
                    anchors.right: parent.right
                    anchors.rightMargin: 7
                    anchors.verticalCenter: parent.verticalCenter
                    icon: streamRow.modelData.audio && streamRow.modelData.audio.muted ? "audio-volume-muted-symbolic" : "audio-volume-high-symbolic"
                    fallbackText: streamRow.modelData.audio && streamRow.modelData.audio.muted ? "󰖁" : ""
                    enabled: streamRow.modelData.audio !== null && streamRow.modelData.audio !== undefined
                    onClicked: {
                        if (streamRow.modelData.audio)
                            streamRow.modelData.audio.muted = !streamRow.modelData.audio.muted;
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Item {
                Layout.fillWidth: true
            }
            IconButton {
                icon: "multimedia-volume-control-symbolic"
                fallbackText: "EQ"
                onClicked: Quickshell.execDetached(["easyeffects"])
            }
            IconButton {
                icon: "multimedia-volume-control-symbolic"
                fallbackText: "PA"
                onClicked: Quickshell.execDetached(["pavucontrol"])
            }
        }
    }

    PwObjectTracker {
        objects: [AudioService.sink, AudioService.source].concat(Pipewire.nodes.values.filter(node => ShellState.activePanel === "audio" && node.isStream))
    }
}
