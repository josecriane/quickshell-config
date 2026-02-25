pragma ComponentBehavior: Bound

import qs.services
import qs.ds
import qs.ds.buttons as Buttons
import qs.ds.buttons.circularButtons as CircularButtons
import qs.ds.list as Lists
import qs.ds.text as Text
import qs.ds as Ds
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.ds.animations

Item {
    id: root

    required property var wrapper

    property int margin: Foundations.spacing.s

    implicitHeight: layout.implicitHeight + margin * 2
    implicitWidth: layout.implicitWidth + margin * 2

    ButtonGroup {
        id: sinks

    }
    ButtonGroup {
        id: sources

    }
    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Text.HeadingS {
            Layout.bottomMargin: Foundations.spacing.xxs
            text: qsTr("Output device")
        }
        Repeater {
            id: sinksRepeater

            model: Audio.sinks

            Lists.ListItem {
                required property PwNode modelData

                buttonGroup: sinks
                selected: Audio.sink?.id === modelData.id
                text: modelData.description

                onClicked: {
                    Audio.setAudioSink(modelData);
                }
            }
        }
        Text.HeadingS {
            Layout.bottomMargin: root.margin
            Layout.topMargin: root.margin
            text: qsTr("Volume (%1)").arg(Audio.muted ? qsTr("Muted") : `${Math.round(Audio.volume * 100)}%`)
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: root.margin
            
            Ds.Slider {
                Layout.fillWidth: true
                implicitHeight: Foundations.spacing.s * 3
                value: Audio.volume

                Behavior on value {
                    BasicNumberAnimation {
                    }
                }

                onMoved: Audio.setVolume(value)
                onWheelDown: Audio.decrementVolume()
                onWheelUp: Audio.incrementVolume()
            }
            CircularButtons.L {
                icon: Audio.muted ? "volume_off" : "volume_up"
                active: Audio.muted
                onClicked: Audio.toggleMute()
            }
        }

        Text.HeadingS {
            Layout.bottomMargin: root.margin
            Layout.topMargin: root.margin
            text: qsTr("Input device")
        }
        Repeater {
            id: sourcesRepeater

            model: Audio.sources

            Lists.ListItem {
                required property PwNode modelData

                buttonGroup: sources
                selected: Audio.source?.id === modelData.id
                text: modelData.description

                onClicked: {
                    Audio.setAudioSource(modelData);
                }
            }
        }
        Text.HeadingS {
            Layout.bottomMargin: root.margin
            Layout.topMargin: root.margin
            text: qsTr("Volume (%1)").arg(Audio.sourceMuted ? qsTr("Muted") : `${Math.round(Audio.sourceVolume * 100)}%`)
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: root.margin
            
            Ds.Slider {
                Layout.fillWidth: true
                implicitHeight: Foundations.spacing.s * 3
                value: Audio.sourceVolume

                Behavior on value {
                    BasicNumberAnimation {
                    }
                }

                onMoved: Audio.setSourceVolume(value)
                onWheelDown: Audio.decrementSourceVolume()
                onWheelUp: Audio.incrementSourceVolume()
            }
            CircularButtons.L {
                icon: Audio.sourceMuted ? "mic_off" : "mic"
                active: Audio.sourceMuted
                onClicked: Audio.toggleSourceMute()
            }
        }
    }

    // Update selection when audio devices change externally
    Connections {
        function onSinkChanged() {
            for (let i = 0; i < sinksRepeater.count; i++) {
                let item = sinksRepeater.itemAt(i);
                if (item) {
                    item.selected = (Audio.sink?.id === item.modelData.id);
                }
            }
        }
        function onSourceChanged() {
            for (let i = 0; i < sourcesRepeater.count; i++) {
                let item = sourcesRepeater.itemAt(i);
                if (item) {
                    item.selected = (Audio.source?.id === item.modelData.id);
                }
            }
        }

        target: Audio
    }
}
