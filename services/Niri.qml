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

    function spawn(command: string): void {
        spawnProcess.command = ["niri", "msg", "action", "spawn", "--"].concat(command.split(" "));
        spawnProcess.running = false;
        spawnProcess.running = true;
    }

    // Function to focus a Window
    function focusWindowById(windowId: int): void {
        focusWindowProcess.command = ["niri", "msg", "action", "focus-window", "--id", windowId.toString()]
        focusWindowProcess.running = false;
        focusWindowProcess.running = true;
    }

    // Function to get a windowId
    function getWindowByAppId(appId: string, callback: var, titleHint: string): void {
        const hint = titleHint || "";

        getWindowIdProcess.running = false;
        getWindowIdProcess.targetAppId = appId.toLowerCase();
        getWindowIdProcess.titleHint = hint.toLowerCase();
        getWindowIdProcess.resultCallback = callback;
        getWindowIdProcess.running = true;
    }

    // Function to switch keyboard layout
    function switchKbLayout(index: int): void {
        switchLayoutProcess.command = ["niri", "msg", "action", "switch-layout", index.toString()];
        switchLayoutProcess.running = false;
        switchLayoutProcess.running = true;
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

                // Update focused output on any event that might change focus
                if (event.WorkspaceActivated || event.WindowFocusChanged || event.WindowOpenedOrClosed) {
                    root.updateFocusedOutput();
                }
            }
        }
    }

    // Process to get a window id
    Process {
        id: getWindowIdProcess

        property string targetAppId
        property string titleHint
        property var resultCallback

        command: ["niri", "msg", "-j", "windows"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const windows = JSON.parse(text.trim());

                    // Find window matching the target appId
                    // Strategy:
                    // 1. Exact app_id match (most reliable)
                    // 2. If titleHint provided and we have PWA-like windows, match by title
                    // 3. Fallback: don't match (to avoid focusing wrong PWA)

                    // First pass: try exact match
                    for (let i = 0; i < windows.length; i++) {
                        const window = windows[i];
                        const windowAppId = (window.app_id || "").toLowerCase();

                        if (windowAppId === getWindowIdProcess.targetAppId) {
                            getWindowIdProcess.resultCallback(window);
                            return;
                        }
                    }

                    // Second pass: if titleHint provided, try title matching for PWA-like windows
                    if (getWindowIdProcess.titleHint && getWindowIdProcess.titleHint.length > 0) {
                        const searchPrefix = getWindowIdProcess.targetAppId.replace("google-", "").replace("-", "");

                        for (let i = 0; i < windows.length; i++) {
                            const window = windows[i];
                            const windowAppId = (window.app_id || "").toLowerCase();
                            const windowTitle = (window.title || "").toLowerCase();

                            // Only do fuzzy matching for PWA-like windows (chrome-, firefox-, etc.)
                            if (windowAppId.startsWith(searchPrefix + "-")) {
                                // Check if title contains any significant words from the hint
                                const hintWords = getWindowIdProcess.titleHint.split(/\s+/).filter(w => w.length > 3);
                                for (const word of hintWords) {
                                    if (windowTitle.includes(word)) {
                                        getWindowIdProcess.resultCallback(window);
                                        return;
                                    }
                                }
                            }
                        }
                    }

                    // No match found
                    console.log("No matching window found for app_id:", getWindowIdProcess.targetAppId);
                    getWindowIdProcess.resultCallback(null);
                } catch (e) {
                    console.log("Error parsing windows JSON:", e);
                    getWindowIdProcess.resultCallback(null);
                }
            }
        }
    }

    // Process for switch the focused window
    // Process for switching keyboard layout
    Process {
        id: switchLayoutProcess

        running: false
    }

    Process {
        id: focusWindowProcess

        running: false
    }

    // Get initial keyboard layouts with a separate Process
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
                // Extract the output name from the first line
                const firstLine = text.split("\n")[0];
                const match = firstLine.match(/\(([^)]+)\)/);
                if (match) {
                    root.focusedOutput = match[1];
                }
            }
        }
    }
}
