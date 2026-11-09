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
    property string gpuVendor: ""     // "nvidia" | "amd" | "" (sem GPU suportada)
    property real gpuTemp: 0          // °C (0 = sem sensor)
    property real cpuTemp: 0          // °C (0 = sem sensor)
    property var netPrev: null        // { rx, tx, t } da leitura anterior de /proc/net/dev
    property real netRx: 0            // bytes/s
    property real netTx: 0
    property var disk: ({ total: 0, used: 0, docker: 0, reclaimable: 0, parts: {} })
    property string pruneResult: ""
    property var restarts: ({})       // nome -> RestartCount
    property var restartBumpAt: ({})  // nome -> quando o contador subiu
    property var logsPeek: ({})       // nome -> { text, at } (prévia dos logs no hover)
    property var lastEvent: null      // { kind, name, exitCode, at } (fala da mascote)
    property bool celebrating: false  // humor "happy" por alguns segundos após uma recuperação
    property string dockerVersion: "" // versão do daemon (rodapé)
    property var hostCpuPrev: null    // contadores de /proc/stat da leitura anterior
    property real hostCpu: 0          // % de CPU do computador
    property real hostMemUsed: 0      // bytes
    property real hostMemTotal: 0     // bytes
    property var hostHistory: ({ cpu: [], mem: [], gpu: [], vram: [], net: [] })   // % / bytes/s (coluna de sinais vitais)
    property bool dockerOk: true
    property string errorText: ""
    property string lastContainersJson: ""
    property date lastUpdate: new Date()

    readonly property int historySize: 30
    readonly property int hostHistorySize: 60
    readonly property int runningCount: containers.filter(c => c.state === "running").length
    readonly property int problemCount: containers.filter(c => c.problem).length
    readonly property real maxCpu: Object.values(stats).reduce((a, s) => Math.max(a, s.cpu), 0)
    readonly property var cfg: Plasmoid.configuration
    readonly property var theme: Themes.get(cfg.theme, cfg.customFur, cfg.customVisor)
    readonly property string baseMood: (!dockerOk || problemCount > 0) ? "alarm"
                                     : runningCount === 0 ? "sleep"
                                     : (gpuUtil >= cfg.busyGpu || maxCpu >= cfg.busyCpu) ? "busy"
                                     : "idle"
    readonly property string mood: celebrating && baseMood !== "alarm" ? "happy" : baseMood

    readonly property string psCmd: "docker ps -a --format '{{json .}}'"
    readonly property string statsCmd: "docker stats --no-stream --format '{{json .}}'"
    // CPU, RAM, temperatura da CPU (hwmon) e bytes de rede (sem loopback nem interfaces do Docker)
    readonly property string hostCmd: "head -n1 /proc/stat; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo;"
        + " for h in /sys/class/hwmon/hwmon*; do case $(cat $h/name 2>/dev/null) in coretemp|k10temp|zenpower|cpu_thermal)"
        + " echo \"temp $(cat $h/temp1_input 2>/dev/null)\"; break;; esac; done;"
        + " awk 'NR>2 && $1 !~ /^(lo|docker|veth|br-|virbr)/ {rx+=$2; tx+=$10} END {print \"net\", rx+0, tx+0}' /proc/net/dev"
    readonly property string diskCmd: "d=$(docker info -f '{{.DockerRootDir}}' 2>/dev/null) && df -P -B1 \"$d\" | awk 'NR==2 {print \"df\", $2, $3}'"
        + " && docker system df --format '{{.Type}}\t{{.Size}}\t{{.Reclaimable}}'"
    readonly property string pruneCmd: "docker image prune -af 2>&1 | tail -n1; docker builder prune -f 2>&1 | tail -n1"
    readonly property string restartsCmd: "docker ps -aq | xargs -r docker inspect --format '{{.Name}} {{.RestartCount}}'"
    readonly property string logsPrefix: "docker logs --tail 6 "
    readonly property string versionCmd: "docker version -f '{{.Server.Version}}'"
    // NVIDIA via nvidia-smi; senão a 1ª placa AMD (amdgpu) via sysfs.
    // Saída: "uso, usada MiB, total MiB, temperatura °C, fabricante"
    readonly property string gpuCmd: "if command -v nvidia-smi >/dev/null && g=$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits 2>/dev/null); then"
        + " echo \"$g\" | head -n1 | sed 's/$/, nvidia/';"
        + " else for d in /sys/class/drm/card*/device; do [ -r $d/gpu_busy_percent ] && [ -r $d/mem_info_vram_total ] && {"
        + " t=$(cat $d/hwmon/hwmon*/temp1_input 2>/dev/null | head -n1);"
        + " echo \"$(cat $d/gpu_busy_percent), $(( $(cat $d/mem_info_vram_used) / 1048576 )), $(( $(cat $d/mem_info_vram_total) / 1048576 )), $(( ${t:-0} / 1000 )), amd\"; break; }; done; fi"
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
        hostHistory: root.hostHistory
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
        showVitals: root.cfg.showVitals
        cpuKind: root.cfg.cpuMascot || "chip"
        ramKind: root.cfg.ramMascot || "sapo"
        gpuKind: Logic.gpuMascot(root.cfg.gpuMascot, root.gpuVendor)
        gpuVendor: root.gpuVendor
        diskKind: root.cfg.diskMascot || "disquete"
        showTemps: root.cfg.showTemps
        tempHot: root.cfg.tempHot
        tempCritical: root.cfg.tempCritical
        cpuTemp: root.cpuTemp
        gpuTemp: root.gpuTemp
        netRx: root.netRx
        netTx: root.netTx
        disk: root.disk
        pruneResult: root.pruneResult
        restarts: root.restarts
        restartBumpAt: root.restartBumpAt
        logsPeek: root.logsPeek
        lastEvent: root.lastEvent
        dockerVersion: root.dockerVersion
        themeKey: root.cfg.theme || "neon"
        onPeekLogs: name => root.peekLogs(name)
        onPrune: root.prune()
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
        interval: 60000; running: root.dockerOk; repeat: true; triggeredOnStart: true
        onTriggered: exec.run(root.diskCmd)
    }
    Timer {
        id: celebrateTimer
        interval: 6000
        onTriggered: root.celebrating = false
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
        exec.run(restartsCmd)
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
        if (source.startsWith(logsPrefix)) {
            const name = source.slice(logsPrefix.length).split(" ")[0]
            const lp = Object.assign({}, logsPeek)
            lp[name] = { text: Logic.cleanLog(out) || "(sem logs)", at: Date.now() }
            logsPeek = lp
            return
        }
        if (source === psCmd) {
            const wasOk = dockerOk
            dockerOk = ok
            errorText = ok ? "" : ((data["stderr"] || out).trim().split("\n")[0] || "docker não respondeu")
            if (ok) parseContainers(out)
            if (ok && !dockerVersion) exec.run(versionCmd)
            if (!ok) dockerVersion = ""
            if (baselineReady && wasOk !== ok) react({ kind: ok ? "docker-up" : "docker-down", name: "" })
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
            cpuTemp = h.temp
            const now = Date.now()
            if (h.net) {
                const rate = netPrev ? Logic.netRate(netPrev, h.net, now - netPrev.t) : { rx: 0, tx: 0 }
                netRx = rate.rx
                netTx = rate.tx
                netPrev = { rx: h.net.rx, tx: h.net.tx, t: now }
            }
            pushHost({ cpu: hostCpu, mem: h.memTotal > 0 ? h.memUsed / h.memTotal * 100 : 0, net: netRx + netTx })
        } else if (source === gpuCmd) {
            const g = Logic.parseGpu(ok ? out : "")
            gpuUtil = g.util
            gpuMemUsed = g.used
            gpuMemTotal = g.total
            gpuVendor = g.vendor
            gpuTemp = g.temp
            pushHost({ gpu: gpuUtil, vram: gpuMemTotal > 0 ? gpuMemUsed / gpuMemTotal * 100 : 0 })
        } else if (source === versionCmd) {
            if (ok) dockerVersion = out.split("\n")[0]
        } else if (source === diskCmd) {
            if (ok) disk = Logic.parseDisk(out)
        } else if (source === pruneCmd) {
            pruneResult = out.split("\n").filter(l => /reclaimed/i.test(l)).map(l => l.replace(/^Total reclaimed space:\s*/i, "")).join(" + ") || "nada para limpar"
            exec.run(diskCmd)
        } else if (source === restartsCmd) {
            if (!ok) return
            const r = Logic.parseRestarts(out)
            const bumps = Logic.restartBumps(restarts, r)
            if (bumps.length) {
                const b = Object.assign({}, restartBumpAt)
                for (const n of bumps) b[n] = Date.now()
                restartBumpAt = b
                react({ kind: "restart-bump", name: bumps[0] })
            }
            if (JSON.stringify(r) !== JSON.stringify(restarts)) restarts = r
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

    function pushHost(samples) {
        const h = Object.assign({}, hostHistory)
        for (const k of Object.keys(samples)) h[k] = Logic.pushSample(h[k], samples[k], hostHistorySize)
        hostHistory = h
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

        if (baselineReady) {
            const evs = Logic.detectEvents(lastSnapshot, list)
            if (cfg.notify) for (const ev of evs) notifyEvent(ev)
            // a mascote comenta o evento mais grave (problemas antes de recuperações)
            if (evs.length) react(evs.find(e => e.kind !== "recovered") || evs[0])
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

    // ---- reações da mascote, logs e limpeza -----------------------------------
    function react(ev) {
        lastEvent = Object.assign({ at: Date.now() }, ev)
        if (ev.kind === "recovered" || ev.kind === "docker-up") {
            celebrating = true
            celebrateTimer.restart()
        }
    }

    function peekLogs(name) {
        if (!Logic.validContainerName(name)) return
        const cached = logsPeek[name]
        if (cached && Date.now() - cached.at < 4000) return
        exec.run(logsPrefix + name + " 2>&1 | tail -n 6 | cut -c1-160")
    }

    function prune() {
        pruneResult = "limpando…"
        exec.run(pruneCmd)
    }

    function toggleFavorite(name) {
        const favs = (cfg.favorites || []).slice()
        const i = favs.indexOf(name)
        if (i >= 0) favs.splice(i, 1)
        else favs.push(name)
        cfg.favorites = favs
    }
}
