// VitaParms mobile – Anpassung an die Systemleisten (siehe systemui.h)
// SPDX-License-Identifier: MIT
#include "systemui.h"

#include <QMetaMethod>
#include <QStringList>

#ifdef Q_OS_ANDROID
#include <QCoreApplication>
#include <QJniObject>
#endif

SystemUi::SystemUi(QObject *parent)
    : QObject(parent)
{
    const QStringList f = qEnvironmentVariable("VP_AUTOPILOT_SAFE").split(QLatin1Char(','));
    if (f.size() == 4) {
        m_fake = QMargins(f[3].toInt(), f[0].toInt(), f[1].toInt(), f[2].toInt());
        m_hasFake = true;
        m_margins = m_fake;
    }
}

bool SystemUi::windowPads() const
{
    if (m_hasFake) return false;          // vorgetäuschte Ränder: Qt weiß nichts davon, QML polstert
#if QT_VERSION >= QT_VERSION_CHECK(6, 9, 0)
    return true;
#else
    return false;
#endif
}

// Ab Qt 6.9 polstert ApplicationWindow den Inhalt selbst (windowPads); die Ränder werden dann nicht
// abgefragt. 0.31.2 fragte QWindow::safeAreaMargins() bei jeder Änderung ab – beim Drehen des
// Tablets kam diese Meldung mitten im Größenwechsel von Android, die Abfrage blockierte, und die
// Oberfläche blieb stehen bzw. schwarz. Abgefragt wird jetzt nur noch, wenn Qt nicht selbst polstert
// (ältere Qt-Versionen ohne Android), und nie während der Meldung, sondern danach (queued).
void SystemUi::attach(QWindow *window)
{
    m_window = window;
#if QT_VERSION >= QT_VERSION_CHECK(6, 9, 0)
    if (window && !m_hasFake && !windowPads())
        connect(window, &QWindow::safeAreaMarginsChanged, this, &SystemUi::update, Qt::QueuedConnection);
#endif
    update();
}

void SystemUi::update()
{
    QMargins m = m_fake;
#if QT_VERSION >= QT_VERSION_CHECK(6, 9, 0)
    if (!m_hasFake && !windowPads() && m_window) m = m_window->safeAreaMargins();
#endif
    if (m == m_margins) return;
    m_margins = m;
    emit marginsChanged();
}

void SystemUi::setLightBars(bool light)
{
    if (m_barsSet && light == m_lightBars) return;   // nur bei echter Änderung (hell/dunkel)
    m_barsSet = true;
    m_lightBars = light;
#ifdef Q_OS_ANDROID
    const QJniObject activity(QNativeInterface::QAndroidApplication::context());
    QJniObject::callStaticMethod<void>("de/mbergmann/vitaparms/SystemBars", "setLight",
        "(Landroid/content/Context;Z)V", activity.object(), jboolean(light));
#else
    Q_UNUSED(light)
#endif
}

int SystemUi::signalArity(QObject *obj, const QString &name) const
{
    if (!obj) return -1;
    const QMetaObject *mo = obj->metaObject();
    for (int i = 0; i < mo->methodCount(); ++i) {
        const QMetaMethod m = mo->method(i);
        if (m.methodType() == QMetaMethod::Signal && QString::fromLatin1(m.name()) == name) return m.parameterCount();
    }
    return -1;
}
