import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import "Themes.js" as Themes

PlasmoidItem {
    id: root

    property var containers: []
    property var stats: ({})          // nome -> { cpu, mem }
    property var crashes: ({})        // nome -> timestamp do crash recente
    property var lastStates: ({})     // nome -> state anterior
    property real gpuUtil: 0
    property bool dockerOk: true
    property string errorText: ""
    property date lastUpdate: new Date()

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
    readonly property string gpuCmd: "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits"
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
        running: root.runningCount
        problems: root.problemCount
        gpuUtil: root.gpuUtil
        dockerOk: root.dockerOk
        errorText: root.errorText
        lastUpdate: root.lastUpdate
        theme: root.theme
        kind: root.cfg.mascot
        glowLevel: root.cfg.glowLevel
        animated: root.cfg.animations
        active: root.expanded
        onAction: (verb, name) => root.dockerAction(verb, name)
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
        onTriggered: exec.run(root.statsCmd)
    }
    Timer {
        id: refreshSoon
        interval: 900
        onTriggered: root.poll()
    }

    function poll() {
        exec.run(psCmd)
        exec.run(gpuCmd)
    }

    function handle(source, data) {
        const out = (data["stdout"] || "").trim()
        const ok = data["exit code"] === 0
        if (source === psCmd) {
            dockerOk = ok
            errorText = ok ? "" : ((data["stderr"] || out).trim().split("\n")[0] || "docker não respondeu")
            if (ok) parseContainers(out)
            lastUpdate = new Date()
        } else if (source === statsCmd) {
            if (!ok) return
            const s = {}
            for (const line of out.split("\n")) {
                if (!line) continue
                try {
                    const j = JSON.parse(line)
                    s[j.Name] = { cpu: parseFloat(j.CPUPerc) || 0, mem: (j.MemUsage || "").split(" / ")[0] }
                } catch (e) {}
            }
            stats = s
        } else if (source === gpuCmd) {
            gpuUtil = ok ? (parseFloat(out.split("\n")[0]) || 0) : 0
        }
    }

    function parseContainers(out) {
        const now = Date.now()
        const list = []
        const newStates = {}
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
            if (lastStates[name] === "running" && state === "exited" && exitCode !== 0 && exitCode !== 143 && exitCode !== 137)
                crashedAt = now
            if (state === "running") crashedAt = 0
            const recentCrash = crashedAt && (now - crashedAt) < crashWindowMs
            if (recentCrash) newCrashes[name] = crashedAt

            newStates[name] = state
            list.push({
                name: name,
                image: j.Image,
                state: state,
                status: j.Status,
                health: health,
                ports: j.Ports || "",
                project: (/com\.docker\.compose\.project=([^,]+)/.exec(j.Labels || "") || [])[1] || "",
                problem: state === "restarting" || state === "dead" || health === "unhealthy" || !!recentCrash
            })
        }
        const rank = c => c.problem ? 0 : c.state === "running" ? 1 : 2
        list.sort((a, b) => rank(a) - rank(b) || a.name.localeCompare(b.name))
        lastStates = newStates
        crashes = newCrashes
        containers = list
    }

    function dockerAction(verb, name) {
        if (!/^[A-Za-z0-9][A-Za-z0-9_.-]*$/.test(name)) return
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
}
