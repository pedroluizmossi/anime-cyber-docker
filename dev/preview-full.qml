// Renderiza o popup com dados falsos e salva PNG. Uso: qml dev/preview-full.qml -- <mood> saida.png
import QtQuick
import "../package/contents/ui"

Window {
    id: win
    width: 900; height: 580; visible: true; color: "#000000"
    readonly property var args: Qt.application.arguments
    readonly property string moodArg: args[args.length - 2]
    readonly property var fake: [
        { name: "database-index-postgres-1", image: "code-index-postgres:pg17-pgsearch0.26.5", state: "running", status: "Up 2 hours (healthy)", health: "healthy", project: "database-index", problem: false },
        { name: "llama-swap", image: "ghcr.io/mostlygeek/llama-swap:unified-cuda13", state: "running", status: "Up 12 minutes", health: "", project: "embeddings", problem: false },
        { name: "vikunja-vikunja-1", image: "vikunja/vikunja:latest", state: moodArg === "alarm" ? "restarting" : "running", status: moodArg === "alarm" ? "Restarting (1) 3 seconds ago" : "Up 2 hours", health: "", project: "vikunja", problem: moodArg === "alarm" },
        { name: "minikube", image: "gcr.io/k8s-minikube/kicbase:v0.0.50", state: "exited", status: "Exited (255) 2 months ago", health: "", project: "", problem: false }
    ]
    Row {
        anchors.centerIn: parent; spacing: 30
        FullView {
            width: 440; height: 560
            mood: win.moodArg
            containers: win.fake
            stats: ({ "llama-swap": { cpu: 3.2, mem: "1.4GiB" }, "database-index-postgres-1": { cpu: 0.4, mem: "212MiB" } })
            running: 3; problems: win.moodArg === "alarm" ? 1 : 0; gpuUtil: win.moodArg === "busy" ? 87 : 4
        }
        Rectangle {
            width: 380; height: 44; color: "#1b1e24"; anchors.verticalCenter: parent.verticalCenter
            CompactView { anchors.right: parent.right; height: parent.height; width: implicitWidth; mood: win.moodArg; running: 3; total: 4; problems: win.moodArg === "alarm" ? 1 : 0 }
        }
    }
    Timer { interval: 1500; running: true; onTriggered: win.contentItem.grabToImage(r => { r.saveToFile(win.args[win.args.length - 1]); Qt.quit() }) }
}
