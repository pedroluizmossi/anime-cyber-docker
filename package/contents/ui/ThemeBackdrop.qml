// Fundo animado por tema, desenhado acima do gradiente do popup (anchors.fill, opacidade baixa).
// Um único Canvas e um Timer leve que só roda com animated && visible. Com animated: false,
// desenha um quadro estático.
import QtQuick
import "Themes.js" as Themes

Item {
    id: bd

    property string themeKey: "neon"     // neon | matrix | synthwave | vaporwave | akira | ghost | custom
    property var theme: Themes.get("neon")
    property bool animated: true

    opacity: 0.25

    readonly property var th: theme || Themes.get("neon")   // tema pode chegar indefinido na criação
    readonly property color cFur: th.fur
    readonly property color cVisor: th.visor
    readonly property color cWarn: th.warn
    readonly property color cOk: th.ok
    readonly property color cText: th.text
    readonly property string glyphs: "ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈ0123456789"

    property int frame: 0

    readonly property string paintKey: [themeKey, width, height, th.fur, th.visor, th.warn, th.ok, th.text].join("|")

    // hash inteiro determinístico -> [0, 1)
    function rnd(n) {
        let x = Math.imul(n ^ (n >>> 16), 0x45d9f3b)
        x = Math.imul(x ^ (x >>> 16), 0x45d9f3b)
        x ^= x >>> 16
        return (x >>> 0) / 4294967296
    }

    // ---- matrix: colunas de glifos caindo ----------------------------------
    function drawMatrix(ctx, w, h) {
        const step = 14, lineH = 11
        const cycle = h + 16 * lineH
        const n = Math.floor(w / step)
        ctx.font = "11px 'Hack Nerd Font Mono', monospace"
        ctx.textBaseline = "top"
        ctx.textAlign = "left"
        for (let i = 0; i < n; i++) {
            const x = i * step + 2
            const spd = 0.5 + rnd(i * 5) * 1.2
            const head = ((rnd(i * 5 + 1) * cycle + frame * spd) % cycle) - 2 * lineH
            const len = 8 + Math.floor(rnd(i * 5 + 2) * 8)
            for (let k = 0; k < len; k++) {
                const y = head - k * lineH
                if (y < -lineH || y > h) continue
                const gi = Math.floor(rnd(i * 977 + k * 13 + Math.floor(frame / 4)) * glyphs.length)
                if (k === 0) {
                    ctx.globalAlpha = 0.9
                    ctx.fillStyle = Qt.lighter(cOk, 1.7)
                } else {
                    ctx.globalAlpha = 0.7 * (1 - k / len)
                    ctx.fillStyle = cOk
                }
                ctx.fillText(glyphs.charAt(gi), x, y)
            }
        }
    }

    // ---- grade em perspectiva (synthwave e neon) ----------------------------
    function drawGrid(ctx, w, h, col, alpha) {
        const hy = h * 0.65                      // linha do horizonte: grade ocupa ~35% de baixo
        const vx = w / 2
        ctx.strokeStyle = col
        ctx.lineWidth = 1
        ctx.globalAlpha = alpha
        ctx.beginPath()
        ctx.moveTo(0, hy)
        ctx.lineTo(w, hy)
        for (let u = -8; u <= 8; u++) {           // linhas verticais convergindo ao horizonte
            ctx.moveTo(vx, hy)
            ctx.lineTo(vx + u * w * 0.16, h)
        }
        const N = 9
        const phase = (frame * 0.04) % 1          // rolagem em direção ao observador
        for (let k = 0; k < N; k++) {
            const p = (k + phase) / N
            const y = hy + (h - hy) * p * p
            ctx.moveTo(0, y)
            ctx.lineTo(w, y)
        }
        ctx.stroke()
    }

    // sol retrô: semicírculo com faixas recortadas, gradiente warn -> fur
    function drawSun(ctx, w, h) {
        const R = Math.min(w * 0.26, h * 0.2)
        const cx = w / 2, cy = h * 0.36
        const g = ctx.createLinearGradient(0, cy - R, 0, cy + R)
        g.addColorStop(0, cWarn)
        g.addColorStop(1, cFur)
        ctx.save()
        ctx.globalAlpha = 1
        ctx.fillStyle = g
        ctx.beginPath()
        ctx.arc(cx, cy, R, 0, Math.PI * 2)
        ctx.fill()
        ctx.globalCompositeOperation = "destination-out"
        let y = cy + R * 0.12, gap = 1.5
        while (y < cy + R) {
            ctx.fillRect(cx - R, y, 2 * R, gap)
            y += gap + 4
            gap += 0.7
        }
        ctx.restore()
    }

    // ---- vaporwave: estrelas piscando ---------------------------------------
    function drawStars(ctx, w, h) {
        const n = Math.max(12, Math.floor(w * h / 1800))
        for (let i = 0; i < n; i++) {
            const x = Math.floor(rnd(i * 3 + 1) * w)
            const y = Math.floor(rnd(i * 3 + 2) * h * 0.8)
            const tw = 0.5 + 0.5 * Math.sin(frame * 0.35 + i * 1.7)
            const s = rnd(i * 3 + 3) < 0.25 ? 2 : 1
            ctx.globalAlpha = 0.2 + 0.8 * tw
            ctx.fillStyle = i % 3 === 0 ? cVisor : cText
            ctx.fillRect(x, y, s, s)
        }
    }

    // ---- ghost: neve / gelo caindo devagar ----------------------------------
    function drawSnow(ctx, w, h) {
        const n = Math.max(20, Math.floor(w * h / 700))
        for (let i = 0; i < n; i++) {
            const spd = 0.3 + rnd(i * 4 + 1) * 0.7
            const y = (rnd(i * 4 + 2) * h + frame * spd) % h
            const x = (rnd(i * 4 + 3) * w + Math.sin(frame * 0.06 + i) * 6 + w) % w
            ctx.globalAlpha = 0.3 + rnd(i * 4 + 4) * 0.6
            ctx.fillStyle = i % 4 === 0 ? cVisor : cText
            const s = rnd(i * 4 + 4) < 0.3 ? 2 : 1
            ctx.fillRect(Math.floor(x), Math.floor(y), s, s)
        }
    }

    // ---- akira: linhas de velocidade diagonais ------------------------------
    function drawSpeed(ctx, w, h) {
        const n = 16
        const span = w * 1.4
        ctx.strokeStyle = cFur
        for (let i = 0; i < n; i++) {
            const len = 40 + rnd(i * 4 + 1) * 90
            const spd = 2 + rnd(i * 4 + 3) * 3
            const x = (((rnd(i * 4 + 2) * span - frame * spd) % span) + span) % span - 40
            const y = rnd(i * 4 + 4) * h
            ctx.globalAlpha = 0.25 + rnd(i * 4 + 5) * 0.35
            ctx.lineWidth = i % 3 === 0 ? 2 : 1
            ctx.beginPath()
            ctx.moveTo(x, y)
            ctx.lineTo(x + len * 0.6, y - len * 0.6)
            ctx.stroke()
        }
    }

    function drawFrame(ctx, w, h) {
        ctx.reset()
        switch (themeKey) {
        case "matrix":    drawMatrix(ctx, w, h); break
        case "synthwave": drawSun(ctx, w, h); drawGrid(ctx, w, h, cFur, 0.55); break
        case "vaporwave": drawStars(ctx, w, h); break
        case "ghost":     drawSnow(ctx, w, h); break
        case "akira":     drawSpeed(ctx, w, h); break
        default:          drawGrid(ctx, w, h, cVisor, 0.5)    // neon / custom: só a grade
        }
    }

    onPaintKeyChanged: cv.requestPaint()
    Component.onCompleted: cv.requestPaint()

    Canvas {
        id: cv
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative
        onPaint: bd.drawFrame(getContext("2d"), width, height)
    }

    Timer {
        interval: 80
        running: bd.visible && bd.animated
        repeat: true
        onTriggered: {
            bd.frame = (bd.frame + 1) % 1000000
            cv.requestPaint()
        }
    }
}
