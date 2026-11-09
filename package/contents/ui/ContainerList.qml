// Lista de containers (com cabeçalhos de stack) e o horizonte da cidade ao fundo.
import QtQuick

ListView {
    id: list
    property Item hud

    clip: true
    spacing: 6
    model: hud.rows
    boundsBehavior: Flickable.StopAtBounds

    // horizonte da cidade atrás da lista: janelas acesas seguem a CPU, chove no alarme
    Skyline {
        parent: list
        z: -1
        anchors.fill: parent
        theme: list.hud.theme
        mood: list.hud.mood
        load: list.hud.hostCpu
        animated: list.hud.animating
    }

    // a lista é reconstruída quando containers/filtros mudam: preserva a rolagem
    property real keptY: 0
    onMovementEnded: keptY = contentY
    onModelChanged: Qt.callLater(() => contentY = Math.max(0, Math.min(keptY, contentHeight - height)))

    delegate: Item {
        id: d
        required property var modelData
        width: list.width
        height: ld.item ? ld.item.implicitHeight : 0
        Loader {
            id: ld
            width: parent.width
            sourceComponent: d.modelData.type === "header" ? headerComp : rowComp
        }
        Component {
            id: headerComp
            StackHeader {
                width: d.width
                group: d.modelData
                theme: list.hud.theme
                onToggled: list.hud.toggleCollapsed(d.modelData.project)
                onStackAction: verb => list.hud.stackAction(verb, d.modelData.project)
            }
        }
        Component {
            id: rowComp
            ContainerRow {
                readonly property string cname: d.modelData.c.name
                width: d.width
                container: d.modelData.c
                favorite: d.modelData.favorite
                theme: list.hud.theme
                showGraphs: list.hud.showGraphs
                stat: list.hud.stats[cname] || null
                hist: list.hud.history[cname] || null
                vramMiB: list.hud.vram[cname] || 0
                restartCount: list.hud.restarts[cname] || 0
                // lastUpdate muda a cada leitura: o destaque some sozinho depois de 10 min
                restartBumped: list.hud.lastUpdate.getTime() - (list.hud.restartBumpAt[cname] || 0) < 600000
                onPeekLogs: (on, anchor) => {
                    if (on) { list.hud.peekName = cname; list.hud.peekAnchor = anchor; list.hud.peekLogs(cname) }
                    else if (list.hud.peekName === cname) list.hud.peekName = ""
                }
                onAction: verb => list.hud.action(verb, cname)
                onToggleFavorite: list.hud.toggleFavorite(cname)
                onOpenUrl: url => Qt.openUrlExternally(url)
            }
        }
    }
    Text {
        anchors.centerIn: parent
        visible: list.count === 0 && list.hud.dockerOk
        text: list.hud.containers.length ? i18n("// nothing matches the filter") : i18n("// no containers")
        color: list.hud.theme.muted
        font.family: "Hack Nerd Font Mono"
    }
}
