pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    property var selectedAdapter: null
    readonly property var adapter: selectedAdapter || Bluetooth.defaultAdapter
    readonly property var adapters: Bluetooth.adapters.values
    readonly property var connectedDevices: Bluetooth.devices.values
    readonly property int connectedCount: connectedDevices.length
    readonly property bool available: adapter !== null
    readonly property bool enabled: available && adapter.enabled
    readonly property bool discovering: available && adapter.discovering

    function togglePower() {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }

    function toggleScan() {
        if (adapter && adapter.enabled)
            adapter.discovering = !adapter.discovering;
    }

    function iconFor(device) {
        if (!device)
            return "bluetooth-active-symbolic";
        const icon = (device.icon || "").toLowerCase();
        if (icon.indexOf("head") >= 0 || icon.indexOf("audio") >= 0)
            return "audio-headphones-symbolic";
        if (icon.indexOf("mouse") >= 0 || icon.indexOf("input-mouse") >= 0)
            return "input-mouse-symbolic";
        if (icon.indexOf("keyboard") >= 0)
            return "input-keyboard-symbolic";
        if (icon.indexOf("phone") >= 0)
            return "phone-symbolic";
        return device.icon || "bluetooth-active-symbolic";
    }
}
