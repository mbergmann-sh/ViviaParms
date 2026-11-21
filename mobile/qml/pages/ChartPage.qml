// Verlaufskurven: Tag/Woche/Monat/Jahr, Bereiche wählen, Kurven per Legende ein-/ausblenden
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ViviaParms 1.0
import "../components"
import ".."

Item {
    id: page
    property var personId: 0
    property bool active: false
    property var selected: ["bp", "glucose", "weight"]

    function exportPdf() {
        const f = app.exportReport("chart", page.personId, { scale: chart.scale, ref: chart.refDate, from: chart.fromDate, to: chart.toDate,
                                                            panels: page.selected, hidden: chart.hiddenKeys })
        if (f) app.openFile(f); else win.toast(app.lastError, true)
    }
    function togglePanel(id) {
        const s = selected.slice()
        const i = s.indexOf(id)
        if (i >= 0) s.splice(i, 1); else s.push(id)
        // Reihenfolge wie in der Auswahl
        selected = chart.availablePanels.map(p => p.id).filter(x => s.indexOf(x) >= 0)
    }

    // Die ganze Seite rollt: auf dem Smartphone nehmen Kopf und Bedienelemente fast die ganze Höhe ein –
    // ein eigener, mit Layout.fillHeight bemessener Kurvenbereich blieb dort 0 Pixel hoch (Kurven unsichtbar).
    Flickable {
        id: pageFlick
        objectName: "chartPageFlick"
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + Theme.gapL
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollIndicator.vertical: ScrollIndicator {}

    ColumnLayout {
        id: col
        x: Theme.gapL; y: Theme.gap
        width: pageFlick.width - 2 * Theme.gapL
        spacing: Theme.gapS

        Row {
            spacing: 0
            Repeater {
                model: [qsTr("Tag"), qsTr("Woche"), qsTr("Monat"), qsTr("Jahr"), qsTr("Zeitraum")]
                delegate: AbstractButton {
                    objectName: "scale_" + index
                    width: Math.max(win.phone ? 50 : 84, lbl.implicitWidth + (win.phone ? 14 : 28)); height: Theme.touch
                    onClicked: chart.scale = index
                    readonly property bool on: chart.scale === index
                    contentItem: Label { id: lbl; text: modelData; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                         color: on ? Theme.brandInk : Theme.ink; font.bold: on }
                    background: Rectangle {
                        color: on ? Theme.brand : parent.down ? Theme.brandWash : Theme.surface
                        border.color: Theme.ruleStrong
                        radius: index === 0 || index === 4 ? Theme.radius : 0
                        Rectangle { visible: index > 0 && index < 4; anchors.fill: parent; color: "transparent"; border.color: Theme.ruleStrong }
                    }
                }
            }
        }
        // Zeitraum: ◀ Text ▶ Heute in einer Zeile
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gapS
            VButton { text: "◀"; Layout.preferredWidth: Theme.touch; onClicked: chart.step(-1) }
            Label { text: chart.periodText; font.pixelSize: win.phone ? Theme.fsM : Theme.fsL; font.bold: true; color: Theme.ink
                    Layout.fillWidth: true; Layout.minimumWidth: 0; elide: Text.ElideRight
                    wrapMode: win.phone ? Text.WordWrap : Text.NoWrap; maximumLineCount: 2   // Zeitraum am Smartphone zweizeilig
                    horizontalAlignment: win.phone ? Text.AlignHCenter : Text.AlignLeft; verticalAlignment: Text.AlignVCenter }
            VButton { text: "▶"; Layout.preferredWidth: Theme.touch; onClicked: chart.step(1) }
            VButton { text: qsTr("Heute"); onClicked: chart.today() }
        }
        // Zeitraum von–bis (einschließlich) per Kalender. Früher Textfelder: Zwischenstände beim Tippen
        // („01.10.20“ = 2020) verstellten den Zeitraum, und das Feld wurde dabei überschrieben.
        Flow {
            visible: chart.scale === 4
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            spacing: Theme.gapS
            DatePicker { id: rangeFrom; objectName: "chartFrom"; label: qsTr("Von"); width: win.phone ? 160 : 190
                         isoDate: chart.fromDate; onPicked: (iso) => chart.fromDate = iso }
            DatePicker { id: rangeTo; objectName: "chartTo"; label: qsTr("Bis"); width: win.phone ? 160 : 190
                         isoDate: chart.toDate; minDate: chart.fromDate; onPicked: (iso) => chart.toDate = iso }
        }
        // Kurvenauswahl: am Tablet umbrechend, am Smartphone eine Zeile zum Seitwärtswischen,
        // damit die Kurve gleich zu sehen ist
        Flow {
            visible: !win.phone
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            spacing: Theme.gapS
            Repeater {
                model: win.phone ? [] : chart.availablePanels.filter(p => p.hasData)
                VChip { text: modelData.title; colors: modelData.colors; checked: page.selected.indexOf(modelData.id) >= 0
                        onClicked: page.togglePanel(modelData.id) }
            }
            VButton { text: qsTr("Als PDF"); onClicked: page.exportPdf() }
        }
        Flickable {
            objectName: "chartChipRow"
            property bool scrollStrip: true          // gewollt breiter als der Bildschirm
            visible: win.phone
            Layout.fillWidth: true
            Layout.preferredHeight: chipRow.height
            contentWidth: chipRow.width
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            Row {
                id: chipRow
                spacing: Theme.gapS
                Repeater {
                    model: win.phone ? chart.availablePanels.filter(p => p.hasData) : []
                    VChip { text: modelData.title; colors: modelData.colors; checked: page.selected.indexOf(modelData.id) >= 0
                            onClicked: page.togglePanel(modelData.id) }
                }
                VButton { text: qsTr("Als PDF"); onClicked: page.exportPdf() }
            }
        }
        Label { visible: !win.phone
                text: qsTr("Tipp: Auf einen Legendeneintrag tippen blendet die Kurve aus oder ein; auf einen Messpunkt tippen zeigt den Wert.")
                color: Theme.muted; font.pixelSize: Theme.fsXs; Layout.fillWidth: true; wrapMode: Text.WordWrap }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: chart.height
            color: Theme.surface; border.color: Theme.rule
            Chart {
                id: chart
                width: parent.width
                // je Kurvenbereich etwa 42 % der sichtbaren Höhe, 260–420 Pixel
                height: Math.max(1, page.selected.length) * Math.max(win.phone ? 260 : 300, Math.min(420, page.height * 0.42))
                patientId: page.personId
                panels: page.selected
                revision: app.dataRevision
                dark: Theme.dark
                TapHandler { onTapped: (ev) => chart.tapAt(ev.position.x, ev.position.y) }
            }
            Label { anchors.centerIn: parent; visible: chart.recordCount === 0; color: Theme.muted
                    text: qsTr("Keine Messungen in diesem Zeitraum.") }
            // Wert des angetippten Messpunkts
            Rectangle {
                visible: chart.tipText !== ""
                x: Math.min(parent.width - width - 8, Math.max(8, chart.tipPos.x - width / 2))
                y: Math.max(8, chart.tipPos.y - height - 18)
                width: tip.implicitWidth + 24; height: tip.implicitHeight + 16
                radius: 8; color: Theme.ink
                Label { id: tip; anchors.centerIn: parent; text: chart.tipText; color: Theme.paper; font.pixelSize: Theme.fsS }
            }
        }
    }
    }
}
