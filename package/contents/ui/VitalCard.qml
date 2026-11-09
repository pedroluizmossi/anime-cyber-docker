// Cartão da coluna de sinais vitais: uma mascote cujo humor segue a métrica,
// valor grande, temperatura, barras segmentadas (com a parte do Docker destacada) e histórico.
// Filhos declarados dentro do cartão entram no fim dele (ex.: rede e limpeza no cartão de disco).
// compact: cabeçalho numa linha só (mascote pequena, valor ao lado do rótulo) e gráfico baixo.
// Animações: o valor conta até o novo número e os segmentos acendem/apagam em sequência (25 ms cada).
import QtQuick
import QtQuick.Layouts
import "Themes.js" as Themes
import "Logic.js" as Logic

Rectangle {
    id: card

    property string label: "CPU"
    property string kind: "robo"
    property real value: 0                 // 0..100
    property bool available: true
    property real warnAt: 60
    property real alarmAt: 85
    // barras: [{ k: "uso", v: 0..100, part: 0..100 (parte do Docker, opcional) }]
    property var bars: []
    property var series: []                // histórico 0..100
    property bool showSeries: true
    property real temp: 0                  // °C; 0 = sem sensor / desligado
    property real tempHot: 80
    property real tempCritical: 90
    readonly property bool hot: temp > 0 && temp >= tempHot
    default property alias extra: extraCol.data
    property string detail: ""
    property string tip: ""
    property var theme: Themes.get("neon")
    property int glowLevel: 75
    property bool animated: true
    property bool compact: false           // modo compacto: cabeçalho de uma linha e gráfico baixo
    property int lookX: 0                  // para onde a mascote olha (-1 esquerda, 1 direita)

    // humor = o pior entre carga e temperatura
    readonly property string mood: Logic.worstMood(Logic.vitalMood(value, warnAt, alarmAt, available),
                                                   Logic.tempMood(temp, tempHot, tempCritical))
    readonly property color tempColor: temp >= tempCritical ? theme.alarm : temp >= tempHot ? theme.warn : theme.sub
    readonly property color accent: mood === "alarm" ? theme.alarm
                                  : mood === "busy" ? theme.warn
                                  : mood === "sleep" ? theme.sleep
                                  : theme.ok
    readonly property var tags: ({ sleep: "休止", idle: "平常", busy: "全力", alarm: "危険" })
    readonly property int pad: compact ? 6 : 8

    // valor exibido: conta até o valor real quando animado
    property real shown: value
    Behavior on shown {
        enabled: card.animated
        NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
    }
    readonly property string shownText: available ? Math.round(shown) + "%" : "N/A"

    function barColor(v) { return v >= alarmAt ? theme.alarm : v >= warnAt ? theme.warn : theme.ok }

    implicitHeight: col.implicitHeight + 2 * pad
    radius: 3
    color: hover.hovered ? Qt.rgba(accent.r, accent.g, accent.b, 0.08) : Qt.rgba(1, 1, 1, 0.025)
    border.width: 1
    border.color: Qt.rgba(accent.r, accent.g, accent.b, mood === "alarm" ? 0.9 : 0.45)
    Behavior on border.color { ColorAnimation { duration: 400 } }

    HoverHandler { id: hover }
    ToolTipLite { text: card.tip; shown: hover.hovered && !!card.tip; accent: card.theme.visor; background: card.theme.bg0 }

    // pulso da borda no alarme
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.width: 1
        border.color: card.theme.alarm
        visible: card.mood === "alarm"
        SequentialAnimation on opacity {
            running: card.mood === "alarm" && card.animated
            loops: Animation.Infinite
            NumberAnimation { from: 0.9; to: 0.1; duration: 300 }
            NumberAnimation { from: 0.1; to: 0.9; duration: 300 }
        }
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: card.pad
        spacing: card.compact ? 3 : 5

        RowLayout {
            id: topRow
            spacing: card.compact ? 6 : 8
            Mascot {
                mood: card.mood
                kind: card.kind
                theme: card.theme
                glowLevel: Math.round(card.glowLevel * 0.7)
                animated: card.animated
                showEffects: true
                hot: card.hot
                lookX: card.lookX
                interactive: true          // clique = carinho, clique duplo = dancinha
                Layout.preferredWidth: card.compact ? 36 : 52
                Layout.preferredHeight: card.compact ? 32 : 46
            }
            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                RowLayout {
                    id: headerRow
                    Layout.fillWidth: true
                    // cabeçalho: rótulo (elide quando falta espaço), temperatura, etiqueta e,
                    // no modo compacto, o valor grande
                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: card.label
                        elide: Text.ElideRight
                        color: card.theme.sub
                        font.family: "Hack Nerd Font Mono"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 2
                    }
                    Text {
                        visible: card.temp > 0
                        text: Math.round(card.temp) + "°C"
                        color: card.tempColor
                        font.family: "Hack Nerd Font Mono"; font.pixelSize: 10; font.bold: card.hot
                        SequentialAnimation on opacity {
                            running: card.temp >= card.tempCritical && card.animated
                            loops: Animation.Infinite
                            NumberAnimation { from: 1; to: 0.3; duration: 350 }
                            NumberAnimation { from: 0.3; to: 1; duration: 350 }
                        }
                    }
                    Rectangle {
                        implicitWidth: tagText.implicitWidth + 8
                        implicitHeight: tagText.implicitHeight + 2
                        radius: 2
                        color: Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.18)
                        Text {
                            id: tagText
                            anchors.centerIn: parent
                            text: card.tags[card.mood]
                            color: card.accent
                            font.family: "Noto Sans Mono CJK JP"; font.pixelSize: 9; font.bold: true
                        }
                    }
                    Text {
                        id: numCompact
                        visible: card.compact
                        Layout.leftMargin: 6
                        text: card.shownText
                        color: card.accent
                        font.family: "Hack Nerd Font Mono"; font.bold: true; font.pixelSize: 17
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                }
                Text {
                    id: numBig
                    visible: !card.compact
                    text: card.shownText
                    color: card.accent
                    font.family: "Hack Nerd Font Mono"; font.bold: true; font.pixelSize: 24
                    Behavior on color { ColorAnimation { duration: 400 } }
                }
            }
        }

        // barras segmentadas
        Repeater {
            model: card.available ? card.bars : []
            delegate: RowLayout {
                id: barRow
                required property var modelData
                readonly property int segs: 20
                readonly property int lit: Math.round(Math.max(0, Math.min(100, modelData.v)) / 100 * segs)
                readonly property int part: Math.round(Math.max(0, Math.min(100, modelData.part || 0)) / 100 * segs)
                // níveis animados: segmentos acendem/apagam em sequência (ver NumberAnimations abaixo)
                property real litAnim: 0
                property real partAnim: 0
                Layout.fillWidth: true
                spacing: card.compact ? 4 : 6

                Component.onCompleted: { litAnim = lit; partAnim = part }
                onLitChanged: {
                    litRun.stop()
                    if (card.animated) {
                        litRun.to = barRow.lit
                        litRun.duration = Math.abs(barRow.lit - barRow.litAnim) * 25
                        litRun.start()
                    } else {
                        barRow.litAnim = barRow.lit
                    }
                }
                onPartChanged: {
                    partRun.stop()
                    if (card.animated) {
                        partRun.to = barRow.part
                        partRun.duration = Math.abs(barRow.part - barRow.partAnim) * 25
                        partRun.start()
                    } else {
                        barRow.partAnim = barRow.part
                    }
                }
                // desligou a animação no meio do caminho: cai direto no estado final
                Connections {
                    target: card
                    function onAnimatedChanged() {
                        if (card.animated) return
                        litRun.stop(); partRun.stop()
                        barRow.litAnim = barRow.lit
                        barRow.partAnim = barRow.part
                    }
                }
                NumberAnimation {
                    id: litRun
                    target: barRow; property: "litAnim"
                    easing.type: Easing.Linear
                }
                NumberAnimation {
                    id: partRun
                    target: barRow; property: "partAnim"
                    easing.type: Easing.Linear
                }

                Text {
                    Layout.preferredWidth: 30
                    text: barRow.modelData.k
                    color: card.theme.muted
                    font.family: "Hack Nerd Font Mono"; font.pixelSize: 9
                }
                Row {
                    id: segRow
                    Layout.fillWidth: true
                    spacing: card.compact ? 1 : 2
                    readonly property real segW: Math.max(2, (width - spacing * (barRow.segs - 1)) / barRow.segs)
                    Repeater {
                        model: barRow.segs
                        delegate: Rectangle {
                            required property int index
                            width: segRow.segW; height: 7
                            radius: 1
                            // parte do Docker primeiro (cor da mascote), depois o resto do uso
                            color: index < barRow.partAnim ? card.theme.fur
                                 : index < barRow.litAnim ? card.barColor(barRow.modelData.v)
                                 : Qt.rgba(1, 1, 1, 0.07)
                            opacity: index < barRow.litAnim ? 0.55 + 0.45 * (index + 1) / barRow.segs : 1
                        }
                    }
                }
            }
        }

        Sparkline {
            Layout.fillWidth: true
            Layout.preferredHeight: card.compact ? 12 : 22
            visible: card.available && card.showSeries
            values: card.series
            color: card.accent
            minScale: 100
        }

        Text {
            Layout.fillWidth: true
            text: card.detail
            visible: !!card.detail
            color: card.theme.sub
            elide: Text.ElideRight
            font.family: "Hack Nerd Font Mono"; font.pixelSize: 9
        }

        ColumnLayout {
            id: extraCol
            Layout.fillWidth: true
            spacing: 4
            visible: children.length > 0
        }
    }
}
