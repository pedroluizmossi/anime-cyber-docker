// Mascote em pixel art desenhada em Canvas, com aura neon.
// mood: "sleep" | "idle" | "busy" | "alarm" | "happy"     kind: chave em Sprites.js
// hot: superaquecida (vapor subindo e gota de suor), independente do humor
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
    readonly property var spriteColors: spriteDef.colors || ({})   // cores fixas da sprite (ignoram o tema)
    property color fur: spriteColors.fur || th.fur
    property color visor: th.visor
    property int glowLevel: 75          // 0..100
    property bool animated: true
    property bool showEffects: true     // textos flutuantes (zzz, !, ⚡, ♥) e vapor
    property bool hot: false            // temperatura alta: vapor + suor
    property int lookX: 0               // olhar: -1 esquerda, 0 centro, 1 direita (pose estática)
    property bool interactive: false    // true: clique faz carinho (pet) e duplo clique dança
    readonly property bool glow: glowLevel > 0
    signal petted()
    readonly property var spriteDef: Sprites.get(kind)
    readonly property var grid: spriteDef.grid

    implicitWidth: 64
    implicitHeight: 56

    readonly property color accent: mood === "alarm" ? th.alarm
                                  : mood === "sleep" ? th.sleep
                                  : mood === "busy"  ? th.warn
                                  : mood === "happy" ? th.ok
                                  : visor
    readonly property color skin: "#ffe0d0"
    property int frame: 1

    Timer {
        interval: m.mood === "alarm" ? 80 : m.mood === "busy" || m.mood === "happy" ? 120 : m.mood === "sleep" ? 250 : 200
        running: m.visible && m.animated
        repeat: true
        onTriggered: {
            m.frame = (m.frame + 1) % 600
            m.paintIfChanged()
        }
    }

    // ---- reações (carinho e dança): só rodam enquanto ativas ----------------
    property real petPhase: 0           // 0..1 durante o carinho (coração sobe e some)
    property real hop: 0                // pulinho do carinho (px lógicos, negativo = para cima)
    property bool dancing: false
    property real danceHop: 0           // pulinho no ritmo da dança
    property real sway: 0               // -1..1: balanço lateral da dança
    property real noteClock: 0          // 0..1 em loop: fase das notas musicais
    readonly property bool reacting: reactAnim.running

    // carinho: clique na mascote (ou pet() por código)
    function pet() {
        if (animated) {
            reactAnim.restart()
            hopAnim.restart()
        }
        petted()
    }

    // dança: duplo clique (ou dance() por código); ~2,5 s
    function dance() {
        if (!animated) return
        dancing = true
        danceEnd.restart()
    }

    NumberAnimation {
        id: reactAnim
        target: m
        property: "petPhase"
        from: 0; to: 1
        duration: 1200
        onRunningChanged: m.repaintAll()     // olhos fecham/abrem junto com a reação
    }
    SequentialAnimation {
        id: hopAnim                          // dois pulinhos de 15% da altura
        NumberAnimation { target: m; property: "hop"; from: 0; to: -m.height * 0.15; duration: 140; easing.type: Easing.OutQuad }
        NumberAnimation { target: m; property: "hop"; to: 0; duration: 140; easing.type: Easing.InQuad }
        NumberAnimation { target: m; property: "hop"; to: -m.height * 0.15; duration: 140; easing.type: Easing.OutQuad }
        NumberAnimation { target: m; property: "hop"; to: 0; duration: 140; easing.type: Easing.InQuad }
        onRunningChanged: if (!running) m.hop = 0
    }
    Timer {
        id: danceEnd
        interval: 2500
        onTriggered: m.dancing = false
    }
    SequentialAnimation {
        id: swayAnim                         // balanço: um ciclo por compasso (1,2 s)
        running: m.dancing
        loops: Animation.Infinite
        onRunningChanged: if (!running) m.sway = 0
        NumberAnimation { target: m; property: "sway"; to: 1; duration: 300; easing.type: Easing.InOutSine }
        NumberAnimation { target: m; property: "sway"; to: -1; duration: 600; easing.type: Easing.InOutSine }
        NumberAnimation { target: m; property: "sway"; to: 0; duration: 300; easing.type: Easing.InOutSine }
    }
    SequentialAnimation {
        id: danceHopAnim                     // pulinho a cada batida (600 ms)
        running: m.dancing
        loops: Animation.Infinite
        onRunningChanged: if (!running) m.danceHop = 0
        NumberAnimation { target: m; property: "danceHop"; from: 0; to: -m.height * 0.12; duration: 150; easing.type: Easing.OutQuad }
        NumberAnimation { target: m; property: "danceHop"; to: 0; duration: 150; easing.type: Easing.InQuad }
        PauseAnimation { duration: 300 }
    }
    NumberAnimation {
        id: noteAnim
        target: m
        property: "noteClock"
        from: 0; to: 1
        duration: 1600
        loops: Animation.Infinite
        running: m.dancing
        onRunningChanged: if (!running) m.noteClock = 0
    }

    // ---- cores -------------------------------------------------------------
    function eyeColor() {
        if (reacting) return null                                              // carinho: olhos felizes fechados
        switch (mood) {
        case "sleep": return null                                              // fechado
        case "alarm": return frame % 4 < 2 ? th.alarm : Qt.lighter(th.alarm, 1.6)
        case "busy":  return frame % 6 < 3 ? th.warn : Qt.darker(th.warn, 1.35)
        case "happy": return (animated && frame % 10 >= 7) ? null : Qt.lighter(th.ok, 1.25)   // piscadinhas rápidas
        default:      return (animated && frame % 25 === 0) ? null : Qt.lighter(th.outline, 2.2) // piscada
        }
    }

    function ledColor() {
        switch (mood) {
        case "sleep": return Qt.darker(visor, 2.8)
        case "alarm": return frame % 4 < 2 ? th.alarm : th.outline
        case "busy":  return frame % 4 < 2 ? th.warn : Qt.darker(th.warn, 1.8)
        case "happy": return frame % 4 < 2 ? th.ok : visor
        default:      return visor
        }
    }

    function glitchOn() { return mood === "alarm" && animated && frame % 6 < 2 }

    function cellColor(ch, x, y) {
        const dim = mood === "sleep"
        switch (ch) {
        case "K": return th.outline
        case "M": return spriteColors.ear || th.ear
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
            if (lookX !== 0) {   // olhar para o lado: a cor vem da célula de origem (x - lookX), se também for olho
                const sx = x - lookX
                const src = (sx >= 0 && sx < grid[y].length) ? grid[y][sx] : "."
                if (src !== "E" && src !== "W") return cellColor(spriteDef.eyeBg, x, y)
                return src === "W" ? "#ffffff" : e
            }
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
        return (e === null ? "-" : e.toString()) + "|" + glitchOn() + "|" + ledColor().toString() + "|" + lookX
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
    onAnimatedChanged: {
        if (!animated) {        // reduzir movimento: encerra qualquer reação em curso
            reactAnim.stop()
            hopAnim.stop()
            danceEnd.stop()
            dancing = false
        }
        repaintAll()
    }
    onLookXChanged: repaintAll()
    Component.onCompleted: repaintAll()   // garante o 1º desenho mesmo sem animação

    Item {
        id: wrapper
        anchors.fill: parent
        transform: Translate {
            // alarme: tremor lateral; dança: balanço de ±2 pixels da sprite
            x: m.snap((m.animated && m.mood === "alarm" ? ((m.frame % 2) ? 1 : -1) * Math.max(1, m.px) : 0)
                      + m.sway * 2 * m.px)
            // humor + pulinho do carinho + pulinho da dança
            y: m.snap((!m.animated ? 0 : m.mood === "busy"  ? -Math.abs(Math.sin(m.frame * 0.73)) * m.height * 0.09
                    : m.mood === "happy" ? -Math.abs(Math.sin(m.frame * 0.45)) * m.height * 0.12
                    : m.mood === "sleep" ? Math.sin(m.frame * 0.2) * m.height * 0.025
                    : m.mood === "idle"  ? Math.sin(m.frame * 0.107) * m.height * 0.03
                    : 0) + m.hop + m.danceHop)
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
        // comemoração: coração subindo
        Text {
            visible: m.showEffects && m.mood === "happy"
            readonly property int t: m.frame % 20
            text: "♥"
            color: m.th.blush
            font.pixelSize: Math.max(8, Math.round(m.height * 0.3))
            x: Math.round(m.width * 0.8)
            y: Math.round(m.height * 0.1 - t * m.height * 0.015)
            opacity: 1 - t / 20
        }
        // carinho: coração que pula sobre a cabeça e some (separado do coração de "happy")
        Text {
            visible: m.showEffects && m.reacting
            text: "♥"
            color: m.th.blush
            font.pixelSize: Math.max(9, Math.round(m.height * 0.3))
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(m.height * 0.02 - m.petPhase * m.height * 0.3)
            scale: 0.5 + 0.5 * Math.min(1, m.petPhase * 4)
            opacity: 1 - m.petPhase
        }
        // dança: notas "♪" e "♫" alternando cores do visor e do pelo, subindo em sequência
        Repeater {
            model: 4
            Text {
                readonly property real p: (m.noteClock + index * 0.25) % 1
                visible: m.showEffects && m.dancing
                text: index % 2 === 0 ? "♪" : "♫"
                color: index % 2 === 0 ? m.visor : m.fur
                font.pixelSize: Math.max(8, Math.round(m.height * 0.3))
                x: Math.round(m.width * (0.42 + 0.13 * index))
                y: Math.round(m.height * 0.1 - p * m.height * 0.5)
                opacity: Math.sin(p * Math.PI)
            }
        }
        // superaquecida: vapor pulsando no canto + gota de suor escorrendo
        Text {
            visible: m.hot && m.showEffects
            readonly property int t: m.animated ? m.frame % 16 : 0
            text: "♨"
            color: Qt.lighter(m.th.warn, 1.3)
            font.pixelSize: Math.max(9, Math.round(m.height * 0.34))
            anchors.left: parent.left
            anchors.leftMargin: -m.width * 0.08
            y: Math.round(-m.height * 0.12 - t * m.height * 0.01)
            opacity: 1 - t / 24
        }
        Rectangle {
            visible: m.hot && m.showEffects
            readonly property int t: m.animated ? m.frame % 12 : 4
            width: Math.max(1, m.px); height: Math.max(2, m.px * 2)
            radius: width / 2
            color: "#7fd8ff"
            x: Math.round(m.ox + m.px * 14.5)
            y: Math.round(m.oy + m.px * (4 + t * 0.5))
            opacity: 1 - t / 12
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

    // interação só quando pedida: sem `interactive` não existe MouseArea, e o cursor
    // continua passando para o MouseArea do painel (CompactView)
    Loader {
        anchors.fill: parent
        active: m.interactive
        sourceComponent: MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: m.pet()
            onDoubleClicked: m.dance()
        }
    }
}
