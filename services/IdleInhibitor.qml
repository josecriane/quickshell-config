pragma Singleton

import Quickshell

Singleton {
    id: root

    property alias enabled: props.enabled

    PersistentProperties {
        id: props

        property bool enabled

        reloadableId: "idleInhibitor"
    }
}
