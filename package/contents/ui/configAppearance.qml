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
    property string cfg_cpuMascot
    property string cfg_ramMascot
    property string cfg_gpuMascot
    property string cfg_diskMascot

    readonly property string mascotKey: cfg_mascot || "neko"   // chave nova pode vir vazia
    readonly property var previewTheme: Themes.get(cfg_theme, cfg_customFur, cfg_customVisor)

    // seletor de mascote de um cartão de sinal vital: combo + prévia nos humores idle/busy/alarm
    component VitalPicker: RowLayout {
        id: picker
        property string value
        property bool allowAuto: false
        property var theme
        property int glow: 75
        property bool anim: true
        signal picked(string key)
        readonly property var options: (allowAuto ? [{ key: "auto", label: i18n("Automatic (NVIDIA / AMD)") }] : [])
            .concat(Sprites.list().map(o => ({ key: o.key, label: i18n(o.label) })))   // rótulos marcados com N_() em Sprites.js
        // na prévia, "auto" mostra a placa NVIDIA
        readonly property string shownKind: value === "auto" || !value ? "nvidia" : value
        spacing: Kirigami.Units.smallSpacing
        QQC2.ComboBox {
            id: box
            model: picker.options
            textRole: "label"
            valueRole: "key"
            currentIndex: count > 0 ? Math.max(0, indexOfValue(picker.value)) : -1
            onActivated: picker.picked(currentValue)
            Layout.preferredWidth: Kirigami.Units.gridUnit * 13
        }
        Repeater {
            model: ["idle", "busy", "alarm"]
            Mascot {
                required property string modelData
                width: 40; height: 35
                Layout.preferredWidth: 40; Layout.preferredHeight: 35
                mood: modelData
                kind: picker.shownKind
                theme: picker.theme
                glowLevel: Math.round(picker.glow * 0.6)
                animated: picker.anim
            }
        }
    }

    Kirigami.FormLayout {

        // prévia ao vivo
        Rectangle {
            Kirigami.FormData.label: i18n("Preview:")
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
                    model: ["sleep", "idle", "busy", "alarm", "happy"]
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
            Kirigami.FormData.label: i18n("Mascot:")
            // os delegates leem estes valores via parent: referenciar "page" direto falha
            // no 1º delegate criado (id ainda indisponível) e o binding nunca reavalia
            property var galleryTheme: page.previewTheme
            property string selectedKey: page.mascotKey
            property int glowLvl: page.cfg_glowLevel
            property bool anim: page.cfg_animations
            Layout.preferredWidth: Kirigami.Units.gridUnit * 26
            spacing: 6
            Repeater {
                model: Sprites.list().map(o => ({ key: o.key, label: i18n(o.label), vital: o.vital }))
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
            Kirigami.FormData.label: i18n("Theme:")
            model: Themes.list().map(o => ({ key: o.key, label: i18n(o.label) }))   // rótulos marcados com N_() em Themes.js
            textRole: "label"
            valueRole: "key"
            // depende de count: reavalia quando o modelo fica pronto
            currentIndex: count > 0 ? Math.max(0, indexOfValue(page.cfg_theme)) : -1
            onActivated: page.cfg_theme = currentValue
        }

        KQControls.ColorButton {
            Kirigami.FormData.label: i18n("Fur color:")
            visible: page.cfg_theme === "custom"
            color: page.cfg_customFur
            onAccepted: color => page.cfg_customFur = color.toString()
        }
        KQControls.ColorButton {
            Kirigami.FormData.label: i18n("Visor color:")
            visible: page.cfg_theme === "custom"
            color: page.cfg_customVisor
            onAccepted: color => page.cfg_customVisor = color.toString()
        }

        Item { Kirigami.FormData.isSection: true }

        RowLayout {
            Kirigami.FormData.label: i18n("Icon size:")
            QQC2.Slider {
                id: scaleSlider
                from: 50; to: 100; stepSize: 5
                value: page.cfg_iconScale
                onMoved: page.cfg_iconScale = value
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            }
            QQC2.Label { text: i18n("%1% of the panel height", page.cfg_iconScale) }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Glow intensity:")
            QQC2.Slider {
                from: 0; to: 100; stepSize: 5
                value: page.cfg_glowLevel
                onMoved: page.cfg_glowLevel = value
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            }
            QQC2.Label { text: page.cfg_glowLevel === 0 ? i18n("off") : page.cfg_glowLevel + "%" }
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Vital signs (HUD column)")
        }
        VitalPicker {
            Kirigami.FormData.label: "CPU:"
            value: page.cfg_cpuMascot || "chip"
            theme: page.previewTheme; glow: page.cfg_glowLevel; anim: page.cfg_animations
            onPicked: key => page.cfg_cpuMascot = key
        }
        VitalPicker {
            Kirigami.FormData.label: "RAM:"
            value: page.cfg_ramMascot || "sapo"
            theme: page.previewTheme; glow: page.cfg_glowLevel; anim: page.cfg_animations
            onPicked: key => page.cfg_ramMascot = key
        }
        VitalPicker {
            Kirigami.FormData.label: "GPU:"
            value: page.cfg_gpuMascot || "auto"
            allowAuto: true
            theme: page.previewTheme; glow: page.cfg_glowLevel; anim: page.cfg_animations
            onPicked: key => page.cfg_gpuMascot = key
        }
        VitalPicker {
            Kirigami.FormData.label: i18n("Disk / network:")
            value: page.cfg_diskMascot || "disquete"
            theme: page.previewTheme; glow: page.cfg_glowLevel; anim: page.cfg_animations
            onPicked: key => page.cfg_diskMascot = key
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Panel:")
            text: i18n("Show counter (running/total)")
            checked: page.cfg_showCounter
            onToggled: page.cfg_showCounter = checked
        }
        QQC2.CheckBox {
            text: i18n("Animations (turn off to reduce motion)")
            checked: page.cfg_animations
            onToggled: page.cfg_animations = checked
        }
    }
}
