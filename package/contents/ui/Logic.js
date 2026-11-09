.pragma library

// Lógica pura (sem QML), testada em dev/test-logic.mjs.

// ---- portas ----------------------------------------------------------------
// "127.0.0.1:8090->8080/tcp, [::]:5432->5432/tcp, 0.0.0.0:80-81->80-81/tcp, 6379/tcp"
// -> [{ host, port, url }] só das portas TCP publicadas no host, sem duplicar IPv4/IPv6.
function parsePorts(text) {
    const out = []
    const seen = {}
    const re = /(?:(\[[^\]]*\]|[0-9.]+|[A-Za-z0-9.-]+):)?(\d+)(?:-\d+)?->\d+(?:-\d+)?\/(tcp|udp)/g
    let m
    while ((m = re.exec(text || "")) !== null) {
        if (m[3] !== "tcp") continue
        const ip = m[1] || ""
        const wildcard = ip === "" || ip === "0.0.0.0" || ip === "[::]" || ip === "::"
        const host = wildcard ? "localhost" : ip
        const port = parseInt(m[2])
        const key = (wildcard || ip === "127.0.0.1" || ip === "[::1]" ? "local" : host) + ":" + port
        if (seen[key]) continue
        seen[key] = true
        out.push({ host: host, port: port, url: `http://${host}:${port}` })
    }
    return out.sort((a, b) => a.port - b.port)
}

// ---- bytes -----------------------------------------------------------------
const UNITS = { B: 1, KB: 1e3, MB: 1e6, GB: 1e9, TB: 1e12, KIB: 1024, MIB: 1048576, GIB: 1073741824, TIB: 1099511627776 }

// "1.4GiB" | "184MiB" | "18.5kB" -> bytes
function parseBytes(text) {
    const m = /([\d.]+)\s*([A-Za-z]+)/.exec(text || "")
    if (!m) return 0
    const unit = UNITS[m[2].toUpperCase()]
    return unit ? parseFloat(m[1]) * unit : 0
}

// bytes -> "184M" / "1.4G" (compacto, base 1024)
function formatBytes(bytes) {
    if (!bytes || bytes < 0) return "0"
    const steps = [["G", 1073741824], ["M", 1048576], ["K", 1024]]
    for (const [suffix, size] of steps) {
        if (bytes >= size) {
            const v = bytes / size
            return (v >= 100 ? v.toFixed(0) : v >= 10 ? v.toFixed(0) : v.toFixed(1)) + suffix
        }
    }
    return Math.round(bytes) + "B"
}

// MiB (nvidia-smi) -> "2.2G" / "512M"
function formatMiB(mib) {
    return formatBytes(mib * 1048576)
}

// ---- histórico para sparklines --------------------------------------------
function pushHistory(history, name, cpu, memBytes, max) {
    const h = history[name] || { cpu: [], mem: [] }
    const next = {
        cpu: h.cpu.concat([cpu]).slice(-max),
        mem: h.mem.concat([memBytes]).slice(-max)
    }
    return next
}

// ---- lista do HUD ----------------------------------------------------------
// opts: { search, hideStopped, group, favorites: [], collapsed: {projeto: true} }
// Retorna linhas planas: { type: "header", project, total, running, problems, collapsed }
//                        { type: "container", c, favorite }
function rank(c) { return c.problem ? 0 : c.state === "running" ? 1 : c.state === "paused" ? 2 : 3 }

