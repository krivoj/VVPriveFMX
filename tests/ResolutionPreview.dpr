program ResolutionPreview;

uses
  System.SysUtils, System.Classes, System.UITypes, System.IOUtils,
  FMX.Forms, FMX.Types, FMX.Controls, FMX.Controls3D, FMX.Viewport3D,
  Unit1 in '../Unit1.pas', u_Dialogs, u_GirlStorage, u_ActivitiesDialog;

type
  TPreviewForm = class(TForm1)
  private
    procedure PreviewKey(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
  public
    constructor Create(AOwner: TComponent); override;
  end;

constructor TPreviewForm.Create(AOwner: TComponent);
var
  Storage: TGirlStorage;
  D: TGirlData;
  I: Integer;
begin
  inherited CreateNew(AOwner);
  Form1 := Self;
  Caption := 'VVPrive resolution preview - F1/F2/F3 resize - F5 input - F6 duration - F7 activities';
  SetBounds(20, 20, 1040, 810);
  Fill.Color := TAlphaColors.Dimgray;
  Viewport3D1 := TViewport3D.Create(Self);
  Viewport3D1.Parent := Self;
  Viewport3D1.Align := TAlignLayout.Client;
  Viewport3D1.Color := TAlphaColors.Darkgray;
  Camera1 := TCamera.Create(Viewport3D1);
  Viewport3D1.Camera := Camera1;
  Viewport3D1.UsingDesignCamera := False;
  Viewport3D1.OnMouseDown := Viewport3D1MouseDown;
  TimerPrive := TTimer.Create(Self);
  TimerPrive.Enabled := False;
  TimerPrive.OnTimer := TimerPriveTimer;
  OnResize := FormResize;
  OnKeyDown := PreviewKey;
  // Isolated synthetic data: preview never reads production saves or licensing.
  DirSaves := ExtractFilePath(ParamStr(0)) + 'preview-data\';
  ForceDirectories(DirSaves);
  Storage := TGirlStorage.Create;
  try
    D.Prive := -1;
    D.Slot := -1;
    D.Start := 0;
    SetLength(D.Activities, 0);
    for I := 1 to 40 do
      Storage.SaveGirl(Format('TEST %.2d', [I]), D);
  finally
    Storage.Free;
  end;
  MessageDialog := TMessageDialog.Create(Self, Self);
  TFile.WriteAllText(ExtractFilePath(ParamStr(0)) + 'preview-status.txt', 'Building dashboard');
  ContinueApplication;
  TFile.WriteAllText(ExtractFilePath(ParamStr(0)) + 'preview-status.txt', 'Dashboard ready');
end;

procedure TPreviewForm.PreviewKey(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
var
  Duration: TSpinBoxDialog;
begin
  case Key of
    vkF1: begin ClientWidth := 640; ClientHeight := 480; end;
    vkF2: begin ClientWidth := 1024; ClientHeight := 768; end;
    vkF3: begin ClientWidth := 1280; ClientHeight := 720; end;
    vkF5: InputGirl.Show('Nome di prova', nil, nil);
    vkF6: begin
      Duration := TSpinBoxDialog.Create(Self, Self);
      Duration.Show('Durata in minuti', nil, nil);
    end;
    vkF7: AActivitiesDialog.ShowCentered('TEST 01');
  end;
end;

var
  Preview: TPreviewForm;
begin
  try
    Application.Initialize;
    Application.CreateForm(TPreviewForm, Preview);
    Application.Run;
  except
    on E: Exception do
      TFile.WriteAllText(ExtractFilePath(ParamStr(0)) + 'preview-status.txt',
        E.ClassName + ': ' + E.Message);
  end;
end.
