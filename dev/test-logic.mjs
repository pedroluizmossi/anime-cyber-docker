// Testes da lógica pura (package/contents/ui/Logic.js). Uso: node dev/test-logic.mjs
import { readFileSync } from "node:fs"
import assert from "node:assert/strict"

const src = readFileSync(new URL("../package/contents/ui/Logic.js", import.meta.url), "utf8")
    .replace(/^\.pragma library\s*$/m, "")
const L = new Function(src + "\nreturn { parseHost, cpuPercent, parsePorts, parseBytes, formatBytes, formatMiB, pushHistory, buildRows, detectEvents, snapshot, validContainerName, validProjectName, vitalMood, pushSample, parseGpu, gpuMascot, tempMood, worstMood, netRate, parseDisk, parseRestarts, restartBumps, cleanLog }")()

let n = 0
const test = (name, fn) => { fn(); n++; console.log("ok -", name) }

test("parsePorts: IPv4/IPv6 duplicados, wildcard vira localhost, ignora não publicadas e udp", () => {
    const p = L.parsePorts("0.0.0.0:80->80/tcp, [::]:80->80/tcp, 127.0.0.1:8090->8080/tcp, 6379/tcp, 0.0.0.0:53->53/udp")
    assert.deepEqual(p.map(x => x.url), ["http://localhost:80", "http://127.0.0.1:8090"])
})
test("parsePorts: faixa de portas usa a primeira, IP específico preservado", () => {
    const p = L.parsePorts("192.168.0.10:3000-3002->3000-3002/tcp")
    assert.deepEqual(p, [{ host: "192.168.0.10", port: 3000, url: "http://192.168.0.10:3000" }])
})
test("parsePorts: vazio", () => assert.deepEqual(L.parsePorts(""), []))

test("parseBytes / formatBytes", () => {
    assert.equal(L.parseBytes("1.5GiB"), 1.5 * 1073741824)
    assert.equal(L.parseBytes("184MiB"), 184 * 1048576)
    assert.equal(L.parseBytes("18.5kB"), 18500)
    assert.equal(L.parseBytes("lixo"), 0)
    assert.equal(L.formatBytes(184 * 1048576), "184M")
    assert.equal(L.formatBytes(1.4 * 1073741824), "1.4G")
    assert.equal(L.formatMiB(2288), "2.2G")
})

test("pushHistory limita o tamanho", () => {
    let h = {}
    for (let i = 0; i < 40; i++) h.a = L.pushHistory(h, "a", i, i * 10, 30)
    assert.equal(h.a.cpu.length, 30)
    assert.equal(h.a.cpu[29], 39)
})

const cs = [
    { name: "web", image: "nginx", state: "running", project: "shop", problem: false },
    { name: "db", image: "postgres", state: "running", project: "shop", problem: false },
    { name: "worker", image: "py", state: "restarting", project: "shop", problem: true },
    { name: "old", image: "x", state: "exited", project: "", problem: false },
    { name: "llm", image: "llama", state: "running", project: "ai", problem: false }
]

test("buildRows: problema primeiro, depois rodando, depois parado", () => {
    const r = L.buildRows(cs, {}).map(x => x.c.name)
    assert.deepEqual(r, ["worker", "db", "llm", "web", "old"])
})
test("buildRows: favorito vai pro topo", () => {
    const r = L.buildRows(cs, { favorites: ["old"] }).map(x => x.c.name)
    assert.equal(r[0], "old")
})
test("buildRows: ocultar parados mantém favoritos e problemas", () => {
    assert.ok(!L.buildRows(cs, { hideStopped: true }).some(x => x.c.name === "old"))
    assert.ok(L.buildRows(cs, { hideStopped: true, favorites: ["old"] }).some(x => x.c.name === "old"))
    assert.ok(L.buildRows(cs, { hideStopped: true }).some(x => x.c.name === "worker"))
})
test("buildRows: busca por nome, imagem ou projeto", () => {
    assert.deepEqual(L.buildRows(cs, { search: "POST" }).map(x => x.c.name), ["db"])
    assert.equal(L.buildRows(cs, { search: "shop" }).length, 3)
})
test("buildRows: agrupado — stack com problema primeiro, sem stack por último, colapso", () => {
    const r = L.buildRows(cs, { group: true })
    assert.deepEqual(r.filter(x => x.type === "header").map(x => x.project), ["shop", "ai", ""])
    const shop = r[0]
    assert.deepEqual([shop.total, shop.running, shop.problems], [3, 2, 1])
    const col = L.buildRows(cs, { group: true, collapsed: { shop: true } })
    assert.equal(col[1].type, "header")          // nenhum container de "shop" depois do header
})

test("detectEvents: crash, restarting, unhealthy, recovered; ignora stop manual e containers novos", () => {
    const prev = {
        a: { state: "running", health: "", problem: false },
        b: { state: "running", health: "", problem: false },
        c: { state: "running", health: "healthy", problem: false },
        d: { state: "restarting", health: "", problem: true },
        e: { state: "running", health: "", problem: false }
    }
    const now = [
        { name: "a", state: "exited", exitCode: 1, health: "", problem: true },
        { name: "b", state: "restarting", exitCode: 0, health: "", problem: true },
        { name: "c", state: "running", exitCode: 0, health: "unhealthy", problem: true },
        { name: "d", state: "running", exitCode: 0, health: "", problem: false },
        { name: "e", state: "exited", exitCode: 143, health: "", problem: false },
        { name: "novo", state: "exited", exitCode: 1, health: "", problem: false }
    ]
    const ev = L.detectEvents(prev, now).map(e => e.kind + ":" + e.name)
    assert.deepEqual(ev, ["crash:a", "restarting:b", "unhealthy:c", "recovered:d"])
})

