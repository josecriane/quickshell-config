pragma ComponentBehavior: Bound

import qs.services
import qs.ds
import QtQuick
import QtQuick.Effects

Item {
    id: root

    required property Item bar
    required property int margin
    required property int radius

    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Foundations.palette.base01, 0.95)
        layer.enabled: true

        layer.effect: MultiEffect {
            maskEnabled: true
            maskInverted: true
            maskSource: mask
            maskSpreadAtMin: 1
            maskThresholdMin: 0.5
        }
    }
    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            anchors.margins: root.margin
            anchors.topMargin: root.bar.implicitHeight
            radius: root.radius
        }
    }
}
