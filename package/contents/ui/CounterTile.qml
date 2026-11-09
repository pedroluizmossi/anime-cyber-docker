// Quadro de contador do HUD (RUN / STOP / ERR, CPU / RAM / GPU no modo estreito).
// Valor com efeito de placa de flip ao mudar, LED no canto que respira (ou pisca em alerta)
// e borda que pulsa quando `pulse` está ligado. Com `animated: false` tudo fica estático.
import QtQuick
import "Themes.js" as Themes

Rectangle {
    id: tile

    property string label: ""
    property var value: 0                  // número ou texto (ex.: "23%")
    property color accent: "#00f0ff"
    property var theme: Themes.get("neon")
    property string tip: ""
    property bool animated: true
    property bool pulse: false             // estado urgente (ex.: ERR > 0)

    readonly property bool zero: !pulse && String(value) === "0"
    readonly property bool breathing: animated && !pulse && !zero
    readonly property bool blinking: animated && pulse
    readonly property real ledOpacity: zero ? 0.3 : blinking ? blinkLevel : breathing ? breathLevel : 1
    readonly property real borderAlpha: !pulse ? 0.5 : blinking ? borderLevel : 1

    // texto mostrado (trocado no meio do flip)
    property string displayed: ""
    property bool ready: false
    property real breathLevel: 1
    property real blinkLevel: 1
    property real borderLevel: 1
    property real flashA: 0

    function fmt(v) {
        return v === undefined || v === null ? "–" : String(v)
    }

    implicitWidth: 60
    implicitHeight: 40
    radius: 3
    color: Qt.rgba(1, 1, 1, 0.03)
    border.width: 1
    border.color: Qt.rgba(accent.r, accent.g, accent.b, borderAlpha)

    // flash de fundo ao mudar o valor
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        visible: tile.flashA > 0
        color: Qt.rgba(tile.accent.r, tile.accent.g, tile.accent.b, tile.flashA)
    }

    // LED: brilho suave atrás, quadrado de 5x5 na frente
    Rectangle {
        x: 2; y: 2; width: 9; height: 9
        radius: 3
        color: Qt.rgba(tile.accent.r, tile.accent.g, tile.accent.b, 0.2)
        opacity: tile.zero ? 0 : tile.ledOpacity
    }
    Rectangle {
        x: 4; y: 4; width: 5; height: 5
        radius: 1
        color: tile.accent
        opacity: tile.ledOpacity
    }

    Column {
        anchors.centerIn: parent
        Text {
            id: valueText
            anchors.horizontalCenter: parent.horizontalCenter
            text: tile.displayed
            color: tile.accent
            font.family: "Hack Nerd Font Mono"
            font.bold: true
            font.pixelSize: 15
            transform: Rotation {
                id: flipRot
                axis { x: 1; y: 0; z: 0 }
                origin.x: valueText.width / 2
                origin.y: valueText.height / 2
                angle: 0
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tile.label
            color: tile.theme.sub
            font.family: "Hack Nerd Font Mono"
            font.pixelSize: 9
            font.letterSpacing: tile.label.length > 5 ? 0 : 2
        }
    }

    // respiração lenta do LED
    SequentialAnimation on breathLevel {
        running: tile.breathing
        loops: Animation.Infinite
        NumberAnimation { to: 0.45; duration: 800; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1; duration: 800; easing.type: Easing.InOutSine }
    }
    // pisca rápido do LED em alerta
    SequentialAnimation on blinkLevel {
        running: tile.blinking
        loops: Animation.Infinite
        NumberAnimation { to: 0.15; duration: 150; easing.type: Easing.InOutQuad }
        NumberAnimation { to: 1; duration: 150; easing.type: Easing.InOutQuad }
    }
    // borda pulsando em alerta
    SequentialAnimation on borderLevel {
        running: tile.blinking
        loops: Animation.Infinite
        NumberAnimation { to: 0.35; duration: 150; easing.type: Easing.InOutQuad }
        NumberAnimation { to: 1; duration: 150; easing.type: Easing.InOutQuad }
    }

    // flip: o texto antigo gira para longe, o novo entra girando de -90°
    SequentialAnimation {
        id: flipAnim
        NumberAnimation { target: flipRot; property: "angle"; from: 0; to: 90; duration: 130; easing.type: Easing.InQuad }
        ScriptAction { script: tile.displayed = tile.fmt(tile.value) }
        NumberAnimation { target: flipRot; property: "angle"; from: -90; to: 0; duration: 130; easing.type: Easing.OutQuad }
    }
    // flash do fundo: accent 0.18 -> 0.03, depois some
    SequentialAnimation {
        id: flashAnim
        NumberAnimation { target: tile; property: "flashA"; from: 0.18; to: 0.03; duration: 400 }
        PropertyAction { target: tile; property: "flashA"; value: 0 }
    }

    onValueChanged: {
        if (!ready)
            return
        if (animated) {
            flashAnim.restart()
            flipAnim.restart()
        } else {
            displayed = fmt(value)
        }
    }

    Component.onCompleted: {
        displayed = fmt(value)
        ready = true
    }

    HoverHandler { id: tileHover; enabled: tile.tip !== "" }
    ToolTipLite {
        text: tile.tip
        shown: tileHover.hovered && tile.tip !== ""
        accent: tile.theme.visor
        background: tile.theme.bg0
    }
}
