// ViviaParms – Übersetzungen (Quellsprache Deutsch, Übersetzung Englisch)
// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
#pragma once

#include <QString>

class QCoreApplication;

namespace I18n {

// Ermittelt die effektive Sprache ("de"/"en") aus der Einstellung und lädt
// die Übersetzungen (ViviaParms + Qt-eigene Dialoge). Vor dem ersten Fenster aufrufen.
QString install(QCoreApplication &app);
QString effectiveLanguage();
void restartApplication();

} // namespace I18n
