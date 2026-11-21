// Hinweis-Plakette (Pflegegrad, Schwerbehindertenausweis)
import QtQuick
import QtQuick.Controls
import ".."

Rectangle {
    property alias text: l.text
    property bool warn: false
    // nie breiter als der Platz daneben – langer Text bricht um
    implicitWidth: Math.min(l.implicitWidth + 24, parent && parent.width > 0 ? parent.width : l.implicitWidth + 24)
    width: implicitWidth
    implicitHeight: l.implicitHeight + 12
    radius: 6
    color: warn ? Theme.warnWash : Theme.surface
    border.color: warn ? Theme.warn : Theme.ruleStrong
    Label { id: l; anchors.centerIn: parent; width: Math.min(implicitWidth, parent.width - 24); wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; color: warn ? Theme.warn : Theme.ink2; font.pixelSize: Theme.fsS }
}
