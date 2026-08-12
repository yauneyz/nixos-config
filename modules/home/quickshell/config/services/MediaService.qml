pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import ".."

Singleton {
    id: root
    readonly property var players: Mpris.players.values
    readonly property var player: choosePlayer()
    readonly property bool available: player !== null

    function choosePlayer() {
        if (ShellState.selectedPlayer && players.indexOf(ShellState.selectedPlayer) >= 0)
            return ShellState.selectedPlayer;
        for (let i = 0; i < players.length; ++i) {
            if (players[i].isPlaying)
                return players[i];
        }
        for (let j = 0; j < players.length; ++j) {
            if (players[j].trackTitle)
                return players[j];
        }
        return players.length > 0 ? players[0] : null;
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.available && (ShellState.activePanel === "media" || (!ShellState.performanceMode && root.player.isPlaying))
        onTriggered: root.player.positionChanged()
    }
}
