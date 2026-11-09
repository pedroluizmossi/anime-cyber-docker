// O que aparece no painel: mascote + contador neon.
import QtQuick
import QtQuick.Layouts
import "Themes.js" as Themes

Item {
    id: compact

    property string mood: "idle"
    property int running: 0
    property int total: 0
    property int problems: 0
    property var theme: Themes.get("neon")
    property string kind: "neko"
    property int iconScale: 100
    property bool showCounter: true
    property int glowLevel: 75
    property bool animated: true
    signal activated()

    readonly property color neon: mood === "alarm" ? theme.alarm : mood === "sleep" ? theme.sleep : theme.visor
    readonly property int iconHeight: Math.round(height * iconScale / 100)

    implicitWidth: row.implicitWidth + 4
    Layout.minimumWidth: row.implicitWidth + 4
    Layout.preferredWidth: row.implicitWidth + 4

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 2
        anchors.rightMargin: 2
        spacing: 3

        Mascot {
            mood: compact.mood
            kind: compact.kind
            theme: compact.theme
            glowLevel: compact.glowLevel
            animated: compact.animated
            showEffects: compact.iconHeight >= 36
            // altura cheia + largura inteira: sprite alinhada à grade de pixels
            Layout.preferredHeight: compact.iconHeight
            Layout.preferredWidth: Math.ceil(compact.iconHeight * 16 / 14)
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: compact.showCounter || compact.problems > 0
            text: compact.problems > 0 ? `${compact.problems}!` : `${compact.running}/${compact.total}`
            color: compact.neon
            font.family: "Hack Nerd Font Mono"
            font.bold: true
            font.pixelSize: Math.max(10, compact.height * 0.34)
            renderType: Text.NativeRendering
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: compact.activated()
    }
}
