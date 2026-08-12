pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import ".."

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool available: sink !== null && sink.audio !== null
    readonly property real volume: available ? sink.audio.volume : 0
    readonly property bool muted: available ? sink.audio.muted : true
    readonly property int percent: Math.round(volume * 100)

    function changeVolume(change) {
        if (!available) {
            ShellState.showOsd("volume", -1, "No audio device");
            return;
        }

        if (change === "mute") {
            sink.audio.muted = !sink.audio.muted;
        } else {
            const delta = Number(change);
            if (!isNaN(delta))
                sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + delta));
        }
        ShellState.showOsd("volume", sink.audio.volume, sink.audio.muted ? "Muted" : Math.round(sink.audio.volume * 100) + "%");
    }

    function setVolume(value) {
        if (!available)
            return;
        sink.audio.volume = Math.max(0, Math.min(1, value));
        ShellState.showOsd("volume", sink.audio.volume, Math.round(sink.audio.volume * 100) + "%");
    }

    function changeMic(change) {
        if (!source || !source.audio) {
            ShellState.showOsd("microphone", -1, "No input device");
            return;
        }
        if (change === "mute")
            source.audio.muted = !source.audio.muted;
        else {
            const delta = Number(change);
            if (!isNaN(delta))
                source.audio.volume = Math.max(0, Math.min(1, source.audio.volume + delta));
        }
        ShellState.showOsd("microphone", source.audio.volume, source.audio.muted ? "Microphone muted" : Math.round(source.audio.volume * 100) + "%");
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }
}
