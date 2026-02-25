pragma ComponentBehavior: Bound

import qs.services
import qs.ds
import qs.ds.text as Text
import QtQuick

Rectangle {
    id: root

    signal clicked()

    property int margin: Foundations.spacing.s

    clip: true
    color: Foundations.palette.base02
    implicitWidth: dateText.implicitWidth + margin * 2
    implicitHeight: height
    radius: Foundations.radius.all

    InteractiveArea {
        function onClicked(): void {
            root.clicked();
        }

        radius: parent.radius
    }

    Text.BodyS {
        id: dateText

        anchors.centerIn: parent
        color: Foundations.palette.base0D
        font.family: Foundations.font.family.mono
        text: Time.format("ddd dd MMM  HH:mm")
    }
}
