unit Unit1;
{$R Images.res}
interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, Generics.defaults,
  System.IOUtils, FMX.ListBox, u_PrivGrid, u_GirlGrid, u_girlStorage,u_Dialogs, u_ActivitiesDialog, u_PrivStorage,
  FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.edit, FMX.ani,
  FMX.Viewport3D, System.Math.Vectors, FMX.Controls3D , FMX.Objects3D, FMX.SpinBox,
  FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, FMX.MaterialSources, FMX.Types3d, system.Math,
  FMX.Types, System.Generics.Collections,  FMX.Effects;

type
  TForm1 = class(TForm)
    TimerPrive: TTimer;
    Viewport3D1: TViewport3D;
    Camera1: TCamera;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerPriveTimer(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Viewport3D1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
  private
    GirlGrid: TGirlGrid;
    PrivGrid: TPrivGrid;
    procedure SetupCameraTopView;
    procedure CancelSelectedPrive;
  public
    procedure TileMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; TileTag: Integer);
    procedure SwitchMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; TileTag: Integer);
    procedure PriveAddMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; TileTag: Integer);
    procedure OnStateChanged(Sender: TObject; PriveTag: Integer; Data: TPrivStatus);
    procedure GirlGridMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; Tag: string);
    procedure GirlGridDeleteMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; Tag: string);
    procedure GirlGridInfoMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; Tag: string);

    // Menu click
    procedure AddGirlMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);

    procedure GetGirlsByPrive ( PriveTag: Integer; var PriveGirls: TObjectList<TGirl> );
    function GetGirlsCountByPrive ( PriveTag: Integer ): Integer;


  end;
  function CreateBlinkingText3D(
    const AOwner: TFmxObject;       // es: Viewport3D
    const TextStr: string;
    const Pos: TVector3D;
    const FontSize: Single = 12
  ): TText3D;
procedure SetTxtSelGirlVisible(AVisible: Boolean);

const MAXGIRLS = 40;
const MAXGIRLSPRIVE = 4;
var
  Form1: TForm1;
  FormReady: Boolean;
  DirSaves: string;
  TmpPriveGirls: TObjectList<TGirl>;
  SelectedPrive: Integer;
  TxtSelGirl: TText3d;

  MatMenu : TColorMaterialSource;
  PlaneAddGirl: TPlane;
  TxtAddGirl : TText3D;
  MatMenuText, MatMenuText2 : TColorMaterialSource;

  MBorder: TPlane;
  BorderMat: TColorMaterialSource;

  Confirm: TConfirmDialog;
  InputGirl: TInputDialog;
  AActivitiesDialog: TActivitiesDialog;
  MessageDialog: TMessageDialog;

implementation

{$R *.fmx}


