// ViviaParms light – Verknüpfungen: Windows (Startmenü, Desktop), Linux (Anwendungsmenü)
function Component()
{
}

Component.prototype.createOperations = function()
{
    component.createOperations();
    var os = systemInfo.productType;
    if (os === "windows") {
        component.addOperation("CreateShortcut", "@TargetDir@/ViviaParmsLight.exe", "@StartMenuDir@/ViviaParms light.lnk",
            "workingDirectory=@TargetDir@", "iconPath=@TargetDir@/ViviaParmsLight.exe", "iconId=0",
            "description=Das einfache Vitalwerte-Tagebuch / The simple vital signs diary");
        component.addOperation("CreateShortcut", "@TargetDir@/ViviaParmsLight.exe", "@StartMenuDir@/ViviaParms light - Demo.lnk", "--demo",
            "workingDirectory=@TargetDir@", "iconPath=@TargetDir@/ViviaParmsLight.exe", "iconId=0",
            "description=Demo-Datenbank / Demo database");
        component.addOperation("CreateShortcut", "@TargetDir@/ViviaParmsLight-Wartung.exe",
            "@StartMenuDir@/ViviaParms light aktualisieren oder entfernen.lnk", "workingDirectory=@TargetDir@",
            "description=Update or uninstall ViviaParms light");
        component.addOperation("CreateShortcut", "@TargetDir@/ViviaParmsLight.exe", "@DesktopDir@/ViviaParms light.lnk",
            "workingDirectory=@TargetDir@", "iconPath=@TargetDir@/ViviaParmsLight.exe", "iconId=0");
    } else if (os !== "osx" && os !== "macos") {
        // Linux: Einträge im Anwendungsmenü (freedesktop.org); Ordner ggf. erst anlegen
        if (!installer.fileExists(installer.value("HomeDir") + "/.local/share/applications"))
            component.addOperation("Mkdir", "@HomeDir@/.local/share/applications");
        component.addOperation("CreateDesktopEntry", "@HomeDir@/.local/share/applications/viviaparms-light.desktop",
            "Type=Application\nName=ViviaParms light\nGenericName=Vitalwerte-Tagebuch\nComment=Das einfache Vitalwerte-Tagebuch\n"
            + "Exec=\"@TargetDir@/ViviaParmsLight.sh\"\nIcon=@TargetDir@/viviaparms-light.png\nTerminal=false\n"
            + "Categories=Office;MedicalSoftware;\nStartupWMClass=ViviaParmsLight");
        component.addOperation("CreateDesktopEntry", "@HomeDir@/.local/share/applications/viviaparms-light-demo.desktop",
            "Type=Application\nName=ViviaParms light – Demo\nExec=\"@TargetDir@/ViviaParmsLight.sh\" --demo\n"
            + "Icon=@TargetDir@/viviaparms-light.png\nTerminal=false\nCategories=Office;MedicalSoftware;");
    }
}
