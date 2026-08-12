pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Singleton {
    id: root
    property int cpu: 0
    property int memory: 0
    property int disk: 0

    Process {
        id: stats
        command: ["bash", Quickshell.shellPath("helpers/stats.sh")]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                for (let i = 0; i < lines.length; ++i) {
                    const pair = lines[i].split("=");
                    if (pair[0] === "cpu")
                        root.cpu = Number(pair[1]);
                    else if (pair[0] === "mem")
                        root.memory = Number(pair[1]);
                    else if (pair[0] === "disk")
                        root.disk = Number(pair[1]);
                }
            }
        }
    }

    Timer {
        interval: ShellState.performanceMode ? 10000 : 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: if (!stats.running)
            stats.running = true
    }
}