{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
var
  S: TPrivStorage;
  D: TPrivData;
  I: integer;
  APrive: TPlane;
begin
  DirSaves := GetEnvironmentVariable('LOCALAPPDATA') + '\VVprive\';
  ForceDirectories(DirSaves);
  SelectedPrive := -1;

  FormReady := False;
  Confirm := TConfirmDialog.Create(Self, Self);
  InputGirl := TInputDialog.Create(Self, Self);
  AActivitiesDialog := TActivitiesDialog.Create(Self);
  MessageDialog:= TMessageDialog.Create(self,self);

  Viewport3D1.Align := TAlignLayout.Client;
  Viewport3D1.Visible := True;


  // Crea grid privè 6x4
  PrivGrid := TPrivGrid.Create(Viewport3D1,  5, 3, 3,4,0.05,0.05);
  PrivGrid.SetBasePosition(-8.5,-4);
  PrivGrid.OnTileMouseDown := TileMouseDown;
  PrivGrid.OnSwitchMouseDown := SwitchMouseDown;
  PrivGrid.OnAddMouseDown := PriveAddMouseDown;
  PrivGrid.OnStateChanged := OnStateChanged;

  GirlGrid := TGirlGrid.Create ( ViewPort3d1, 2, 0.42,  0.02,0.02, PrivGrid );
  GirlGrid.LoadfromFiles;
  GirlGrid.OnGirlGridMouseDown := GirlGridMouseDown;
  GirlGrid.OnGirlGridImgDeleteMouseDown := GirlGridDeleteMouseDown;
  GirlGrid.OnGirlGridImgInfoMouseDown := GirlGridInfoMouseDown;
  GirlGrid.SetBasePosition(9,-2.5);
  TmpPriveGirls:=  TObjectList<TGirl>.Create(false);

  S:= TPrivStorage.Create(DirSaves + 'prive.j');
  for I := 0 to 14 do begin
    D:= S.LoadOne( I );
    APrive := PrivGrid.GetPriveByTag(I);
    TPrivStatus(APrive.TagObject).Number := I;
    TPrivStatus(APrive.TagObject).State := D.State;
    TPrivStatus(APrive.TagObject).StartTime := D.StartTime;
    TPrivStatus(APrive.TagObject).EndTime := D.EndTime;
    PrivGrid.SetTileState ( I, D.State );
  end;
  S.Free;

  MatMenuText := TColorMaterialSource.Create(Viewport3D1);
  MatMenuText.Color := TAlphaColorRec.Yellow;
  MatMenuText2 := TColorMaterialSource.Create(Viewport3D1);
  MatMenuText2.Color := TAlphaColorRec.oRANGE;

  MatMenu := TColorMaterialSource.Create(Viewport3D1);
  MatMenu.Color := TAlphaColorRec.Black;

//  TxtSelGirl := CreateBlinkingText3D(Viewport3D1, 'Seleziona una ragazza', Vector3D(8,-3.5,0), 12);
  TxtSelGirl := CreateBlinkingText3D(Viewport3D1, 'Seleziona una ragazza', Vector3D(8,-3.5,0), 12);

  PlaneAddGirl := TPlane.Create(Viewport3D1);
  PlaneAddGirl.Parent := Viewport3D1;
  PlaneAddGirl.Width := 2.2;
  PlaneAddGirl.Height := 0.5;
  PlaneAddGirl.MaterialSource := MatMenu;
  PlaneAddGirl.Position.X := 9;
  PlaneAddGirl.Position.Y := -5;
  PlaneAddGirl.HitTest := True;
  PlaneAddGirl.OnMouseDown := AddGirlMouseDown;
  PlaneAddGirl.Cursor := CrHandPoint;

  // Testo identificativo della cella
  TxtAddGirl := TText3D.Create(PlaneAddGirl);
  TxtAddGirl.Parent := PlaneAddGirl;
  TxtAddGirl.Font.Size := 10;
  TxtAddGirl.WordWrap := False;
  TxtAddGirl.MaterialSource := MatMenuText;
  TxtAddGirl.Text := 'AGGIUNGI RAGAZZA';
  TxtAddGirl.HorzTextAlign := TTextAlign.Center;
  TxtAddGirl.VertTextAlign := TTextAlign.Center;
// Posizione al centro del plane
  TxtAddGirl.Position.X := 0;
  TxtAddGirl.Position.Y := 0;
  TxtAddGirl.Depth := 0.00;
  TxtAddGirl.Scale.X := 0.70;
  TxtAddGirl.Scale.Y := 0.15;
  //TxtAddGirl.Stretch := false;
  TxtAddGirl.Position.Z := 0.05;
  TxtAddGirl.RotationAngle.X := -180;
  TxtAddGirl.HitTest := false;

  BorderMat := TColorMaterialSource.Create(Viewport3D1);
  BorderMat.Color := TAlphaColorRec.gray;   // colore bordo

  MBorder := TPlane.Create(Viewport3D1);
  MBorder.Parent := Viewport3D1;
  MBorder.Width := PlaneAddGirl.Width + 0.08;    // bordo esterno
  MBorder.Height := PlaneAddGirl.Height + 0.08;
  MBorder.Position.X := PlaneAddGirl.Position.X;
  MBorder.Position.Y := PlaneAddGirl.Position.Y;
  MBorder.Position.Z := PlaneAddGirl.Position.Z - 0.02; // dietro al pulsante
  MBorder.MaterialSource := BorderMat;
  MBorder.HitTest := False; // non deve prendere i click

  SetupCameraTopView;
  TimerPrive.Enabled := true;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  TmpPriveGirls.Free;
  Confirm.Free;
  InputGirl.Free;
  MessageDialog.Free;
  PrivGrid.Free;
  //GirlGrid.Free;
end;

procedure TForm1.TimerPriveTimer(Sender: TObject);
begin
  PrivGrid.UpdateCountdowns;
end;

procedure TForm1.Viewport3D1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  CancelSelectedPrive;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  if FormReady then
    SetupCameraTopView;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  FormReady := True;
  FormResize(Self);
end;

procedure TForm1.SetupCameraTopView;
begin
  Camera1.Parent := Viewport3D1;
  Camera1.Position.X := 0;
  Camera1.Position.Y := 0;
  Camera1.Position.Z := 15;
  Camera1.RotationAngle.X := -180;
  Camera1.RotationAngle.Y := 0;
  Camera1.RotationAngle.Z := 0;
end;

procedure TForm1.TileMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; TileTag: Integer);
begin
    CancelSelectedPrive;
