import qs.services
import qs.ds
import qs.ds.text as DSText
import qs.ds.icons as Icons
import qs.ds.buttons.circularButtons as CircularButtons
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Column {
    id: root

    property date currentMonth: new Date()

    property int margin: Foundations.spacing.l
    property int itemSpacing: Foundations.spacing.xxs

    height: implicitHeight + margin
    spacing: Foundations.spacing.s
    width: 300

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: root.margin
        Layout.rightMargin: root.margin
        Layout.topMargin: root.margin
        width: root.width

        CircularButtons.M {
            icon: "chevron_left"

            onClicked: {
                let newDate = new Date(root.currentMonth);
                newDate.setMonth(newDate.getMonth() - 1);
                root.currentMonth = newDate;
            }
        }
        DSText.HeadingM {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Qt.formatDate(root.currentMonth, "MMMM yyyy")
        }
        CircularButtons.M {
            icon: "chevron_right"

            onClicked: {
                let newDate = new Date(root.currentMonth);
                newDate.setMonth(newDate.getMonth() + 1);
                root.currentMonth = newDate;
            }
        }
    }
    DayOfWeekRow {
        id: days

        anchors.left: parent.left
        anchors.margins: parent.padding
        anchors.right: parent.right

        delegate: DSText.HeadingS {
            required property var model

            horizontalAlignment: Text.AlignHCenter
            text: model.shortName
        }
    }
    MonthGrid {
        id: grid

        anchors.left: parent.left
        anchors.margins: parent.padding
        anchors.right: parent.right
        height: Math.max(200, implicitHeight)
        month: root.currentMonth.getMonth()
        spacing: 3
        year: root.currentMonth.getFullYear()

        delegate: Item {
            id: day

            required property var model

            implicitHeight: text.implicitHeight + root.itemSpacing * 2
            implicitWidth: implicitHeight

            Rectangle {
                anchors.centerIn: parent
                color: Qt.alpha(Foundations.palette.base05, day.model.today ? 1 : 0)
                implicitHeight: parent.implicitHeight
                implicitWidth: parent.implicitHeight
                radius: Foundations.radius.all

                DSText.BodyM {
                    id: text

                    anchors.centerIn: parent
                    color: day.model.today ? Foundations.palette.base03 : day.model.month === grid.month ? Foundations.palette.base04 : Foundations.palette.base0D
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDate(day.model.date, "d")
                }
            }
        }
    }
}
