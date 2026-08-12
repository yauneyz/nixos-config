pragma Singleton
import QtQuick

QtObject {
    readonly property int instant: ShellState.reducedMotion ? 60 : 100
    readonly property int fast: ShellState.reducedMotion ? 90 : 175
    readonly property int normal: ShellState.reducedMotion ? 120 : 260
    readonly property int expressive: ShellState.reducedMotion ? 140 : 460
    readonly property int ambient: ShellState.reducedMotion || ShellState.performanceMode ? 0 : 2000
    readonly property int travel: ShellState.reducedMotion ? 0 : 10
    readonly property int outCubic: Easing.OutCubic
    readonly property int outQuint: Easing.OutQuint
    readonly property int inCubic: Easing.InCubic
    readonly property int inOutSine: Easing.InOutSine
}
