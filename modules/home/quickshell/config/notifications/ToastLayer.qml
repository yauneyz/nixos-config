import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import ".."
import "../services"

PanelWindow {
    id: root
    required property var modelData
    screen: modelData
    property bool toastShown: false
    readonly property bool active: toastShown && NotificationService.toastScreen === screen
    visible: active
    color: "transparent"
    implicitWidth: Math.min(390, screen.width - 24)
    implicitHeight: toastShown && toastLoader.item ? toastLoader.item.implicitHeight : 1
    anchors {
        right: true
        top: true
    }
    margins {
        right: 12
        top: 12
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "zac-shell-notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    property int seenSerial: 0

    Loader {
        id: toastLoader
        width: root.implicitWidth
        active: root.toastShown && NotificationService.latest !== null
        visible: active
        opacity: active ? 1 : 0
        transform: Translate {
            x: root.toastShown ? 0 : 24
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Motion.fast
            }
        }
        sourceComponent: NotificationCard {
            notification: NotificationService.latest
            onDismissRequested: {
                NotificationService.remove(notification);
                root.toastShown = false;
            }
        }
    }

    Connections {
        target: NotificationService
        function onSerialChanged() {
            if (NotificationService.toastScreen === root.screen) {
                root.seenSerial = NotificationService.serial;
                root.toastShown = true;
                dismissTimer.interval = NotificationService.latest && NotificationService.latest.urgency === NotificationUrgency.Critical ? 0 : Math.max(3000, (NotificationService.latest ? NotificationService.latest.expireTimeout * 1000 : 5000));
                if (dismissTimer.interval > 0)
                    dismissTimer.restart();
            }
        }
    }
    Timer {
        id: dismissTimer
        onTriggered: root.toastShown = false
    }
}
