import qs.services
import qs.ds
import qs.ds.text as Text
import qs.ds.progress
import qs.ds.icons
import QtQuick
import QtQuick.Layouts
import qs.ds.animations

ColumnLayout {
    id: root

    readonly property int padding: Foundations.spacing.m

    function displayTemp(temp: real): string {
        return `${Math.ceil(temp)}°C`;
    }

    function formatBytes(kib: real): string {
        const fmt = SystemUsage.formatKib(kib);
        return `${+fmt.value.toFixed(1)}${fmt.unit}`;
    }

    spacing: padding
    width: 400

    // Keeps SystemUsage sampling the GPU only while this popup exists
    Component.onCompleted: SystemUsage.refCount++
    Component.onDestruction: SystemUsage.refCount--

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: padding
        Layout.rightMargin: padding
        Layout.topMargin: padding / 2

        Text.HeadingS {
            Layout.fillWidth: true
            text: qsTr("System Performance")
        }
    }

    // CPU Section
    ResourceBar {
        Layout.fillWidth: true
        Layout.leftMargin: padding
        Layout.rightMargin: padding

        icon: "speed"
        title: "CPU"
        resourceValue: SystemUsage.cpuPerc || 0
        label: `${Math.round((SystemUsage.cpuPerc || 0) * 100)}%`
        sublabel: root.displayTemp(SystemUsage.cpuTemp || 0)
        barColor: Foundations.palette.base05
    }

    // GPU Section (if available)
    ResourceBar {
        Layout.fillWidth: true
        Layout.leftMargin: padding
        Layout.rightMargin: padding
        visible: SystemUsage.gpuType !== "NONE"

        icon: "memory"
        title: "GPU"
        resourceValue: SystemUsage.gpuPerc || 0
        label: `${Math.round((SystemUsage.gpuPerc || 0) * 100)}%`
        sublabel: root.displayTemp(SystemUsage.gpuTemp || 0)
        barColor: Foundations.palette.base05
    }

    // Memory Section
    ResourceBar {
        Layout.fillWidth: true
        Layout.leftMargin: padding
        Layout.rightMargin: padding

        icon: "memory_alt"
        title: "Memory"
        resourceValue: SystemUsage.memPerc || 0
        label: `${Math.round((SystemUsage.memPerc || 0) * 100)}%`
        sublabel: `${root.formatBytes(SystemUsage.memUsed || 0)} / ${root.formatBytes(SystemUsage.memTotal || 0)}`
        barColor: Foundations.palette.base05
    }

    // Storage Section
    ResourceBar {
        Layout.fillWidth: true
        Layout.leftMargin: padding
        Layout.rightMargin: padding
        Layout.bottomMargin: padding

        icon: "storage"
        title: "Storage"
        resourceValue: SystemUsage.storagePerc || 0
        label: `${root.formatBytes((SystemUsage.storageTotal || 0) - (SystemUsage.storageUsed || 0))} free`
        sublabel: `${root.formatBytes(SystemUsage.storageUsed || 0)} / ${root.formatBytes(SystemUsage.storageTotal || 0)}`
        barColor: Foundations.palette.base05
    }

    component ResourceBar: ColumnLayout {
        property color barColor: Foundations.palette.base05
        property string icon: ""
        property string label: ""
        property string sublabel: ""
        property string title: ""
        property real resourceValue: 0.0

        spacing: Foundations.spacing.xs

        // Title row with icon and labels
        RowLayout {
            Layout.fillWidth: true
            spacing: Foundations.spacing.m

            // Icon and title (left side, vertically centered)
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: Foundations.spacing.m

                MaterialFontIcon {
                    color: barColor
                    font.pointSize: Foundations.font.size.m
                    text: icon
                }

                Text.BodyM {
                    text: title
                    color: Foundations.palette.base05
                }
            }

            Item { Layout.fillWidth: true }

            // Values (right side)
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text.BodyS {
                    Layout.alignment: Qt.AlignRight
                    text: label
                    color: barColor
                    font.family: Foundations.font.family.mono
                }

                Text.BodyS {
                    Layout.alignment: Qt.AlignRight
                    text: sublabel
                    color: Foundations.palette.base04
                }
            }
        }

        // Progress bar
        LinearProgress {
            Layout.fillWidth: true
            Layout.preferredHeight: Foundations.spacing.xs

            fgColour: barColor
            bgColour: Foundations.palette.base03
            value: resourceValue
        }
    }
}
