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
    // parte do Docker (soma dos containers, de docker stats)
    readonly property real dockerCpu: Object.values(stats).reduce((a, s) => a + s.cpu, 0)
    readonly property real dockerMem: Object.values(stats).reduce((a, s) => a + (s.memBytes || 0), 0)
    property bool groupStacks: false
    property bool hideStopped: false
    property bool showGraphs: true
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

    Layout.preferredWidth: 500
    Layout.preferredHeight: 620
    Layout.minimumWidth: 420
    Layout.minimumHeight: 320

    readonly property color neon: mood === "alarm" ? theme.alarm : mood === "sleep" ? theme.sleep : mood === "busy" ? theme.warn : theme.visor
    readonly property var moodText: ({
        sleep: ["スリープ", "nenhum container ativo... zzz"],
        idle:  ["システム正常", "todos os sistemas online"],
        busy:  ["フル稼働", "carga alta na rede neural"],
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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // cabeçalho
        RowLayout {
            spacing: 12
            Mascot {
                mood: full.mood
                kind: full.kind
                theme: full.theme
                glowLevel: full.glowLevel
                animated: full.animating
                Layout.preferredWidth: 84
                Layout.preferredHeight: 74
            }
            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Item {
                    implicitWidth: title.implicitWidth
                    implicitHeight: title.implicitHeight
                    // aberração cromática do título
                    Text { x: glitch.offset; text: title.text; font: title.font; color: full.theme.visor; opacity: 0.7 }
                    Text { x: -glitch.offset; text: title.text; font: title.font; color: full.theme.fur; opacity: 0.7 }
                    Text { id: title; text: "CYBERDOCK"; color: "#ffffff"; font.family: "Hack Nerd Font Mono"; font.bold: true; font.pixelSize: 24; font.letterSpacing: 3 }
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
        }

        // barra de stats
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: [
                    { k: "RUN", v: full.running, c: full.theme.visor, w: 1 },
                    { k: "STOP", v: full.containers.length - full.running, c: full.theme.sub, w: 1 },
                    { k: "ERR", v: full.problems, c: full.problems ? full.theme.alarm : full.theme.muted, w: 1 },
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
                ]
                delegate: Rectangle {
                    required property var modelData
                    readonly property color cc: modelData.c
                    Layout.fillWidth: true
                    Layout.preferredWidth: 60 * modelData.w     // quadros com texto maior ganham mais espaço
                    height: 40; radius: 3
                    color: Qt.rgba(1, 1, 1, 0.03)
                    border.color: Qt.rgba(cc.r, cc.g, cc.b, 0.5)
                    Column {
                        anchors.centerIn: parent
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.v; color: modelData.c; font.family: "Hack Nerd Font Mono"; font.bold: true; font.pixelSize: 15 }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.k; color: full.theme.sub; font.family: "Hack Nerd Font Mono"; font.pixelSize: 9; font.letterSpacing: modelData.k.length > 5 ? 0 : 2 }
                    }
                    HoverHandler { id: tileHover; enabled: !!modelData.tip }
                    ToolTipLite { text: modelData.tip || ""; shown: tileHover.hovered && !!modelData.tip; accent: full.theme.visor; background: full.theme.bg0 }
                }
            }
        }

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
                    { key: "showGraphs", on: full.showGraphs, g: "∿", t: "gráficos de cpu/mem" }
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

        // rodapé
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: "sync " + Qt.formatTime(full.lastUpdate, "hh:mm:ss") + "  //  net.docker.local"
                      + (full.hiddenCount > 0 ? `  //  ${full.hiddenCount} oculto(s)` : "")
                color: full.theme.muted
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
}
