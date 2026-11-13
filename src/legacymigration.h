// ViviaParms – Umzug von VitaParms (Programmname bis 0.31.4)
//
// Seit 0.32.0 heißt das Programm ViviaParms. Organisation und Programmname bestimmen, wo Qt
// Einstellungen und Daten ablegt (QSettings, QStandardPaths::AppDataLocation). Beim ersten Start von
// ViviaParms (bzw. ViviaParms light) übernimmt migrate() deshalb einmalig:
//   * die Einstellungen von VitaParms (bzw. VitaParms light),
//   * den Datenordner (Datenbank, Schlüsseldatei, Sicherungen …) – als Kopie; der alte Ordner bleibt
//     als Sicherung unverändert stehen. vitaparms.sqlite* heißt danach viviaparms.sqlite*.
//   * Einstellungen, die in den alten Datenordner zeigen, zeigen danach in den neuen.
// Nichts geschieht, wenn ViviaParms schon Einstellungen oder eine Datenbank hat.
// Auf Android/iOS gibt es nichts zu übernehmen (neue App, eigener Speicher): Umzug per Sicherung
// oder USB-Abgleich.
// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
#pragma once

#include <QString>

namespace LegacyMigration {

struct Result {
    bool settings = false;          // Einstellungen übernommen
    bool data = false;              // Datenordner kopiert
    QString oldDataDir, newDataDir;
    QString error;                  // Kopieren teilweise fehlgeschlagen
    bool any() const { return settings || data; }
};

// Nach QCoreApplication::setOrganizationName/setApplicationName aufrufen, vor jedem Zugriff auf
// QSettings. legacyApp: bisheriger Programmname ("VitaParms" bzw. "VitaParmsLight").
Result migrate(const QString &legacyOrg, const QString &legacyApp);

// Datenordner von VitaParms bzw. VitaParms light (bisheriger Name), "" wenn nicht vorhanden
QString legacyDataDir(const QString &legacyOrg, const QString &legacyApp);

// Text für die einmalige Meldung nach dem Umzug (übersetzt, Kontext "LegacyMigration")
QString message(const Result &r);

} // namespace LegacyMigration
