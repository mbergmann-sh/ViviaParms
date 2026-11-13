; ===========================================================================
;  ViviaParms light – Windows-Installer, -Updater und -Deinstaller (Inno Setup 6.1 oder neuer)
;
;  ERZEUGT von qmake aus light/installer/ViviaParmsLight.iss.in – Änderungen bitte dort vornehmen.
;  Die Versionsnummer kommt automatisch aus version.pri.
;
;  Voraussetzung: ein Release-Build von light/ViviaParmsLight.pro unter Windows hat das
;  Installationsverzeichnis light\installer\install_src befüllt (light_deploy.pri).
;  Übersetzen: ISCC.exe ViviaParmsLight.iss  (oder in Inno Setup öffnen und F9)
;  Ergebnis:   light\installer\Output\ViviaParms-light-<Version>-Setup.exe
; ===========================================================================

#define AppName      "ViviaParms light"
#define AppVersion   "0.32.0"
#define AppPublisher "Michael Bergmann"
#define AppExe       "ViviaParmsLight.exe"
#define AppGuid      "0AD93A66-2F43-489D-A041-4547ACAED549"   ; eigene AppId: unabhängig von ViviaParms

[Setup]
AppId={{{#AppGuid}}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppCopyright=Copyright (c) 2026 Michael Bergmann
VersionInfoVersion={#AppVersion}
VersionInfoDescription={#AppName} Setup
; Zielordner (Abfrage im Assistenten, Vorgabe C:\VPlight); bei Updates der bisherige Ordner
DefaultDirName=C:\VPlight
DisableDirPage=no
UsePreviousAppDir=yes
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
SourceDir=install_src
OutputDir=..\Output
OutputBaseFilename=ViviaParms-light-{#AppVersion}-Setup
SetupIconFile=..\..\resources\viviaparms-light.ico
WizardStyle=modern
DisableWelcomePage=no
WizardImageFile=..\wizard_image.bmp,..\wizard_image_200.bmp
WizardSmallImageFile=..\wizard_small.bmp,..\wizard_small_200.bmp
ShowLanguageDialog=yes
Compression=lzma2/ultra64
LZMAUseSeparateProcess=yes
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
PrivilegesRequired=admin
CloseApplications=yes
RestartApplications=no
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName} {#AppVersion}
SetupLogging=yes

[Languages]
Name: "de"; MessagesFile: "compiler:Languages\German.isl"; LicenseFile: "..\license_de.txt"
Name: "en"; MessagesFile: "compiler:Default.isl"; LicenseFile: "..\license_en.txt"

[CustomMessages]
de.TypeFull=Vollständige Installation
en.TypeFull=Full installation
de.TypeCustom=Benutzerdefinierte Installation
en.TypeCustom=Custom installation
de.CompMain=ViviaParms light (Programm und Qt-Bibliotheken)
en.CompMain=ViviaParms light (program and Qt libraries)
de.CompDocs=Handbücher Deutsch und Englisch (PDF und Windows-Hilfe, für F1)
en.CompDocs=User manuals in English and German (PDF and Windows Help, for F1)
de.TaskDesktop=Verknüpfung auf dem &Desktop anlegen
en.TaskDesktop=Create a &desktop shortcut
de.DemoShortcut=ViviaParms light Demo
en.DemoShortcut=ViviaParms light Demo
de.ManualShortcut=ViviaParms light – Benutzerhandbuch
en.ManualShortcut=ViviaParms light User Guide
de.GuideShortcut=ViviaParms light – Erste Schritte
en.GuideShortcut=ViviaParms light – Getting Started
de.LaunchDemo=Demo-Datenbank zum Ausprobieren öffnen
en.LaunchDemo=Open the demo database to try ViviaParms light
de.ExistingTitle=ViviaParms light ist bereits installiert
en.ExistingTitle=ViviaParms light is already installed
de.ExistingText=Installiert ist ViviaParms light %1 in %2.%n%nDieses Setup enthält Version %3. Beim Aktualisieren bleiben Ihre Datenbanken und Einstellungen erhalten.
en.ExistingText=ViviaParms light %1 is installed in %2.%n%nThis setup contains version %3. Updating keeps your databases and settings.
de.BtnUpdate=&Aktualisieren bzw. neu installieren
en.BtnUpdate=&Update or reinstall
de.BtnRemove=&Deinstallieren
en.BtnRemove=&Uninstall
de.RemoveFailed=Das Deinstallationsprogramm konnte nicht gestartet werden:%n%1
en.RemoveFailed=The uninstaller could not be started:%n%1
de.DataKept=ViviaParms light wurde entfernt. Ihre Datenbanken, Schlüsseldateien und Einstellungen sind erhalten geblieben.
en.DataKept=ViviaParms light has been removed. Your databases, key files and settings have been kept.

[Types]
Name: "full";   Description: "{cm:TypeFull}"
Name: "custom"; Description: "{cm:TypeCustom}"; Flags: iscustom

[Components]
Name: "main"; Description: "{cm:CompMain}"; Types: full custom; Flags: fixed
Name: "docs"; Description: "{cm:CompDocs}"; Types: full

[Tasks]
Name: "desktopicon"; Description: "{cm:TaskDesktop}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "*";      DestDir: "{app}";      Excludes: "\docs\*"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: main
Source: "docs\*"; DestDir: "{app}\docs"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: docs

[InstallDelete]
; Reste einer Vorversion, deren Dateinamen sich geändert haben könnten
Type: filesandordirs; Name: "{app}\docs"

[Icons]
Name: "{group}\{#AppName}";          Filename: "{app}\{#AppExe}"; WorkingDir: "{app}"
Name: "{group}\{cm:DemoShortcut}";   Filename: "{app}\{#AppExe}"; Parameters: "--demo"; WorkingDir: "{app}"; IconFilename: "{app}\{#AppExe}"
Name: "{group}\{cm:ManualShortcut}"; Filename: "{app}\docs\ViviaParms-light-Benutzerhandbuch.chm"; Languages: de; Components: docs
Name: "{group}\{cm:ManualShortcut}"; Filename: "{app}\docs\ViviaParms-light-UserGuide.chm"; Languages: en; Components: docs
Name: "{group}\{cm:GuideShortcut}";  Filename: "{app}\docs\ViviaParms-light-ErsteSchritte.chm";  Languages: de; Components: docs
Name: "{group}\{cm:GuideShortcut}";  Filename: "{app}\docs\ViviaParms-light-GettingStarted.chm"; Languages: en; Components: docs
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}";    Filename: "{app}\{#AppExe}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
Filename: "{app}\{#AppExe}"; Parameters: "--demo"; Description: "{cm:LaunchDemo}"; Flags: nowait postinstall skipifsilent unchecked

[UninstallDelete]
; Nur die jedes Mal neu erzeugte Demo – NIEMALS die eigenen Datenbanken
Type: filesandordirs; Name: "{localappdata}\ViviaParms\ViviaParmsLight-Demo"

[Code]
const
  UninstKey = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{{#AppGuid}}_is1';

{ Vorhandene Installation suchen (64-Bit- und 32-Bit-Registrierung, Rechner und Benutzer) }
function FindInstalled(var Version, Location, Uninstaller: String): Boolean;
var
  Roots: array[0..2] of Integer;
  I: Integer;
begin
  Result := False;
  Roots[0] := HKLM64; Roots[1] := HKLM32; Roots[2] := HKCU;
  for I := 0 to 2 do
    if RegQueryStringValue(Roots[I], UninstKey, 'UninstallString', Uninstaller) then
    begin
      RegQueryStringValue(Roots[I], UninstKey, 'DisplayVersion', Version);
      RegQueryStringValue(Roots[I], UninstKey, 'InstallLocation', Location);
      Result := True;
      Exit;
    end;
end;

{ Beim Start: aktualisieren (gleiche AppId → Update an Ort und Stelle) oder deinstallieren }
function InitializeSetup(): Boolean;
var
  Version, Location, Uninstaller: String;
  Answer, Code: Integer;
begin
  Result := True;
  if WizardSilent() or not FindInstalled(Version, Location, Uninstaller) then
    Exit;
  Answer := TaskDialogMsgBox(CustomMessage('ExistingTitle'),
    FmtMessage(CustomMessage('ExistingText'), [Version, RemoveBackslash(Location), '{#AppVersion}']),
    mbConfirmation, MB_YESNOCANCEL, [CustomMessage('BtnUpdate'), CustomMessage('BtnRemove')], 0);
  case Answer of
    IDYES: Result := True;
    IDNO:
      begin
        Result := False;
        if not Exec(RemoveQuotes(Uninstaller), '', '', SW_SHOWNORMAL, ewWaitUntilTerminated, Code) then
          MsgBox(FmtMessage(CustomMessage('RemoveFailed'), [SysErrorMessage(Code)]), mbError, MB_OK);
      end;
  else
    Result := False;
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if (CurUninstallStep = usPostUninstall) and not UninstallSilent() then
    MsgBox(CustomMessage('DataKept'), mbInformation, MB_OK);
end;

