// ViviaParms Tablet – Termine in einen Kalender des Geräts übertragen (siehe calendarexport.h)
// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
#include "calendarexport.h"

#include "apptcore.h"
#include "database.h"
#include "session.h"

#include <QCryptographicHash>
#include <QHash>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSettings>
#include <QTimeZone>

#ifdef Q_OS_ANDROID
#include <QJniObject>
#include <QtCore/qcoreapplication_platform.h>
#endif

namespace {
const char *kClass = "de/mbergmann/viviaparms/CalendarExport";
QString key(const char *k) { return QStringLiteral("calendar/") + QLatin1String(k); }
#ifdef Q_OS_ANDROID
QJniObject context() { return QJniObject(QNativeInterface::QAndroidApplication::context()); }
#endif
}

CalendarExport::CalendarExport(QObject *parent) : QObject(parent)
{
    m_debounce.setSingleShot(true);
    m_debounce.setInterval(3000);
    connect(&m_debounce, &QTimer::timeout, this, [this] { syncNow(); });
}

QList<CalendarExport::Item> CalendarExport::plan(const QDateTime &now, bool withNotes, qint64 personId)
{
    QList<Item> l;
    if (!Session::isLoggedIn() || !Database::instance().isOpen()) return l;
    Database &db = Database::instance();
    QHash<qint64, QString> names;
    for (const Patient &p : db.patients()) names.insert(p.id, p.displayName());
    const QDateTime from(now.date().addDays(-30), QTime(0, 0));
    const QDateTime to(now.date().addDays(366), QTime(0, 0));
    // sichtbar wie im Terminplaner: Verwaltung alle Konten, sonst die eigenen
    const QString owner = Session::isAdmin() ? QString() : Session::user();
    const QList<Appointment> list = db.appointments(from, to, owner, personId, true);
    for (const Appointment &a : list) {
        if (!a.start.isValid() || !ApptUi::canSee(a)) continue;
        Item it;
        it.key = QStringLiteral("a%1").arg(a.id);
        const QString who = a.patientId ? names.value(a.patientId) : QString();
        // mehrere Personen im Konto: Name in den Titel, sonst ist im Kalender nicht zu sehen, für wen
        it.title = (personId == 0 && names.size() > 1 && !who.isEmpty()) ? QStringLiteral("%1 (%2)").arg(a.title, who) : a.title;
        it.location = a.location;
        QStringList d;
        if (!who.isEmpty()) d << tr("Für: %1").arg(who);
        if (withNotes && !a.notes.trimmed().isEmpty()) d << a.notes.trimmed();
        d << tr("Aus ViviaParms übertragen – Änderungen bitte in ViviaParms vornehmen.");
        it.description = d.join(QStringLiteral("\n\n"));
        it.allDay = a.allDay;
        if (a.allDay) {
            // ganztägig: UTC-Mitternacht, Ende exklusiv
            const QDate last = a.end.isValid() && a.end.date() >= a.start.date() ? a.end.date() : a.start.date();
            it.start = QDateTime(a.start.date(), QTime(0, 0), QTimeZone::utc());
            it.end = QDateTime(last.addDays(1), QTime(0, 0), QTimeZone::utc());
        } else {
            it.start = a.start;
            it.end = a.end.isValid() && a.end > a.start ? a.end : a.start.addSecs(30 * 60);
        }
        const QByteArray raw = QStringList{ it.title, it.location, it.description,
                                            QString::number(it.start.toMSecsSinceEpoch()),
                                            QString::number(it.end.toMSecsSinceEpoch()),
                                            it.allDay ? QStringLiteral("1") : QStringLiteral("0") }.join(QChar(0x1f)).toUtf8();
        it.hash = QString::fromLatin1(QCryptographicHash::hash(raw, QCryptographicHash::Sha1).toHex().left(16));
        l << it;
    }
    return l;
}

bool CalendarExport::enabled() const { return QSettings().value(key("enabled"), false).toBool(); }
qint64 CalendarExport::calendarId() const { return QSettings().value(key("id"), -1).toLongLong(); }
qint64 CalendarExport::personId() const { return QSettings().value(key("person"), 0).toLongLong(); }

void CalendarExport::setPersonId(qint64 id)
{
    QSettings().setValue(key("person"), id);
    syncNow(true);                         // nicht mehr gewählte Termine verschwinden aus dem Kalender
}

bool CalendarExport::withNotes() const { return QSettings().value(key("notes"), false).toBool(); }

bool CalendarExport::mine() const
{
    return enabled() && QSettings().value(key("owner")).toString() == Session::user();
}

void CalendarExport::setEnabled(bool on)
{
    QSettings s;
    s.setValue(key("enabled"), on);
    if (on) {
        s.setValue(key("owner"), Session::user());
        requestPermission();
        pickDefault();
        syncNow(true);
    } else {
        m_lastPlan.clear();
        m_count = 0;
#ifdef Q_OS_ANDROID
        QJniObject::callStaticMethod<void>(kClass, "clear", "(Landroid/content/Context;)V", context().object());
#endif
    }
}

