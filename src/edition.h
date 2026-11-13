// ViviaParms – Ausgabe (Edition) des Programms: ViviaParms oder ViviaParms light
//
// ViviaParms light (qmake-Projekte unter light/, Schalter VP_LIGHT) baut auf demselben Code und
// derselben Datenbank auf, zeigt aber nur einen Teil der Funktionen – für eine Person, mit
// vereinfachter Oberfläche. Die Datenbank bleibt vollständig kompatibel: Eine Light-Datenbank lässt
// sich mit ViviaParms öffnen (Umstieg) und umgekehrt.
// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
#pragma once

#include <QString>

namespace Edition {

constexpr bool light()
{
#ifdef VP_LIGHT
    return true;
#else
    return false;
#endif
}

// Name für Fenstertitel, Meldungen und Berichte
inline QString appName()
{
    return light() ? QStringLiteral("ViviaParms light") : QStringLiteral("ViviaParms");
}

// Name für Einstellungen und Datenordner (getrennt, damit beide Ausgaben nebeneinander laufen)
inline QString settingsName()
{
    return light() ? QStringLiteral("ViviaParmsLight") : QStringLiteral("ViviaParms");
}

} // namespace Edition
