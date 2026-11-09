// Popup HUD com dados de exemplo. Uso: qml6 dev/render-popup.qml -- <humor> <tema> <mascote> saida.png
import QtQuick
import "../package/contents/ui"
import "../package/contents/ui/Themes.js" as Themes

Window {
    id: win
    readonly property var args: Qt.application.arguments
    readonly property string mood: args[args.length - 4]
    readonly property var th: Themes.get(args[args.length - 3])
    readonly property string kind: args[args.length - 2]
    readonly property bool alarm: mood === "alarm"
    width: 480; height: 600; visible: true; color: "transparent"

    readonly property var fake: [
        { name: "api-gateway", image: "ghcr.io/acme/gateway:2.4.1", state: alarm ? "restarting" : "running", status: alarm ? "Restarting (1) 4 seconds ago" : "Up 3 hours (healthy)", health: alarm ? "unhealthy" : "healthy", project: "acme", problem: alarm },
        { name: "postgres", image: "postgres:17-alpine", state: "running", status: "Up 3 hours (healthy)", health: "healthy", project: "acme", problem: false },
        { name: "llama-swap", image: "ghcr.io/mostlygeek/llama-swap:unified-cuda13", state: "running", status: "Up 41 minutes", health: "", project: "embeddings", problem: false },
        { name: "redis", image: "redis:8", state: "running", status: "Up 3 hours", health: "", project: "acme", problem: false },
        { name: "minio", image: "minio/minio:latest", state: "exited", status: "Exited (0) 2 days ago", health: "", project: "storage", problem: false }
    ]

    Item {
        id: stage
        width: 456; height: 576
        anchors.centerIn: parent
        FullView {
            anchors.fill: parent
            mood: win.mood
            kind: win.kind
            theme: win.th
            glowLevel: 90
            containers: win.fake
            stats: ({
                "api-gateway": { cpu: 12.4, mem: "184MiB" },
                "postgres": { cpu: 0.6, mem: "312MiB" },
                "llama-swap": { cpu: win.mood === "busy" ? 96.2 : 2.1, mem: "1.4GiB" },
                "redis": { cpu: 0.3, mem: "18MiB" }
            })
            running: 4
            problems: win.alarm ? 1 : 0
            gpuUtil: win.mood === "busy" ? 87 : 6
        }
    }

    Timer { interval: 1500; running: true; onTriggered: stage.grabToImage(r => { r.saveToFile(win.args[win.args.length - 1]); Qt.quit() }) }
}
