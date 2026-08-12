import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../services"

BarCapsule {
    id: root
    required property var barWindow
    required property var shellScreen
    readonly property var player: MediaService.player
    visible: MediaService.available
    implicitWidth: visible ? Math.min(250, mediaRow.implicitWidth + 18) : 0
    opacity: visible ? 1 : 0

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Motion.normal
            easing.type: Motion.outCubic
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: Motion.fast
        }
    }

    RowLayout {
        id: mediaRow
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 7

        Image {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            source: root.player ? root.player.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
        }
        Text {
            Layout.preferredWidth: Math.min(145, implicitWidth)
            text: root.player ? (root.player.trackTitle || root.player.identity) : ""
            color: Theme.text
            elide: Text.ElideRight
            font.pixelSize: 12
        }
        IconButton {
            icon: root.player && root.player.isPlaying ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
            fallbackText: root.player && root.player.isPlaying ? "Ⅱ" : "▶"
            onClicked: if (root.player && root.player.canTogglePlaying)
                root.player.togglePlaying()
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        z: -1
        onClicked: ShellState.togglePanel("media", root.shellScreen, root.barWindow, root)
    }
}
