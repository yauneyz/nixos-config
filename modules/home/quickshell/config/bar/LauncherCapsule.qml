import QtQuick
import Quickshell
import ".."
import "../components"

BarCapsule {
    id: root
    required property var barWindow
    required property var shellScreen
    implicitWidth: launcher.implicitWidth + 8

    IconButton {
        id: launcher
        anchors.centerIn: parent
        icon: "nix-snowflake"
        fallbackText: ""
        accent: Theme.primary
        onClicked: button => {
            if (button === Qt.LeftButton)
                Quickshell.execDetached(RuntimeConfig.launcher === "vicinae" ? ["vicinae", "toggle"] : ["rofi", "-show", "drun"]);
            else if (button === Qt.RightButton)
                Quickshell.execDetached(["init-wallpaper"]);
        }
    }
}
