// ViviaParms – Wiederholungsregeln für Terminserien
// Teilmenge von RFC 5545 (RRULE), die sich 1:1 nach iCalendar exportieren lässt:
//   täglich / wöchentlich (Wochentage) / monatlich (Monatstag, n-ter oder letzter Wochentag) /
//   jährlich, jeweils mit Intervall und Ende (unbegrenzt, bis Datum, Anzahl).
// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
#pragma once

#include <QDate>
#include <QDateTime>
#include <QJsonObject>
#include <QList>
#include <QMap>
#include <QString>
#include <QTime>

struct Recurrence
{
    enum Freq { None = 0, Daily, Weekly, Monthly, Yearly };
    enum MonthMode { ByMonthDay = 0, ByNthWeekday, ByLastWeekday };

    Freq  freq = None;
    int   interval = 1;
    int   weekdays = 0;              // wöchentlich: Bit 0 = Montag … Bit 6 = Sonntag
    int   monthMode = ByMonthDay;    // monatlich
    QDate until;                     // letzter möglicher Tag (einschließlich)
    int   count = 0;                 // Anzahl der Termine (inkl. erstem), 0 = ohne Begrenzung

    // Wöchentlich mit eigener Uhrzeit je Wochentag (ab 0.33): Schlüssel 1 = Montag … 7 = Sonntag.
    // Fehlt ein Wochentag, gilt die Uhrzeit des ersten Termins. minutes < 0: ohne Ende (Dauer wie
    // der erste Termin bzw. ganztägig). Nicht in iCalendar-RRULE darstellbar – der Export teilt
    // die Serie nach Uhrzeiten auf (siehe icalexport.cpp).
    struct DayTime {
        QTime start;
        int   minutes = -1;          // Dauer in Minuten
        bool operator==(const DayTime &o) const { return start == o.start && minutes == o.minutes; }
        bool operator!=(const DayTime &o) const { return !(*this == o); }
    };
    QMap<int, DayTime> dayTimes;

    bool hasDayTimes() const { return freq == Weekly && !dayTimes.isEmpty(); }
    // Beginn und Dauer (Sekunden, -1 = ohne Ende) des Termins am Tag d; fallback: erster Termin
    QTime  startTimeOn(const QDate &d, const QTime &fallback) const;
    qint64 durationOn(const QDate &d, qint64 fallbackSecs) const;

    bool isNone() const { return freq == None; }
    bool isEndless() const { return freq != None && !until.isValid() && count <= 0; }

    // Regel an das Startdatum anpassen (Wochentag des Starts gehört immer dazu,
    // ungültige Monatsmodi werden zurückgesetzt) – so ist der Start stets das erste Vorkommen.
    void normalize(const QDate &start);

    // Alle Termintage ab 'start' (der Start selbst ist der erste) bis einschließlich 'to'.
    QList<QDate> dates(const QDate &start, const QDate &to, int maxCount = 5000) const;
    QDate lastDate(const QDate &start) const;   // ungültig bei unbegrenzten Serien

    // RRULE-Wert (ohne "RRULE:"); untilValue wird vom Aufrufer passend formatiert
    QString rrule(const QDate &start, const QString &untilValue) const;
    QString describe(const QDate &start) const;  // "wöchentlich am Mo, Mi, bis 31.12.2026"
                                                 // mit Uhrzeiten: "wöchentlich am Mo 08:00, Mi 14:30 …"

    // Hilfen für den Monatsmodus
    static int  nthOfMonth(const QDate &d) { return (d.day() - 1) / 7 + 1; }
    // Ordnungszahl in der Programmsprache: „2.“ bzw. „2nd“
    static QString ordinal(int n);
    static bool isLastOfMonth(const QDate &d) { return d.day() + 7 > d.daysInMonth(); }

    QJsonObject toJson() const;
    static Recurrence fromJson(const QJsonObject &o);
    bool operator==(const Recurrence &o) const;
    bool operator!=(const Recurrence &o) const { return !(*this == o); }
};

// Kopf einer Terminserie; die einzelnen Termine liegen als normale Zeilen in "appointments"
struct AppointmentSeries
{
    qint64      id = 0;
    Recurrence  rule;
    QDateTime   dtstart;            // erstes Vorkommen (Datum + Uhrzeit)
    QList<QDate> exdates;           // einzeln gelöschte Vorkommen
    QDate       generatedUntil;     // bis hierhin sind Zeilen angelegt
    QString     createdBy;
};
