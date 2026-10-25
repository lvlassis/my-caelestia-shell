pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.I18n

Singleton {
    id: root

    property bool connected: false
    readonly property bool connecting: startProc.running
    readonly property bool disconnecting: stopProc.running

    function connect(): void {
        if (!connected && !connecting)
            startProc.running = true
    }

    function disconnect(): void {
        if (connected && !disconnecting)
            stopProc.running = true
    }

    function toggle(): void {
        if (connected || connecting)
            disconnect()
        else
            connect()
    }

    onConnectedChanged: {
        if (connected)
            Toaster.toast(Tr.tr("Work network connected"), Tr.tr("VPN and SSH tunnel active"), "corporate_fare")
        else if (!connecting)
            Toaster.toast(Tr.tr("Work network disconnected"), Tr.tr("VPN and SSH tunnel stopped"), "work_off")
    }

    Process {
        id: startProc

        command: ["systemctl", "start", "workmode.target"]
        onRunningChanged: {
            if (!running)
                statusCheckTimer.start()
        }
    }

    Process {
        id: stopProc

        command: ["systemctl", "stop", "workmode.target"]
        onRunningChanged: {
            if (!running)
                statusCheckTimer.start()
        }
    }

    Process {
        id: statusProc

        command: ["systemctl", "is-active", "workmode.target"]
        stdout: StdioCollector {
            onStreamFinished: {
                const state = text.trim()
                const wasConnected = root.connected
                root.connected = state === "active"

                if (state === "activating" || state === "deactivating")
                    statusCheckTimer.start()
            }
        }
    }

    Timer {
        id: statusCheckTimer

        interval: 1000
        repeat: false
        onTriggered: statusProc.running = true
    }

    Component.onCompleted: statusProc.running = true

    LoggingCategory {
        id: lc

        name: "caelestia.qml.services.worknetwork"
        defaultLogLevel: LoggingCategory.Info
    }
}
