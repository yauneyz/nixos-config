pragma Singleton
import QtQuick

QtObject {
    readonly property string reducedMotionSetting: "@REDUCED_MOTION@"
    readonly property string performanceModeSetting: "@PERFORMANCE_MODE@"
    readonly property bool reducedMotion: reducedMotionSetting === "true"
    readonly property bool performanceMode: performanceModeSetting === "true"
    readonly property string launcher: "vicinae"
    readonly property string preferredWorkspacesJson: '@PREFERRED_WORKSPACES@'
    readonly property var preferredWorkspaces: preferredWorkspacesJson.charAt(0) === "{" ? JSON.parse(preferredWorkspacesJson) : ({
            "*": [1, 2, 3, 4, 5]
        })
}
