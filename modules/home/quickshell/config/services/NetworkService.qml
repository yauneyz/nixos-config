pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root
    readonly property var devices: Networking.devices.values
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool hardwareEnabled: Networking.wifiHardwareEnabled
    readonly property var connectedDevice: findConnectedDevice()
    readonly property bool connected: connectedDevice !== null
    readonly property string name: connectionName()

    function findConnectedDevice() {
        for (let i = 0; i < devices.length; ++i) {
            if (devices[i].connected)
                return devices[i];
        }
        return null;
    }

    function connectionName() {
        if (!connectedDevice)
            return "Disconnected";
        const networks = connectedDevice.networks ? connectedDevice.networks.values : [];
        for (let i = 0; i < networks.length; ++i) {
            if (networks[i].connected)
                return networks[i].name;
        }
        return connectedDevice.name || "Connected";
    }
}