end;
procedure TForm1.SwitchMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; TileTag: Integer);
begin
    CancelSelectedPrive;
end;

procedure TForm1.PriveAddMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; TileTag: Integer);
begin

  if TPrivStatus((Tplane(Sender)).TagObject).State = tsOff  then begin
    SelectedPrive := TileTag;
    SetTxtSelGirlVisible ( True );
  end
  else if TPrivStatus((Tplane(Sender)).TagObject).State = tsOff then   { non puoi aggiungere ragazze ad un privè in corso , tsOn, tsAlaram }
  begin
    MessageDialog.Show( 'Non puoi aggiungere una ragzza se il privè è attivo.' );
  end;

end;
procedure TForm1.OnStateChanged(Sender: TObject; PriveTag: Integer; Data: TPrivStatus);
var
  I: integer;
  AGirlStorage: TGirlStorage;
begin
    case Data.State of
      tsOn: begin
         { per tutte le girl in quel prive' setto start. lo start del prive è stato settato nella unit u_privGrid  }
        for I := 0 to GirlGrid.FGirls.Count -1 do
          begin
            if GirlGrid.FGirls[I].Prive = PriveTag then begin
              GirlGrid.FGirls[I].Start := Now;
              AGirlStorage:= TGirlStorage.Create;
              AGirlStorage.SetStatus(GirlGrid.FGirls[I].Name , PriveTag, Now);  // SCRIVE SUBITO SUL FILE
              AGirlStorage.Free;
            end;
          end;

      end;
      tsOff: begin
         {  se il privè è durato troppo poco chiedo }
        if (Now - Data.StartTime) < (5 / 1440) then   // meno di 5 minuti
        begin
        Confirm.Show( 'Il Privè è durato meno di 5 minuti. registro comunque l''attività?' + sLineBreak ,
          procedure
          begin
            //
          end,
          procedure
          begin
            CancelSelectedPrive;
            Exit;
          end
        );
        end;
         {  per tutte le girl in quel prive' LogActivity }
        for I := 0 to GirlGrid.FGirls.Count -1 do
          begin
            if GirlGrid.FGirls[I].Prive = PriveTag then begin
              AGirlStorage:= TGirlStorage.Create;
              AGirlStorage.LogActivity(GirlGrid.FGirls[I].Name);   // CHIUDE L’ULTIMA ATTIVITÀ
              AGirlStorage.Free;
            end;
          end;
      end;
    end;
    CancelSelectedPrive;
end;
procedure TForm1.GirlGridDeleteMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; Tag: string);
var
  AGirl : TGirl;
  AGirlStorage: TGirlStorage;
  APrive: TPlane;
begin
  CancelSelectedPrive;
  AGirl := GirlGrid.GetGirl( Tag );

  if AGirl.Prive < 0 then begin
    if FileExists (dirSaves + Tag + '.json' ) then
    Confirm.Show(
      'Vuoi davvero cancellare questa ragazza?' + sLineBreak + Uppercase(Tag),
      procedure
      begin
        // YES
        Girlgrid.DeleteGirl(Tag);
        Deletefile (dirSaves + Tag + '.json');

      end,
      procedure
      begin
        // NO
      end
    );
  end
  else begin  // LA RAGAZZA E' IN PRIVE' (AGirl.Prive >= 0) , NON PUO' ESSERE RIMOSSA
    APrive := PrivGrid.GetPriveByTag(AGirl.Prive);
    case TPrivStatus (APrive.TagObject).State of
      tsOn,tsAlarm: begin
        MessageDialog.Show( 'Non puoi rimuovere una ragzza se il privè è attivo.' );
      end;
      tsOff: begin
        AGirl.Prive := -1; // la rimette enlla GirlGrid
        AGirl.Start := 0;
        AGirlStorage:= TGirlStorage.Create;
        AGirlStorage.SetStatus( AGirl.Name, -1, 0 );
        AGirlStorage.Free;
        GirlGrid.UpdateGrid;
        //GirlGrid.LoadfromFiles;

      end;

    end;

  end;

  CancelSelectedPrive;
end;
procedure TForm1.GirlGridMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; Tag: string);
var
  AGirl: TGirl;
  AGirlStorage: TGirlStorage;
  APrive: TPlane;
