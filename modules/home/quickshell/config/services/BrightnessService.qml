pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Singleton {
    id: root
    property real value: -1
    property real pendingDelta: 0

    function refresh() {
        if (!query.running)
            query.running = true;
    }

    function change(delta) {
        pendingDelta = delta;
        if (!changeProcess.running) {
            changeProcess.command = ["brightnessctl", "set", (delta > 0 ? "+" : "") + delta + "%"];
            changeProcess.running = true;
        }
    }

    Process {
        id: query
        command: ["brightnessctl", "-m"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/,(\d+)%/);
                if (match)
                    root.value = Number(match[1]) / 100;
            }
        }
    }

    Process {
        id: changeProcess
        stdout: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            root.refresh();
            delayedOsd.restart();
        }
    }

    Timer {
        id: delayedOsd
        interval: 60
        onTriggered: ShellState.showOsd("brightness", root.value, root.value < 0 ? "Brightness unavailable" : Math.round(root.value * 100) + "%")
    }
}
