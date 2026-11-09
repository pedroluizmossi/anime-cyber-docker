// Popup estilo HUD cyberpunk: guarda o estado do HUD e monta as partes.
// Cada parte recebe `hud: full` e lê o estado daqui (ver HudHeader, StatsBar, SearchBar,
// ContainerList, VitalsColumn, HudFooter, SpeechBubble, LogPeek, BootCurtain, HudBackground).
import QtQuick
import QtQuick.Layouts
import "Themes.js" as Themes
import "Logic.js" as Logic

Item {
    id: full

    property string mood: "idle"
    property var containers: []
    property var stats: ({})
    property var history: ({})
    property var vram: ({})
    property real gpuMemUsed: 0
    property real gpuMemTotal: 0
    property real hostCpu: 0
    property real hostMemUsed: 0
    property real hostMemTotal: 0
    property var hostHistory: ({ cpu: [], mem: [], gpu: [], vram: [], net: [] })
    // parte do Docker (soma dos containers, de docker stats)
    readonly property real dockerCpu: Object.values(stats).reduce((a, s) => a + s.cpu, 0)
    readonly property real dockerMem: Object.values(stats).reduce((a, s) => a + (s.memBytes || 0), 0)
    property bool groupStacks: false
    property bool hideStopped: false
    property bool showGraphs: true
    property bool showVitals: true
    property string cpuKind: "chip"
    property string ramKind: "sapo"
    property string gpuKind: "nvidia"
    property string gpuVendor: ""
    property string diskKind: "disquete"
    property bool showTemps: true
    property int tempHot: 80
    property int tempCritical: 90
    property real cpuTemp: 0
    property real gpuTemp: 0
    property real netRx: 0
    property real netTx: 0
    property var disk: ({ total: 0, used: 0, docker: 0, reclaimable: 0, parts: {} })
    property string pruneResult: ""
    property var restarts: ({})
    property var restartBumpAt: ({})
    property var logsPeek: ({})
    property var lastEvent: null
    property string dockerVersion: ""
    property string themeKey: "neon"

    // ---- rodapé: segundos desde a última leitura (relógio só com o popup aberto) ----
    property date now: new Date()
    Timer { interval: 1000; running: full.active; repeat: true; triggeredOnStart: true; onTriggered: full.now = new Date() }
    readonly property int syncAge: Math.max(0, Math.round((now.getTime() - lastUpdate.getTime()) / 1000))

    // ---- abertura: varredura de CRT, título digitado e cartões entrando em sequência ----
    property real bootT: 1                  // 0..1 (1 = abertura concluída)
    // só na primeira abertura da sessão; depois o popup já aparece pronto
    property bool booted: false
    onActiveChanged: {
        if (!active || booted) return
        booted = true
        if (animated) bootAnim.restart()
    }
    NumberAnimation { id: bootAnim; target: full; property: "bootT"; from: 0; to: 1; duration: 650; easing.type: Easing.Linear }
    // entrada do i-ésimo cartão (0..1), escalonada depois da varredura começar
    function cardIn(i) { return Math.max(0, Math.min(1, (bootT - 0.25 - i * 0.12) / 0.3)) }
    // coluna de sinais vitais só cabe em popups largos; estreito volta aos quadros do topo
    readonly property bool sideBySide: showVitals && width >= 640
    readonly property real hostMemPct: hostMemTotal > 0 ? hostMemUsed / hostMemTotal * 100 : 0
    readonly property real gpuMemPct: gpuMemTotal > 0 ? gpuMemUsed / gpuMemTotal * 100 : 0
    readonly property real dockerVram: Object.values(vram).reduce((a, v) => a + v, 0)
    function topBy(obj, f) {
        let best = "", bv = 0
        for (const k of Object.keys(obj)) { const v = f(obj[k]); if (v > bv) { bv = v; best = k } }
        return best ? { name: best, v: bv } : null
    }
    readonly property var topCpu: topBy(stats, s => s.cpu)
    readonly property var topVram: topBy(vram, v => v)
    property var favorites: []
    property int running: 0
    property int problems: 0
    property real gpuUtil: 0
    property bool dockerOk: true
    property string errorText: ""
    property date lastUpdate: new Date()
    property var theme: Themes.get("neon")
    property string kind: "neko"
    property int glowLevel: 75
    property bool animated: true
    property bool active: true          // popup aberto; fechado = animações pausadas
    readonly property bool animating: animated && active
    signal action(string verb, string name)
    signal stackAction(string verb, string project)
    signal toggleFavorite(string name)
    signal setOption(string key, var value)
    signal refresh()
    signal peekLogs(string name)
    signal prune()

    // prévia de logs (hover no botão ≡): container e botão de referência
    property string peekName: ""
    property Item peekAnchor: null

    // balão de fala da mascote: aparece por alguns segundos a cada evento
    property bool bubbleOn: false
    onLastEventChanged: if (lastEvent && Date.now() - lastEvent.at < 15000) { bubbleOn = true; bubbleTimer.restart() }
    Timer { id: bubbleTimer; interval: 8000; onTriggered: full.bubbleOn = false }

    // estado só da sessão do popup
    property string search: ""
    property var collapsed: ({})

    // linhas do HUD: só dependem dos containers e dos filtros (stats/histórico entram por linha)
    readonly property var rows: Logic.buildRows(containers, {
        search: search,
        hideStopped: hideStopped,
        group: groupStacks,
        favorites: Array.from(favorites || []),
        collapsed: collapsed
    })
    readonly property int hiddenCount: containers.length - rows.filter(r => r.type === "container").length

    function toggleCollapsed(project) {
        const c = Object.assign({}, collapsed)
        c[project] = !c[project]
        collapsed = c
    }

    Layout.preferredWidth: showVitals ? 780 : 500
    Layout.preferredHeight: showVitals ? 680 : 620
    Layout.minimumWidth: 420
    Layout.minimumHeight: 320

    readonly property color neon: mood === "alarm" ? theme.alarm : mood === "sleep" ? theme.sleep : mood === "busy" ? theme.warn : mood === "happy" ? theme.ok : theme.visor

    HudBackground {
        anchors.fill: parent
        hud: full
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        HudHeader {
            hud: full
            Layout.fillWidth: true
        }

        // no modo estreito os contadores (com CPU/RAM/GPU) ficam numa linha própria
        StatsBar {
            hud: full
            visible: !full.sideBySide
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                SearchBar {
                    hud: full
                    Layout.fillWidth: true
                }

                // erro do docker
                Text {
                    visible: !full.dockerOk
                    Layout.fillWidth: true
                    text: "⚠ " + full.errorText
                    color: full.theme.alarm
                    wrapMode: Text.Wrap
                    font.family: "Hack Nerd Font Mono"; font.pixelSize: 11
                }

                ContainerList {
                    hud: full
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }

            VitalsColumn {
                hud: full
                visible: full.sideBySide
                Layout.preferredWidth: 250
                Layout.maximumWidth: 250
                Layout.fillHeight: true
            }
        }

        HudFooter {
            hud: full
            Layout.fillWidth: true
        }
    }

    SpeechBubble {
        hud: full
        z: 50
        x: 12 + 84 + 8
        y: 14
        maxW: full.width - x - 12 - (full.sideBySide ? 262 : 0)
    }

    LogPeek {
        hud: full
        z: 60
    }

    BootCurtain {
        hud: full
        z: 90
    }
}
