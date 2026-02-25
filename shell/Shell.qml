pragma ComponentBehavior: Bound

import qs.services
import qs.ds
import qs.modules.bar
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs.ds.animations

Variants {
    id: root

    required property int marginSize
    required property int radiusSize
    required property int barSize

    model: Quickshell.screens

    Scope {
        id: scope

        required property ShellScreen modelData

        Exclusions {
            bar: bar
            margin: root.marginSize
            screen: scope.modelData
        }
        PanelWindow {
            id: win

            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: visibilities.captureKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.namespace: `quickshell-drawers`
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            anchors.top: true
            color: "transparent"
            screen: scope.modelData

            mask: Region {
                height: win.height - bar.implicitHeight - root.marginSize
                intersection: Intersection.Xor
                regions: regions.instances
                width: win.width - root.marginSize * 2
                x: root.marginSize
                y: bar.implicitHeight
            }

            Variants {
                id: regions

                model: panels.children

                Region {
                    required property Item modelData

                    height: modelData.visible ? modelData.height : 0
                    intersection: Intersection.Subtract
                    width: modelData.visible ? modelData.width : 0
                    x: modelData.x + root.marginSize
                    y: modelData.y + bar.implicitHeight
                }
            }

            Rectangle {
                id: disabledBackground

                anchors.fill: parent
                color: "#000000"
                opacity: visibilities.captureKeyboard ? 0.5 : 0

                Behavior on opacity {
                    BasicNumberAnimation {
                    }
                }
            }
            Item {
                anchors.fill: parent
                layer.enabled: true
                opacity: 1

                layer.effect: MultiEffect {
                    blurMax: 15
                    shadowColor: Qt.alpha("#000000", 0.7)
                    shadowEnabled: true
                }

                Border {
                    bar: bar
                    margin: root.marginSize
                    radius: root.radiusSize
                }
                Backgrounds {
                    bar: bar
                    panels: panels
                    margin: root.marginSize
                    radius: root.radiusSize
                }
            }
            PersistentProperties {
                id: visibilities

                property bool bar
                property bool launcher
                property bool notifications
                property string searchText: ""
                property var launcherList: null

                readonly property bool captureKeyboard: launcher | notifications | panels.popouts.needsFocus

                Component.onCompleted: Visibilities.load(scope.modelData, this)
            }
            Interactions {
                bar: bar
                panels: panels
                popouts: panels.popouts
                screen: scope.modelData
                visibilities: visibilities
                margin: root.marginSize
                radius: root.radiusSize

                Panels {
                    id: panels

                    bar: bar
                    screen: scope.modelData
                    visibilities: visibilities
                    margin: root.marginSize
                }
                BarWrapper {
                    id: bar

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    popouts: panels.popouts
                    screen: scope.modelData
                    visibilities: visibilities
                    margin: root.marginSize
                    barHeight: root.barSize

                    Component.onCompleted: Visibilities.bars.set(scope.modelData, this)
                }
            }
        }
    }
}
