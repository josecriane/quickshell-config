pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int currentKbLayoutIndex: 0
    property string focusedOutput: ""
    property int focusedWorkspaceIndex: 0
    property bool inOverview: false
    property list<string> kbLayouts: []
    property list<var> workspaces: []

    // Function to get current layout name
    function currentKbLayoutName(): string {
        if (root.currentKbLayoutIndex >= 0 && root.currentKbLayoutIndex < root.kbLayouts.length) {
            return root.kbLayouts[root.currentKbLayoutIndex];
        }
        return "";
    }

    function getWindowByAppId(appId: string, callback: var, titleHint: string): void {
        const hint = titleHint || "";
        windowQueryComponent.createObject(root, {
            targetAppId: appId.toLowerCase(),
            titleHint: hint.toLowerCase(),
            resultCallback: callback
        });
    }

    function focusWindowById(windowId: int): void {
        focusWindowComponent.createObject(root, {
            windowId: windowId
        });
    }

    function spawn(command: string): void {
        spawnProcess.command = ["niri", "msg", "action", "spawn", "--"].concat(command.split(" "));
        spawnProcess.running = false;
        spawnProcess.running = true;
    }

    function switchKbLayout(index: int): void {
        switchLayoutProcess.command = ["niri", "msg", "action", "switch-layout", index.toString()];
        switchLayoutProcess.running = false;
        switchLayoutProcess.running = true;
    }

    function focusWorkspace(workspaceId: int): void {
        focusWorkspaceProcess.command = ["niri", "msg", "action", "focus-workspace", workspaceId.toString()];
        focusWorkspaceProcess.running = false;
        focusWorkspaceProcess.running = true;
    }

    function updateFocusedOutput(): void {
        focusedOutputProcess.running = false;
        focusedOutputProcess.running = true;
    }

    Component.onCompleted: {
        layoutsInitProcess.running = true;
        updateFocusedOutput();
    }

    Process {
        command: ["niri", "msg", "-j", "event-stream"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const event = JSON.parse(data.trim());

                if (event.WorkspacesChanged) {
                    root.workspaces = [...event.WorkspacesChanged.workspaces].sort((a, b) => a.idx - b.idx);
                    root.focusedWorkspaceIndex = root.workspaces.findIndex(w => w.is_focused);
                    if (root.focusedWorkspaceIndex < 0) {
                        root.focusedWorkspaceIndex = 0;
                    }
                } else if (event.WorkspaceActivated) {
                    root.focusedWorkspaceIndex = root.workspaces.findIndex(w => w.id === event.WorkspaceActivated.id);
                    if (root.focusedWorkspaceIndex < 0) {
                        root.focusedWorkspaceIndex = 0;
                    }
                } else if (event.OverviewOpenedOrClosed) {
                    root.inOverview = event.OverviewOpenedOrClosed.is_open;
                } else if (event.KeyboardLayoutsChanged) {
                    root.kbLayouts = [];
                    root.currentKbLayoutIndex = -1;

                    const layouts = event.KeyboardLayoutsChanged.keyboard_layouts;
                    if (layouts && layouts.names) {
                        root.kbLayouts = layouts.names;
                        root.currentKbLayoutIndex = layouts.current_idx || 0;
                    }
                } else if (event.KeyboardLayoutSwitched) {
                    root.currentKbLayoutIndex = event.KeyboardLayoutSwitched.idx;
                }

                if (event.WorkspaceActivated || event.WindowFocusChanged || event.WindowOpenedOrClosed) {
                    root.updateFocusedOutput();
                }
            }
        }
    }

    Process {
        id: switchLayoutProcess

        running: false
    }

    Process {
        id: focusWorkspaceProcess

        running: false
    }

    Process {
        id: layoutsInitProcess

        command: ["niri", "msg", "-j", "keyboard-layouts"]
        running: false

        onStdoutChanged: {
            try {
                const data = JSON.parse(stdout.trim());
                if (data.names) {
                    root.kbLayouts = data.names;
                    root.currentKbLayoutIndex = data.current_idx || 0;
                }
            } catch (e) {
                console.log("Error parsing keyboard layouts:", e);
            }
        }
    }
    Process {
        id: spawnProcess

        running: false
    }

    Process {
        id: focusedOutputProcess

        command: ["niri", "msg", "focused-output"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const firstLine = text.split("\n")[0];
                const match = firstLine.match(/\(([^)]+)\)/);
                if (match) {
                    root.focusedOutput = match[1];
                }
            }
        }
    }

    Component {
        id: windowQueryComponent

        Process {
            property string targetAppId
            property string titleHint
            property var resultCallback

            command: ["niri", "msg", "-j", "windows"]
            running: true

            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        const windows = JSON.parse(text.trim());

                        // Find window matching the target app_id
                        // Strategy:
                        // 1. Exact app_id match (most reliable)
                        // 2. If titleHint provided and we have PWA-like windows, match by title
                        // 3. Fallback: don't match (to avoid focusing wrong PWA)
                        for (let i = 0; i < windows.length; i++) {
                            const window = windows[i];
                            const windowAppId = (window.app_id || "").toLowerCase();

                            if (windowAppId === targetAppId) {
                                resultCallback(window);
                                return;
                            }
                        }

                        if (titleHint && titleHint.length > 0) {
                            const searchPrefix = targetAppId.replace("google-", "").replace("-", "");

                            for (let i = 0; i < windows.length; i++) {
                                const window = windows[i];
                                const windowAppId = (window.app_id || "").toLowerCase();
                                const windowTitle = (window.title || "").toLowerCase();

                                if (windowAppId.startsWith(searchPrefix + "-")) {
                                    const hintWords = titleHint.split(/\s+/).filter(w => w.length > 3);
                                    for (const word of hintWords) {
                                        if (windowTitle.includes(word)) {
                                            resultCallback(window);
                                            return;
                                        }
                                    }
                                }
                            }
                        }

                        resultCallback(null);
                    } catch (e) {
                        console.log("Error parsing windows JSON:", e);
                        resultCallback(null);
                    }
                }
            }
        }
    }

    Component {
        id: focusWindowComponent

        Process {
            property int windowId

            command: ["niri", "msg", "action", "focus-window", "--id", windowId.toString()]
            running: true
        }
    }
}
