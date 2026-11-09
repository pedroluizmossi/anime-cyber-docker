// Popup estilo HUD cyberpunk.
import QtQuick
import QtQuick.Layouts
import "Themes.js" as Themes

Item {
    id: full

    property string mood: "idle"
    property var containers: []
    property var stats: ({})
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
    signal refresh()

    Layout.preferredWidth: 440
    Layout.preferredHeight: 560
    Layout.minimumWidth: 360
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
                    { k: "RUN", v: full.running, c: full.theme.visor },
                    { k: "STOP", v: full.containers.length - full.running, c: full.theme.sub },
                    { k: "ERR", v: full.problems, c: full.problems ? full.theme.alarm : full.theme.muted },
                    { k: "GPU", v: Math.round(full.gpuUtil) + "%", c: full.mood === "busy" ? full.theme.warn : full.theme.ok }
                ]
                delegate: Rectangle {
                    required property var modelData
                    readonly property color cc: modelData.c
                    Layout.fillWidth: true
                    height: 40; radius: 3
                    color: Qt.rgba(1, 1, 1, 0.03)
                    border.color: Qt.rgba(cc.r, cc.g, cc.b, 0.5)
                    Column {
                        anchors.centerIn: parent
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.v; color: modelData.c; font.family: "Hack Nerd Font Mono"; font.bold: true; font.pixelSize: 15 }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.k; color: full.theme.sub; font.family: "Hack Nerd Font Mono"; font.pixelSize: 9; font.letterSpacing: 2 }
                    }
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
            model: full.containers
            delegate: ContainerRow {
                required property var modelData
                width: list.width
                container: modelData
                theme: full.theme
                stat: full.stats[modelData.name] || null
                onAction: verb => full.action(verb, modelData.name)
            }
            Text {
                anchors.centerIn: parent
                visible: list.count === 0 && full.dockerOk
                text: "// nenhum container"
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
