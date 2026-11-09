import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQControls
import "Themes.js" as Themes
import "Sprites.js" as Sprites

KCM.SimpleKCM {
    id: page

    property string cfg_mascot
    property string cfg_theme
    property string cfg_customFur
    property string cfg_customVisor
    property int cfg_iconScale
    property bool cfg_showCounter
    property int cfg_glowLevel
    property bool cfg_animations

    readonly property string mascotKey: cfg_mascot || "neko"   // chave nova pode vir vazia
    readonly property var previewTheme: Themes.get(cfg_theme, cfg_customFur, cfg_customVisor)

    Kirigami.FormLayout {

        // prévia ao vivo
        Rectangle {
            Kirigami.FormData.label: "Prévia:"
            implicitWidth: previewRow.implicitWidth + 24
            implicitHeight: previewRow.implicitHeight + 24
            radius: 4
            gradient: Gradient {
                GradientStop { position: 0; color: page.previewTheme.bg0 }
                GradientStop { position: 1; color: page.previewTheme.bg1 }
            }
            border.color: page.previewTheme.visor
            Row {
                id: previewRow
                anchors.centerIn: parent
                spacing: 18
                Repeater {
                    model: ["sleep", "idle", "busy", "alarm"]
                    Column {
                        spacing: 4
                        Mascot {
                            width: 64; height: 56
                            mood: modelData
                            kind: page.mascotKey
                            theme: page.previewTheme
                            glowLevel: page.cfg_glowLevel
                            animated: page.cfg_animations
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData
                            color: page.previewTheme.sub
                            font.family: "Hack Nerd Font Mono"; font.pixelSize: 10
                        }
                    }
                }
            }
        }

        // galeria de mascotes: clique para escolher
        Flow {
            id: gallery
            Kirigami.FormData.label: "Mascote:"
            // os delegates leem estes valores via parent: referenciar "page" direto falha
            // no 1º delegate criado (id ainda indisponível) e o binding nunca reavalia
            property var galleryTheme: page.previewTheme
            property string selectedKey: page.mascotKey
            property int glowLvl: page.cfg_glowLevel
            property bool anim: page.cfg_animations
            Layout.preferredWidth: Kirigami.Units.gridUnit * 26
            spacing: 6
            Repeater {
                model: Sprites.list()
                delegate: Rectangle {
                    id: tile
                    // propriedades próprias (não "required") para o binding de seleção reagir certo
                    readonly property string key: modelData.key
                    readonly property string label: modelData.label
                    readonly property var g: parent      // = gallery
                    readonly property var th: g ? g.galleryTheme : undefined
                    readonly property bool selected: !!g && g.selectedKey === key
                    width: 96; height: 78; radius: 4
                    color: selected && th ? Qt.rgba(th.visor.r, th.visor.g, th.visor.b, 0.18)
                                    : (tileMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                    border.width: selected ? 2 : 1
                    border.color: selected && th ? th.visor : Qt.rgba(1, 1, 1, 0.15)
                    Mascot {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 6
                        width: 48; height: 42
                        kind: tile.key
                        mood: "idle"
                        theme: tile.th
                        glowLevel: tile.selected && tile.g ? tile.g.glowLvl : 0
                        animated: tile.selected && !!tile.g && tile.g.anim
                    }
                    QQC2.Label {
                        anchors.bottom: parent.bottom; anchors.bottomMargin: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tile.label
                        font: Kirigami.Theme.smallFont
                        width: parent.width - 6
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        id: tileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.cfg_mascot = tile.key
                    }
                }
            }
        }

        QQC2.ComboBox {
            id: themeBox
            Kirigami.FormData.label: "Tema:"
            model: Themes.list()
            textRole: "label"
            valueRole: "key"
            // depende de count: reavalia quando o modelo fica pronto
            currentIndex: count > 0 ? Math.max(0, indexOfValue(page.cfg_theme)) : -1
            onActivated: page.cfg_theme = currentValue
        }

        KQControls.ColorButton {
            Kirigami.FormData.label: "Cor do pelo:"
            visible: page.cfg_theme === "custom"
            color: page.cfg_customFur
            onAccepted: color => page.cfg_customFur = color.toString()
        }
        KQControls.ColorButton {
            Kirigami.FormData.label: "Cor do visor:"
            visible: page.cfg_theme === "custom"
            color: page.cfg_customVisor
            onAccepted: color => page.cfg_customVisor = color.toString()
        }

        Item { Kirigami.FormData.isSection: true }

        RowLayout {
            Kirigami.FormData.label: "Tamanho do ícone:"
            QQC2.Slider {
                id: scaleSlider
                from: 50; to: 100; stepSize: 5
                value: page.cfg_iconScale
                onMoved: page.cfg_iconScale = value
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            }
            QQC2.Label { text: page.cfg_iconScale + "% da altura do painel" }
        }

        RowLayout {
            Kirigami.FormData.label: "Intensidade do glow:"
            QQC2.Slider {
                from: 0; to: 100; stepSize: 5
                value: page.cfg_glowLevel
                onMoved: page.cfg_glowLevel = value
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            }
            QQC2.Label { text: page.cfg_glowLevel === 0 ? "desligado" : page.cfg_glowLevel + "%" }
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: "Painel:"
            text: "Mostrar contador (rodando/total)"
            checked: page.cfg_showCounter
            onToggled: page.cfg_showCounter = checked
        }
        QQC2.CheckBox {
            text: "Animações (desligue para reduzir movimento)"
            checked: page.cfg_animations
            onToggled: page.cfg_animations = checked
        }
    }
}
