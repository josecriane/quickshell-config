pragma ComponentBehavior: Bound

import qs.ds
import qs.ds.icons as Icons
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    signal replySent(string text)

    color: Foundations.palette.base03
    implicitHeight: rowLayout.implicitHeight + Foundations.spacing.s * 2
    radius: Foundations.radius.s

    Component.onCompleted: {
        textInput.forceActiveFocus()
    }

    RowLayout {
        id: rowLayout

        anchors.fill: parent
        anchors.margins: Foundations.spacing.s
        spacing: Foundations.spacing.s

        TextField {
            id: textInput

            Layout.fillWidth: true

            background: Rectangle {
                color: Foundations.palette.base00
                radius: Foundations.radius.xs
            }

            color: Foundations.palette.base07
            font.family: Foundations.font.family.sansSerif
            font.pointSize: Foundations.font.size.m
            placeholderText: "Type your reply..."
            placeholderTextColor: Foundations.palette.base04
            selectByMouse: true

            onAccepted: {
                if (text.trim() !== "") {
                    root.replySent(text)
                    text = ""
                }
            }
        }

        Rectangle {
            id: sendButton

            Layout.preferredHeight: 32
            Layout.preferredWidth: 32

            color: sendButtonArea.containsMouse ? Foundations.palette.base04 : Foundations.palette.base03
            radius: Foundations.radius.xs

            Icons.MaterialFontIcon {
                anchors.centerIn: parent
                color: Foundations.palette.base07
                font.pointSize: Foundations.font.size.l
                text: "send"
            }

            MouseArea {
                id: sendButtonArea

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: {
                    if (textInput.text.trim() !== "") {
                        root.replySent(textInput.text)
                        textInput.text = ""
                    }
                }
            }
        }
    }
}
