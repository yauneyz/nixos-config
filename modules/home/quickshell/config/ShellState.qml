pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

QtObject {
    property string activePanel: ""
    property var targetScreen: null
    property var targetWindow: null
    property var targetItem: null
    property bool notificationCenterOpen: false
    property bool dnd: false
    property var selectedPlayer: null
    property bool reducedMotion: RuntimeConfig.reducedMotion
    property bool performanceMode: RuntimeConfig.performanceMode

    property string osdKind: ""
    property real osdValue: -1
    property string osdLabel: ""
    property var osdScreen: null
    property int osdSerial: 0

    function screenForFocusedMonitor() {
        const focused = Hyprland.focusedMonitor;
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; ++i) {
            if (Hyprland.monitorFor(screens[i]) === focused)
                return screens[i];
        }
        return screens.length > 0 ? screens[0] : null;
    }

    function openFromItem(name, screen, window, item) {
        targetScreen = screen;
        targetWindow = window;
        targetItem = item;
        notificationCenterOpen = name === "notifications";
        activePanel = name;
    }

    function openPanel(name) {
        targetScreen = screenForFocusedMonitor();
        targetWindow = null;
        targetItem = null;
        notificationCenterOpen = name === "notifications";
        activePanel = name;
    }

    function togglePanel(name, screen, window, item) {
        if (activePanel === name && (!screen || targetScreen === screen)) {
            closePanel();
        } else if (screen && window) {
            openFromItem(name, screen, window, item);
        } else {
            openPanel(name);
        }
    }

    function closePanel() {
        activePanel = "";
        notificationCenterOpen = false;
        targetItem = null;
    }

    function showOsd(kind, value, label, screen) {
        osdKind = kind;
        osdValue = value;
        osdLabel = label;
        osdScreen = screen || screenForFocusedMonitor();
        osdSerial += 1;
    }
}
