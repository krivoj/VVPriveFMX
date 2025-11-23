program VVprive;

{$R 'images.res' 'images.rc'}

uses
  System.StartUpCopy,
  FMX.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  u_PrivGrid in 'u_PrivGrid.pas',
  u_GirlGrid in 'u_GirlGrid.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
