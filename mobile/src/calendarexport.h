// ViviaParms Tablet – Termine in einen Kalender des Geräts übertragen (nur ViviaParms → Kalender)
//
// Einstellung „Termine in den Kalender übertragen“: alle Termine oder nur die einer Person –
// so weit das angemeldete Konto sie sehen darf (wie im Terminplaner: Verwaltung alle Konten,
// sonst die eigenen) –, 30 Tage zurück bis ein Jahr voraus, werden in einen gewählten Kalender des Geräts geschrieben
// (Java: de.mbergmann.viviaparms.CalendarExport → CalendarContract). Gehört der Kalender zu einem
// Google-Konto, gleicht Android ihn mit Google Kalender ab. Änderungen im Kalender werden nicht
// zurückgeholt – ViviaParms bleibt maßgeblich. Notizen nur auf Wunsch; ausschalten entfernt die
// übertragenen Einträge wieder. Nicht in der Demo.
// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
#pragma once

#include <QByteArray>
#include <QDateTime>
#include <QList>
#include <QObject>
#include <QString>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>

class CalendarExport : public QObject
{
    Q_OBJECT
public:
    struct Item {
        QString key;              // „a<Termin-ID>“
        QString title, location, description;
        QDateTime start, end;
        bool allDay = false;
        QString hash;             // Prüfsumme der Felder: unverändert → nicht neu schreiben
    };
    explicit CalendarExport(QObject *parent = nullptr);

    static QList<Item> plan(const QDateTime &now, bool withNotes, qint64 personId = 0);   // 0 = alle Personen

    bool enabled() const;
    void setEnabled(bool on);              // aus: übertragene Einträge entfernen
    qint64 calendarId() const;
    void setCalendarId(qint64 id);
    qint64 personId() const;               // 0 = alle Termine, sonst nur die dieser Person
    void setPersonId(qint64 id);
    bool withNotes() const;
    void setWithNotes(bool on);
    QVariantList calendars() const;        // beschreibbare Kalender des Geräts
    QVariantMap status() const;            // letzter Lauf: at, total, ins, upd, del, error
    bool permissionGranted() const;
    void requestPermission();

    void syncSoon();                       // nach Änderungen (gebündelt)
    void syncNow(bool force = false);
    int lastCount() const { return m_count; }

private:
    bool mine() const;                     // eingeschaltet vom angemeldeten Konto
    void pickDefault();                    // noch kein Kalender gewählt: einen vorschlagen
    QTimer m_debounce;
    QByteArray m_lastPlan;
    qint64 m_lastCalendar = -1;
    int m_count = 0;
};
