// HUD largo com a coluna de sinais vitais. Uso: qml6 dev/preview-vitals.qml -- <tema> <cenário calm|busy|hot> saida.png
import QtQuick
import "../package/contents/ui"
import "../package/contents/ui/Themes.js" as Themes
import "../package/contents/ui/Logic.js" as Logic
import "I18nShim.js" as I18n

Window {
    id: win
    // i18n fora do Plasma (ver dev/I18nShim.js)
    function i18n(...a) { return I18n.i18n(...a) }
    function i18nc(...a) { return I18n.i18nc(...a) }
    function i18np(...a) { return I18n.i18np(...a) }
    function i18ncp(...a) { return I18n.i18ncp(...a) }
    readonly property var args: Qt.application.arguments
    readonly property var th: Themes.get(args[args.length - 3])
    readonly property string sc: args[args.length - 2]
    readonly property real cpu: sc === "hot" ? 93 : sc === "busy" ? 64 : 3.4
    readonly property real gpu: sc === "hot" ? 98 : sc === "busy" ? 71 : 0
    width: 820; height: 720; visible: true; color: "transparent"

    function wave(n, base, amp, phase) {
        const out = []
        for (let i = 0; i < n; i++) out.push(Math.max(0, Math.min(100, base + amp * Math.sin(i / 4 + phase) + amp * 0.4 * Math.sin(i * 1.7 + phase))))
        return out
    }
    readonly property var fake: [
        { id: "a2", name: "database-index-postgres-1", image: "code-index-postgres:pg17-pgsearch0.26.5", state: "running", status: "Up About an hour (healthy)", health: "healthy", project: "database-index", problem: false,
          ports: Logic.parsePorts("127.0.0.1:5432->5432/tcp") },
        { id: "a4", name: "llama-swap", image: "ghcr.io/mostlygeek/llama-swap:unified-cuda13", state: "running", status: "Up About an hour", health: "", project: "embeddings", problem: false,
          ports: Logic.parsePorts("127.0.0.1:8090->8080/tcp") }
    ]
    Item {
        id: stage
        width: 780; height: 680
        anchors.centerIn: parent
        FullView {
            anchors.fill: parent
            mood: win.sc === "calm" ? "happy" : "busy"
            kind: "neko"
            cpuKind: "chip"; ramKind: "sapo"; gpuKind: "nvidia"; gpuVendor: "nvidia"
            theme: win.th
            themeKey: win.args[win.args.length - 3]
            animated: false
            containers: win.fake
            stats: ({
                "database-index-postgres-1": { cpu: 0.4, mem: "232MiB", memBytes: 232 * 1048576 },
                "llama-swap": { cpu: win.sc === "calm" ? 0.1 : 180, mem: "1.5GiB", memBytes: 1.5 * 1073741824 }
            })
            history: ({
                "database-index-postgres-1": { cpu: win.wave(30, 1, 1, 0), mem: win.wave(30, 230, 5, 1).map(x => x * 1048576) },
                "llama-swap": { cpu: win.wave(30, 2, 2, 1), mem: win.wave(30, 1500, 50, 2).map(x => x * 1048576) }
            })
            vram: ({ "llama-swap": 2100 })
            hostHistory: ({ cpu: win.wave(60, win.cpu * 0.8, 12, 0), mem: win.wave(60, 23, 2, 1), gpu: win.wave(60, win.gpu * 0.7, 20, 2), vram: [],
                            net: win.wave(60, 40, 30, 1).map(x => x * 20000) })
            cpuTemp: win.sc === "hot" ? 94 : win.sc === "busy" ? 82 : 43.5
            gpuTemp: win.sc === "hot" ? 88 : win.sc === "busy" ? 71 : 37
            netRx: 1.3 * 1048576; netTx: 84 * 1024
            disk: ({ total: 576716800000, used: 347058270208, docker: 25.9e9, reclaimable: 3.43e9,
                     parts: { "Images": 21.89e9, "Containers": 348200, "Local Volumes": 4e9, "Build Cache": 0 } })
            restarts: ({ "llama-swap": win.sc === "calm" ? 0 : 3, "database-index-postgres-1": 1 })
            restartBumpAt: ({ "llama-swap": win.sc === "calm" ? 0 : Date.now() })
            lastUpdate: new Date()
            lastEvent: win.sc === "calm" ? { kind: "recovered", name: "database-index-postgres-1", at: Date.now() }
                                         : { kind: "restart-bump", name: "llama-swap", at: Date.now() }
            logsPeek: ({ "llama-swap": { at: 0, text: "srv  load_model: loading model 'qwen3-embedding-8b'\nllama_model_loader: loaded meta data with 35 key-value pairs\nWARN: n_ctx_per_seq (4096) < n_ctx_train (40960)\nsrv  update_slots: all slots are idle\nERROR: request timed out after 30s (client disconnected)\nINFO  proxy: swapped model in 4.2s" } })
            peekName: win.sc === "busy" ? "llama-swap" : ""
            peekAnchor: anchorDummy
            Item { id: anchorDummy; x: 370; y: 236; width: 26; height: 26 }
            gpuUtil: win.gpu; gpuMemUsed: 2860; gpuMemTotal: 16376
            hostCpu: win.cpu; hostMemUsed: (win.sc === "hot" ? 43 : 11) * 1073741824; hostMemTotal: 47 * 1073741824
            running: 2; problems: 0
        }
    }
    Timer { interval: 1500; running: true; onTriggered: stage.grabToImage(r => { r.saveToFile(win.args[win.args.length - 1]); Qt.quit() }) }
}
