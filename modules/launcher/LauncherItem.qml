import "services"
import qs.services
import qs.ds.text as DsText
import qs.ds.icons as Icons
import qs.ds
import Quickshell
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    default property alias customContent: textContainer.data
    property int itemHeight: 57
    property var list
    required property LauncherItemModel modelData
    property PersistentProperties visibilities

    function activate(): void {
        if (root.modelData.autocompleteText) {
            root.visibilities.searchText = root.modelData.autocompleteText;
        }

        if (root.modelData.onActivate) {
            let shouldClose = root.modelData.onActivate();

            if (shouldClose === undefined || shouldClose === null) {
                shouldClose = true;
            }

            if (shouldClose) {
                root.visibilities.launcher = false;
            }
        }
    }

    anchors.left: parent?.left
    anchors.right: parent?.right
    implicitHeight: itemHeight

    InteractiveArea {
        function onClicked(): void {
            root.activate();
        }

        radius: Foundations.radius.xs
    }
    Item {
        anchors.fill: parent
        anchors.leftMargin: Foundations.spacing.m
        anchors.margins: Foundations.spacing.xs
        anchors.rightMargin: Foundations.spacing.m

        // Icon - Apps use IconImage, Actions use MaterialIcon
        IconImage {
            id: appIcon

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: root.itemHeight * 0.6
            source: visible ? Quickshell.iconPath(root.modelData?.appIcon, "image-missing") : ""
            visible: root.modelData?.isApp ?? false
            width: root.itemHeight * 0.6
        }
        Icons.MaterialFontIcon {
            id: fontIcon

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            font.pointSize: Foundations.font.size.l
            text: visible ? (root.modelData?.fontIcon ?? "") : ""
            visible: root.modelData?.isAction ?? false
        }
        Item {
            id: textContainer

            anchors.left: appIcon.visible ? appIcon.right : fontIcon.right
            anchors.leftMargin: Foundations.spacing.s
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: name.height + subtitle.height

            DsText.BodyM {
                id: name

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                elide: Text.ElideRight
                text: root.modelData?.name ?? ""
            }
            DsText.BodyS {
                id: subtitle

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: name.bottom
                disabled: true
                elide: Text.ElideRight
                text: root.modelData?.subtitle ?? ""
            }
        }
    }
}
