pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    readonly property var battery: UPower.displayDevice
    readonly property bool available: battery && battery.ready && battery.isPresent
    readonly property int percentage: available ? Math.round(battery.percentage) : 0
    readonly property bool charging: available && (battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged)
}
