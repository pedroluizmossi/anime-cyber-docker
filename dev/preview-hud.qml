// HUD com cenário completo: stacks, portas, favoritos, sparklines, VRAM, problema.
// Uso: qml6 dev/preview-hud.qml -- <agrupar 0|1> <tema> <busca|-> saida.png
import QtQuick
import "../package/contents/ui"
import "../package/contents/ui/Themes.js" as Themes
import "../package/contents/ui/Logic.js" as Logic

Window {
    id: win
    readonly property var args: Qt.application.arguments
    readonly property bool group: args[args.length - 4] === "1"
    readonly property var th: Themes.get(args[args.length - 3])
    readonly property string query: args[args.length - 2] === "-" ? "" : args[args.length - 2]
    width: 540; height: 700; visible: true; color: "transparent"

    function wave(n, base, amp, phase) {
        const out = []
        for (let i = 0; i < n; i++) out.push(Math.max(0, base + amp * Math.sin(i / 3 + phase) + amp * 0.4 * Math.sin(i * 1.7 + phase)))
        return out
    }

    readonly property var fake: [
        { id: "a1", name: "shop-api-1", image: "ghcr.io/acme/api:2.4.1", state: "restarting", status: "Restarting (1) 4 seconds ago", health: "", project: "shop", problem: true,
          ports: Logic.parsePorts("0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp") },
        { id: "a2", name: "shop-db-1", image: "postgres:17-alpine", state: "running", status: "Up 3 hours (healthy)", health: "healthy", project: "shop", problem: false,
          ports: Logic.parsePorts("127.0.0.1:5432->5432/tcp") },
        { id: "a3", name: "shop-web-1", image: "nginx:1.29", state: "running", status: "Up 3 hours", health: "", project: "shop", problem: false,
          ports: Logic.parsePorts("0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 0.0.0.0:8443->8443/tcp, 0.0.0.0:9000->9000/tcp") },
        { id: "a4", name: "llama-swap", image: "ghcr.io/mostlygeek/llama-swap:unified-cuda13", state: "running", status: "Up 41 minutes", health: "", project: "embeddings", problem: false,
          ports: Logic.parsePorts("127.0.0.1:8090->8080/tcp") },
        { id: "a5", name: "minio", image: "minio/minio:latest", state: "exited", status: "Exited (0) 2 days ago", health: "", project: "", problem: false, ports: [] }
    ]

    Item {
        id: stage
        width: 500; height: 660
        anchors.centerIn: parent
        FullView {
            anchors.fill: parent
            mood: "alarm"
            kind: "hacker"
            theme: win.th
            glowLevel: 80
            animated: false
            containers: win.fake
            groupStacks: win.group
            favorites: ["llama-swap"]
            search: win.query
            stats: ({
                "shop-db-1": { cpu: 1.2, mem: "312MiB", memBytes: 312 * 1048576 },
                "shop-web-1": { cpu: 4.8, mem: "38MiB", memBytes: 38 * 1048576 },
                "llama-swap": { cpu: 96.4, mem: "1.4GiB", memBytes: 1.4 * 1073741824 }
            })
            history: ({
                "shop-db-1": { cpu: win.wave(30, 1.5, 1, 0), mem: win.wave(30, 300, 15, 1).map(x => x * 1048576) },
                "shop-web-1": { cpu: win.wave(30, 5, 3, 2), mem: win.wave(30, 38, 2, 0).map(x => x * 1048576) },
                "llama-swap": { cpu: win.wave(30, 60, 35, 1), mem: win.wave(30, 1300, 150, 2).map(x => x * 1048576) }
            })
            vram: ({ "llama-swap": 2288 })
            gpuUtil: 71; gpuMemUsed: 3120; gpuMemTotal: 16376
            hostCpu: 23.4; hostMemUsed: 14.2 * 1073741824; hostMemTotal: 46 * 1073741824
            running: 3; problems: 1
        }
    }
    Timer { interval: 1500; running: true; onTriggered: stage.grabToImage(r => { r.saveToFile(win.args[win.args.length - 1]); Qt.quit() }) }
}
