pragma ComponentBehavior: Bound

import qs.services
import qs.services as Services
import qs.ds
import qs.ds.text as Text
import QtQuick
import qs.ds.animations
import Quickshell.Wayland

Item {
    id: root

    property string activeAppId: activeToplevel?.appId ?? ""

    property string activeTitle: activeToplevel?.title ?? ""
    property Toplevel activeToplevel: ToplevelManager.activeToplevel
    property color colour: Foundations.palette.base05
    property Title current: text1
    readonly property int maxWidth: screen.width / 3
    required property var screen

    clip: true
    implicitWidth: Math.min(contentItem.width, maxWidth)

    property int margin: Foundations.spacing.s

    Behavior on implicitWidth {
        BasicNumberAnimation {
        }
    }

    Component.onCompleted: {
        activeToplevel = Qt.binding(() => {
            const trigger = ToplevelManager.activeToplevel;
            const toplevels = ToplevelManager.toplevels.values;

            if (!toplevels || !toplevels.length) {
                return activeToplevel;
            }

            for (let i = 0; i < toplevels.length; i++) {
                const toplevel = toplevels[i];
                if (toplevel && toplevel.activated) {
                    if (toplevel.screens && toplevel.screens.length > 0) {
                        const toplevelScreen = toplevel.screens[0];
                        if (screen.name === toplevelScreen.name) {
                            return toplevel;
                        }
                    }
                }
            }

            return activeToplevel;
        });

        activeTitle = Qt.binding(() => activeToplevel?.title ?? "");
        activeAppId = Qt.binding(() => activeToplevel?.appId ?? "");
    }

    Item {
        id: contentItem

        anchors.centerIn: parent
        height: Math.max(icon.implicitHeight, current.implicitHeight)
        width: icon.implicitWidth + current.implicitWidth + margin

        FontIcon {
            id: icon

            text: Services.Apps.getIcon(root.activeAppId)
        }
        Title {
            id: text1

        }
        Title {
            id: text2

        }
    }
    TextMetrics {
        id: metrics

        elide: Qt.ElideRight
        elideWidth: root.maxWidth - icon.implicitWidth - margin
        font.family: Foundations.font.family.mono
        font.pointSize: Foundations.font.size.s
        text: Services.Apps.cleanTitle(root.activeTitle)

        onElideWidthChanged: root.current.text = elidedText
        onTextChanged: {
            const next = root.current === text1 ? text2 : text1;
            next.text = elidedText;
            root.current = next;
        }
    }

    component FontIcon: Text.BodyM {
        anchors.verticalCenter: parent.verticalCenter
        primary: true
    }
    component Title: Text.BodyM {
        id: text

        anchors.left: icon.right
        anchors.leftMargin: margin
        anchors.verticalCenter: icon.verticalCenter
        opacity: root.current === this ? 1 : 0
        primary: true

        Behavior on opacity {
            BasicNumberAnimation {
            }
        }
    }
}
