// Skyline cyberpunk em pixel art, ancorada no rodapé da área (atrás da lista de containers).
// Layout determinístico (hash do índice, sem Math.random): o Canvas estático só é refeito
// quando tamanho, tema, humor ou faixa de carga (de 10 em 10) mudam. Só as antenas, algumas
// janelas e a chuva (alarme) animam, num Timer leve que roda apenas com animated && visible.
import QtQuick
import "Themes.js" as Themes

Item {
    id: sky

    property var theme: Themes.get("neon")   // objeto de Themes.js
    property string mood: "idle"             // "sleep" | "idle" | "busy" | "alarm" | "happy"
    property real load: 0                    // 0..100, CPU do host: mais carga = mais janelas acesas
    property bool animated: true

    readonly property var th: theme || Themes.get("neon")   // tema pode chegar indefinido na criação
    readonly property real cell: 3                          // um "pixel" da skyline, em px
    readonly property int cols: Math.max(1, Math.floor(width / cell))
    readonly property int rows: Math.max(1, Math.floor(height / cell))
    readonly property int loadBucket: Math.round(Math.max(0, Math.min(100, load)) / 10) * 10
    readonly property bool sleeping: mood === "sleep"
    readonly property bool alarming: mood === "alarm"
    readonly property real litChance: sleeping ? 0.02 : 0.10 + loadBucket * 0.006
    readonly property real stageOpacity: sleeping ? 0.3 : alarming ? 0.5 : 0.42   // visual total fica entre 0.35 e 0.5

    readonly property color cFill: mix(th.bg1, th.text, 0.12)   // silhueta: um pouco mais clara que bg1
    readonly property color cFur: th.fur
    readonly property color cVisor: th.visor
    readonly property color cWarn: th.warn
    readonly property color cOk: th.ok
    readonly property color cAlarm: th.alarm

    property int frame: 0

    // chave de redesenho do Canvas estático: qualquer mudança visível refaz a cidade
    readonly property string cityKey: [width, height, mood, loadBucket, th.fur, th.visor, th.warn,
                                       th.ok, th.alarm, th.bg1, th.text].join("|")

    // ---- utilidades --------------------------------------------------------
    // hash inteiro determinístico -> [0, 1)
    function rnd(n) {
        let x = Math.imul(n ^ (n >>> 16), 0x45d9f3b)
        x = Math.imul(x ^ (x >>> 16), 0x45d9f3b)
        x ^= x >>> 16
        return (x >>> 0) / 4294967296
    }

    function mix(a, b, t) {
        const A = Qt.color(a), B = Qt.color(b)
        return Qt.rgba(A.r + (B.r - A.r) * t, A.g + (B.g - A.g) * t, A.b + (B.b - A.b) * t, 1)
    }

    // ---- layout ------------------------------------------------------------
    // Prédios em fileira contínua; as alturas saem do índice, então não mudam entre repaints.
    function makeLayer(nCols, nRows, seedBase, hMin, hMax, startX) {
        const out = []
        let x = startX, i = 0
        while (x < nCols) {
            const s = seedBase + i * 8
            const w = 5 + Math.floor(rnd(s) * 8)                                   // 5..12 células
            const gap = rnd(s + 1) < 0.3 ? 1 : 0
            const h = Math.min(nRows, Math.max(4, Math.round(nRows * (hMin + rnd(s + 2) * (hMax - hMin)))))
            const ant = rnd(s + 3) < 0.22 ? 3 + Math.floor(rnd(s + 4) * 3) : 0    // antena com LED
            out.push({ x: x, w: w, h: h, ant: ant, seed: s })
            x += w + gap
            i++
        }
        return out
    }
    readonly property var backLayer: makeLayer(cols, rows, 5000, 0.12, 0.26, -4)   // fundo, mais baixo e apagado
    readonly property var frontLayer: makeLayer(cols, rows, 100, 0.18, 0.40, 0)    // 18%..40% da altura

    // ---- pintura estática (cidade) ------------------------------------------
    function paintLayer(ctx, list, k) {
        const cs = cell
        for (let b = 0; b < list.length; b++) {
            const B = list[b]
            const top = rows - B.h
            ctx.globalAlpha = k
            ctx.fillStyle = cFill
            ctx.fillRect(B.x * cs, top * cs, B.w * cs, B.h * cs)

            // borda superior fina na cor fur
            ctx.globalAlpha = 0.3 * k
            ctx.fillStyle = cFur
            ctx.fillRect(B.x * cs, top * cs, B.w * cs, cs)

            if (B.ant > 0) {
                ctx.globalAlpha = k
                ctx.fillStyle = cFill
                ctx.fillRect((B.x + Math.floor(B.w / 2)) * cs, (top - B.ant) * cs, cs, B.ant * cs)
            }

            // janelas: uma célula com espaço de uma célula entre elas
            for (let wy = top + 2; wy < rows - 1; wy += 2) {
                for (let wx = B.x + 1; wx < B.x + B.w - 1; wx += 2) {
                    const id = B.seed * 7 + wy * 131 + wx * 17
                    if (rnd(id) >= litChance) continue
                    const r2 = rnd(id + 1), r3 = rnd(id + 2)
                    let col = cVisor, a = 0.4 + r2 * 0.35
                    if (sleeping) {
                        a = 0.25
                    } else if (alarming) {
                        col = cAlarm
                        a = 0.45 + r2 * 0.3
                    } else if (mood === "happy" && r3 < 0.12) {
                        col = cOk
                        a = 0.6
                    } else if (r3 < (mood === "busy" ? 0.35 : 0.12)) {
                        col = cWarn
                    }
                    ctx.globalAlpha = a * k
                    ctx.fillStyle = col
                    ctx.fillRect(wx * cs, wy * cs, cs, cs)
                }
            }
        }
    }

    // ---- pintura animada (LEDs e janelas piscando) --------------------------
    function paintBlink(ctx) {
        ctx.reset()
        const cs = cell
        for (let b = 0; b < frontLayer.length; b++) {
            const B = frontLayer[b]
            if (B.ant <= 0) continue
            const on = alarming ? (frame % 2 === 0) : ((frame + B.seed) % 6 < 3)
            if (!on) continue
            const top = rows - B.h
            ctx.globalAlpha = sleeping ? 0.3 : 0.85
            ctx.fillStyle = (alarming || B.seed % 2 === 0) ? cAlarm : cVisor
            ctx.fillRect((B.x + Math.floor(B.w / 2)) * cs, (top - B.ant - 1) * cs, cs, cs)
        }

        // duas janelas "piscando" por quadro (acendem e apagam no quadro seguinte)
        if (!sleeping && frontLayer.length > 0) {
            for (let k = 0; k < 2; k++) {
                const id = frame * 37 + k * 7919 + 13
                const B = frontLayer[Math.floor(rnd(id) * frontLayer.length)]
                const nWx = Math.max(1, Math.floor((B.w - 2) / 2))
                const nWy = Math.max(1, Math.floor((B.h - 3) / 2))
                const wx = B.x + 1 + 2 * Math.floor(rnd(id + 1) * nWx)
                const wy = rows - B.h + 2 + 2 * Math.floor(rnd(id + 2) * nWy)
                ctx.globalAlpha = 0.6
                ctx.fillStyle = alarming ? cAlarm : cVisor
                ctx.fillRect(wx * cs, wy * cs, cs, cs)
            }
        }
    }

    // chuva neon diagonal (só em alarme): traços de 1px descendo em diagonal
    function paintRain(ctx, w, h) {
        ctx.reset()
        if (!alarming) return
        const n = Math.max(10, Math.floor(w / 10))
        ctx.fillStyle = cVisor
        for (let k = 0; k < n; k++) {
            const x0 = rnd(k * 3 + 1) * w
            const speed = 0.6 + rnd(k * 3 + 2) * 0.8
            const y0 = ((rnd(k * 3 + 3) * (h + 40) + frame * 10 * speed) % (h + 40)) - 20
            ctx.globalAlpha = 0.12 + rnd(k * 3 + 4) * 0.12
            for (let s = 0; s < 10; s++)
                ctx.fillRect(Math.round(x0 - s * 0.5), Math.round(y0 + s), 1, 1)
        }
    }

    function repaintAll() {
        city.requestPaint()
        blink.requestPaint()
        rain.requestPaint()
    }
    onCityKeyChanged: repaintAll()
    Component.onCompleted: repaintAll()

    Timer {
        id: ticker
        interval: 150
        running: sky.visible && sky.animated
        repeat: true
        onTriggered: {
            sky.frame = (sky.frame + 1) % 100000
            blink.requestPaint()
            if (sky.alarming) rain.requestPaint()
        }
    }

    Item {
        id: stage
        anchors.fill: parent
        opacity: sky.stageOpacity

        Canvas {
            id: city
            anchors.fill: parent
            antialiasing: false
            renderStrategy: Canvas.Cooperative
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                sky.paintLayer(ctx, sky.backLayer, 0.55)
                sky.paintLayer(ctx, sky.frontLayer, 1.0)
            }
        }

        Canvas {
            id: blink
            anchors.fill: parent
            antialiasing: false
            renderStrategy: Canvas.Cooperative
            onPaint: sky.paintBlink(getContext("2d"))
        }

        Canvas {
            id: rain
            anchors.fill: parent
            visible: sky.alarming
            antialiasing: false
            renderStrategy: Canvas.Cooperative
            onPaint: sky.paintRain(getContext("2d"), width, height)
        }
    }
}
