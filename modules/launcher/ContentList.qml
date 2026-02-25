pragma ComponentBehavior: Bound

import qs.services
import qs.ds
import qs.ds.text as DsText
import qs.ds.icons as Icons
import Quickshell
import QtQuick
import QtQuick.Controls
import qs.ds.animations

Item {
    id: root

    readonly property Item currentList: appList.item
    property int itemHeight: 57
    property int itemWidth: 600
    required property int padding
    required property var panels
    required property string searchText
    required property PersistentProperties visibilities
    required property var wrapper

    Component.onCompleted: {
        root.visibilities.launcherList = root.currentList;
    }

    onCurrentListChanged: {
        root.visibilities.launcherList = root.currentList;
    }

    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    clip: true
    state: "apps"

    Behavior on implicitHeight {
        enabled: false
    }
    Behavior on implicitWidth {
        enabled: root.visibilities.launcher

        BasicNumberAnimation {
            duration: Foundations.duration.slow
        }
    }
    Behavior on state {
        SequentialAnimation {
            BasicNumberAnimation {
                duration: Foundations.duration.fast
                from: 1
                property: "opacity"
                target: root
                to: 0
            }
            PropertyAction {
            }
            BasicNumberAnimation {
                duration: Foundations.duration.fast
                from: 0
                property: "opacity"
                target: root
                to: 1
            }
        }
    }
    states: [
        State {
            name: "apps"

            PropertyChanges {
                appList.active: true
                root.implicitHeight: root.currentList?.count > 0 ? appList.implicitHeight : empty.implicitHeight
                root.implicitWidth: root.itemWidth
            }
            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        }
    ]

    Loader {
        id: appList

        active: false
        anchors.left: parent.left
        anchors.right: parent.right
        asynchronous: true

        sourceComponent: LauncherList {
            searchText: root.searchText
            visibilities: root.visibilities
        }
    }
    Item {
        id: empty

        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: root.itemHeight * 4
        opacity: root.currentList?.count === 0 ? 1 : 0
        scale: root.currentList?.count === 0 ? 1 : 0.5

        Behavior on opacity {
            BasicNumberAnimation {
            }
        }
        Behavior on scale {
            BasicNumberAnimation {
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: Foundations.spacing.xs

            Icons.MaterialFontIcon {
                anchors.verticalCenter: parent.verticalCenter
                color: Foundations.palette.base04
                font.pointSize: Foundations.font.size.xl
                text: "manage_search"
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter

                DsText.HeadingM {
                    text: qsTr("No results")
                }
                DsText.BodyM {
                    disabled: true
                    text: qsTr("Try searching for something else")
                }
            }
        }
    }
}
