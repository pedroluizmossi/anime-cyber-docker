// Rodapé do HUD: versão do Docker, idade da última leitura (com ponto que pisca) e refresh.
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: footer
    property Item hud

    // pisca o ponto a cada leitura nova
    Connections {
        target: footer.hud
        function onLastUpdateChanged() { if (footer.hud.animating) syncBlink.restart() }
    }

    Rectangle {
        id: syncDot
        width: 5; height: 5; radius: 1
        color: !footer.hud.dockerOk ? footer.hud.theme.alarm : footer.hud.syncAge > 15 ? footer.hud.theme.warn : footer.hud.theme.ok
        opacity: 0.45
        SequentialAnimation {
            id: syncBlink
            NumberAnimation { target: syncDot; property: "opacity"; to: 1; duration: 80 }
            NumberAnimation { target: syncDot; property: "opacity"; to: 0.45; duration: 600; easing.type: Easing.OutCubic }
        }
    }
    Text {
        Layout.fillWidth: true
        text: (footer.hud.dockerOk ? (footer.hud.dockerVersion ? "docker " + footer.hud.dockerVersion : "docker") : i18n("docker offline"))
              + "  //  " + (footer.hud.syncAge <= 1 ? i18n("sync now") : i18n("sync %1s ago", footer.hud.syncAge))
              + (footer.hud.hiddenCount > 0 ? "  //  " + i18np("%1 hidden", "%1 hidden", footer.hud.hiddenCount) : "")
        color: footer.hud.syncAge > 15 ? footer.hud.theme.warn : footer.hud.theme.muted
        font.family: "Hack Nerd Font Mono"; font.pixelSize: 9
    }
    Text {
        text: "⟳ " + i18n("refresh")
        color: refreshArea.containsMouse ? footer.hud.theme.fur : footer.hud.theme.sub
        font.family: "Hack Nerd Font Mono"; font.pixelSize: 10
        MouseArea { id: refreshArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: footer.hud.refresh() }
    }
}
