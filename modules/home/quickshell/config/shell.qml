//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "."
import "bar"
import "osd"
import "notifications"
import "services"

ShellRoot {
    // Force construction of the singleton services exactly once.
    readonly property var audioService: AudioService
    readonly property var bluetoothService: BluetoothService
    readonly property var mediaService: MediaService
    readonly property var notificationService: NotificationService
    readonly property var systemStatsService: SystemStatsService

    Variants {
        model: Quickshell.screens

        delegate: Bar {}
    }

    Variants {
        model: Quickshell.screens

        delegate: OsdHost {}
    }

    Variants {
        model: Quickshell.screens

        delegate: ToastLayer {}
    }

    IpcHandler {
        target: "shell"

        function togglePanel(name: string): void {
            ShellState.togglePanel(name);
        }
        function openPanel(name: string): void {
            ShellState.openPanel(name);
        }
        function closePanel(): void {
            ShellState.closePanel();
        }
        function toggleNotificationCenter(): void {
            ShellState.togglePanel("notifications");
        }
        function showOsd(kind: string, value: real, label: string): void {
            ShellState.showOsd(kind, value, label);
        }
        function changeAudio(change: string): void {
            AudioService.changeVolume(change);
        }
        function changeMic(change: string): void {
            AudioService.changeMic(change);
        }
        function changeBrightness(delta: real): void {
            BrightnessService.change(delta);
        }
        function reload(): void {
            Quickshell.reload(false);
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "monitorremoved" && ShellState.activePanel !== "")
                ShellState.closePanel();
        }
    }
}
