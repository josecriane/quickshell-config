pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // mmsg cannot enumerate layouts, so this mirrors xkb_rules_layout/variant
    // in the mango config. Order must match.
    readonly property list<string> kbLayouts: ["English (Dvorak, Macintosh, ANSI)", "English (Macintosh, ABC, ANSI)"]
    property int currentKbLayoutIndex: 0
    property string focusedOutput: ""
    property int focusedWorkspaceIndex: 0
    property list<var> workspaces: []
    property var lastAllTags: []

    // Function to get current layout name
    function currentKbLayoutName(): string {
        if (root.currentKbLayoutIndex >= 0 && root.currentKbLayoutIndex < root.kbLayouts.length) {
            return root.kbLayouts[root.currentKbLayoutIndex];
        }
        return "";
    }

    // Query windows by app id and invoke callback with found window (or null)
    // Optional titleHint can be provided for fuzzy matching (e.g., notification summary)
    function getWindowByAppId(appId: string, callback: var, titleHint: string): void {
        console.log("getWindowByAppId called with:", appId, "titleHint:", titleHint);
        const hint = titleHint || "";
        windowQueryComponent.createObject(root, {
            targetAppId: appId.toLowerCase(),
            titleHint: hint.toLowerCase(),
            resultCallback: callback
        });
    }

    // Focus a window by its ID
    function focusWindowById(windowId: int): void {
        console.log("focusWindowById called with:", windowId);
        focusWindowComponent.createObject(root, {
            windowId: windowId
        });
    }

    function spawn(command: string): void {
        spawnProcess.command = ["mmsg", "dispatch", "spawn," + command];
        spawnProcess.running = false;
        spawnProcess.running = true;
    }

    // Function to switch keyboard layout
    function switchKbLayout(index: int): void {
        // mango's index is 1-based; 0 means "cycle to next"
        switchLayoutProcess.command = ["mmsg", "dispatch", "switch_keyboard_layout," + (index + 1).toString()];
        switchLayoutProcess.running = false;
        switchLayoutProcess.running = true;
    }

    // Function to view a tag by number (1-9)
    function focusWorkspace(workspaceId: int): void {
        focusWorkspaceProcess.command = ["mmsg", "dispatch", "view," + workspaceId.toString() + ",0"];
        focusWorkspaceProcess.running = false;
        focusWorkspaceProcess.running = true;
    }

    // Every monitor always exposes mango's nine compiled-in tags; tagCount
    // must match the tags bound in the mango config. A tag is "active" when
    // viewed on its monitor and "focused" when also on the focused monitor.
    readonly property int tagCount: 7

    function rebuildWorkspaces(): void {
        const list = [];
        let focusedIndex = 0;
        for (const entry of root.lastAllTags) {
            for (const tag of (entry.tags || [])) {
                if (tag.index > root.tagCount) {
                    continue;
                }
                const isActive = tag.is_active === true;
                const isFocused = isActive && entry.monitor === root.focusedOutput;
                if (isFocused && list.findIndex(w => w.is_focused) < 0) {
                    focusedIndex = list.length;
                }
                list.push({
                    id: tag.index,
                    idx: tag.index - 1,
                    name: "",
                    output: entry.monitor,
                    is_active: isActive,
                    is_focused: isFocused,
                    is_urgent: tag.is_urgent === true,
                    occupied: (tag.client_count || 0) > 0
                });
            }
        }
        root.workspaces = list;
        root.focusedWorkspaceIndex = focusedIndex;
    }

    Process {
        command: ["mmsg", "watch", "all-tags"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                try {
                    const event = JSON.parse(data.trim());
                    if (event.all_tags) {
                        root.lastAllTags = event.all_tags;
                        root.rebuildWorkspaces();
                    }
                } catch (e) {
                    console.log("Error parsing all-tags:", e);
                }
            }
        }
    }

    Process {
        command: ["mmsg", "watch", "all-monitors"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                try {
                    const event = JSON.parse(data.trim());
                    const monitors = event.monitors || [];
                    const active = monitors.find(m => m.active);
                    if (active && active.name !== root.focusedOutput) {
                        root.focusedOutput = active.name;
                        root.rebuildWorkspaces();
                    }
                } catch (e) {
                    console.log("Error parsing all-monitors:", e);
                }
            }
        }
    }

    // Focus changes are reported here faster than via all-monitors
    Process {
        command: ["mmsg", "watch", "focusing-client"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                try {
                    const event = JSON.parse(data.trim());
                    if (event.monitor && event.monitor !== root.focusedOutput) {
                        root.focusedOutput = event.monitor;
                        root.rebuildWorkspaces();
                    }
                } catch (e) {
                    console.log("Error parsing focusing-client:", e);
                }
            }
        }
    }

    Process {
        command: ["mmsg", "watch", "keyboardlayout"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                try {
                    const event = JSON.parse(data.trim());
                    if (event.layout === undefined) {
                        return;
                    }
                    // mango truncates the name to 31 chars, so match by prefix
                    const index = root.kbLayouts.findIndex(n => n.startsWith(event.layout));
                    if (index >= 0) {
                        root.currentKbLayoutIndex = index;
                    }
                } catch (e) {
                    console.log("Error parsing keyboardlayout:", e);
                }
            }
        }
    }

    // Process for switching keyboard layout
    Process {
        id: switchLayoutProcess

        running: false
    }

    // Process for focusing workspace
    Process {
        id: focusWorkspaceProcess

        running: false
    }

    Process {
        id: spawnProcess

        running: false
    }

    Component {
        id: windowQueryComponent

        Process {
            property string targetAppId
            property string titleHint
            property var resultCallback

            command: ["mmsg", "get", "all-clients"]
            running: true

            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        const parsed = JSON.parse(text.trim());
                        const windows = parsed.clients || [];
                        console.log("Clients query returned:", windows.length, "clients");

                        // Find window matching the target appid
                        // Strategy:
                        // 1. Exact appid match (most reliable)
                        // 2. If titleHint provided and we have PWA-like windows, match by title
                        // 3. Fallback: don't match (to avoid focusing wrong PWA)

                        // First pass: try exact match
                        for (let i = 0; i < windows.length; i++) {
                            const window = windows[i];
                            const windowAppId = (window.appid || "").toLowerCase();

                            if (windowAppId === targetAppId) {
                                console.log("Found exact appid match:", window.title);
                                resultCallback(window);
                                return;
                            }
                        }

                        // Second pass: if titleHint provided, try title matching for PWA-like windows
                        if (titleHint && titleHint.length > 0) {
                            const searchPrefix = targetAppId.replace("google-", "").replace("-", "");

                            for (let i = 0; i < windows.length; i++) {
                                const window = windows[i];
                                const windowAppId = (window.appid || "").toLowerCase();
                                const windowTitle = (window.title || "").toLowerCase();

                                // Only do fuzzy matching for PWA-like windows (chrome-, firefox-, etc.)
                                if (windowAppId.startsWith(searchPrefix + "-")) {
                                    console.log("Checking PWA window:", windowTitle, "against hint:", titleHint);

                                    // Check if title contains any significant words from the hint
                                    const hintWords = titleHint.split(/\s+/).filter(w => w.length > 3);
                                    for (const word of hintWords) {
                                        if (windowTitle.includes(word)) {
                                            console.log("Found title match with word:", word, "in window:", window.title);
                                            resultCallback(window);
                                            return;
                                        }
                                    }
                                }
                            }
                        }

                        // No match found
                        console.log("No matching window found for appid:", targetAppId);
                        resultCallback(null);
                    } catch (e) {
                        console.log("Error parsing clients JSON:", e);
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

            command: ["mmsg", "dispatch", "focusid", "client," + windowId.toString()]
            running: true
        }
    }
}
