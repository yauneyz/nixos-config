pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import ".."

Singleton {
    id: root
    property var history: []
    property var latest: null
    property var toastScreen: null
    property int serial: 0
    readonly property int count: history.length

    function remove(notification) {
        history = history.filter(entry => entry !== notification);
        notification.dismiss();
    }

    function clearAll() {
        const old = history;
        history = [];
        for (let i = 0; i < old.length; ++i)
            old[i].dismiss();
    }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        actionsSupported: true
        actionIconsSupported: true
        imageSupported: true
        inlineReplySupported: false

        onNotification: notification => {
            notification.tracked = true;
            root.history = [notification].concat(root.history.filter(entry => entry !== notification)).slice(0, 100);
            if (!ShellState.dnd) {
                root.latest = notification;
                root.toastScreen = ShellState.screenForFocusedMonitor();
                root.serial += 1;
            }
        }
    }
}
