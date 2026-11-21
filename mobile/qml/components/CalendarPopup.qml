// Monatsblatt zum Antippen eines Tages (für DatePicker und DateField)
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Popup {
    id: pop
    property string title: ""
    property string isoDate: ""          // vorausgewählter Tag (ISO)
    property string minDate: ""          // optional: frühester wählbarer Tag
    property string maxDate: ""          // optional: spätester wählbarer Tag
    signal picked(string iso)

    function pad(n) { return (n < 10 ? "0" : "") + n }
    function toIso(d) { return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) }
    function fromIso(iso) {
        const p = (iso || "").split("-")
        return p.length === 3 ? new Date(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2])) : new Date()
    }
    function openAt(iso) { isoDate = iso || ""; cal.show(fromIso(isoDate)); open() }

    parent: Overlay.overlay
    modal: true
    anchors.centerIn: parent
    width: Math.min(400, (parent ? parent.width : 400) - 24)
    padding: 16
    background: Rectangle { radius: Theme.radius + 4; color: Theme.surface; border.color: Theme.rule }
    Overlay.modal: Rectangle { color: "#80000000" }

    contentItem: ColumnLayout {
        id: cal
        spacing: Theme.gapS
        property int month: 0
        property int year: 2026
        function show(d) { month = d.getMonth(); year = d.getFullYear() }
        function move(n) { const d = new Date(year, month + n, 1); month = d.getMonth(); year = d.getFullYear() }
        function allowed(d) {
            const iso = pop.toIso(d)
            return (!pop.minDate || iso >= pop.minDate) && (!pop.maxDate || iso <= pop.maxDate)
        }

        Label { visible: pop.title !== ""; text: pop.title; font.family: Theme.family; font.pixelSize: Theme.fsS; color: Theme.ink2 }
        RowLayout {
            Layout.fillWidth: true
            spacing: 2
            VButton { text: "«"; kind: "flat"; leftPadding: 8; rightPadding: 8; onClicked: cal.move(-12); objectName: "calYearBack" }
            VButton { text: "‹"; kind: "flat"; leftPadding: 10; rightPadding: 10; onClicked: cal.move(-1); objectName: "calMonthBack" }
            Label { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale().standaloneMonthName(cal.month, Locale.LongFormat) + " " + cal.year
                    font.family: Theme.family; font.pixelSize: Theme.fsL; font.bold: true; color: Theme.ink }
            VButton { text: "›"; kind: "flat"; leftPadding: 10; rightPadding: 10; onClicked: cal.move(1); objectName: "calMonthNext" }
            VButton { text: "»"; kind: "flat"; leftPadding: 8; rightPadding: 8; onClicked: cal.move(12); objectName: "calYearNext" }
        }
        DayOfWeekRow {
            Layout.fillWidth: true
            locale: grid.locale
            delegate: Label { text: shortName; horizontalAlignment: Text.AlignHCenter
                              font.family: Theme.family; font.pixelSize: Theme.fsS; color: Theme.muted }
        }
        MonthGrid {
            id: grid
            objectName: "calGrid"
            Layout.fillWidth: true
            Layout.preferredHeight: 6 * 46
            month: cal.month
            year: cal.year
            locale: Qt.locale()
            // Tag aus year/month/day (nicht aus model.date – das ist je nach Qt-Version UTC-Mitternacht)
            delegate: Rectangle {
                readonly property var d: new Date(model.year, model.month, model.day)
                readonly property string iso: pop.toIso(d)
                readonly property bool inMonth: model.month === grid.month
                readonly property bool sel: pop.isoDate !== "" && iso === pop.isoDate
                readonly property bool ok: cal.allowed(d)
                objectName: "calDay_" + iso
                implicitHeight: 44
                radius: height / 2
                color: sel ? Theme.brand : "transparent"
                border.width: model.today && !sel ? 1 : 0
                border.color: Theme.brand
                Label {
                    anchors.centerIn: parent
                    text: model.day
                    font.family: Theme.family; font.pixelSize: Theme.fsM; font.bold: sel || model.today
                    color: sel ? Theme.brandInk : !ok ? Theme.rule : inMonth ? Theme.ink : Theme.muted
                }
                function choose() {
                    if (!ok) return
                    pop.close()
                    pop.picked(iso)          // isoDate bleibt gebunden – der Verwender übernimmt den Wert
                }
                TapHandler { onTapped: parent.choose() }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            VButton { text: qsTr("Heute"); kind: "flat"; onClicked: cal.show(new Date()) }
            Item { Layout.fillWidth: true }
            VButton { text: qsTr("Abbrechen"); onClicked: pop.close() }
        }
    }
}
