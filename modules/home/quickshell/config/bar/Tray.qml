import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray

RowLayout {
    id: root
    required property var barWindow
    spacing: 2
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items
        TrayItem {
            required property var modelData
            trayItem: modelData
            barWindow: root.barWindow
        }
    }
}
