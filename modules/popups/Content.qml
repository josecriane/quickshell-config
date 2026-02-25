pragma ComponentBehavior: Bound

import qs.ds
import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import qs.ds.animations

Item {
    id: root

    required property Item wrapper

    property int margin: Foundations.spacing.l
    property int itemSpacing: Foundations.spacing.xxs

    anchors.centerIn: parent
    implicitHeight: (content.children.find(c => c.shouldBeActive)?.implicitHeight ?? 0) + margin * 2
    implicitWidth: (content.children.find(c => c.shouldBeActive)?.implicitWidth ?? 0) + margin * 2

    Item {
        id: content

        anchors.fill: parent
        anchors.margins: root.margin

        Popout {
            name: "network"

            sourceComponent: Network {
                wrapper: root.wrapper
            }
        }
        Popout {
            name: "vpn"
            sourceComponent: VPN {
            }
        }
        Popout {
            name: "bluetooth"

            sourceComponent: Bluetooth {
                wrapper: root.wrapper
            }
        }
        Popout {
            name: "battery"
            source: "Battery.qml"
        }
        Popout {
            name: "audio"

            sourceComponent: Audio {
                wrapper: root.wrapper
            }
        }
        Popout {
            name: "kblayout"
            source: "KbLayout.qml"
        }
        Popout {
            name: "calendar"
            source: "Calendar.qml"
        }
        Popout {
            name: "systemtray"
            source: "Performance.qml"
        }
        Repeater {
            model: ScriptModel {
                values: [...SystemTray.items.values]
            }

            Popout {
                id: trayMenu

                required property int index
                required property SystemTrayItem modelData

                name: `traymenu${index}`
                sourceComponent: trayMenuComp

                Connections {
                    function onHasCurrentChanged(): void {
                        if (root.wrapper.hasCurrent && trayMenu.shouldBeActive) {
                            trayMenu.sourceComponent = null;
                            trayMenu.sourceComponent = trayMenuComp;
                        }
                    }

                    target: root.wrapper
                }
                Component {
                    id: trayMenuComp

                    TrayMenu {
                        popouts: root.wrapper
                        trayItem: trayMenu.modelData.menu
                    }
                }
            }
        }
    }

    component Popout: Loader {
        id: popout

        required property string name
        property bool shouldBeActive: root.wrapper.currentName === name

        active: false
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        asynchronous: true
        opacity: 0
        scale: 0.8

        states: State {
            name: "active"
            when: popout.shouldBeActive

            PropertyChanges {
                popout.active: true
                popout.opacity: 1
                popout.scale: 1
            }
        }
        transitions: [
            Transition {
                from: "active"
                to: ""

                SequentialAnimation {
                    BasicNumberAnimation {
                        duration: Foundations.duration.fast
                        properties: "opacity,scale"
                    }
                    PropertyAction {
                        property: "active"
                        target: popout
                    }
                }
            },
            Transition {
                from: ""
                to: "active"

                SequentialAnimation {
                    PropertyAction {
                        property: "active"
                        target: popout
                    }
                    BasicNumberAnimation {
                        properties: "opacity,scale"
                    }
                }
            }
        ]
    }
}