test("validação de nomes", () => {
    assert.ok(L.validContainerName("database-index-postgres-1"))
    assert.ok(!L.validContainerName("x; rm -rf ~"))
    assert.ok(L.validProjectName("embeddings"))
    assert.ok(!L.validProjectName("Bad Name"))
})

test("parseHost + cpuPercent", () => {
    const a = L.parseHost("cpu  100 0 100 700 100 0 0 0 0 0\nMemTotal:       48000000 kB\nMemAvailable:   36000000 kB")
    assert.deepEqual(a.cpu, { busy: 200, total: 1000 })
    assert.equal(a.memTotal, 48000000 * 1024)
    assert.equal(a.memUsed, 12000000 * 1024)
    const b = L.parseHost("cpu  250 0 150 1300 100 0 0 0 0 0")
    assert.equal(L.cpuPercent(a.cpu, b.cpu), 25)      // +200 ocupado em +800 total
    assert.equal(L.cpuPercent(null, b.cpu), 0)
})

test("vitalMood: dorme parada/indisponível, pula na carga, alarme saturada", () => {
    assert.equal(L.vitalMood(1, 60, 85), "sleep")
    assert.equal(L.vitalMood(50, 60, 85, false), "sleep")
    assert.equal(L.vitalMood(30, 60, 85), "idle")
    assert.equal(L.vitalMood(60, 60, 85), "busy")
    assert.equal(L.vitalMood(92, 60, 85), "alarm")
})
test("pushSample: limita o tamanho e aceita série vazia", () => {
    assert.deepEqual(L.pushSample(undefined, 5, 3), [5])
    assert.deepEqual(L.pushSample([1, 2, 3], 4, 3), [2, 3, 4])
})

test("parseGpu: nvidia, amd e vazio", () => {
    assert.deepEqual(L.parseGpu("71, 3120, 16376, 64, nvidia\n12, 1, 2, 3, nvidia"), { util: 71, used: 3120, total: 16376, temp: 64, vendor: "nvidia" })
    assert.deepEqual(L.parseGpu("5, 512, 8176, , amd"), { util: 5, used: 512, total: 8176, temp: 0, vendor: "amd" })
    assert.deepEqual(L.parseGpu(""), { util: 0, used: 0, total: 0, temp: 0, vendor: "" })
})
test("gpuMascot: auto segue o fabricante, escolha manual vence", () => {
    assert.equal(L.gpuMascot("auto", "amd"), "amd")
    assert.equal(L.gpuMascot("auto", ""), "nvidia")
    assert.equal(L.gpuMascot("sapo", "amd"), "sapo")
})

test("parseHost: temperatura e rede opcionais", () => {
    const h = L.parseHost("cpu 1 2 3 4 5 6 7 8\nMemTotal: 100 kB\nMemAvailable: 40 kB\ntemp 37750\nnet 1000 200")
    assert.equal(h.temp, 37.75)
    assert.deepEqual(h.net, { rx: 1000, tx: 200 })
    assert.equal(L.parseHost("cpu 1 2 3 4").temp, 0)
})
test("tempMood / worstMood", () => {
    assert.equal(L.tempMood(0, 80, 90), "sleep")
    assert.equal(L.tempMood(85, 80, 90), "busy")
    assert.equal(L.tempMood(95, 80, 90), "alarm")
    assert.equal(L.worstMood("idle", "sleep"), "idle")
    assert.equal(L.worstMood("idle", "alarm"), "alarm")
})
test("netRate: bytes/s e contador zerado não dá negativo", () => {
    assert.deepEqual(L.netRate({ rx: 0, tx: 0 }, { rx: 3000, tx: 300 }, 3000), { rx: 1000, tx: 100 })
    assert.deepEqual(L.netRate({ rx: 9000, tx: 0 }, { rx: 10, tx: 0 }, 1000), { rx: 0, tx: 0 })
    assert.deepEqual(L.netRate(null, { rx: 1, tx: 1 }, 1000), { rx: 0, tx: 0 })
})
test("parseDisk: df + docker system df", () => {
    const d = L.parseDisk("df 576716800000 347058270208\nImages\t21.89GB\t3.43GB (15%)\nContainers\t348.2kB\t0B (0%)\nLocal Volumes\t4GB\t0B (0%)\nBuild Cache\t0B\t0B")
    assert.equal(d.total, 576716800000)
    assert.equal(d.used, 347058270208)
    assert.equal(d.parts.Images, 21.89e9)
    assert.equal(Math.round(d.docker), Math.round(21.89e9 + 348200 + 4e9))
    assert.equal(d.reclaimable, 3.43e9)
})
test("parseRestarts / restartBumps", () => {
    const r = L.parseRestarts("/llama-swap 0\n/shop-api-1 7\nlixo")
    assert.deepEqual(r, { "llama-swap": 0, "shop-api-1": 7 })
    assert.deepEqual(L.restartBumps({ "shop-api-1": 6, "llama-swap": 0 }, r), ["shop-api-1"])
    assert.deepEqual(L.restartBumps({}, r), [])                       // 1ª leitura não conta
})
test("cleanLog tira ANSI e controle", () => {
    assert.equal(L.cleanLog("\x1b[32mINFO\x1b[0m ok\r\nnext\x07"), "INFO ok\nnext")
})

console.log(`\n${n} testes passaram`)
