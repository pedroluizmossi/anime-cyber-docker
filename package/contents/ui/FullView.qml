// Popup estilo HUD cyberpunk.
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
    // pisca o ponto do rodapé a cada leitura nova
    onLastUpdateChanged: if (animating) syncBlink.restart()

    // ---- abertura: varredura de CRT, título digitado e cartões entrando em sequência ----
    property real bootT: 1                  // 0..1 (1 = abertura concluída)
    onActiveChanged: if (active && animated) bootAnim.restart()
    NumberAnimation { id: bootAnim; target: full; property: "bootT"; from: 0; to: 1; duration: 650; easing.type: Easing.Linear }
    // entrada do i-ésimo cartão (0..1), escalonada depois da varredura começar
    // cartões compactos quando os quatro não cabem na altura disponível (~570 px no modo normal)
    readonly property bool compactVitals: vflick.height > 0 && vflick.height < 570
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
    readonly property color bubbleColor: !lastEvent ? theme.visor
        : (lastEvent.kind === "recovered" || lastEvent.kind === "docker-up") ? theme.ok
        : lastEvent.kind === "restart-bump" ? theme.warn : theme.alarm

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
    readonly property var moodText: ({
        sleep: ["スリープ", "nenhum container ativo... zzz"],
        idle:  ["システム正常", "todos os sistemas online"],
        busy:  ["フル稼働", "carga alta na rede neural"],
        happy: ["やったー!", "tudo de volta ao normal"],
        alarm: ["警告", dockerOk ? `${problems} container(s) com problema` : "docker offline"]
    })

    // fundo
    Rectangle {
        anchors.fill: parent
        radius: 4
        gradient: Gradient {
            GradientStop { position: 0.0; color: full.theme.bg0 }
            GradientStop { position: 1.0; color: full.theme.bg1 }
        }
        border.width: 1
        border.color: Qt.rgba(full.neon.r, full.neon.g, full.neon.b, 0.5)
    }
    // fundo animado do tema (chuva matrix, sol synthwave, estrelas…)
    ThemeBackdrop {
        anchors.fill: parent
        anchors.margins: 1
        themeKey: full.themeKey
        theme: full.theme
        animated: full.animating
        opacity: 0.22
    }
    // scanlines
    Canvas {
        anchors.fill: parent
        opacity: 0.07
        onPaint: {
            const ctx = getContext("2d")
            ctx.fillStyle = "#ffffff"
            for (let y = 0; y < height; y += 3) ctx.fillRect(0, y, width, 1)
        }
    }
    // linha de varredura descendo
    Rectangle {
        width: parent.width; height: 40
        opacity: 0.06
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: full.neon }
        }
        NumberAnimation on y { running: full.animating; from: -40; to: full.height; duration: 4000; loops: Animation.Infinite }
    }

    // contadores RUN/STOP/ERR (+ CPU/RAM/GPU quando não há coluna de vitais)
    Component {
        id: statsBar
            RowLayout {
                spacing: 6
                Repeater {
                    model: [
                        { k: "RUN", v: full.running, c: full.theme.visor, w: 1 },
                        { k: "STOP", v: full.containers.length - full.running, c: full.theme.sub, w: 1 },
                        { k: "ERR", v: full.problems, c: full.problems ? full.theme.alarm : full.theme.muted, w: 1, urgent: full.problems > 0 },
                    ].concat(full.sideBySide ? [] : [
                        { k: "CPU", v: Math.round(full.hostCpu) + "%", w: 1.25,
                          c: full.hostCpu >= 85 ? full.theme.alarm : full.hostCpu >= 60 ? full.theme.warn : full.theme.ok,
                          tip: `computador ${full.hostCpu.toFixed(1)}%  ·  docker ${full.dockerCpu.toFixed(1)}% (100% = 1 núcleo)` },
                        { k: "RAM " + Logic.formatBytes(full.hostMemUsed) + "/" + Logic.formatBytes(full.hostMemTotal), w: 1.6,
                          v: full.hostMemTotal > 0 ? Math.round(full.hostMemUsed / full.hostMemTotal * 100) + "%" : "–",
                          c: full.hostMemTotal && full.hostMemUsed / full.hostMemTotal >= 0.9 ? full.theme.alarm
                           : full.hostMemTotal && full.hostMemUsed / full.hostMemTotal >= 0.75 ? full.theme.warn : full.theme.ok,
                          tip: `computador ${Logic.formatBytes(full.hostMemUsed)} de ${Logic.formatBytes(full.hostMemTotal)}  ·  docker ${Logic.formatBytes(full.dockerMem)}` },
                        { k: full.gpuMemTotal > 0 ? "GPU " + Logic.formatMiB(full.gpuMemUsed) + "/" + Logic.formatMiB(full.gpuMemTotal) : "GPU", w: 1.6,
                          v: Math.round(full.gpuUtil) + "%", c: full.mood === "busy" ? full.theme.warn : full.theme.ok,
                          tip: full.gpuMemTotal > 0 ? `uso ${Math.round(full.gpuUtil)}%  ·  VRAM ${Logic.formatMiB(full.gpuMemUsed)} de ${Logic.formatMiB(full.gpuMemTotal)}` : "" }
                    ])
                    delegate: CounterTile {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 60 * modelData.w     // quadros com texto maior ganham mais espaço
                        label: modelData.k
                        value: modelData.v
                        accent: modelData.c
                        theme: full.theme
                        tip: modelData.tip || ""
                        animated: full.animating
                        pulse: !!modelData.urgent
                    }
                }
            }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // cabeçalho
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Mascot {
                mood: full.mood
                kind: full.kind
                theme: full.theme
                glowLevel: full.glowLevel
                animated: full.animating
                interactive: true            // clique = carinho, clique duplo = dancinha
                Layout.preferredWidth: 84
                Layout.preferredHeight: 74
            }
            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Item {
                    // some enquanto a mascote fala (o balão ocupa este lugar)
                    opacity: full.bubbleOn ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    implicitWidth: title.implicitWidth
                    implicitHeight: title.implicitHeight
                    // aberração cromática do título
                    Text { x: glitch.offset; text: title.text; font: title.font; color: full.theme.visor; opacity: 0.7 }
                    Text { x: -glitch.offset; text: title.text; font: title.font; color: full.theme.fur; opacity: 0.7 }
                    Text { id: title; text: "CYBERDOCK".slice(0, Math.ceil(Math.min(1, full.bootT / 0.6) * 9)) + (full.bootT < 0.6 ? "▌" : ""); color: "#ffffff"; font.family: "Hack Nerd Font Mono"; font.bold: true; font.pixelSize: 24; font.letterSpacing: 3 }
                    QtObject { id: glitch; property real offset: 1 }
                    SequentialAnimation {
                        running: full.animating; loops: Animation.Infinite
                        PauseAnimation { duration: full.mood === "alarm" ? 300 : 2600 }
                        NumberAnimation { target: glitch; property: "offset"; to: 4; duration: 60 }
                        NumberAnimation { target: glitch; property: "offset"; to: -3; duration: 60 }
                        NumberAnimation { target: glitch; property: "offset"; to: 1; duration: 80 }
                    }
                }
                Text {
                    text: full.moodText[full.mood][0]
                    color: full.neon
                    font.family: "Noto Sans Mono CJK JP"; font.pixelSize: 13; font.bold: true
                }
                Text {
                    text: "> " + full.moodText[full.mood][1] + (cursor.visible ? "_" : " ")
                    color: Qt.lighter(full.theme.sub, 1.3)
                    font.family: "Hack Nerd Font Mono"; font.pixelSize: 11
                    Timer { id: cursor; property bool visible: true; interval: 500; running: full.active; repeat: true; onTriggered: visible = !visible }
                }
            }
            Item { Layout.fillWidth: true; visible: full.sideBySide }
            Loader {
                active: full.sideBySide
                visible: active
                sourceComponent: statsBar
                Layout.preferredWidth: 250
                Layout.alignment: Qt.AlignVCenter
            }
        }

        Loader {
            active: !full.sideBySide
            visible: active
            sourceComponent: statsBar
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

                // busca + filtros
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        height: 26; radius: 3
                        color: Qt.rgba(1, 1, 1, 0.04)
                        border.width: 1
                        border.color: searchInput.activeFocus ? full.theme.visor : Qt.rgba(full.theme.visor.r, full.theme.visor.g, full.theme.visor.b, 0.3)
                        Text {
                            id: searchIcon
                            anchors.left: parent.left; anchors.leftMargin: 7
                            anchors.verticalCenter: parent.verticalCenter
                            text: "⌕"
                            color: full.theme.sub
                            font.pixelSize: 14
                        }
                        TextInput {
                            id: searchInput
                            anchors.left: searchIcon.right; anchors.leftMargin: 6
                            anchors.right: clearSearch.left; anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            color: full.theme.text
                            selectionColor: full.theme.fur
                            selectedTextColor: "#ffffff"
                            font.family: "Hack Nerd Font Mono"; font.pixelSize: 11
                            clip: true
                            onTextChanged: full.search = text
                            Keys.onEscapePressed: text = ""
                            Text {
                                visible: !searchInput.text && !searchInput.activeFocus
                                text: "filtrar por nome, imagem ou stack…"
                                color: full.theme.muted
                                font: searchInput.font
                            }
                        }
                        Text {
                            id: clearSearch
                            visible: searchInput.text.length > 0
                            anchors.right: parent.right; anchors.rightMargin: 7
                            anchors.verticalCenter: parent.verticalCenter
                            text: "✕"
                            color: clearArea.containsMouse ? full.theme.fur : full.theme.sub
                            font.pixelSize: 11
                            MouseArea { id: clearArea; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: searchInput.text = "" }
                        }
                    }

                    Repeater {
                        model: [
                            { key: "hideStopped", on: full.hideStopped, g: "◌", t: "ocultar parados" },
                            { key: "groupStacks", on: full.groupStacks, g: "▤", t: "agrupar por stack" },
                            { key: "showGraphs", on: full.showGraphs, g: "∿", t: "gráficos de cpu/mem" },
                            { key: "showVitals", on: full.showVitals, g: "▥", t: "coluna de sinais vitais" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            width: 28; height: 26; radius: 3
                            color: modelData.on ? Qt.rgba(full.theme.visor.r, full.theme.visor.g, full.theme.visor.b, 0.22)
                                                : (chipArea.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                            border.width: 1
                            border.color: modelData.on ? full.theme.visor : Qt.rgba(full.theme.visor.r, full.theme.visor.g, full.theme.visor.b, 0.3)
                            Text {
                                anchors.centerIn: parent
                                text: modelData.g
                                color: modelData.on ? full.theme.visor : full.theme.sub
                                font.pixelSize: 14; font.bold: true
                            }
                            MouseArea {
                                id: chipArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: full.setOption(modelData.key, !modelData.on)
                            }
                            ToolTipLite { text: modelData.t; shown: chipArea.containsMouse; accent: full.theme.visor; background: full.theme.bg0 }
                        }
                    }
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

                // lista
                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: full.rows
                    boundsBehavior: Flickable.StopAtBounds

                    // horizonte da cidade atrás da lista: janelas acesas seguem a CPU, chove no alarme
                    Skyline {
                        parent: list
                        z: -1
                        anchors.fill: parent
                        theme: full.theme
                        mood: full.mood
                        load: full.hostCpu
                        animated: full.animating
                    }

                    // a lista é reconstruída quando containers/filtros mudam: preserva a rolagem
                    property real keptY: 0
                    onMovementEnded: keptY = contentY
                    onModelChanged: Qt.callLater(() => contentY = Math.max(0, Math.min(keptY, contentHeight - height)))

                    delegate: Item {
                        id: d
                        required property var modelData
                        width: list.width
                        height: ld.item ? ld.item.implicitHeight : 0
                        Loader {
                            id: ld
                            width: parent.width
                            sourceComponent: d.modelData.type === "header" ? headerComp : rowComp
                        }
                        Component {
                            id: headerComp
                            StackHeader {
                                width: d.width
                                group: d.modelData
                                theme: full.theme
                                onToggled: full.toggleCollapsed(d.modelData.project)
                                onStackAction: verb => full.stackAction(verb, d.modelData.project)
                            }
                        }
                        Component {
                            id: rowComp
                            ContainerRow {
                                width: d.width
                                container: d.modelData.c
                                favorite: d.modelData.favorite
                                theme: full.theme
                                showGraphs: full.showGraphs
                                stat: full.stats[d.modelData.c.name] || null
                                hist: full.history[d.modelData.c.name] || null
                                vramMiB: full.vram[d.modelData.c.name] || 0
                                restartCount: full.restarts[d.modelData.c.name] || 0
                                // lastUpdate muda a cada leitura: o destaque some sozinho depois de 10 min
                                restartBumped: full.lastUpdate.getTime() - (full.restartBumpAt[d.modelData.c.name] || 0) < 600000
                                onPeekLogs: (on, anchor) => {
                                    if (on) { full.peekName = d.modelData.c.name; full.peekAnchor = anchor; full.peekLogs(d.modelData.c.name) }
                                    else if (full.peekName === d.modelData.c.name) full.peekName = ""
                                }
                                onAction: verb => full.action(verb, d.modelData.c.name)
                                onToggleFavorite: full.toggleFavorite(d.modelData.c.name)
                                onOpenUrl: url => Qt.openUrlExternally(url)
                            }
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: list.count === 0 && full.dockerOk
                        text: full.containers.length ? "// nada corresponde ao filtro" : "// nenhum container"
                        color: full.theme.muted
                        font.family: "Hack Nerd Font Mono"
                    }
                }
            }

            // coluna de sinais vitais: uma mascote por recurso do computador (rola se não couber)
            ColumnLayout {
                visible: full.sideBySide
                Layout.preferredWidth: 250
                Layout.maximumWidth: 250
                Layout.fillHeight: true
                spacing: 8

                Text {
                    text: "// VITALS  バイタル"
                    color: full.theme.sub
                    font.family: "Hack Nerd Font Mono"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1
                    Layout.preferredHeight: 26
                    verticalAlignment: Text.AlignVCenter
                }
                Flickable {
                    id: vflick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: vcol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    // indicador de rolagem (só aparece quando os cartões não cabem)
                    Rectangle {
                        parent: vflick
                        visible: vflick.contentHeight > vflick.height
                        anchors.right: parent.right
                        width: 2; radius: 1
                        y: vflick.visibleArea.yPosition * vflick.height
                        height: vflick.visibleArea.heightRatio * vflick.height
                        color: full.theme.visor
                        opacity: 0.6
                        z: 5
                    }
                    ColumnLayout {
                        id: vcol
                        width: vflick.width
                        spacing: 8
                        VitalCard {
                            Layout.fillWidth: true
                            opacity: full.cardIn(0)
                            transform: Translate { x: (1 - full.cardIn(0)) * 24 }
                            compact: full.compactVitals
                            // no alarme (ou quando a principal fala) todas olham para ela, à esquerda
                            lookX: full.mood === "alarm" || full.bubbleOn ? -1 : 0
                            label: "CPU"; kind: full.cpuKind
                            value: full.hostCpu
                            warnAt: 60; alarmAt: 85
                            bars: [{ k: "uso", v: full.hostCpu }]
                            series: full.hostHistory.cpu
                            temp: full.showTemps ? full.cpuTemp : 0
                            tempHot: full.tempHot; tempCritical: full.tempCritical
                            detail: `docker ${full.dockerCpu.toFixed(1)}%` + (full.topCpu ? `  ·  ▲ ${full.topCpu.name}` : "")
                            tip: `computador ${full.hostCpu.toFixed(1)}%  ·  docker ${full.dockerCpu.toFixed(1)}% (100% = 1 núcleo)`
                                 + (full.topCpu ? `\nmais pesado: ${full.topCpu.name} ${full.topCpu.v.toFixed(1)}%` : "")
                            theme: full.theme; glowLevel: full.glowLevel; animated: full.animating
                        }
                        VitalCard {
                            Layout.fillWidth: true
                            opacity: full.cardIn(1)
                            transform: Translate { x: (1 - full.cardIn(1)) * 24 }
                            compact: full.compactVitals
                            // no alarme (ou quando a principal fala) todas olham para ela, à esquerda
                            lookX: full.mood === "alarm" || full.bubbleOn ? -1 : 0
                            label: "RAM"; kind: full.ramKind
                            value: full.hostMemPct
                            available: full.hostMemTotal > 0
                            warnAt: 75; alarmAt: 90
                            bars: [{ k: "mem", v: full.hostMemPct, part: full.hostMemTotal > 0 ? full.dockerMem / full.hostMemTotal * 100 : 0 }]
                            series: full.hostHistory.mem
                            detail: `${Logic.formatBytes(full.hostMemUsed)} / ${Logic.formatBytes(full.hostMemTotal)}  ·  docker ${Logic.formatBytes(full.dockerMem)}`
                            tip: "barra: parte do Docker em destaque, o resto é do computador"
                            theme: full.theme; glowLevel: full.glowLevel; animated: full.animating
                        }
                        VitalCard {
                            Layout.fillWidth: true
                            opacity: full.cardIn(2)
                            transform: Translate { x: (1 - full.cardIn(2)) * 24 }
                            compact: full.compactVitals
                            // no alarme (ou quando a principal fala) todas olham para ela, à esquerda
                            lookX: full.mood === "alarm" || full.bubbleOn ? -1 : 0
                            label: full.gpuVendor ? "GPU " + full.gpuVendor.toUpperCase() : "GPU"; kind: full.gpuKind
                            value: full.gpuUtil
                            available: full.gpuMemTotal > 0
                            warnAt: 40; alarmAt: 90
                            bars: [{ k: "core", v: full.gpuUtil },
                                   { k: "vram", v: full.gpuMemPct, part: full.gpuMemTotal > 0 ? full.dockerVram / full.gpuMemTotal * 100 : 0 }]
                            series: full.hostHistory.gpu
                            temp: full.showTemps ? full.gpuTemp : 0
                            tempHot: full.tempHot; tempCritical: full.tempCritical
                            detail: full.gpuMemTotal > 0
                                    ? `VRAM ${Logic.formatMiB(full.gpuMemUsed)} / ${Logic.formatMiB(full.gpuMemTotal)}` + (full.topVram ? `  ·  ▲ ${full.topVram.name}` : "")
                                    : "nenhuma GPU NVIDIA/AMD"
                            tip: full.gpuMemTotal > 0
                                 ? `uso ${Math.round(full.gpuUtil)}%  ·  VRAM ${Logic.formatMiB(full.gpuMemUsed)} de ${Logic.formatMiB(full.gpuMemTotal)}  ·  docker ${Logic.formatMiB(full.dockerVram)}`
                                 : "sem nvidia-smi nem placa amdgpu"
                            theme: full.theme; glowLevel: full.glowLevel; animated: full.animating
                        }
                        VitalCard {
                            id: diskCard
                            Layout.fillWidth: true
                            opacity: full.cardIn(3)
                            transform: Translate { x: (1 - full.cardIn(3)) * 24 }
                            compact: full.compactVitals
                            // no alarme (ou quando a principal fala) todas olham para ela, à esquerda
                            lookX: full.mood === "alarm" || full.bubbleOn ? -1 : 0
                            label: "DISCO · REDE"; kind: full.diskKind
                            readonly property real pct: full.disk.total > 0 ? full.disk.used / full.disk.total * 100 : 0
                            value: pct
                            available: full.disk.total > 0
                            warnAt: 85; alarmAt: 95
                            bars: [{ k: "disco", v: pct, part: full.disk.total > 0 ? full.disk.docker / full.disk.total * 100 : 0 }]
                            showSeries: false
                            detail: `${Logic.formatBytes(full.disk.used)} / ${Logic.formatBytes(full.disk.total)}  ·  docker ${Logic.formatBytes(full.disk.docker)}`
                            tip: Object.keys(full.disk.parts).map(k => `${k} ${Logic.formatBytes(full.disk.parts[k])}`).join("  ·  ")
                            theme: full.theme; glowLevel: full.glowLevel; animated: full.animating

                            // rede: throughput total do computador (sem loopback / interfaces do Docker)
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 5
                                Text { text: "rede"; color: full.theme.muted; font.family: "Hack Nerd Font Mono"; font.pixelSize: 9; Layout.preferredWidth: 30 }
                                Sparkline {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 16
                                    values: full.hostHistory.net || []
                                    color: full.theme.visor
                                    minScale: 64 * 1024
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: `↓ ${Logic.formatBytes(full.netRx)}/s   ↑ ${Logic.formatBytes(full.netTx)}/s`
                                color: full.theme.visor
                                font.family: "Hack Nerd Font Mono"; font.pixelSize: 9; font.bold: true
                            }
                            // limpeza: dois cliques (o 1º arma, o 2º confirma)
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                Text {
                                    Layout.fillWidth: true
                                    text: full.pruneResult ? "♻ " + full.pruneResult
                                                           : `♻ ${Logic.formatBytes(full.disk.reclaimable)} recuperável`
                                    color: full.theme.sub
                                    elide: Text.ElideRight
                                    font.family: "Hack Nerd Font Mono"; font.pixelSize: 9
                                }
                                Rectangle {
                                    id: pruneBtn
                                    property bool armed: false
                                    readonly property color cc: armed ? full.theme.alarm : full.theme.fur
                                    implicitWidth: pruneLabel.implicitWidth + 12
                                    implicitHeight: 18
                                    radius: 3
                                    color: pruneArea.containsMouse || armed ? Qt.rgba(cc.r, cc.g, cc.b, 0.25) : "transparent"
                                    border.width: 1
                                    border.color: cc
                                    Text {
                                        id: pruneLabel
                                        anchors.centerIn: parent
                                        text: pruneBtn.armed ? "confirmar?" : "limpar"
                                        color: pruneBtn.cc
                                        font.family: "Hack Nerd Font Mono"; font.pixelSize: 9; font.bold: true
                                    }
                                    MouseArea {
                                        id: pruneArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (pruneBtn.armed) { pruneBtn.armed = false; full.prune() }
                                            else { pruneBtn.armed = true; disarm.restart() }
                                        }
                                    }
                                    Timer { id: disarm; interval: 4000; onTriggered: pruneBtn.armed = false }
                                    ToolTipLite {
                                        text: "remove imagens sem container e o cache de build\n(precisarão ser baixadas de novo)"
                                        shown: pruneArea.containsMouse; accent: full.theme.alarm; background: full.theme.bg0
                                        anchors.horizontalCenter: undefined; anchors.right: parent.right
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // rodapé
        RowLayout {
            Layout.fillWidth: true
            // ponto que acende a cada leitura nova
            Rectangle {
                id: syncDot
                width: 5; height: 5; radius: 1
                color: !full.dockerOk ? full.theme.alarm : full.syncAge > 15 ? full.theme.warn : full.theme.ok
                opacity: 0.45
                SequentialAnimation {
                    id: syncBlink
                    NumberAnimation { target: syncDot; property: "opacity"; to: 1; duration: 80 }
                    NumberAnimation { target: syncDot; property: "opacity"; to: 0.45; duration: 600; easing.type: Easing.OutCubic }
                }
            }
            Text {
                Layout.fillWidth: true
                text: (full.dockerOk ? (full.dockerVersion ? "docker " + full.dockerVersion : "docker") : "docker offline")
                      + "  //  sync " + (full.syncAge <= 1 ? "agora" : `há ${full.syncAge}s`)
                      + (full.hiddenCount > 0 ? `  //  ${full.hiddenCount} oculto(s)` : "")
                color: full.syncAge > 15 ? full.theme.warn : full.theme.muted
                font.family: "Hack Nerd Font Mono"; font.pixelSize: 9
            }
            Text {
                text: "⟳ refresh"
                color: refreshArea.containsMouse ? full.theme.fur : full.theme.sub
                font.family: "Hack Nerd Font Mono"; font.pixelSize: 10
                MouseArea { id: refreshArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: full.refresh() }
            }
        }
    }

    // ---- balão de fala da mascote --------------------------------------------
    Rectangle {
        id: bubble
        z: 50
        x: 12 + 84 + 8
        y: 14
        readonly property real maxW: full.width - x - 12 - (full.sideBySide ? 262 : 0)
        width: Math.min(bubbleText.implicitWidth + 16, maxW)
        height: bubbleText.implicitHeight + 10
        radius: 6
        color: full.theme.bg0
        border.width: 1
        border.color: full.bubbleColor
        opacity: full.bubbleOn ? 1 : 0
        scale: full.bubbleOn ? 1 : 0.6
        visible: opacity > 0
        transformOrigin: Item.Left
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
        // rabicho apontando para a mascote
        Rectangle {
            width: 8; height: 8
            rotation: 45
            x: -4; y: parent.height / 2 - 4
            color: full.theme.bg0
            border.width: 1
            border.color: full.bubbleColor
            z: -1
        }
        Rectangle { x: 0; y: parent.height / 2 - 5; width: 2; height: 10; color: full.theme.bg0 }   // esconde a borda do rabicho por dentro
        Text {
            id: bubbleText
            anchors.centerIn: parent
            width: Math.min(implicitWidth, bubble.maxW - 16)
            text: full.lastEvent ? Logic.eventSpeech(full.lastEvent) : ""
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: full.bubbleColor
            font.family: "Hack Nerd Font Mono"; font.pixelSize: 11; font.bold: true
        }
        MouseArea { anchors.fill: parent; onClicked: full.bubbleOn = false }
    }

    // ---- prévia de logs --------------------------------------------------------
    Rectangle {
        id: peek
        z: 60
        visible: full.peekName !== "" && full.peekAnchor !== null
        readonly property var entry: full.logsPeek[full.peekName]
        readonly property var lines: entry ? entry.text.split("\n") : ["carregando…"]
        readonly property point p: full.peekAnchor ? full.peekAnchor.mapToItem(full, 0, 0) : Qt.point(0, 0)
        readonly property real aw: full.peekAnchor ? full.peekAnchor.width : 0
        readonly property real ah: full.peekAnchor ? full.peekAnchor.height : 0
        width: Math.min(full.width - 24, 470)
        height: peekCol.implicitHeight + 12
        x: Math.max(12, Math.min(p.x + aw - width, full.width - 12 - width))
        y: p.y + ah + 4 + height > full.height - 8 ? p.y - height - 4 : p.y + ah + 4
        radius: 3
        color: Qt.rgba(full.theme.bg1.r, full.theme.bg1.g, full.theme.bg1.b, 0.97)
        border.width: 1
        border.color: full.theme.visor
        Column {
            id: peekCol
            x: 8; y: 6
            width: parent.width - 16
            spacing: 1
            Text {
                text: "// logs · " + full.peekName + "  (clique para abrir)"
                color: full.theme.visor
                font.family: "Hack Nerd Font Mono"; font.pixelSize: 9; font.bold: true
            }
            Repeater {
                model: peek.lines
                Text {
                    required property string modelData
                    width: peekCol.width
                    text: modelData || " "
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: /error|fatal|panic|exception/i.test(modelData) ? full.theme.alarm
                         : /warn/i.test(modelData) ? full.theme.warn : full.theme.text
                    font.family: "Hack Nerd Font Mono"; font.pixelSize: 9
                }
            }
        }
    }

    // ---- abertura: cortina que a varredura vai revelando --------------------------
    Rectangle {
        visible: full.bootT < 1
        z: 90
        x: 0; width: parent.width
        y: full.bootT * parent.height
        height: parent.height - y
        color: full.theme.bg1
        // linha de varredura brilhante na borda da cortina
        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right
            anchors.bottom: parent.top
            height: 24
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(full.neon.r, full.neon.g, full.neon.b, 0.35) }
            }
        }
        Rectangle {
            width: parent.width; height: 2
            color: Qt.lighter(full.neon, 1.4)
        }
    }
}