begin
    // LA RAGAZZA E' NELLA GRIDGIRL , LA MUOVE NEL PRIVE' . LogActivity
  if SelectedPrive > -1 then
  begin
    APrive:= PrivGrid.GetPriveByTag( SelectedPrive );
    AGirl := GirlGrid.GetGirl(Tag);

    case TPrivStatus(APrive).State of
      tsOn, tsAlarm: begin
       { non puoi aggiungere ragazze ad un privè in corso }
       { il check è già avvenuto in PriveAddMouseDown }

      end;
      tsOff: begin
        if GetGirlsCountByPrive ( SelectedPrive ) < MAXGIRLSPRIVE then begin
          AGirl.Prive := SelectedPrive;
          AGirl.Start := 0; // lo start lo setta lo Switch
        end
        else MessageDialog.Show ( 'Massimo ' + MAXGIRLSPRIVE.ToString + ' in un privè.') ;
      end;
    end;

    CancelSelectedPrive;
  end;

end;
procedure TForm1.GirlGridInfoMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; Tag: string);
begin
  CancelSelectedPrive;
  AActivitiesDialog.ShowCentered ( Tag );

end;

procedure TForm1.AddGirlMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
var
  GirlStorage: TGirlStorage;
  Data: TGirlData;
  Name: string;
begin
  CancelSelectedPrive;
  if GirlGrid.FGirls.Count < MAXGIRLS then
  begin

    InputGirl.Show(
      'Aggiungi ragazza, digita il nome.',
      procedure
      begin
        // YES
        Name := Trim(InputGirl.FEdit.Text);
        if Length(Name) <= 0 then
        begin
          ShowMessage('Inserisci un nome.');
          Exit;
        end;
        if not System.IOUtils.TPath.HasValidFileNameChars(Name, False) then
        begin
          ShowMessage('Inserisci un nome senza caratteri speciali.');
          Exit;
        end;
        if not FileExists(DirSaves + Name + '.json') then
        begin
          Data.Prive := -1;
          Data.Start := 0;
          SetLength(Data.Activities, 0);
          GirlStorage.SaveGirl(Name, Data);
          TThread.Queue(nil,
          procedure
          begin
        // ora è sicuro modificare FGirls o ricreare le tile
            GirlGrid.AddGirl(Name);
          end);
          InputGirl.FEdit.Text := '';
        end
        else
        begin
          ShowMessage(Name + ' è già presente');
        end;
      end,
      procedure
      begin
        // NO
      end
    ); // <- chiude la chiamata a InputGirl.Show
      InputGirl.FEdit.setfocus;

  end
  else
    ShowMessage('Puoi gestire al massimo ' +  MAXGIRLS.ToString + ' ragazze');
