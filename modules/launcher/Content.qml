pragma ComponentBehavior: Bound

import "services"
import qs.services
import qs.ds
import qs.ds.icons as Icons
import qs.ds.buttons.circularButtons as CircularButtons
import Quickshell
import QtQuick
import qs.ds.animations

Item {
    id: root

    required property var panels
    required property PersistentProperties visibilities
    required property var wrapper

    readonly property int padding: Foundations.spacing.l
    readonly property int innerMargin: Foundations.spacing.s

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    implicitHeight: listWrapper.height + padding * 2
    implicitWidth: listWrapper.width + padding * 2

    Behavior on implicitHeight {
        enabled: false
    }

    Item {
        id: listWrapper

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.padding
        implicitHeight: list.height + root.padding
        implicitWidth: list.width

        ContentList {
            id: list

            padding: root.padding
            panels: root.panels
            searchText: root.visibilities.searchText
            visibilities: root.visibilities
            wrapper: root.wrapper
        }
    }
}
