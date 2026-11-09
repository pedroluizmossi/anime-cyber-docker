// Mascote em pixel art desenhada em Canvas, com aura neon.
// mood: "sleep" | "idle" | "busy" | "alarm"     kind: chave em Sprites.js
//
// Desempenho: o Timer só avança o quadro. A sprite é redesenhada apenas quando
// algo visível muda (olho, glitch, LED) e o glow só em mudanças estruturais
// (humor, tema, mascote, tamanho). Flutuar/pular é um Translate, sem redesenho.
import QtQuick
import QtQuick.Window
import QtQuick.Effects
import "Themes.js" as Themes
import "Sprites.js" as Sprites

Item {
    id: m

    property string mood: "idle"
    property string kind: "neko"
    property var theme: Themes.get("neon")
    readonly property var th: theme || Themes.get("neon")   // tema pode chegar indefinido durante a criação
    property color fur: th.fur
    property color visor: th.visor
    property int glowLevel: 75          // 0..100
    property bool animated: true
    property bool showEffects: true     // textos flutuantes (zzz, !, ⚡)
    readonly property bool glow: glowLevel > 0
    readonly property var spriteDef: Sprites.get(kind)
    readonly property var grid: spriteDef.grid

    implicitWidth: 64
    implicitHeight: 56

    readonly property color accent: mood === "alarm" ? th.alarm
                                  : mood === "sleep" ? th.sleep
                                  : mood === "busy"  ? th.warn
                                  : visor
    readonly property color skin: "#ffe0d0"
    property int frame: 1

    Timer {
        interval: m.mood === "alarm" ? 80 : m.mood === "busy" ? 120 : m.mood === "sleep" ? 250 : 200
        running: m.visible && m.animated
        repeat: true
        onTriggered: {
            m.frame = (m.frame + 1) % 600
            m.paintIfChanged()
        }
    }

    // ---- cores -------------------------------------------------------------
    function eyeColor() {
        switch (mood) {
        case "sleep": return null                                              // fechado
        case "alarm": return frame % 4 < 2 ? th.alarm : Qt.lighter(th.alarm, 1.6)
        case "busy":  return frame % 6 < 3 ? th.warn : Qt.darker(th.warn, 1.35)
        default:      return (animated && frame % 25 === 0) ? null : Qt.lighter(th.outline, 2.2) // piscada
        }
    }

    function ledColor() {
        switch (mood) {
        case "sleep": return Qt.darker(visor, 2.8)
        case "alarm": return frame % 4 < 2 ? th.alarm : th.outline
        case "busy":  return frame % 4 < 2 ? th.warn : Qt.darker(th.warn, 1.8)
        default:      return visor
        }
    }

    function glitchOn() { return mood === "alarm" && animated && frame % 6 < 2 }

    function cellColor(ch, x, y) {
        const dim = mood === "sleep"
        switch (ch) {
        case "K": return th.outline
        case "M": return th.ear
        case "H": return dim ? fur : Qt.lighter(fur, 1.45)
        case "S": return Qt.darker(fur, dim ? 1.6 : 1.35)
        case "B": return mood === "alarm" ? fur : th.blush
        case "P": return y >= spriteDef.shadeFrom ? Qt.darker(fur, 1.35) : (dim ? Qt.darker(fur, 1.2) : fur)
        case "T": return mood === "alarm" ? th.alarm : th.outline
        case "C": return dim ? Qt.darker(visor, 2.8) : (mood === "alarm" ? Qt.darker(th.alarm, 1.6) : visor)
        case "F": return dim ? Qt.darker(skin, 1.15) : skin
        case "D": return Qt.lighter(th.outline, 3.2)
        case "A": return ledColor()
        case "E":
        case "W": {
            const e = eyeColor()
            if (e === null) // olho fechado: traço na última linha do olho
                return y === spriteDef.closedRow ? th.outline : cellColor(spriteDef.eyeBg, x, y)
            return ch === "W" ? "#ffffff" : e
        }
        }
        return null
    }

    // ---- geometria travada em pixels inteiros: sem bordas borradas ----------
    readonly property real dpr: Screen.devicePixelRatio || 1
    readonly property real px: Math.max(1, Math.floor(Math.min(width / 16, height / 14) * dpr)) / dpr
    readonly property real ox: Math.round((width - 16 * px) / 2 * dpr) / dpr
    readonly property real oy: Math.round((height - 14 * px) / 2 * dpr) / dpr
    function snap(v) { return Math.round(v * dpr) / dpr }

    function paintSprite(ctx, forGlow) {
        ctx.reset()
        const drawPass = function (dx, tint, alpha) {
            ctx.globalAlpha = alpha
            for (let y = 0; y < grid.length; y++) {
                const row = grid[y]
                for (let x = 0; x < row.length; x++) {
                    if (row[x] === ".") continue
                    const c = tint || cellColor(row[x], x, y)
                    if (c === null) continue
                    ctx.fillStyle = c
                    ctx.fillRect(ox + (x + dx) * px, oy + y * px, px, px)
                }
            }
        }
        if (!forGlow && glitchOn()) {   // glitch RGB
            drawPass(-1, visor.toString(), 0.45)
            drawPass(1, fur.toString(), 0.45)
        }
        drawPass(0, null, 1.0)
    }

    // ---- controle de redesenho ---------------------------------------------
    property string lastKey: ""
    property int paintCount: 0          // diagnóstico (dev/preview-perf.qml)

    function visualKey() {
        const e = eyeColor()
        return (e === null ? "-" : e.toString()) + "|" + glitchOn() + "|" + ledColor().toString()
    }
    function paintIfChanged() {
        if (!theme) return
        const k = visualKey()
        if (k === lastKey) return
        lastKey = k
        sprite.requestPaint()
    }
    function repaintAll() {
        if (!theme) return          // ainda sendo criado; onThemeChanged chama de novo
        lastKey = visualKey()
        sprite.requestPaint()
        if (glow) glowCanvas.requestPaint()
    }
    onWidthChanged: repaintAll()
    onHeightChanged: repaintAll()
    onMoodChanged: repaintAll()
    onThemeChanged: repaintAll()
    onKindChanged: repaintAll()
    onGlowLevelChanged: repaintAll()
    onAnimatedChanged: repaintAll()
    Component.onCompleted: repaintAll()   // garante o 1º desenho mesmo sem animação

    Item {
        id: wrapper
        anchors.fill: parent
        transform: Translate {
            x: !m.animated ? 0 : m.snap(m.mood === "alarm" ? ((m.frame % 2) ? 1 : -1) * Math.max(1, m.px) : 0)
            y: !m.animated ? 0 : m.snap(m.mood === "busy"  ? -Math.abs(Math.sin(m.frame * 0.73)) * m.height * 0.09
                    : m.mood === "sleep" ? Math.sin(m.frame * 0.2) * m.height * 0.025
                    : m.mood === "idle"  ? Math.sin(m.frame * 0.107) * m.height * 0.03
                    : 0)
        }

        // fonte do glow (invisível): só alimenta o MultiEffect, redesenhada raramente
        Item {
            id: glowSource
            anchors.fill: parent
            visible: false
            Canvas {
                id: glowCanvas
                anchors.fill: parent
                antialiasing: false
                renderStrategy: Canvas.Cooperative
                onAvailableChanged: if (available) requestPaint()
                onPaint: m.paintSprite(getContext("2d"), true)
            }
        }

        MultiEffect {
            anchors.fill: glowSource
            source: glowSource
            visible: m.glow
            autoPaddingEnabled: true
            shadowEnabled: true
            shadowColor: m.accent
            // no painel (pequeno) o glow fica mais contido para não "embaçar" a sprite
            shadowBlur: m.height < 48 ? 0.4 : 0.9
            shadowScale: m.height < 48 ? 1.0 : 1.05
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            // pisca só no alarme; nos outros humores é constante (não força recomposição)
            shadowOpacity: (m.glowLevel / 100) * (m.height < 48 ? 1.0 : 1.3)
                           * (m.mood === "alarm" && m.animated ? (m.frame % 4 < 2 ? 1.0 : 0.5) : 0.85)
        }

        // sprite nítida, desenhada por cima do glow sem passar pelo filtro
        Canvas {
            id: sprite
            anchors.fill: parent
            antialiasing: false
            smooth: false
            renderStrategy: Canvas.Cooperative
            onAvailableChanged: if (available) requestPaint()
            onPaint: {
                m.paintCount++
                m.paintSprite(getContext("2d"), false)
            }
        }

        // efeitos flutuantes
        Text {
            visible: m.showEffects && m.mood === "sleep"
            readonly property int t: m.frame % 24
            text: "z"
            color: Qt.lighter(m.th.sleep, 1.4)
            font.family: "Hack Nerd Font Mono"
            font.bold: true
            font.pixelSize: Math.max(8, Math.round(m.height * 0.28 * (0.6 + t / 36)))
            x: Math.round(m.width * 0.78 + t * m.width * 0.0067)
            y: Math.round(m.height * 0.05 - t * m.height * 0.01)
            opacity: 1 - t / 24
        }
        Text {
            visible: m.showEffects && m.mood === "alarm"
            text: "!"
            color: m.th.alarm
            font.family: "Hack Nerd Font Mono"
            font.bold: true
            font.pixelSize: Math.max(9, m.height * 0.4)
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: -m.height * 0.12
            opacity: (!m.animated || m.frame % 4 < 2) ? 1 : 0.2
        }
        Text {
            visible: m.showEffects && m.mood === "busy"
            text: "⚡"
            color: m.th.warn
            font.pixelSize: Math.max(8, m.height * 0.3)
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: -m.height * 0.1
            opacity: (!m.animated || m.frame % 6 < 3) ? 1 : 0.35
        }
    }
}
