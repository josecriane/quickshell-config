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
    readonly property int pillActiveWidth: 28
    readonly property int pillFocusedWidth: 44
    readonly property int pillHeight: 12
    readonly property int pillIdleWidth: 16
    required property var screen
    property real scrollAccumulated: 0
    property int scrollPendingSteps: 0
    property int scrollTargetRow: -1
    property int spacingBetweenPills: 8
    property ListModel workspaces: ListModel {
    }

    signal workspaceChanged(int workspaceId, color accentColor)

    function focusedRow(): int {
        for (let i = 0; i < workspaces.count; i++) {
            if (workspaces.get(i).isFocused)
                return i;
        }
        return -1;
    }
    function rowForId(id: int, from: int): int {
        for (let i = from; i < workspaces.count; i++) {
            if (workspaces.get(i).id === id)
                return i;
        }
        return -1;
    }
    function stepScroll() {
        if (root.scrollPendingSteps === 0) {
            root.scrollTargetRow = -1;
            return;
        }
        const step = root.scrollPendingSteps > 0 ? 1 : -1;
        root.scrollPendingSteps -= step;
        // niri's model lags behind the action, so a queued burst walks from
        // the last requested row rather than the one the pills still show
        const current = root.scrollTargetRow >= 0 ? root.scrollTargetRow : root.focusedRow();
        const target = current - step;
        if (current < 0 || target < 0 || target >= workspaces.count) {
            root.scrollPendingSteps = 0;
            root.scrollAccumulated = 0;
            root.scrollTargetRow = -1;
            return;
        }
        root.scrollTargetRow = target;
        Niri.focusWorkspace(workspaces.get(target).idx);
        scrollGuard.restart();
    }
    function triggerUnifiedWave() {
        masterAnimation.restart();
    }
    function updateWorkspaceFocus() {
        const focusedId = Niri.workspaces?.[Niri.focusedWorkspaceIndex]?.id ?? -1;
        for (let i = 0; i < workspaces.count; i++) {
            const ws = workspaces.get(i);
            const isFocused = ws.id === focusedId;
            if (ws.isFocused !== isFocused) {
                workspaces.setProperty(i, "isFocused", isFocused);
                if (isFocused) {
                    root.triggerUnifiedWave();
                    root.workspaceChanged(ws.id, root.activeColor);
                }
            }
        }
    }
    function updateWorkspaceList() {
        const incoming = (Niri.workspaces || []).filter(ws => ws.output === root.screen.name);

        for (let i = workspaces.count - 1; i >= 0; i--) {
            if (!incoming.some(ws => ws.id === workspaces.get(i).id))
                workspaces.remove(i);
        }

        for (let i = 0; i < incoming.length; i++) {
            const ws = incoming[i];
            const fields = {
                id: ws.id,
                idx: ws.idx,
                name: ws.name || "",
                output: ws.output,
                isActive: ws.is_active === true,
                isUrgent: ws.is_urgent === true,
                occupied: ws.active_window_id !== null && ws.active_window_id !== undefined
            };

            const row = root.rowForId(ws.id, i);
            if (row < 0) {
                workspaces.insert(i, Object.assign({
                    isFocused: false
                }, fields));
                continue;
            }
            if (row !== i)
                workspaces.move(row, i, 1);

            const current = workspaces.get(i);
            for (const key in fields) {
                if (current[key] !== fields[key])
                    workspaces.setProperty(i, key, fields[key]);
            }
        }

        updateWorkspaceFocus();
    }

    implicitHeight: 30
    implicitWidth: {
        let total = 0;
        for (let i = 0; i < workspaces.count; i++) {
            const ws = workspaces.get(i);
            if (ws.isFocused)
                total += root.pillFocusedWidth;
            else if (ws.isActive)
                total += root.pillActiveWidth;
            else
                total += root.pillIdleWidth;
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
    Timer {
        id: scrollGuard

        interval: 80

        onTriggered: root.stepScroll()
    }
    Row {
        id: pillRow

        anchors.centerIn: parent
        spacing: spacingBetweenPills

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

            onWheel: event => {
                root.scrollAccumulated += event.angleDelta.y;
                const steps = Math.trunc(root.scrollAccumulated / 120);
                if (steps === 0)
                    return;
                root.scrollAccumulated -= steps * 120;
                root.scrollPendingSteps += steps;
                if (!scrollGuard.running)
                    root.stepScroll();
            }
        }

        Repeater {
            model: root.workspaces

            Rectangle {
                id: workspacePill

                property bool isHovered: pillMouseArea.containsMouse

                color: {
                    if (model.isFocused)
                        return activeColor;
                    if (model.isUrgent)
                        return Foundations.palette.base08;
                    if (isHovered)
                        return Qt.lighter(Foundations.palette.base02, 1.3);
                    if (model.occupied)
                        return Qt.lighter(Foundations.palette.base02, 1.15);
                    return Foundations.palette.base02;
                }
                height: root.pillHeight
                radius: root.pillHeight / 2
                scale: model.isFocused ? 1.0 : (isHovered ? 0.95 : 0.9)
                width: {
                    if (model.isFocused)
                        return root.pillFocusedWidth;
                    else if (model.isActive)
                        return root.pillActiveWidth;
                    else
                        return root.pillIdleWidth;
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

                SequentialAnimation {
                    id: urgentPulse

                    loops: Animation.Infinite
                    running: model.isUrgent && !model.isFocused

                    onStopped: workspacePill.opacity = 1.0

                    NumberAnimation {
                        duration: Foundations.duration.slow
                        easing.type: Easing.InOutQuad
                        property: "opacity"
                        target: workspacePill
                        to: 0.35
                    }
                    NumberAnimation {
                        duration: Foundations.duration.slow
                        easing.type: Easing.InOutQuad
                        property: "opacity"
                        target: workspacePill
                        to: 1.0
                    }
                }

                MouseArea {
                    id: pillMouseArea

                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: model.isFocused ? Qt.ArrowCursor : Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            Niri.moveWindowToWorkspace(model.idx);
                            moveFlashAnimation.restart();
                            return;
                        }
                        if (!model.isFocused)
                            Niri.focusWorkspace(model.idx);
                    }
                }

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

                Rectangle {
                    id: moveFlash

                    anchors.fill: parent
                    color: Foundations.palette.base0B
                    opacity: 0
                    radius: parent.radius
                    z: 2

                    NumberAnimation {
                        id: moveFlashAnimation

                        duration: Foundations.duration.standard
                        easing.type: Easing.OutCubic
                        from: 0.85
                        property: "opacity"
                        target: moveFlash
                        to: 0
                    }
                }
            }
        }
    }
}
