import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.services
import qs.ds

Item {
    id: root

    property color activeColor: Foundations.palette.base0D
    property bool effectsActive: false
    property int horizontalPadding: 8
    property bool hovered: false
    property bool isDestroying: false
    property real masterProgress: 0.0
    required property var screen
    property int spacingBetweenPills: 8
    property ListModel workspaces: ListModel {
    }

    signal workspaceChanged(int workspaceId, color accentColor)

    function triggerUnifiedWave() {
        masterAnimation.restart();
    }
    function updateWorkspaceFocus() {
        const focusedId = Niri.workspaces?.[Niri.focusedWorkspaceIndex]?.id ?? -1;
        for (let i = 0; i < workspaces.count; i++) {
            const ws = workspaces.get(i);
            const isFocused = ws.id === focusedId;
            const isActive = isFocused;
            if (ws.isFocused !== isFocused || ws.isActive !== isActive) {
                workspaces.setProperty(i, "isFocused", isFocused);
                workspaces.setProperty(i, "isActive", isActive);
                if (isFocused) {
                    root.triggerUnifiedWave();
                    root.workspaceChanged(ws.id, root.activeColor);
                }
            }
        }
    }
    function updateWorkspaceList() {
        const newList = Niri.workspaces || [];
        workspaces.clear();
        for (let i = 0; i < newList.length; i++) {
            const ws = newList[i];
            // Only show workspaces for this screen/monitor
            if (ws.output === root.screen.name) {
                // Check workspaces model on niri
                workspaces.append({
                    id: ws.id,
                    idx: ws.idx,
                    name: ws.name || "",
                    output: ws.output,
                    isActive: ws.is_active,
                    isFocused: ws.is_focused,
                    isUrgent: ws.is_urgent
                });
            }
        }
        updateWorkspaceFocus();
    }

    anchors.centerIn: parent
    height: 30
    width: {
        let total = 0;
        for (let i = 0; i < workspaces.count; i++) {
            const ws = workspaces.get(i);
            if (ws.isFocused)
                total += 44;
            else if (ws.isActive)
                total += 28;
            else
                total += 16;
        }
        total += Math.max(workspaces.count - 1, 0) * spacingBetweenPills;
        total += horizontalPadding * 2;
        return total;
    }

    Component.onCompleted: updateWorkspaceList()
    Component.onDestruction: {
        root.isDestroying = true;
    }

    Connections {
        function onFocusedWorkspaceIndexChanged() {
            updateWorkspaceFocus();
        }
        function onWorkspacesChanged() {
            updateWorkspaceList();
        }

        target: Niri
    }
    SequentialAnimation {
        id: masterAnimation

        PropertyAction {
            property: "effectsActive"
            target: root
            value: true
        }
        NumberAnimation {
            duration: Foundations.duration.slow
            easing.type: Easing.OutQuint
            from: 0.0
            property: "masterProgress"
            target: root
            to: 1.0
        }
        PropertyAction {
            property: "effectsActive"
            target: root
            value: false
        }
        PropertyAction {
            property: "masterProgress"
            target: root
            value: 0.0
        }
    }
    Row {
        id: pillRow

        anchors.centerIn: parent
        spacing: spacingBetweenPills
        width: root.width - horizontalPadding * 2
        x: horizontalPadding

        Repeater {
            model: root.workspaces

            Rectangle {
                id: workspacePill

                property bool isHovered: pillMouseArea.containsMouse

                color: {
                    if (model.isFocused) return activeColor;
                    if (isHovered) return Qt.lighter(Foundations.palette.base02, 1.3);
                    return Foundations.palette.base02;
                }
                height: 12
                radius: 6
                scale: model.isFocused ? 1.0 : (isHovered ? 0.95 : 0.9)
                width: {
                    if (model.isFocused)
                        return 44;
                    else if (model.isActive)
                        return 28;
                    else
                        return 16;
                }
                z: 0

                Behavior on color {
                    ColorAnimation {
                        duration: Foundations.duration.fast
                        easing.type: Easing.InOutCubic
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: Foundations.duration.standard
                        easing.type: Easing.OutBack
                    }
                }
                Behavior on width {
                    NumberAnimation {
                        duration: Foundations.duration.standard
                        easing.type: Easing.OutBack
                    }
                }

                MouseArea {
                    id: pillMouseArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: model.isFocused ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: {
                        if (!model.isFocused) {
                            Niri.focusWorkspace(model.id);
                        }
                    }
                }

                // Burst effect overlay for focused pill (smaller outline)
                Rectangle {
                    id: pillBurst

                    anchors.centerIn: parent
                    border.color: root.activeColor
                    border.width: 2 + 6 * (1.0 - root.masterProgress)
                    color: "transparent"
                    height: parent.height + 18 * root.masterProgress
                    opacity: root.effectsActive && model.isFocused ? (1.0 - root.masterProgress) * 0.7 : 0
                    radius: width / 2
                    visible: root.effectsActive && model.isFocused
                    width: parent.width + 18 * root.masterProgress
                    z: 1
                }
            }
        }
    }
}
