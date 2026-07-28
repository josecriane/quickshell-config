pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property bool isSharing: screenCastNodes.length > 0
    readonly property var screenCastNodes: Pipewire.nodes.values.filter(node => {
        // Detect xdg-desktop-portal-wlr screen cast nodes
        const isWlrScreenCast = (node.name || "").startsWith("xdpw");

        // Also detect video streams (for other apps)
        const isVideoStream = node.isStream && !!node.video;

        return isWlrScreenCast || isVideoStream;
    })

    readonly property var screenCaptureNodes: Pipewire.nodes.values.filter(node => {
        return !node.isStream && 
               node.properties?.["media.class"] === "Video/Source" &&
               node.properties?.["node.description"] &&
               (node.properties["node.description"].includes("screen") ||
                node.properties["node.description"].includes("Screen") ||
                node.properties["node.description"].includes("desktop"))
    })

    // Track all video nodes for debugging
    PwObjectTracker {
        objects: Pipewire.nodes.values.filter(node => 
            node.properties?.["media.class"]?.includes("Video"))
    }

}
