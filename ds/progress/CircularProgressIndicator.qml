import "."
import qs.services
import qs.ds
import QtQuick
import QtQuick.Controls
import qs.ds.animations

BusyIndicator {
    id: root

    property string animState: "stopped"
    property color bgColour: Foundations.palette.base04
    property color fgColour: Foundations.palette.base05
    property real implicitSize: Foundations.font.size.m * 3
    property real internalStrokeWidth: strokeWidth
    property real strokeWidth: Foundations.spacing.s

    background: null
    implicitHeight: implicitSize
    implicitWidth: implicitSize
    padding: 0

    contentItem: CircularProgress {
        anchors.fill: parent
        fgColour: root.fgColour
        startAngle: updater.startFraction * 360
        strokeWidth: root.internalStrokeWidth
        value: updater.endFraction - updater.startFraction
    }
    states: State {
        name: "stopped"
        when: !root.running

        PropertyChanges {
            root.internalStrokeWidth: root.strokeWidth / 3
            root.opacity: 0
        }
    }
    transitions: Transition {
        BasicNumberAnimation {
            duration: updater.completeEndDuration
            properties: "opacity,internalStrokeWidth"
        }
    }

    Component.onCompleted: {
        if (root.running)
            root.animState = "running";
    }
    onRunningChanged: {
        if (running) {
            updater.completeEndProgress = 0;
            animState = "running";
        } else {
            if (animState == "running")
                animState = "completing";
        }
    }

    Updater {
        id: updater
    }
    NumberAnimation {
        duration: updater.duration
        from: 0
        loops: Animation.Infinite
        property: "progress"
        running: root.animState === "running" || root.animState === "completing"
        target: updater
        to: 1
    }
    NumberAnimation {
        duration: updater.completeEndDuration
        from: 0
        property: "completeEndProgress"
        running: root.animState === "completing"
        target: updater
        to: 1

        onFinished: {
            if (root.animState === "completing")
                root.animState = "stopped";
        }
    }

    component Updater: QtObject {
        readonly property list<int> collapseDelay: [667, 2017, 3367, 4717]
        readonly property int collapseDuration: Foundations.duration.slow
        readonly property int completeEndDuration: Foundations.duration.slow
        property real completeEndProgress: 0
        readonly property int constantRotDeg: 1520
        readonly property int duration: 5400
        property real endFraction: 0
        readonly property list<int> expandDelay: [0, 1350, 2700, 4050]
        readonly property int expandDuration: Foundations.duration.slow
        readonly property int extraDegPerCycle: 250
        property real progress: 0
        property real rotation: 0
        property real startFraction: 0
        readonly property int tailDegOffset: -20

        function cubic(a: real, b: real, c: real, d: real, t: real): real {
            return ((1 - t) ** 3) * a + 3 * ((1 - t) ** 2) * t * b + 3 * (1 - t) * (t ** 2) * c + (t ** 3) * d;
        }
        function cubicBezier(p1x: real, p1y: real, p2x: real, p2y: real, t: real): real {
            return cubic(0, p1y, p2y, 1, t);
        }
        function fastOutSlowIn(t: real): real {
            return cubicBezier(0.4, 0.0, 0.2, 1.0, t);
        }
        function getFractionInRange(currentTime: real, delay: int, duration: int): real {
            if (currentTime < delay)
                return 0;
            if (currentTime > delay + duration)
                return 1;
            return (currentTime - delay) / duration;
        }
        function lerp(a: real, b: real, t: real): real {
            return a + (b - a) * t;
        }
        function update(p: real): void {
            const playtime = p * duration;
            let startDeg = constantRotDeg * p + tailDegOffset;
            let endDeg = constantRotDeg * p;

            for (let i = 0; i < 4; i++) {
                const expandFraction = getFractionInRange(playtime, expandDelay[i], expandDuration);
                endDeg += fastOutSlowIn(expandFraction) * extraDegPerCycle;

                const collapseFraction = getFractionInRange(playtime, collapseDelay[i], collapseDuration);
                startDeg += fastOutSlowIn(collapseFraction) * extraDegPerCycle;
            }

            // Gap closing
            startDeg += (endDeg - startDeg) * completeEndProgress;

            startFraction = startDeg / 360;
            endFraction = endDeg / 360;
        }

        onProgressChanged: update(progress)
    }
}
