import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property int cfg_refreshSeconds
    property int cfg_busyGpu
    property int cfg_busyCpu
    property bool cfg_notify
    property bool cfg_notifyRecovery
    property bool cfg_notifyDocker

    Kirigami.FormLayout {
        QQC2.SpinBox {
            Kirigami.FormData.label: "Atualizar a cada (s):"
            from: 1; to: 60
            value: page.cfg_refreshSeconds
            onValueModified: page.cfg_refreshSeconds = value
        }

        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Modo ⚡ busy quando…" }

        QQC2.SpinBox {
            Kirigami.FormData.label: "Uso da GPU ≥ (%):"
            from: 1; to: 100
            value: page.cfg_busyGpu
            onValueModified: page.cfg_busyGpu = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: "CPU de um container ≥ (%):"
            from: 1; to: 1000
            value: page.cfg_busyCpu
            onValueModified: page.cfg_busyCpu = value
        }
        QQC2.Label {
            text: "CPU do Docker é por núcleo: 100% = um núcleo inteiro."
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Notificações" }

        QQC2.CheckBox {
            Kirigami.FormData.label: "Avisar quando:"
            text: "um container cai, entra em loop ou fica unhealthy"
            checked: page.cfg_notify
            onToggled: page.cfg_notify = checked
        }
        QQC2.CheckBox {
            text: "um container com problema volta ao normal"
            enabled: page.cfg_notify
            checked: page.cfg_notifyRecovery
            onToggled: page.cfg_notifyRecovery = checked
        }
        QQC2.CheckBox {
            text: "o Docker sai do ar ou volta"
            enabled: page.cfg_notify
            checked: page.cfg_notifyDocker
            onToggled: page.cfg_notifyDocker = checked
        }
        QQC2.Label {
            text: "As notificações de problema têm botões para ver os logs e reiniciar."
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }
    }
}
