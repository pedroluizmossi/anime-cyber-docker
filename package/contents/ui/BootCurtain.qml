// Abertura do HUD: cortina que a varredura de CRT vai revelando de cima para baixo.
import QtQuick

Rectangle {
    id: curtain
    property Item hud

    visible: hud.bootT < 1
    x: 0; width: parent.width
    y: hud.bootT * parent.height
    height: parent.height - y
    color: hud.theme.bg1

    // brilho logo acima da borda da cortina
    Rectangle {
        anchors.left: parent.left; anchors.right: parent.right
        anchors.bottom: parent.top
        height: 24
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.rgba(curtain.hud.neon.r, curtain.hud.neon.g, curtain.hud.neon.b, 0.35) }
        }
    }
    // a linha de varredura
    Rectangle {
        width: parent.width; height: 2
        color: Qt.lighter(curtain.hud.neon, 1.4)
    }
}