function buildRows(containers, opts) {
    const o = opts || {}
    const favs = o.favorites || []
    const q = (o.search || "").trim().toLowerCase()
    const isFav = c => favs.indexOf(c.name) >= 0

    let list = (containers || []).filter(c => {
        if (o.hideStopped && c.state !== "running" && !c.problem && !isFav(c)) return false
        if (!q) return true
        return c.name.toLowerCase().indexOf(q) >= 0
            || (c.image || "").toLowerCase().indexOf(q) >= 0
            || (c.project || "").toLowerCase().indexOf(q) >= 0
    })

    const byFavThenRank = (a, b) => (isFav(b) - isFav(a)) || (rank(a) - rank(b)) || a.name.localeCompare(b.name)
    list.sort(byFavThenRank)
    const asRow = c => ({ type: "container", c: c, favorite: isFav(c) })

    if (!o.group) return list.map(asRow)

    const groups = {}
    for (const c of list) {
        const p = c.project || ""
        if (!groups[p]) groups[p] = []
        groups[p].push(c)
    }
    const score = p => {
        const cs = groups[p]
        return [
            p === "" ? 1 : 0,                               // sem stack por último
            cs.some(c => c.problem) ? 0 : 1,                // stacks com problema primeiro
            cs.some(isFav) ? 0 : 1                          // depois as com favoritos
        ]
    }
    const names = Object.keys(groups).sort((a, b) => {
        const sa = score(a), sb = score(b)
        for (let i = 0; i < sa.length; i++) if (sa[i] !== sb[i]) return sa[i] - sb[i]
        return a.localeCompare(b)
    })

    const rows = []
    for (const p of names) {
        const cs = groups[p]
        const collapsed = !!(o.collapsed && o.collapsed[p])
        rows.push({
            type: "header",
            project: p,
            total: cs.length,
            running: cs.filter(c => c.state === "running").length,
            problems: cs.filter(c => c.problem).length,
            collapsed: collapsed
        })
        if (!collapsed) for (const c of cs) rows.push(asRow(c))
    }
    return rows
}

// ---- eventos para notificação ---------------------------------------------
// prev: { nome: { state, health, problem } } da leitura anterior
// Retorna [{ kind: "crash"|"unhealthy"|"restarting"|"recovered", name, exitCode }]
function detectEvents(prev, containers) {
    const events = []
    for (const c of containers) {
        const p = prev[c.name]
        if (!p) continue                                   // container novo: sem histórico
        if (p.state === "running" && c.state === "exited" && c.exitCode !== 0
                && c.exitCode !== 137 && c.exitCode !== 143)
            events.push({ kind: "crash", name: c.name, exitCode: c.exitCode })
        else if (p.state !== "restarting" && c.state === "restarting")
            events.push({ kind: "restarting", name: c.name })
        else if (p.health !== "unhealthy" && c.health === "unhealthy")
            events.push({ kind: "unhealthy", name: c.name })
        else if (p.problem && !c.problem && c.state === "running")
            events.push({ kind: "recovered", name: c.name })
    }
    return events
}

function snapshot(containers) {
    const s = {}
    for (const c of containers) s[c.name] = { state: c.state, health: c.health, problem: c.problem }
    return s
}

// ---- validação de nomes usados em comandos --------------------------------
function validContainerName(n) { return /^[A-Za-z0-9][A-Za-z0-9_.-]*$/.test(n || "") }
function validProjectName(n) { return /^[a-z0-9][a-z0-9_-]*$/.test(n || "") }

// ---- CPU / RAM do host -----------------------------------------------------
// saída de: head -n1 /proc/stat; grep MemTotal/MemAvailable de /proc/meminfo;
//           "temp <miligraus>" (hwmon da CPU, opcional); "net <rx> <tx>" (bytes acumulados)
// -> { cpu: { busy, total } (contadores acumulados), memTotal, memUsed (bytes), temp (°C), net }
function parseHost(text) {
    const r = { cpu: null, memTotal: 0, memUsed: 0, temp: 0, net: null }
    let avail = 0
    for (const line of (text || "").split("\n")) {
        const f = line.trim().split(/\s+/)
        if (f[0] === "cpu") {
            const v = f.slice(1).map(x => parseInt(x) || 0)
            const idle = (v[3] || 0) + (v[4] || 0)            // idle + iowait
            const total = v.slice(0, 8).reduce((a, b) => a + b, 0)  // sem guest (já contado em user)
            r.cpu = { busy: total - idle, total: total }
        } else if (f[0] === "MemTotal:") r.memTotal = (parseInt(f[1]) || 0) * 1024
        else if (f[0] === "MemAvailable:") avail = (parseInt(f[1]) || 0) * 1024
        else if (f[0] === "temp") r.temp = (parseInt(f[1]) || 0) / 1000          // miligraus do hwmon
        else if (f[0] === "net") r.net = { rx: parseFloat(f[1]) || 0, tx: parseFloat(f[2]) || 0 }
    }
    r.memUsed = Math.max(0, r.memTotal - avail)
    return r
}

