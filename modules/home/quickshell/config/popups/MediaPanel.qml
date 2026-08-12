import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../components"
import "../services"

PanelFrame {
    id: root
    title: "Now playing"
    readonly property var player: MediaService.player

    ColumnLayout {
        anchors.fill: parent
        spacing: 12
        Image {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 240
            Layout.preferredHeight: 240
            source: root.player ? root.player.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            Rectangle {
                anchors.fill: parent
                radius: 18
                color: Theme.surfaceRaised
                z: -1
            }
        }
        Text {
            Layout.fillWidth: true
            text: root.player ? (root.player.trackTitle || "Unknown track") : "No media player"
            color: Theme.text
            font.pixelSize: 20
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            text: root.player ? (root.player.trackArtist || root.player.identity) : ""
            color: Theme.textMuted
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
        Slider {
            Layout.fillWidth: true
            enabled: root.player && root.player.canSeek && root.player.lengthSupported
            value: enabled && root.player.length > 0 ? root.player.position / root.player.length : 0
            onMoved: value => {
                if (enabled)
                    root.player.position = value * root.player.length;
            }
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            IconButton {
                icon: "media-skip-backward-symbolic"
                fallbackText: "|◀"
                enabled: root.player && root.player.canGoPrevious
                onClicked: root.player.previous()
            }
            IconButton {
                icon: root.player && root.player.isPlaying ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
                fallbackText: root.player && root.player.isPlaying ? "Ⅱ" : "▶"
                enabled: root.player && root.player.canTogglePlaying
                onClicked: root.player.togglePlaying()
            }
            IconButton {
                icon: "media-skip-forward-symbolic"
                fallbackText: "▶|"
                enabled: root.player && root.player.canGoNext
                onClicked: root.player.next()
            }
            IconButton {
                icon: "media-playback-stop-symbolic"
                fallbackText: "■"
                enabled: root.player && root.player.canControl
                onClicked: root.player.stop()
            }
        }
        SectionHeader {
            text: "Players"
        }
        Repeater {
            model: MediaService.players
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 42
                radius: 10
                color: modelData === root.player ? Theme.alpha(Theme.primary, 0.18) : Theme.surfaceRaised
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.identity
                    color: Theme.text
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: ShellState.selectedPlayer = modelData
                }
            }
        }
        Item {
            Layout.fillHeight: true
        }
        RowLayout {
            Layout.fillWidth: true
            Item {
                Layout.fillWidth: true
            }
            IconButton {
                icon: "go-up-symbolic"
                fallbackText: "Open"
                implicitWidth: 54
                enabled: root.player && root.player.canRaise
                onClicked: root.player.raise()
            }
            IconButton {
                fallbackText: "EQ"
                onClicked: Quickshell.execDetached(["easyeffects"])
            }
        }
    }
}