void CalendarExport::pickDefault()
{
    if (calendarId() > 0 || !permissionGranted()) return;
    // Vorschlag: ein Kalender namens „ViviaParms“, sonst der Hauptkalender eines Kontos, sonst der erste
    const QVariantList cals = calendars();
    qint64 pick = -1;
    for (const QVariant &v : cals)
        if (v.toMap().value(QStringLiteral("name")).toString().compare(QLatin1String("ViviaParms"), Qt::CaseInsensitive) == 0) { pick = v.toMap().value(QStringLiteral("id")).toLongLong(); break; }
    for (const QVariant &v : cals)
        if (pick <= 0 && v.toMap().value(QStringLiteral("primary")).toBool()) pick = v.toMap().value(QStringLiteral("id")).toLongLong();
    if (pick <= 0 && !cals.isEmpty()) pick = cals.first().toMap().value(QStringLiteral("id")).toLongLong();
    if (pick > 0) QSettings().setValue(key("id"), pick);
}

void CalendarExport::setCalendarId(qint64 id)
{
    QSettings().setValue(key("id"), id);
    syncNow(true);
}

void CalendarExport::setWithNotes(bool on)
{
    QSettings().setValue(key("notes"), on);
    syncNow(true);
}

QVariantList CalendarExport::calendars() const
{
    QVariantList out;
#ifdef Q_OS_ANDROID
    const QString json = QJniObject::callStaticMethod<jstring>(kClass, "calendars",
        "(Landroid/content/Context;)Ljava/lang/String;", context().object()).toString();
    for (const QJsonValue &v : QJsonDocument::fromJson(json.toUtf8()).array()) {
        QVariantMap m = v.toObject().toVariantMap();
        const QString acc = m.value(QStringLiteral("account")).toString(), name = m.value(QStringLiteral("name")).toString();
        m.insert(QStringLiteral("id"), qint64(v.toObject().value(QStringLiteral("id")).toDouble()));
        m.insert(QStringLiteral("label"), acc.isEmpty() || acc == name ? name : QStringLiteral("%1 – %2").arg(name, acc));
        out << m;
    }
#else
    // am Computer (Test der Oberfläche): ein Beispielkalender
    out << QVariantMap{ { QStringLiteral("id"), 1 }, { QStringLiteral("name"), QStringLiteral("ViviaParms") },
                        { QStringLiteral("account"), QStringLiteral("erika.mustermann@gmail.com") },
                        { QStringLiteral("type"), QStringLiteral("com.google") }, { QStringLiteral("primary"), false },
                        { QStringLiteral("label"), QStringLiteral("ViviaParms – erika.mustermann@gmail.com") } };
#endif
    return out;
}

QVariantMap CalendarExport::status() const
{
#ifdef Q_OS_ANDROID
    const QString json = QJniObject::callStaticMethod<jstring>(kClass, "status",
        "(Landroid/content/Context;)Ljava/lang/String;", context().object()).toString();
    return QJsonDocument::fromJson(json.toUtf8()).object().toVariantMap();
#else
    if (!enabled()) return {};
    return QVariantMap{ { QStringLiteral("at"), double(QDateTime::currentMSecsSinceEpoch()) }, { QStringLiteral("total"), m_count },
                        { QStringLiteral("ins"), 0 }, { QStringLiteral("upd"), 0 }, { QStringLiteral("del"), 0 } };
#endif
}

bool CalendarExport::permissionGranted() const
{
#ifdef Q_OS_ANDROID
    return QJniObject::callStaticMethod<jboolean>(kClass, "permissionGranted", "(Landroid/content/Context;)Z", context().object());
#else
    return true;
#endif
}

void CalendarExport::requestPermission()
{
#ifdef Q_OS_ANDROID
    QJniObject::callStaticMethod<jboolean>(kClass, "ensurePermission", "(Landroid/content/Context;)Z", context().object());
#endif
}

void CalendarExport::syncSoon()
{
    if (mine()) m_debounce.start();
}

void CalendarExport::syncNow(bool force)
{
    m_debounce.stop();
    if (!mine() || !permissionGranted()) return;
    pickDefault();                         // z. B. gerade erst erlaubt
    if (calendarId() <= 0) return;
    const QList<Item> items = plan(QDateTime::currentDateTime(), withNotes(), personId());
    m_count = int(items.size());
    QJsonArray arr;
    for (const Item &it : items)
        arr << QJsonObject{ { QStringLiteral("key"), it.key }, { QStringLiteral("h"), it.hash },
                            { QStringLiteral("title"), it.title }, { QStringLiteral("loc"), it.location },
                            { QStringLiteral("desc"), it.description },
                            { QStringLiteral("start"), double(it.start.toMSecsSinceEpoch()) },
                            { QStringLiteral("end"), double(it.end.toMSecsSinceEpoch()) },
                            { QStringLiteral("allDay"), it.allDay },
                            { QStringLiteral("tz"), QString::fromUtf8(QTimeZone::systemTimeZoneId()) } };
    const QByteArray planJson = QJsonDocument(arr).toJson(QJsonDocument::Compact);
    if (!force && planJson == m_lastPlan && m_lastCalendar == calendarId()) return;   // nichts geändert
    m_lastPlan = planJson;
    m_lastCalendar = calendarId();
#ifdef Q_OS_ANDROID
    QJniObject::callStaticMethod<void>(kClass, "sync", "(Landroid/content/Context;JLjava/lang/String;)V",
        context().object(), jlong(calendarId()), QJniObject::fromString(QString::fromUtf8(planJson)).object<jstring>());
#endif
}
