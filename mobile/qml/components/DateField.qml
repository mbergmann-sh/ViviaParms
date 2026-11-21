// Datumsfeld zum Tippen (TT.MM.JJJJ) oder per Kalender (Knopf rechts) – Wert als ISO-Datum; leer erlaubt
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

ColumnLayout {
    id: f
    property string label: ""
    property string isoDate: ""          // "2026-10-20" oder ""
    property bool allowEmpty: true
    property string emptyText: "—"
    readonly property bool valid: input.text.trim() === "" ? allowEmpty : parse(input.text) !== ""
    spacing: 4
    opacity: enabled ? 1 : 0.5

    function pad(n) { return (n < 10 ? "0" : "") + n }
    function toText(iso) {
        if (!iso) return ""
        const p = iso.split("-")
        return p.length === 3 ? p[2] + "." + p[1] + "." + p[0] : ""
    }
    function parse(t) {
        const m = t.trim().match(/^(\d{1,2})\.(\d{1,2})\.(\d{2}|\d{4})$/)
        if (!m) return ""
        let y = parseInt(m[3]); if (y < 100) y += 2000
        const d = new Date(y, parseInt(m[2]) - 1, parseInt(m[1]))
        if (d.getDate() !== parseInt(m[1]) || d.getMonth() !== parseInt(m[2]) - 1) return ""
        return y + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate())
    }
    onIsoDateChanged: if (parse(input.text) !== isoDate) input.text = toText(isoDate)
    Component.onCompleted: input.text = toText(isoDate)

    Label { visible: f.label !== ""; text: f.label; font.family: Theme.family; font.pixelSize: Theme.fsS; color: Theme.ink2 }
    RowLayout {
        Layout.fillWidth: true
        spacing: 6
    TextField {
        id: input
        Layout.fillWidth: true
        Layout.minimumWidth: 60
        implicitHeight: Theme.touch
        font.family: Theme.family; font.pixelSize: Theme.fsM; color: Theme.ink
        placeholderText: qsTr("TT.MM.JJJJ")
        placeholderTextColor: Theme.muted
        inputMethodHints: Qt.ImhPreferNumbers
        leftPadding: 14; rightPadding: 14
        onTextEdited: { const p = f.parse(text); f.isoDate = text.trim() === "" ? "" : p }
        onReleased: if (activeFocus && !Qt.inputMethod.visible) Qt.inputMethod.show()   // Android: Tastatur nach „Zurück“ wieder öffnen
        background: Rectangle {
            radius: Theme.radius; color: Theme.surface
            border.width: input.activeFocus ? 2 : 1
            border.color: !f.valid ? Theme.alert : input.activeFocus ? Theme.brand : Theme.ruleStrong
        }
    }
    AbstractButton {
        id: calButton
        objectName: f.objectName !== "" ? f.objectName + "Calendar" : ""
        implicitWidth: Theme.touch - 6; implicitHeight: Theme.touch
        Accessible.name: qsTr("Kalender")
        onClicked: cal.openAt(f.parse(input.text) || f.isoDate)
        // gezeichnetes Kalenderblatt (kein Emoji – nicht jede Schrift hat es)
        contentItem: Item {
            Rectangle {
                id: sheet
                anchors.centerIn: parent
                width: 22; height: 20; radius: 3
                color: "transparent"; border.width: 2; border.color: Theme.brand
                Rectangle { x: 0; y: 0; width: parent.width; height: 6; radius: 3; color: Theme.brand }
                Grid {
                    x: 5; y: 9; columns: 3; spacing: 2
                    Repeater { model: 6; Rectangle { width: 2.5; height: 2.5; color: Theme.brand } }
                }
            }
            Rectangle { x: sheet.x + 5; y: sheet.y - 3; width: 2; height: 5; radius: 1; color: Theme.brand }
            Rectangle { x: sheet.x + sheet.width - 7; y: sheet.y - 3; width: 2; height: 5; radius: 1; color: Theme.brand }
        }
        background: Rectangle { radius: Theme.radius; color: calButton.down ? Theme.brandWash : Theme.surface
                                border.width: 1; border.color: Theme.ruleStrong }
    }
    }
    CalendarPopup {
        id: cal
        parent: Overlay.overlay
        title: f.label
        onPicked: (iso) => { input.text = f.toText(iso); f.isoDate = iso }
    }
}
