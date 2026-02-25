import qs.services
import qs.ds
import Quickshell.Services.SystemTray
import QtQuick
import qs.ds.animations
import qs.ds.buttons

Rectangle {
    id: root

    readonly property alias items: items

    property int margin: Foundations.spacing.xxs
    property int spacingItems: Foundations.spacing.xs
    property int buttonSize: Foundations.font.size.xl

    clip: true
    color: "transparent"
    implicitHeight: height
    implicitWidth: layout.implicitWidth + margin * 2
    radius: Foundations.radius.all
    visible: width > 0 && height > 0

    Behavior on implicitWidth {
        BasicNumberAnimation {
        }
    }

    Row {
        id: layout

        anchors.centerIn: parent
        spacing: root.spacingItems

        add: Transition {
            BasicNumberAnimation {
                from: 0
                properties: "scale"
                to: 1
            }
        }
        move: Transition {
            BasicNumberAnimation {
                properties: "scale"
                to: 1
            }
            BasicNumberAnimation {
                properties: "x,y"
            }
        }

        Repeater {
            id: items

            model: SystemTray.items

            IconButton {
                id: iconButton

                required property SystemTrayItem modelData

                buttonColor: "transparent"
                buttonSize: root.buttonSize
                focusColor: "transparent"
                iconColor: "transparent"

                // Process the icon to extract the path
                iconPath: {
                    let icon = iconButton.modelData.icon;
                    if (icon.includes("?path=")) {
                        const [name, path] = icon.split("?path=");
                        return `file://${path}/${name.slice(name.lastIndexOf("/") + 1)}`;
                    }
                    return icon;
                }

                onClicked: {
                    iconButton.modelData.activate();
                }
                onHovered: {
                    iconButton.modelData.secondaryActivate();
                }
            }
        }
    }
}