// % de CPU entre duas leituras de /proc/stat
function cpuPercent(prev, cur) {
    if (!prev || !cur) return 0
    const dt = cur.total - prev.total
    if (dt <= 0) return 0
    return Math.min(100, Math.max(0, (cur.busy - prev.busy) / dt * 100))
}

// ---- coluna de sinais vitais ------------------------------------------------
// Humor da mascote de uma métrica (0..100): parada dorme, normal flutua,
// carregada pula e saturada entra em alarme. available=false (sem GPU) dorme.
function vitalMood(value, warn, alarm, available) {
    if (available === false || value < 3) return "sleep"
    if (value >= alarm) return "alarm"
    if (value >= warn) return "busy"
    return "idle"
}

// Saída do comando de GPU: "uso, vram usada MiB, vram total MiB, temperatura °C, fabricante".
// temp = 0 quando o sensor não existe.
function parseGpu(text) {
    const p = (text || "").split("\n")[0].split(",").map(x => x.trim())
    return {
        util: parseFloat(p[0]) || 0,
        used: parseFloat(p[1]) || 0,
        total: parseFloat(p[2]) || 0,
        temp: parseFloat(p[3]) || 0,
        vendor: p[4] === "amd" || p[4] === "nvidia" ? p[4] : ""
    }
}

// Mascote do cartão de GPU: "auto" segue o fabricante detectado.
function gpuMascot(choice, vendor) {
    if (choice && choice !== "auto") return choice
    return vendor === "amd" ? "amd" : "nvidia"
}

// Acrescenta uma amostra a uma série numérica com tamanho máximo.
function pushSample(series, value, max) {
    return (series || []).concat([value]).slice(-max)
}

// Humor pela temperatura: quente pula, crítica entra em alarme. temp 0 = sem sensor.
function tempMood(temp, hot, critical) {
    if (!temp) return "sleep"
    return temp >= critical ? "alarm" : temp >= hot ? "busy" : "sleep"
}

// O pior dos humores (sleep < idle < busy < alarm).
function worstMood(a, b) {
    const order = ["sleep", "idle", "busy", "alarm"]
    return order[Math.max(order.indexOf(a), order.indexOf(b))]
}

// Taxa (bytes/s) entre duas leituras de contadores { rx, tx } tiradas em t (ms).
function netRate(prev, cur, dtMs) {
    if (!prev || !cur || dtMs <= 0) return { rx: 0, tx: 0 }
    const r = v => Math.max(0, v) / (dtMs / 1000)
    return { rx: r(cur.rx - prev.rx), tx: r(cur.tx - prev.tx) }
}

// Saída do comando de disco:
//   "df <total> <usado>"  (bytes do sistema de arquivos onde fica o DockerRootDir)
//   "<Tipo>\t<Tamanho>\t<Recuperável (x%)>" por linha de docker system df
function parseDisk(text) {
    const r = { total: 0, used: 0, docker: 0, reclaimable: 0, parts: {} }
    for (const line of (text || "").split("\n")) {
        if (line.startsWith("df ")) {
            const f = line.split(/\s+/)
            r.total = parseFloat(f[1]) || 0
            r.used = parseFloat(f[2]) || 0
        } else if (line.indexOf("\t") > 0) {
            const [type, size, recl] = line.split("\t")
            const b = parseBytes(size)
            r.parts[type] = b
            r.docker += b
            r.reclaimable += parseBytes(recl)
        }
    }
    return r
}

// "/nome 3" por linha (docker inspect) -> { nome: 3 }
function parseRestarts(text) {
    const r = {}
    for (const line of (text || "").split("\n")) {
        const m = /^\/?(\S+)\s+(\d+)$/.exec(line.trim())
        if (m) r[m[1]] = parseInt(m[2])
    }
    return r
}

// Containers cujo contador de reinícios subiu desde a leitura anterior.
function restartBumps(prev, cur) {
    return Object.keys(cur).filter(n => prev[n] !== undefined && cur[n] > prev[n])
}

// Remove códigos ANSI (cores) e caracteres de controle dos logs.
function cleanLog(text) {
    return (text || "").replace(/\x1b\[[0-9;?]*[A-Za-z]/g, "").replace(/[\x00-\x08\x0b-\x1f\x7f]/g, "")
}
