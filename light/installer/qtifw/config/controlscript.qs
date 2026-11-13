// ViviaParms light – Steuerskript für den Qt-Installer-Framework-Installer (Windows, Linux, macOS)
//
// * Zielordner: Windows C:\VPlight, macOS /Applications/VPlight, Linux ~/VPlight (änderbar)
// * Programm nach der Installation starten: je System die passende Datei
// * Aktualisieren mit einem neuen Offline-Installer: Ist ViviaParms light schon installiert, wird die
//   alte Version vor der Installation über ihr Wartungsprogramm entfernt ("purge") und die neue in
//   denselben Ordner installiert. Datenbanken und Einstellungen liegen im Benutzerprofil und
//   bleiben dabei erhalten.

function Controller()
{
    var os = systemInfo.productType;
    if (installer.isInstaller()) {
        if (os === "windows")
            installer.setValue("TargetDir", "C:/VPlight");
        else if (os === "osx" || os === "macos")
            installer.setValue("TargetDir", "/Applications/VPlight");
    }
    if (os === "windows")
        installer.setValue("RunProgram", "@TargetDir@/ViviaParmsLight.exe");
    else if (os === "osx" || os === "macos")
        installer.setValue("RunProgram", "@TargetDir@/ViviaParmsLight.app/Contents/MacOS/ViviaParmsLight");
    else
        installer.setValue("RunProgram", "@TargetDir@/ViviaParmsLight.sh");
}

function maintenanceTool()
{
    var os = systemInfo.productType;
    if (os === "windows") return "ViviaParmsLight-Wartung.exe";
    if (os === "osx" || os === "macos") return "ViviaParmsLight-Wartung.app/Contents/MacOS/ViviaParmsLight-Wartung";
    return "ViviaParmsLight-Wartung";
}

// Vorhandene Installation im (Vorgabe-)Zielordner suchen
function previousLocation()
{
    var dir = installer.value("TargetDir");
    if (installer.fileExists(dir + "/" + maintenanceTool()))
        return dir;
    return "";
}

Controller.prototype.IntroductionPageCallback = function()
{
    if (!installer.isInstaller())
        return;
    var dir = previousLocation();
    if (dir === "")
        return;
    var answer = QMessageBox.question("viviaparmslight.update",
        "ViviaParms light",
        "ViviaParms light ist bereits in " + dir + " installiert.\n"
        + "Die vorhandene Version wird jetzt entfernt und anschließend die neue installiert. "
        + "Ihre Daten und Einstellungen bleiben erhalten.\n\n"
        + "ViviaParms light is already installed in " + dir + ".\n"
        + "The existing version will now be removed and the new one installed afterwards. "
        + "Your data and settings are kept.",
        QMessageBox.Ok | QMessageBox.Cancel);
    if (answer !== QMessageBox.Ok) {
        installer.setCanceled();
        return;
    }
    installer.execute(dir + "/" + maintenanceTool(), ["purge", "-c"]);
    installer.setValue("TargetDir", dir);
}
