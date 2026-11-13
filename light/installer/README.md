# ViviaParms light – Installer (Inno Setup und Qt Installer Framework)

Ein Build von `light/ViviaParmsLight.pro` bereitet alles automatisch vor – gesteuert von
`light_deploy.pri` (unter Windows genauso wie bei ViviaParms, siehe `installer/README.md`):

| Schritt | Windows | Linux | macOS |
|---|---|---|---|
| nach **jedem** Build (auch Debug) | `windeployqt` neben `ViviaParmsLight.exe` – das Programm startet direkt aus dem Build-Ordner | – | – |
| Installationsverzeichnis (nur Release) | `light/installer/install_src`: Programm, DLLs, `docs/` (PDF + CHM), Lizenz, README | – | – |
| Programm + Qt-Bibliotheken ins IFW-Paket `qtifw/packages/de.mbergmann.viviaparms.light/data` | `windeployqt` | `linux_deploy.sh` (per `ldd`: `lib/`, `plugins/`, `qt.conf`, Startskript `ViviaParmsLight.sh`) | `macdeployqt` (`ViviaParmsLight.app`) |
| Handbücher ins Paket `…light.docs/data/docs` | PDF + CHM | PDF | PDF |
| **Inno Setup** (falls `ISCC.exe` gefunden) | `Output/ViviaParms-light-<Version>-Setup.exe` | – | – |
| **Qt Installer Framework** (falls `binarycreator` gefunden) | `Output/ViviaParms-light-<Version>-Setup-IFW.exe` | `Output/ViviaParms-light-<Version>-Setup.run` | `Output/ViviaParms-light-<Version>-Setup.dmg` |

Installationsverzeichnis und Installer entstehen **nur beim Release-Build** (Qt Creator: Build-Konfiguration
„Release“). Beim qmake-Lauf meldet das Projekt, welche Werkzeuge es gefunden hat
(„Inno Setup gefunden …“, „Qt Installer Framework gefunden …“) – in Qt Creator unter *Allgemeine Ausgaben*.

### Inno Setup (`ViviaParmsLight.iss`)

Wie bei ViviaParms: Sprachauswahl Deutsch/Englisch, Lizenz und Haftungshinweis, Zielordner wählbar
(Vorgabe **`C:\VPlight`**), Komponenten Programm/Handbücher, Startmenü (ViviaParms light, Demo,
Benutzerhandbuch, Erste Schritte, Deinstallieren), Desktop-Verknüpfung, Aktualisieren an Ort und Stelle
oder Deinstallieren beim erneuten Start. Eigene AppId – ViviaParms und ViviaParms light lassen sich
nebeneinander installieren und unabhängig entfernen. Daten und Einstellungen bleiben bei der
Deinstallation erhalten; nur die Demo-Datenbank wird entfernt. Grüne Assistentenbilder:
`wizard_image*.bmp`, `wizard_small*.bmp`; Lizenztexte `license_de.txt`, `license_en.txt`.

`ViviaParmsLight.iss` wird von qmake aus `ViviaParmsLight.iss.in` erzeugt (Versionsnummer) –
Änderungen bitte in der `.in`-Datei. Von Hand übersetzen: `ISCC.exe ViviaParmsLight.iss` (nach einem
Release-Build, der `install_src` befüllt hat).

Installationsordner (änderbar im Installer):

* Windows: **`C:\VPlight`** – Startmenü und Desktop-Verknüpfung
* macOS: `/Applications/VPlight`
* Linux: `~/VPlight` – Eintrag im Anwendungsmenü (`~/.local/share/applications`)

Komponenten: *Programm* (fest) und *Handbücher* (abwählbar). Deinstallieren und Aktualisieren über
das mitinstallierte Wartungsprogramm (`maintenancetool`). Daten und Einstellungen liegen getrennt
von ViviaParms im Benutzerprofil (`ViviaParmsLight`) und bleiben bei Deinstallation und Update erhalten.

## Werkzeuge

* **Inno Setup 6.3 oder neuer** – https://jrsoftware.org/isinfo.php. Gesucht in
  `C:\Program Files (x86)\Inno Setup 6`, `C:\Program Files\Inno Setup 6` und
  `%LOCALAPPDATA%\Programs\Inno Setup 6`; sonst Umgebungsvariable `VP_ISCC` auf `ISCC.exe` setzen.
* **Qt Installer Framework 4.x** – im Qt Maintenance Tool unter *Developer and Designer Tools*.
  Gesucht über `VP_BINARYCREATOR` (Pfad zur Datei), `QTIFWDIR` und
  `<Qt>/Tools/QtInstallerFramework/<Version>/bin`. Werkzeuge werden beim **qmake-Lauf** gesucht.
* Linux: `ldd` und `patchelf` sind nicht nötig; `linux_deploy.sh` kopiert die Qt-Bibliotheken und setzt
  `LD_LIBRARY_PATH` im Startskript.
* macOS: `hdiutil` (gehört zum System) für das Disk-Image.

Installer nicht bei jedem Release-Build erzeugen: `qmake CONFIG+=vp_no_installer`. Alle Qt-Teile
mitliefern (ohne die schlanke Auswahl): `qmake CONFIG+=vp_full_deploy`. IFW von Hand:

```sh
binarycreator --offline-only -c qtifw/config/config.xml -p qtifw/packages Output/ViviaParms-light-Setup.run
```

Die Versionsnummer kommt aus `version.pri`; qmake schreibt sie in `config.xml` und die
`package.xml`-Dateien (Vorlagen: `*.in`). **Änderungen bitte in den `.in`-Dateien vornehmen.**

## Android (Tablet und Smartphone)

`light/mobile/ViviaParmsLightMobile.pro` baut die App mit dem Paketnamen
`de.mbergmann.viviaparms.light` (grünes Symbol). Die Android-Dateien in `light/mobile/android` erzeugt
`tools/make_light_android.py` aus `mobile/android`. Signieren wie bei der großen App – Keystore und
Passwörter gehören **nicht** ins Projekt.

## Getestet

* Linux: IFW-Installer mit IFW 4.8.1 erzeugt und installiert (Programm, Handbücher, Menüeintrag, Deinstallation).
* Windows: `ViviaParmsLight.iss` mit Inno Setup 6.3.1 übersetzt (Ergebnis `ViviaParms-light-<Version>-Setup.exe`);
  die von qmake erzeugten Windows-Makefiles enthalten alle Schritte (windeployqt, `install_src`, ISCC, binarycreator).
  Ein echter Windows-Build samt Installation steht noch aus.
* macOS: vorbereitet, nicht geprüft.

## Debian-Paket (.deb)

Für Debian, Ubuntu und Derivate gibt es zusätzlich ein natives Paket `viviaparms-light_<V>-1~<Distribution>_<Arch>.deb`,
gebaut mit dem Qt der Distribution: `installer/debian/build_deb.sh light` (im Projektordner).
Voraussetzungen und Ablauf: `installer/debian/README.md`.

