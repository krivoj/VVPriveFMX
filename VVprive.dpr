program VVprive;

{$R 'images.res' 'images.rc'}

uses
  EMemLeaks,
  EResLeaks,
  EDialogWinAPIMSClassic,
  EDialogWinAPIEurekaLogDetailed,
  EDialogWinAPIStepsToReproduce,
  EDebugExports,
  EFixSafeCallException,
  EMapWin32,
  EAppVCL,
  ExceptionLog7,
  System.StartUpCopy,
  FMX.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  u_PrivGrid in 'u_PrivGrid.pas',
  u_GirlGrid in 'u_GirlGrid.pas',
  u_GirlStorage in 'u_GirlStorage.pas',
  u_Dialogs in 'u_Dialogs.pas',
  u_ActivitiesDialog in 'u_ActivitiesDialog.pas',
  u_PrivStorage in 'u_PrivStorage.pas',
  u_lang in 'u_lang.pas',
  u_Serial in 'u_Serial.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
