pragma Singleton
import QtQuick

QtObject {
    readonly property color background: resolve("@BASE00@", "#070607")
    readonly property color surface: resolve("@BASE01@", "#110a0d")
    readonly property color surfaceRaised: resolve("@BASE02@", "#241218")
    readonly property color surfaceHover: resolve("@BASE03@", "#6f4c54")
    readonly property color text: resolve("@BASE05@", "#e7d9d8")
    readonly property color textMuted: resolve("@BASE04@", "#b79097")
    readonly property color textDisabled: resolve("@BASE03@", "#6f4c54")
    readonly property color primary: resolve("@BASE0D@", "#dc3b59")
    readonly property color secondary: resolve("@BASE0E@", "#e879a0")
    readonly property color tertiary: resolve("@BASE0C@", "#f0a7b2")
    readonly property color success: resolve("@BASE0B@", "#a9c78e")
    readonly property color warning: resolve("@BASE0A@", "#e7b269")
    readonly property color danger: resolve("@BASE08@", "#f06466")
    readonly property color info: resolve("@BASE0C@", "#f0a7b2")
    readonly property color outline: alpha(surfaceHover, 0.72)
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.42)
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.36)
    readonly property color audio: primary
    readonly property color network: secondary
    readonly property color bluetooth: tertiary
    readonly property color battery: warning
    readonly property color workspace: primary

    function alpha(color, amount) {
        return Qt.rgba(color.r, color.g, color.b, amount);
    }

    function resolve(value, fallback) {
        return value.charAt(0) === "#" ? value : fallback;
    }
}
