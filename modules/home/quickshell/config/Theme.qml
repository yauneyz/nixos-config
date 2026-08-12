pragma Singleton
import QtQuick

QtObject {
    readonly property color background: resolve("@BASE00@", "#09111a")
    readonly property color surface: resolve("@BASE01@", "#101b27")
    readonly property color surfaceRaised: resolve("@BASE02@", "#1b2a38")
    readonly property color surfaceHover: resolve("@BASE03@", "#526579")
    readonly property color text: resolve("@BASE05@", "#d7e2ec")
    readonly property color textMuted: resolve("@BASE04@", "#91a4b7")
    readonly property color textDisabled: resolve("@BASE03@", "#526579")
    readonly property color primary: resolve("@BASE0D@", "#6aa9ff")
    readonly property color secondary: resolve("@BASE0E@", "#ad8cff")
    readonly property color tertiary: resolve("@BASE0C@", "#5ccfe6")
    readonly property color success: resolve("@BASE0B@", "#82c99a")
    readonly property color warning: resolve("@BASE0A@", "#e5cc72")
    readonly property color danger: resolve("@BASE08@", "#ef6f7a")
    readonly property color info: resolve("@BASE0C@", "#5ccfe6")
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
