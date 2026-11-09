// Fundo do HUD: gradiente do tema, fundo animado por tema, scanlines e a linha de varredura.
import QtQuick

Item {
    id: bg
    property Item hud

    Rectangle {
        anchors.fill: parent
        radius: 4
        gradient: Gradient {
            GradientStop { position: 0.0; color: bg.hud.theme.bg0 }
            GradientStop { position: 1.0; color: bg.hud.theme.bg1 }
        }
        border.width: 1
        border.color: Qt.rgba(bg.hud.neon.r, bg.hud.neon.g, bg.hud.neon.b, 0.5)
    }
    // fundo animado do tema (chuva matrix, sol synthwave, estrelas…)
    ThemeBackdrop {
        anchors.fill: parent
        anchors.margins: 1
        themeKey: bg.hud.themeKey
        theme: bg.hud.theme
        animated: bg.hud.animating
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
            GradientStop { position: 1.0; color: bg.hud.neon }
        }
        NumberAnimation on y { running: bg.hud.animating; from: -40; to: bg.height; duration: 4000; loops: Animation.Infinite }
    }
}
