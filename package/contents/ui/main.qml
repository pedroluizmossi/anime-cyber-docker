import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import "Themes.js" as Themes
import "Logic.js" as Logic

PlasmoidItem {
    id: root

    property var containers: []
    property var stats: ({})          // nome -> { cpu, mem, memBytes }
    property var history: ({})        // nome -> { cpu: [], mem: [] }  (sparklines)
    property var vram: ({})           // nome -> MiB na GPU
    property var crashes: ({})        // nome -> timestamp do crash recente
    property var lastSnapshot: ({})   // nome -> { state, health, problem } (notificações)
    property bool baselineReady: false
    property var lastNotified: ({})   // "tipo:nome" -> timestamp (anti-spam)
    property var pendingNotifications: ({})   // comando notify-send -> nome do container
    property real gpuUtil: 0
    property real gpuMemUsed: 0       // MiB
    property real gpuMemTotal: 0      // MiB
    property var hostCpuPrev: null    // contadores de /proc/stat da leitura anterior
    property real hostCpu: 0          // % de CPU do computador
    property real hostMemUsed: 0      // bytes
    property real hostMemTotal: 0     // bytes
    property bool dockerOk: true
    property string errorText: ""
    property string lastContainersJson: ""
    property date lastUpdate: new Date()

    readonly property int historySize: 30
    readonly property int runningCount: containers.filter(c => c.state === "running").length
    readonly property int problemCount: containers.filter(c => c.problem).length
    readonly property real maxCpu: Object.values(stats).reduce((a, s) => Math.max(a, s.cpu), 0)
    readonly property var cfg: Plasmoid.configuration
    readonly property var theme: Themes.get(cfg.theme, cfg.customFur, cfg.customVisor)
    readonly property string mood: (!dockerOk || problemCount > 0) ? "alarm"
                                 : runningCount === 0 ? "sleep"
                                 : (gpuUtil >= cfg.busyGpu || maxCpu >= cfg.busyCpu) ? "busy"
                                 : "idle"

    readonly property string psCmd: "docker ps -a --format '{{json .}}'"
    readonly property string statsCmd: "docker stats --no-stream --format '{{json .}}'"
    readonly property string hostCmd: "head -n1 /proc/stat; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo"
    readonly property string gpuCmd: "nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits"
    // PID de cada processo na GPU -> ID do container dono (via cgroup)
    readonly property string vramCmd: "nvidia-smi --query-compute-apps=pid,used_memory --format=csv,noheader,nounits"
        + " | while IFS=', ' read -r pid mem; do id=$(grep -oE '[0-9a-f]{64}' /proc/$pid/cgroup 2>/dev/null | head -n1);"
        + " [ -n \"$id\" ] && echo \"$id $mem\"; done; true"
    readonly property int crashWindowMs: 5 * 60 * 1000

    preferredRepresentation: compactRepresentation
    toolTipMainText: "CyberDock"
    toolTipSubText: !dockerOk ? "Docker indisponível"
                  : `${runningCount}/${containers.length} rodando` + (problemCount ? ` · ${problemCount} com problema` : "")

    compactRepresentation: CompactView {
        mood: root.mood
        running: root.runningCount
        total: root.containers.length
        problems: root.problemCount
        theme: root.theme
        kind: root.cfg.mascot
        iconScale: root.cfg.iconScale
        showCounter: root.cfg.showCounter
        glowLevel: root.cfg.glowLevel
        animated: root.cfg.animations
        onActivated: root.expanded = !root.expanded
    }

    fullRepresentation: FullView {
        mood: root.mood
        containers: root.containers
        stats: root.stats
        history: root.history
        vram: root.vram
        running: root.runningCount
        problems: root.problemCount
        gpuUtil: root.gpuUtil
        gpuMemUsed: root.gpuMemUsed
        gpuMemTotal: root.gpuMemTotal
        hostCpu: root.hostCpu
        hostMemUsed: root.hostMemUsed
        hostMemTotal: root.hostMemTotal
        dockerOk: root.dockerOk
        errorText: root.errorText
        lastUpdate: root.lastUpdate
        theme: root.theme
        kind: root.cfg.mascot
        glowLevel: root.cfg.glowLevel
        animated: root.cfg.animations
        active: root.expanded
        groupStacks: root.cfg.groupStacks
        hideStopped: root.cfg.hideStopped
        showGraphs: root.cfg.showGraphs
        favorites: root.cfg.favorites
        onAction: (verb, name) => root.dockerAction(verb, name)
        onStackAction: (verb, project) => root.stackAction(verb, project)
        onToggleFavorite: name => root.toggleFavorite(name)
        onSetOption: (key, value) => root.cfg[key] = value
        onRefresh: root.poll()
    }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            root.handle(source, data)
            disconnectSource(source)
        }
        function run(cmd) { connectSource(cmd) }
    }

    Timer {
        interval: Math.max(1, root.cfg.refreshSeconds) * 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.poll()
    }
    Timer {
        interval: Math.max(5, root.cfg.refreshSeconds * 2) * 1000; running: root.runningCount > 0; repeat: true; triggeredOnStart: true
        onTriggered: {
            exec.run(root.statsCmd)
            exec.run(root.vramCmd)
        }
    }
    Timer {
        id: refreshSoon
        interval: 900
        onTriggered: root.poll()
    }

    function poll() {
        exec.run(psCmd)
        exec.run(gpuCmd)
        exec.run(hostCmd)
    }

    function handle(source, data) {
        const out = (data["stdout"] || "").trim()
        const ok = data["exit code"] === 0
        if (pendingNotifications[source] !== undefined) {
            // notify-send -A devolve no stdout a ação clicada (vazio se fechada/expirada)
            const target = pendingNotifications[source]
            const p = Object.assign({}, pendingNotifications)
            delete p[source]
            pendingNotifications = p
            if (out === "logs" || out === "restart") dockerAction(out, target)
            return
        }
        if (source === psCmd) {
            const wasOk = dockerOk
            dockerOk = ok
            errorText = ok ? "" : ((data["stderr"] || out).trim().split("\n")[0] || "docker não respondeu")
            if (ok) parseContainers(out)
            if (baselineReady && cfg.notify && cfg.notifyDocker && wasOk !== ok)
                notify(ok ? "docker-up" : "docker-down", "", ok ? "Docker voltou" : "Docker fora do ar",
                       ok ? "O daemon do Docker está respondendo de novo." : errorText, !ok)
            lastUpdate = new Date()
        } else if (source === statsCmd) {
            if (!ok) return
            const s = {}
            let h = Object.assign({}, history)
            for (const line of out.split("\n")) {
                if (!line) continue
                try {
                    const j = JSON.parse(line)
                    const memText = (j.MemUsage || "").split(" / ")[0]
                    const cpu = parseFloat(j.CPUPerc) || 0
                    const memBytes = Logic.parseBytes(memText)
                    s[j.Name] = { cpu: cpu, mem: memText, memBytes: memBytes }
                    h[j.Name] = Logic.pushHistory(h, j.Name, cpu, memBytes, historySize)
                } catch (e) {}
            }
            // descarta histórico de containers que pararam
            for (const name of Object.keys(h)) if (!s[name]) delete h[name]
            stats = s
            history = h
        } else if (source === hostCmd) {
            if (!ok) return
            const h = Logic.parseHost(out)
            hostCpu = Logic.cpuPercent(hostCpuPrev, h.cpu)
            hostCpuPrev = h.cpu
            hostMemUsed = h.memUsed
            hostMemTotal = h.memTotal
        } else if (source === gpuCmd) {
            const parts = ok ? out.split("\n")[0].split(",").map(x => parseFloat(x)) : []
            gpuUtil = parts[0] || 0
            gpuMemUsed = parts[1] || 0
            gpuMemTotal = parts[2] || 0
        } else if (source === vramCmd) {
            const v = {}
            for (const line of out.split("\n")) {
                const [id, mem] = line.trim().split(/\s+/)
                if (!id) continue
                const c = containers.find(x => x.id && id.indexOf(x.id) === 0)
                if (c) v[c.name] = (v[c.name] || 0) + (parseFloat(mem) || 0)
            }
            vram = v
        }
    }

    function parseContainers(out) {
        const now = Date.now()
        const list = []
        const newCrashes = {}
        for (const line of out.split("\n")) {
            if (!line) continue
            let j
            try { j = JSON.parse(line) } catch (e) { continue }
            const name = j.Names
            const state = j.State
            const health = j.HealthStatus && j.HealthStatus !== "none" ? j.HealthStatus
                         : /\(unhealthy\)/.test(j.Status) ? "unhealthy"
                         : /\(healthy\)/.test(j.Status) ? "healthy" : ""
            const exitMatch = /Exited \((\d+)\)/.exec(j.Status)
            const exitCode = exitMatch ? parseInt(exitMatch[1]) : 0

            // crash = estava rodando na leitura anterior e saiu com código != 0
            let crashedAt = crashes[name] || 0
            const prev = lastSnapshot[name]
            if (prev && prev.state === "running" && state === "exited" && exitCode !== 0 && exitCode !== 143 && exitCode !== 137)
                crashedAt = now
            if (state === "running") crashedAt = 0
            const recentCrash = crashedAt && (now - crashedAt) < crashWindowMs
            if (recentCrash) newCrashes[name] = crashedAt

            list.push({
                id: j.ID || "",
                name: name,
                image: j.Image,
                state: state,
                status: j.Status,
                exitCode: exitCode,
                health: health,
                ports: Logic.parsePorts(j.Ports || ""),
                project: (/com\.docker\.compose\.project=([^,]+)/.exec(j.Labels || "") || [])[1] || "",
                problem: state === "restarting" || state === "dead" || health === "unhealthy" || !!recentCrash
            })
        }
        list.sort((a, b) => Logic.rank(a) - Logic.rank(b) || a.name.localeCompare(b.name))

        if (baselineReady && cfg.notify) {
            for (const ev of Logic.detectEvents(lastSnapshot, list))
                notifyEvent(ev)
        }
        lastSnapshot = Logic.snapshot(list)
        baselineReady = true
        crashes = newCrashes

        // só troca o modelo quando algo mudou: evita reconstruir a lista do HUD à toa
        const json = JSON.stringify(list)
        if (json !== lastContainersJson) {
            lastContainersJson = json
            containers = list
        }
    }

    // ---- notificações ------------------------------------------------------
    // ---- notificações ------------------------------------------------------
    // Enviadas pelo notify-send (processo externo): o plasmashell é o próprio servidor de
    // notificações e descarta as que ele mesmo emite via KNotification.
    function notifyEvent(ev) {
        const texts = {
            crash: ["💥 " + ev.name + " caiu", `O container saiu com código ${ev.exitCode}.`, true],
            restarting: ["🔁 " + ev.name + " em loop de reinício", "O container está reiniciando sem parar.", true],
            unhealthy: ["🩺 " + ev.name + " unhealthy", "O healthcheck do container está falhando.", true],
            recovered: ["✅ " + ev.name + " voltou", "O container está rodando normalmente de novo.", false]
        }
        if (ev.kind === "recovered" && !cfg.notifyRecovery) return
        const t = texts[ev.kind]
        if (t) notify(ev.kind, ev.name, t[0], t[1], t[2])
    }

    readonly property string notifyIcon: decodeURIComponent(Qt.resolvedUrl("../images/cyberdock.png").toString().replace(/^file:\/\//, ""))

    function shellQuote(t) { return "'" + String(t).replace(/'/g, "’") + "'" }

    function notify(kind, target, title, text, urgent) {
        const key = kind + ":" + target
        const now = Date.now()
        if (lastNotified[key] && now - lastNotified[key] < 60000) return   // no máximo 1/min por evento
        const ln = Object.assign({}, lastNotified)
        ln[key] = now
        lastNotified = ln

        const withActions = !!target && kind !== "recovered" && Logic.validContainerName(target)
        let cmd = "notify-send -a CyberDock -i " + shellQuote(notifyIcon)
            + " -u " + (urgent ? "normal" : "low")
            + " -h string:x-cyberdock-id:" + now                       // torna cada comando único
        if (!urgent) cmd += " -t 8000"
        if (withActions) cmd += " -A logs='Ver logs' -A restart='Reiniciar'"
        cmd += " " + shellQuote(title) + " " + shellQuote(text) + "; true"
        if (withActions) {
            const p = Object.assign({}, pendingNotifications)
            p[cmd] = target
            pendingNotifications = p
        }
        exec.run(cmd)
    }

    // ---- ações ---------------------------------------------------------------
    function dockerAction(verb, name) {
        if (!Logic.validContainerName(name)) return
        const cmds = {
            start: `docker start ${name}`,
            stop: `docker stop ${name}`,
            restart: `docker restart ${name}`,
            logs: `konsole -p tabtitle='${name} logs' -e docker logs -f --tail 300 ${name}`,
            shell: `konsole -p tabtitle='${name}' -e docker exec -it ${name} sh -c 'command -v bash >/dev/null && exec bash || exec sh'`
        }
        if (!cmds[verb]) return
        exec.run(cmds[verb])
        refreshSoon.restart()
    }

    function stackAction(verb, project) {
        if (!Logic.validProjectName(project) || ["start", "stop", "restart"].indexOf(verb) < 0) return
        // roda a partir de / para nenhum compose.yaml do diretório atual interferir
        exec.run(`cd / && docker compose -p ${project} ${verb}`)
        refreshSoon.restart()
    }

    function toggleFavorite(name) {
        const favs = (cfg.favorites || []).slice()
        const i = favs.indexOf(name)
        if (i >= 0) favs.splice(i, 1)
        else favs.push(name)
        cfg.favorites = favs
    }
}
