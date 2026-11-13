// ViviaParms – Handbücher und „Erste Schritte“ im Startmenü
function Component()
{
}

Component.prototype.createOperations = function()
{
    component.createOperations();
    if (systemInfo.productType !== "windows")
        return;
    component.addOperation("CreateShortcut", "@TargetDir@/docs/ViviaParms-Handbuch.chm",
        "@StartMenuDir@/ViviaParms-Handbuch (Deutsch).lnk", "workingDirectory=@TargetDir@/docs");
    component.addOperation("CreateShortcut", "@TargetDir@/docs/ViviaParms-Manual.chm",
        "@StartMenuDir@/ViviaParms User Manual (English).lnk", "workingDirectory=@TargetDir@/docs");
    component.addOperation("CreateShortcut", "@TargetDir@/docs/ViviaParms-ErsteSchritte.chm",
        "@StartMenuDir@/ViviaParms – Erste Schritte (Deutsch).lnk", "workingDirectory=@TargetDir@/docs");
    component.addOperation("CreateShortcut", "@TargetDir@/docs/ViviaParms-GettingStarted.chm",
        "@StartMenuDir@/ViviaParms – Getting Started (English).lnk", "workingDirectory=@TargetDir@/docs");
}
