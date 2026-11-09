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
    property bool cfg_showTemps
    property int cfg_tempHot
    property int cfg_tempCritical

    Kirigami.FormLayout {
        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Refresh every (s):")
            from: 1; to: 60
            value: page.cfg_refreshSeconds
            onValueModified: page.cfg_refreshSeconds = value
        }

        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("⚡ busy mode when…") }

        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("GPU usage ≥ (%):")
            from: 1; to: 100
            value: page.cfg_busyGpu
            onValueModified: page.cfg_busyGpu = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("CPU of one container ≥ (%):")
            from: 1; to: 1000
            value: page.cfg_busyCpu
            onValueModified: page.cfg_busyCpu = value
        }
        QQC2.Label {
            text: i18n("Docker CPU is per core: 100% = one whole core.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Temperature (CPU and GPU)") }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Sensors:")
            text: i18n("show temperature in the vital signs")
            checked: page.cfg_showTemps
            onToggled: page.cfg_showTemps = checked
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Hot from (°C):")
            enabled: page.cfg_showTemps
            from: 30; to: 120
            value: page.cfg_tempHot
            onValueModified: {
                page.cfg_tempHot = value
                if (page.cfg_tempCritical <= value) page.cfg_tempCritical = Math.min(120, value + 5)
            }
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Critical from (°C):")
            enabled: page.cfg_showTemps
            from: 30; to: 120
            value: page.cfg_tempCritical
            onValueModified: {
                page.cfg_tempCritical = value
                if (page.cfg_tempHot >= value) page.cfg_tempHot = Math.max(30, value - 5)
            }
        }
        QQC2.Label {
            text: i18n("Hot: the mascot sweats, steams and jumps. Critical: it goes into alarm.\nCPU read from hwmon (coretemp / k10temp / zenpower); GPU from nvidia-smi or amdgpu.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Notifications") }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Notify when:")
            text: i18n("a container crashes, loops or becomes unhealthy")
            checked: page.cfg_notify
            onToggled: page.cfg_notify = checked
        }
        QQC2.CheckBox {
            text: i18n("a container with problems is back to normal")
            enabled: page.cfg_notify
            checked: page.cfg_notifyRecovery
            onToggled: page.cfg_notifyRecovery = checked
        }
        QQC2.CheckBox {
            text: i18n("Docker goes down or comes back")
            enabled: page.cfg_notify
            checked: page.cfg_notifyDocker
            onToggled: page.cfg_notifyDocker = checked
        }
        QQC2.Label {
            text: i18n("Problem notifications have buttons to view the logs and restart.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }
    }
}
