// Neko cyborg em pixel art desenhada em Canvas, com aura neon.
// mood: "sleep" | "idle" | "busy" | "alarm"
import QtQuick
import QtQuick.Window
import QtQuick.Effects
import "Themes.js" as Themes

Item {
    id: m

    property string mood: "idle"
    property var theme: Themes.get("neon")
    property color fur: theme.fur
    property color visor: theme.visor
    property int glowLevel: 75          // 0..100
    property bool animated: true
    readonly property bool glow: glowLevel > 0
    property bool showEffects: true   // textos flutuantes (zzz, !, ⚡)

    implicitWidth: 64
    implicitHeight: 64

    readonly property color accent: mood === "alarm" ? theme.alarm
                                  : mood === "sleep" ? theme.sleep
                                  : mood === "busy"  ? theme.warn
                                  : visor
    property int frame: 10

    // 16 x 14. K contorno, P pelo, H reflexo, M orelha, C visor, E olho, W brilho do olho, B blush, T boca
    readonly property var grid: [
        ".K............K.",
        "KMK..........KMK",
        "KMPK..KKKK..KPMK",
        "KPPPKKPPPPKKPPPK",
        "KPPPPPPPPPPPPPPK",
        "KPHPPPPPPPPPPHPK",
        "KCCCCCCCCCCCCCCK",
        "KCEEWCCCCCCEEWCK",
        "KCEEECCCCCCEEECK",
        "KCCCCCCCCCCCCCCK",
        "KPBBPPPPPPPPBBPK",
        "KPPPPPPTTPPPPPPK",
        ".KPPPPPPPPPPPPK.",
        "..KKKKKKKKKKKK.."
    ]

    Timer {
        interval: m.mood === "alarm" ? 70 : m.mood === "busy" ? 90 : 150
        running: m.visible && m.animated
        repeat: true
        onTriggered: {
            m.frame = (m.frame + 1) % 240
            m.repaint()
        }
    }

    function eyeColor() {
        switch (mood) {
        case "sleep": return null                                   // fechado
        case "alarm": return frame % 4 < 2 ? theme.alarm : Qt.lighter(theme.alarm, 1.6)
        case "busy":  return frame % 6 < 3 ? theme.warn : Qt.darker(theme.warn, 1.35)
        default:      return (frame % 30 < 2) ? null : Qt.lighter(theme.outline, 2.2)   // piscada
        }
    }

    function cellColor(ch, x, y) {
        const dim = mood === "sleep"
        const closed = eyeColor() === null
        switch (ch) {
        case "K": return theme.outline
        case "M": return theme.ear
        case "H": return dim ? fur : Qt.lighter(fur, 1.45)
        case "B": return mood === "alarm" ? fur : theme.blush
        case "P": return y >= 11 ? Qt.darker(fur, 1.35) : (dim ? Qt.darker(fur, 1.2) : fur)
        case "T": return mood === "alarm" ? theme.alarm : theme.outline
        case "C": return dim ? Qt.darker(visor, 2.8) : (mood === "alarm" ? Qt.darker(theme.alarm, 1.6) : visor)
        case "E":
        case "W":
            if (closed) // olho fechado: só um traço na linha de baixo
                return y === 8 ? theme.outline : cellColor("C", x, y)
            if (ch === "W") return "#ffffff"
            return eyeColor()
        }
        return null
    }

    // Geometria travada em pixels inteiros do dispositivo: sem bordas borradas.
    readonly property real dpr: Screen.devicePixelRatio || 1
    readonly property real px: Math.max(1, Math.floor(Math.min(width / 16, height / 14) * dpr)) / dpr
    readonly property real ox: Math.round((width - 16 * px) / 2 * dpr) / dpr
    readonly property real oy: Math.round((height - 14 * px) / 2 * dpr) / dpr
    function snap(v) { return Math.round(v * dpr) / dpr }

    function paintSprite(ctx) {
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
        if (mood === "alarm" && frame % 6 < 2) {   // glitch RGB
            drawPass(-1, visor.toString(), 0.45)
            drawPass(1, fur.toString(), 0.45)
        }
        drawPass(0, null, 1.0)
    }

    function repaint() {
        sprite.requestPaint()
        if (glow) glowCanvas.requestPaint()
    }
    onWidthChanged: repaint()
    onHeightChanged: repaint()
    onMoodChanged: repaint()
    onThemeChanged: repaint()
    onGlowLevelChanged: repaint()

    Item {
        id: wrapper
        anchors.fill: parent
        transform: Translate {
            x: !m.animated ? 0 : m.snap(m.mood === "alarm" ? ((m.frame % 2) ? 1 : -1) * Math.max(1, m.px) : 0)
            y: !m.animated ? 0 : m.snap(m.mood === "busy"  ? -Math.abs(Math.sin(m.frame * 0.55)) * m.height * 0.09
                    : m.mood === "sleep" ? Math.sin(m.frame * 0.12) * m.height * 0.025
                    : m.mood === "idle"  ? Math.sin(m.frame * 0.08) * m.height * 0.03
                    : 0)
        }

        // fonte do glow (invisível), só alimenta o MultiEffect
        Item {
            id: glowSource
            anchors.fill: parent
            visible: false
            Canvas {
                id: glowCanvas
                anchors.fill: parent
                antialiasing: false
                renderStrategy: Canvas.Cooperative
                onPaint: m.paintSprite(getContext("2d"))
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
            shadowOpacity: (m.glowLevel / 100) * (m.height < 48 ? 1.0 : 1.3) * (m.mood === "alarm" ? (m.frame % 4 < 2 ? 1.0 : 0.5) : 0.85)
        }

        // sprite nítida, desenhada por cima do glow sem passar pelo filtro
        Canvas {
            id: sprite
            anchors.fill: parent
            antialiasing: false
            smooth: false
            renderStrategy: Canvas.Cooperative
            onPaint: m.paintSprite(getContext("2d"))
        }

        // efeitos flutuantes
        Text {
            visible: m.showEffects && m.mood === "sleep"
            text: "z"
            color: Qt.lighter(m.theme.sleep, 1.4)
            font.family: "Hack Nerd Font Mono"
            font.bold: true
            font.pixelSize: Math.max(8, m.height * 0.28 * (0.6 + (m.frame % 40) / 60))
            x: m.width * 0.78 + (m.frame % 40) * m.width * 0.004
            y: m.height * 0.05 - (m.frame % 40) * m.height * 0.006
            opacity: 1 - (m.frame % 40) / 40
        }
        Text {
            visible: m.showEffects && m.mood === "alarm"
            text: "!"
            color: m.theme.alarm
            font.family: "Hack Nerd Font Mono"
            font.bold: true
            font.pixelSize: Math.max(9, m.height * 0.4)
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: -m.height * 0.12
            opacity: m.frame % 4 < 2 ? 1 : 0.2
        }
        Text {
            visible: m.showEffects && m.mood === "busy"
            text: "⚡"
            color: m.theme.warn
            font.pixelSize: Math.max(8, m.height * 0.3)
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: -m.height * 0.1
            opacity: m.frame % 6 < 3 ? 1 : 0.35
        }
    }
}
