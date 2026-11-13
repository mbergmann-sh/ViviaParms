// ViviaParms – Verknüpfungen im Startmenü und auf dem Desktop
function Component()
{
}

Component.prototype.createOperations = function()
{
    component.createOperations();
    if (systemInfo.productType !== "windows")
        return;
    component.addOperation("CreateShortcut", "@TargetDir@/ViviaParms.exe", "@StartMenuDir@/ViviaParms.lnk",
        "workingDirectory=@TargetDir@", "iconPath=@TargetDir@/ViviaParms.exe", "iconId=0",
        "description=Vitalwerte-Tagebuch / Vital signs diary");
    component.addOperation("CreateShortcut", "@TargetDir@/ViviaParms.exe", "@StartMenuDir@/ViviaParms - Demo.lnk", "--demo",
        "workingDirectory=@TargetDir@", "iconPath=@TargetDir@/ViviaParms.exe", "iconId=0",
        "description=Demo-Datenbank / Demo database");
    component.addOperation("CreateShortcut", "@TargetDir@/ViviaParms-Wartung.exe",
        "@StartMenuDir@/ViviaParms aktualisieren oder entfernen.lnk", "workingDirectory=@TargetDir@",
        "description=Update or uninstall ViviaParms");
    component.addOperation("CreateShortcut", "@TargetDir@/ViviaParms.exe", "@DesktopDir@/ViviaParms.lnk",
        "workingDirectory=@TargetDir@", "iconPath=@TargetDir@/ViviaParms.exe", "iconId=0");
}
