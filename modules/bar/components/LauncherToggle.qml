import qs.services
import qs.ds
import qs.ds.icons as Icons
import qs.ds.text as DsText
import qs.ds.buttons.circularButtons as CircularButtons
import qs.ds.animations
import Quickshell
import QtQuick

Item {
    id: root

    required property real innerHeight
    required property PersistentProperties visibilities

    readonly property bool isExpanded: searchField.activeFocus || root.visibilities.launcher
    readonly property real collapsedWidth: searchIcon.implicitWidth + hintText.implicitWidth + Foundations.spacing.l * 2 + Foundations.spacing.m
    readonly property real expandedWidth: 600

    implicitHeight: innerHeight
    implicitWidth: content.implicitWidth

    Rectangle {
        id: content

        anchors.verticalCenter: parent.verticalCenter
        color: Foundations.palette.base02
        height: root.innerHeight
        implicitWidth: root.isExpanded ? root.expandedWidth : root.collapsedWidth
        radius: Foundations.radius.all

        Behavior on implicitWidth {
            BasicNumberAnimation {
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: Foundations.duration.fast
            }
        }

        Icons.MaterialFontIcon {
            id: searchIcon

            anchors.left: parent.left
            anchors.leftMargin: Foundations.spacing.l
            anchors.verticalCenter: parent.verticalCenter
            color: Foundations.palette.base04
            text: "search"
        }

        DsText.BodyM {
            id: hintText

            anchors.left: searchIcon.right
            anchors.leftMargin: Foundations.spacing.m
            anchors.verticalCenter: parent.verticalCenter
            color: Foundations.palette.base04
            opacity: root.isExpanded ? 0 : 1
            text: "Search"
            visible: !root.isExpanded

            Behavior on opacity {
                BasicNumberAnimation {
                }
            }
        }

        TextField {
            id: searchField

            anchors.left: searchIcon.right
            anchors.leftMargin: Foundations.spacing.m
            anchors.right: clearIcon.left
            anchors.rightMargin: Foundations.spacing.m
            anchors.verticalCenter: parent.verticalCenter
            background: null
            backgroundColor: "transparent"
            font.pointSize: Foundations.font.size.s
            borderWidth: 0
            bottomPadding: Foundations.spacing.xs
            opacity: root.isExpanded ? 1 : 0
            placeholderText: "Type >!# for actions/commands/session"
            text: root.visibilities.searchText
            topPadding: Foundations.spacing.xs
            visible: root.isExpanded

            Keys.onDownPressed: {
                const list = root.visibilities.launcherList;
                if (list) {
                    list.incrementCurrentIndex();
                }
            }
            Keys.onEscapePressed: {
                root.visibilities.launcher = false;
            }
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return && (event.modifiers & Qt.ShiftModifier)) {
                    // Check if current item is interactive (has a hintButton)
                    const list = root.visibilities.launcherList;
                    const currentItem = list?.currentItem;
                    if (currentItem && currentItem.hintButton) {
                        currentItem.hintButton.clicked();
                        event.accepted = true;
                    }
                }
            }
            Keys.onUpPressed: {
                const list = root.visibilities.launcherList;
                if (list) {
                    list.decrementCurrentIndex();
                }
            }

            onAccepted: {
                const list = root.visibilities.launcherList;
                const currentItem = list?.currentItem;
                if (currentItem) {
                    currentItem.activate();
                }
            }
            onTextChanged: {
                root.visibilities.searchText = text;
            }

            Behavior on opacity {
                BasicNumberAnimation {
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                enabled: !searchField.activeFocus

                onClicked: {
                    searchField.forceActiveFocus();
                    root.visibilities.launcher = true;
                }
            }
        }

        CircularButtons.M {
            id: clearIcon

            anchors.right: parent.right
            anchors.rightMargin: Foundations.spacing.l
            anchors.verticalCenter: parent.verticalCenter
            icon: "close"
            opacity: root.isExpanded && searchField.text ? 1 : 0
            visible: root.isExpanded && searchField.text

            Behavior on opacity {
                BasicNumberAnimation {
                }
            }

            onClicked: {
                root.visibilities.searchText = "";
                searchField.forceActiveFocus();
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: !root.isExpanded

            onClicked: {
                root.visibilities.launcher = true;
                searchField.forceActiveFocus();
            }
        }
    }

    HoverHandler {
        enabled: !root.isExpanded

        onHoveredChanged: {
            if (hovered) {
                content.color = Foundations.palette.base03;
            } else {
                content.color = Foundations.palette.base02;
            }
        }
    }

    Timer {
        id: focusTimer

        interval: 50
        repeat: false

        onTriggered: {
            if (root.visibilities.launcher) {
                searchField.forceActiveFocus();
            }
        }
    }

    Connections {
        function onLauncherChanged(): void {
            if (root.visibilities.launcher) {
                focusTimer.start();
            } else {
                // Clear search when launcher closes
                root.visibilities.searchText = "";
                // Reset list index
                const list = root.visibilities.launcherList;
                if (list) {
                    list.currentIndex = 0;
                }
            }
        }

        target: root.visibilities
    }
}
