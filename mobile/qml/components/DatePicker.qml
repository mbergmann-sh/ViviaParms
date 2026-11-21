// Datum per Kalender wählen: Schaltfläche mit dem Datum, ein Tipp öffnet ein Monatsblatt.
// Der Wert gilt erst, wenn ein Tag angetippt ist (Signal picked) – halbe Eingaben gibt es nicht.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

ColumnLayout {
    id: f
    property string label: ""
    property string isoDate: ""          // "2026-10-20" – von außen binden, picked(iso) übernehmen
    property string minDate: ""          // optional: frühester wählbarer Tag (ISO)
    property string maxDate: ""          // optional: spätester wählbarer Tag (ISO)
    signal picked(string iso)
    spacing: 4
    opacity: enabled ? 1 : 0.5

    function pad(n) { return (n < 10 ? "0" : "") + n }
    function toIso(d) { return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) }
    function fromIso(iso) {
        const p = (iso || "").split("-")
        return p.length === 3 ? new Date(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2])) : new Date()
    }
    function open() { pop.openAt(f.isoDate) }

    Label { visible: f.label !== ""; text: f.label; font.family: Theme.family; font.pixelSize: Theme.fsS; color: Theme.ink2 }
    AbstractButton {
        id: btn
        objectName: f.objectName !== "" ? f.objectName + "Button" : ""
        Layout.fillWidth: true
        implicitHeight: Theme.touch
        onClicked: f.open()
        contentItem: RowLayout {
            spacing: Theme.gapS
            Label { Layout.fillWidth: true; leftPadding: 14
                    text: f.isoDate ? f.fromIso(f.isoDate).toLocaleDateString(Qt.locale(), Qt.locale().dateFormat(Locale.ShortFormat).replace(/y+/, "yyyy")) : "—"
                    font.family: Theme.family; font.pixelSize: Theme.fsM; color: Theme.ink; elide: Text.ElideRight }
            Label { rightPadding: 12; text: "▾"; font.pixelSize: Theme.fsM; color: Theme.muted }
        }
        background: Rectangle {
            radius: Theme.radius
            color: btn.down ? Theme.brandWash : Theme.surface
            border.width: pop.visible ? 2 : 1
            border.color: pop.visible ? Theme.brand : Theme.ruleStrong
        }
    }

    CalendarPopup {
        id: pop
        parent: Overlay.overlay
        title: f.label
        minDate: f.minDate
        maxDate: f.maxDate
        onPicked: (iso) => f.picked(iso)          // isoDate bleibt gebunden – der Verwender übernimmt den Wert
    }
}