end;
procedure TForm1.CancelSelectedPrive;
begin

  SelectedPrive := -1;
  SetTxtSelGirlVisible ( False );
  GirlGrid.UpdateGrid;

end;
procedure TForm1.GetGirlsByPrive ( PriveTag: Integer; var PriveGirls: TObjectList<TGirl> );
var
  i: integer;
begin
  PriveGirls.Clear;
  for I := 0 to GirlGrid.FGirls.Count -1 do
  begin
    if GirlGrid.FGirls[I].Prive = PriveTag then
      PriveGirls.Add(GirlGrid.FGirls[I]);
  end;

end;
function TForm1.GetGirlsCountByPrive ( PriveTag: Integer ): Integer;
var
  i: integer;
begin
  Result:= 0;
  for I := 0 to GirlGrid.FGirls.Count -1 do
  begin
    if GirlGrid.FGirls[I].Prive = PriveTag then
      Result := Result + 1;
  end;

end;

function CreateBlinkingText3D(
  const AOwner: TFmxObject;       // es: Viewport3D
  const TextStr: string;
  const Pos: TVector3D;
  const FontSize: Single = 12
): TText3D;
var
  Txt: TText3D;
  Anim: TFloatAnimation;
begin
  // ------------------------
  // Creazione del testo
  // ------------------------
  Txt := TText3D.Create(AOwner);
  Txt.Parent := AOwner;
  Txt.Text := TextStr;
  Txt.Position.Point := Pos;

  Txt.Font.Size := FontSize;
  Txt.HorzTextAlign := TTextAlign.Center;
  Txt.VertTextAlign := TTextAlign.Center;
  Txt.Opacity := 1.0;
  Txt.Stretch := true;
  Txt.WordWrap := false;
  //Txt.Width := 40;
  //Txt.Height := 20;
  Txt.MaterialSource := MatMenu;
  Txt.Depth := 0.01;
  Txt.RotationAngle.X := -180;

  Txt.Scale.X := 1;
  Txt.Scale.Y := 0.35;
  Txt.Visible := False;  // quando diventa visible → parte blinking
  // ------------------------
  // Animazione blinking
  // ------------------------
  Anim := TFloatAnimation.Create(Txt);
  Anim.Name := 'BlinkAnim';
  Anim.Parent := Txt;
  Anim.PropertyName := 'Opacity';
  Anim.StartValue := 1.0;
  Anim.StopValue := 0.25;        // lampo visivo
  Anim.Duration := 0.6;
  Anim.AutoReverse := True;
  Anim.Loop := True;
  Anim.Enabled := True;

  Result := Txt;
end;
procedure SetTxtSelGirlVisible(AVisible: Boolean);
var
  Anim: TFloatAnimation;
begin
  if TxtSelGirl = nil then Exit;

  // imposta la visibilità
  TxtSelGirl.Visible := AVisible;

  // trova l'animazione creata in CreateBlinkingText3D (nome 'BlinkAnim')
  if TxtSelGirl.FindComponent('BlinkAnim') is TFloatAnimation then
  begin
    Anim := TFloatAnimation(TxtSelGirl.FindComponent('BlinkAnim'));
    if AVisible then
    begin
      Anim.Enabled := True;
      // se la tua versione di FMX supporta Start, chiamalo per sicurezza
      try
        Anim.Start;
      except
        // Start può non esistere in tutte le versioni: l'Enabled := True è comunque la cosa importante
      end;
    end
    else
    begin
      // disattiva/ferma animazione quando non visibile
      try
        Anim.Stop;
      except
      end;
      Anim.Enabled := False;
    end;
  end;
end;

end.

