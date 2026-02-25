pragma ComponentBehavior: Bound

import qs.services
import qs.ds.text as Text
import qs.ds.icons as Icons
import qs.ds
import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.ds.animations

Rectangle {
    id: root

    property color colour: Foundations.palette.base0D

    property int margin: Foundations.spacing.s
    property int spacingItems: Foundations.spacing.m

    clip: true
    color: Foundations.palette.base02
    implicitWidth: iconRow.implicitWidth + margin * 2
    radius: Foundations.radius.all

    Behavior on implicitWidth {
        BasicNumberAnimation {
            duration: Foundations.duration.slow
        }
    }

    InteractiveArea {
        function onClicked(): void {
            Niri.spawn("alacritty -e btop");
        }

        radius: parent.radius
    }
    RowLayout {
        id: iconRow

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.spacingItems

        // CPU usage
        ResourceItem {
            colour: SystemUsage.cpuPerc > 0.8 ? Foundations.palette.base09 : Foundations.palette.base0D
            icon: "speed"
            value: SystemUsage.cpuPerc
        }

        // Memory usage
        ResourceItem {
            colour: SystemUsage.memPerc > 0.8 ? Foundations.palette.base09 : Foundations.palette.base0D
            icon: "memory"
            value: SystemUsage.memPerc
        }

        // Disk storage - showing usage percentage
        ResourceItem {
            colour: SystemUsage.storagePerc > 0.8 ? Foundations.palette.base08 : Foundations.palette.base0D
            icon: "storage"
            value: SystemUsage.storagePerc
        }

        // CPU temperature
        ResourceItem {
            colour: {
                const temp = SystemUsage.cpuTemp;
                if (temp > 80) return Foundations.palette.base08;
                if (temp > 65) return Foundations.palette.base09;
                return Foundations.palette.base0D;
            }
            icon: "thermostat"
            value: SystemUsage.cpuTemp
            isPercent: false
        }
    }

    component ResourceItem: RowLayout {
        required property color colour
        required property string icon
        required property real value
        property bool isPercent: true

        spacing: Foundations.spacing.xxxs

        Behavior on value {
            BasicNumberAnimation { }
        }

        Icons.MaterialFontIcon {
            color: parent.colour
            font.pointSize: Foundations.font.size.xs
            text: parent.icon
        }

        Text.BodyS {
            color: parent.colour
            text: isPercent ? Math.round(parent.value * 100) + "%" : Math.round(parent.value) + "°C"
        }
    }
}
