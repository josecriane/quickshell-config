pragma ComponentBehavior: Bound

import qs.services
import qs.ds
import qs.ds.icons as Icons
import qs.ds.text as DsText
import qs.ds.animations
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property var group
    required property int notificationWidth
    property bool expanded: false
    property bool isSelected: false

    readonly property int margin: Foundations.spacing.s
    readonly property int headerHeight: 32
    readonly property var groupNotifications: group.notifications ?? []
    readonly property int count: groupNotifications.length
    readonly property var latestNotification: group.latestNotification ?? null

    color: Foundations.palette.base02
    radius: Foundations.radius.s
    border.width: isSelected ? 2 : 0
    border.color: isSelected ? Foundations.palette.base0D : "transparent"
    implicitWidth: notificationWidth
    implicitHeight: expanded ? expandedHeight : collapsedHeight

    readonly property int collapsedHeight: latestItem.active ? (headerHeight + latestItem.height + margin) : headerHeight
    readonly property int expandedHeight: headerHeight + expandedColumn.implicitHeight + margin

    Behavior on implicitHeight {
        BasicNumberAnimation {
            duration: Foundations.duration.standard
        }
    }

    Behavior on border.width {
        BasicNumberAnimation {
            duration: Foundations.duration.fast
        }
    }

    // Header row with app name, count badge, and expand button
    Rectangle {
        id: header

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: headerHeight
        color: "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.margins: margin
            spacing: Foundations.spacing.s

            // App icon
            Loader {
                active: (root.group?.appIcon ?? "") !== ""
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20

                sourceComponent: IconImage {
                    asynchronous: true
                    source: Quickshell.iconPath(root.group?.appIcon ?? "")
                }
            }

            // App name
            DsText.BodyM {
                Layout.fillWidth: true
                text: root.group.appName
                maximumLineCount: 1
                elide: Text.ElideRight
            }

            // Count badge (only show if more than 1)
            Rectangle {
                visible: root.count > 1
                Layout.preferredWidth: countText.implicitWidth + Foundations.spacing.s * 2
                Layout.preferredHeight: 20
                radius: 10
                color: Foundations.palette.base03

                DsText.BodyS {
                    id: countText
                    anchors.centerIn: parent
                    text: root.count.toString()
                    color: Foundations.palette.base05
                }
            }

            // Expand/collapse button (only show if more than 1)
            Rectangle {
                visible: root.count > 1
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 12
                color: expandMouseArea.containsMouse ? Foundations.palette.base03 : "transparent"

                Icons.MaterialFontIcon {
                    anchors.centerIn: parent
                    text: root.expanded ? "expand_less" : "expand_more"
                    color: Foundations.palette.base05
                    font.pointSize: Foundations.font.size.m

                    Behavior on text {
                        PropertyAnimation {
                            duration: 0
                        }
                    }
                }

                MouseArea {
                    id: expandMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.expanded = !root.expanded
                }
            }

            // Dismiss group button
            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 12
                color: dismissMouseArea.containsMouse ? Foundations.palette.base08 : "transparent"

                Icons.MaterialFontIcon {
                    anchors.centerIn: parent
                    text: "close"
                    color: dismissMouseArea.containsMouse ? Foundations.palette.base07 : Foundations.palette.base05
                    font.pointSize: Foundations.font.size.s
                }

                MouseArea {
                    id: dismissMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.dismissGroup(root.group.appKey)
                }
            }
        }
    }

    // Collapsed view: show only latest notification (compact)
    Loader {
        id: latestItem

        active: !root.expanded && root.latestNotification !== null
        visible: active
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.margins: margin
        anchors.topMargin: 0

        sourceComponent: NotificationItemCompact {
            notification: root.latestNotification
            notificationWidth: root.notificationWidth - root.margin * 2
        }
    }

    // Expanded view: show all notifications
    Column {
        id: expandedColumn

        visible: root.expanded
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.margins: margin
        anchors.topMargin: 0
        spacing: Foundations.spacing.xs

        Repeater {
            model: root.expanded ? root.groupNotifications : []

            NotificationItemCompact {
                required property var modelData
                required property int index

                notification: modelData
                notificationWidth: root.notificationWidth - root.margin * 2
                showDismiss: true
            }
        }
    }
}
