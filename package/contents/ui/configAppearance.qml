import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQControls
import "Themes.js" as Themes

KCM.SimpleKCM {
    id: page

    property string cfg_theme
    property string cfg_customFur
    property string cfg_customVisor
    property int cfg_iconScale
    property bool cfg_showCounter
    property int cfg_glowLevel
    property bool cfg_animations

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

        QQC2.ComboBox {
            id: themeBox
            Kirigami.FormData.label: "Tema:"
            model: Themes.list()
            textRole: "label"
            valueRole: "key"
            currentIndex: Math.max(0, indexOfValue(page.cfg_theme))
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
