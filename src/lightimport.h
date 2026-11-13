// ViviaParms – Datenbank von ViviaParms light in ViviaParms übernehmen
//
// ViviaParms light verwendet dasselbe Datenbankformat. Beim Import wird die Light-Datenbank (eigener
// Schlüssel; entsperrt mit ihrem Anmeldekonto oder dem Wiederherstellungsschlüssel) Zeile für Zeile
// in die geöffnete Datenbank eingeführt – wie beim Abgleich: Die Person der Light-Version kommt mit
// Stammblatt, Messungen, Medikamenten, Terminen, Kontakten und Dokumenten als weitere Person hinzu,
// die vorhandenen Personen bleiben unverändert. Ein erneuter Import derselben Datenbank aktualisiert
// die schon übernommenen Einträge (gleiche Kennungen), statt sie zu verdoppeln.
// Vorher legt ViviaParms eine Sicherung der geöffneten Datenbank an.
// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
#pragma once

#include <QList>
#include <QString>
#include <QStringList>

namespace LightImport {

// Datenordner von ViviaParms light auf diesem Rechner (Vorschlag im Dateidialog)
QString lightDataDir();
// Pfad der Standard-Datenbank von ViviaParms light (existiert evtl. nicht)
QString lightDatabasePath();

struct Result {
    int inserted = 0, updated = 0;
    QStringList persons;             // übernommene Personen („Name, Vorname“)
    QList<qint64> personIds;         // ihre IDs in dieser Datenbank
    QString backup;                  // Sicherung vor dem Import
};

// 'path': Datenbankdatei (*.sqlite) der Light-Version, 'key': ihr Datenbankschlüssel.
bool importFrom(const QString &path, const QByteArray &key, Result *result, QString *error);

} // namespace LightImport
