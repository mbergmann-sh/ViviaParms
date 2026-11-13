// ViviaParms – Umzug von VitaParms (siehe legacymigration.h)
// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
#include "legacymigration.h"

#include <QCoreApplication>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QSettings>
#include <QStandardPaths>

#include "qtcompat.h"

namespace LegacyMigration {

namespace {

QString tr(const char *s) { return QCoreApplication::translate("LegacyMigration", s); }

// vitaparms.sqlite, vitaparms.sqlite.keys, vitaparms.sqlite-wal … → viviaparms.sqlite…
QString newFileName(const QString &name)
{
    static const QString oldBase = QStringLiteral("vitaparms");
    if (name.startsWith(oldBase)) return QStringLiteral("viviaparms") + name.mid(oldBase.size());
    return name;
}

bool copyTree(const QString &from, const QString &to, QString *error)
{
    bool ok = true;
    QDir src(from);
    QDirIterator it(from, QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden, QDirIterator::Subdirectories);
    QDir().mkpath(to);
    while (it.hasNext()) {
        const QString p = it.next();
        const QFileInfo fi(p);
        QString rel = src.relativeFilePath(p);
        const int slash = rel.lastIndexOf(QLatin1Char('/'));
        rel = rel.left(slash + 1) + newFileName(rel.mid(slash + 1));
        const QString target = QDir(to).filePath(rel);
        if (fi.isDir()) { QDir().mkpath(target); continue; }
        if (QFileInfo::exists(target)) continue;               // nie überschreiben
        QDir().mkpath(QFileInfo(target).absolutePath());
        if (!QFile::copy(p, target)) {
            ok = false;
            if (error && error->isEmpty()) *error = tr("Datei konnte nicht kopiert werden: %1").arg(QDir::toNativeSeparators(p));
        } else {
            QFile(target).setPermissions(QFile(p).permissions());
        }
    }
    return ok;
}

QString rewritePath(QString v, const QString &oldDir, const QString &newDir)
{
    const QString o = QDir::cleanPath(oldDir), n = QDir::cleanPath(newDir);
    const QString c = QDir::cleanPath(QDir::fromNativeSeparators(v));
    if (c == o) return n;
    if (!c.startsWith(o + QLatin1Char('/'))) return v;
    QString rel = c.mid(o.size() + 1);
    const int slash = rel.lastIndexOf(QLatin1Char('/'));
    rel = rel.left(slash + 1) + newFileName(rel.mid(slash + 1));
    return QDir::toNativeSeparators(n + QLatin1Char('/') + rel);
}

} // namespace

QString legacyDataDir(const QString &legacyOrg, const QString &legacyApp)
{
    // <Programmdaten>/<Organisation>/<Programm> – Organisation und Programm durch die alten ersetzen
    // (nicht mit QDir::cdUp: das schlägt fehl, solange der neue Ordner noch nicht existiert)
    const QString base = QDir::cleanPath(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + QStringLiteral("/../.."));
    const QString p = base + QLatin1Char('/') + legacyOrg + QLatin1Char('/') + legacyApp;
    return QFileInfo(p).isDir() ? p : QString();
}

Result migrate(const QString &legacyOrg, const QString &legacyApp)
{
    Result r;
#if defined(Q_OS_ANDROID) || defined(Q_OS_IOS)
    Q_UNUSED(legacyOrg) Q_UNUSED(legacyApp)
    return r;
#else
    if (qEnvironmentVariableIsSet("VP_NO_LEGACY_MIGRATION")) return r;
    const QString newDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    const QString oldDir = legacyDataDir(legacyOrg, legacyApp);
    r.newDataDir = newDir;
    r.oldDataDir = oldDir;

    QSettings now;
    const bool haveSettings = !now.allKeys().isEmpty();
    const bool haveData = QFileInfo::exists(QDir(newDir).filePath(QStringLiteral("viviaparms.sqlite")));

    // 1. Datenordner (nur wenn ViviaParms noch keine Datenbank hat)
    if (!haveData && !oldDir.isEmpty() && QDir::cleanPath(oldDir) != QDir::cleanPath(newDir)) {
        QString err;
        copyTree(oldDir, newDir, &err);
        r.data = true;
        r.error = err;
    }
    // 2. Einstellungen (nur wenn ViviaParms noch keine hat)
    if (!haveSettings) {
        QSettings old(legacyOrg, legacyApp);
        const QStringList keys = old.allKeys();
        if (!keys.isEmpty()) {
            for (const QString &k : keys) {
                QVariant v = old.value(k);
                if (!oldDir.isEmpty() && vpTypeId(v) == QMetaType::QString)
                    v = rewritePath(v.toString(), oldDir, newDir);
                now.setValue(k, v);
            }
            now.setValue(QStringLiteral("migration/fromVitaParms"), true);
            now.sync();
            r.settings = true;
        }
    }
    return r;
#endif
}

QString message(const Result &r)
{
    QString t = tr("<p>VitaParms heißt jetzt <b>ViviaParms</b>.</p>");
    if (r.data)
        t += tr("<p>Ihre Daten wurden übernommen. Der bisherige Ordner bleibt unverändert als Sicherung erhalten:"
                "<br><tt>%1</tt></p><p>Sobald ViviaParms wie gewohnt läuft, können Sie ihn löschen.</p>")
                 .arg(QDir::toNativeSeparators(r.oldDataDir).toHtmlEscaped());
    if (r.settings) t += tr("<p>Die Einstellungen wurden ebenfalls übernommen.</p>");
    if (!r.error.isEmpty()) t += QStringLiteral("<p><b>%1</b></p>").arg(r.error.toHtmlEscaped());
    return t;
}

} // namespace LegacyMigration
