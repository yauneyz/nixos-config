import QtQuick
import ".."

Rectangle {
    property bool active: false
    property bool warning: false
    implicitWidth: 8
    implicitHeight: 8
    radius: 4
    color: warning ? Theme.danger : active ? Theme.success : Theme.textDisabled
}
