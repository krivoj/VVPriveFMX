unit Unit1;
{$R Images.res}
interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, Generics.defaults,System.Win.Registry,Dateutils,
  System.IOUtils, FMX.ListBox, u_PrivGrid, u_GirlGrid, u_girlStorage,u_Dialogs, u_ActivitiesDialog, u_PrivStorage, u_lang, u_serial,
  FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.edit, FMX.ani,
  FMX.Viewport3D, System.Math.Vectors, FMX.Controls3D , FMX.Objects3D, FMX.SpinBox,
  FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, FMX.MaterialSources, FMX.Types3d, system.Math,
  FMX.Types, System.Generics.Collections,  FMX.Effects, FMX.Menus;

type
  TForm1 = class(TForm)
    TimerPrive: TTimer;
    Viewport3D1: TViewport3D;
    Camera1: TCamera;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    procedure FormDestroy(Sender: TObject);
    procedure StartApplication;
    procedure TimerPriveTimer(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Viewport3D1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure FormCreate(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
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

    procedure ClearAllActivitiesMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);

    procedure AddGirlMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);

    procedure PrintAllMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);

    procedure ExitMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);

    procedure GetGirlsByPrive ( PriveTag: Integer; var PriveGirls: TObjectList<TGirl> );
    function GetGirlsCountByPrive ( PriveTag: Integer ): Integer;
    function GetPriveFreeSlot ( PriveTag: Integer ): Integer;

    procedure CheckLicense;
    procedure AskForLicense;
    procedure ContinueApplication;

  end;
  function CreateBlinkingText3D(const AOwner: TFmxObject; const TextStr: string ): TText3D;
procedure SetTxtSelGirlVisible(AVisible: Boolean; APrive:TPlane);

const MAXGIRLS = 40;
const MAXGIRLSPRIVE = 4;
const MAXPRIVE = 15;
var
  Form1: TForm1;
  IsDemo: boolean;
  FormReady: Boolean;
  DirSaves: string;
  TmpPriveGirls: TObjectList<TGirl>;
  SelectedPrive: Integer;
  TxtSelGirl: TText3d;

  MatMenu : TColorMaterialSource;
  PlaneClearAllActivities,PlaneAddGirl,PlanePrintAll,PlaneExit: TPlane;
  TxtClearAllActivities,TxtAddGirl,TxtPrintAll, TxtExit : TText3D;
  MatMenuText, MatMenuText2 : TColorMaterialSource;


  Confirm: TConfirmDialog;
  InputGirl,InputLicense: TInputDialog;
  AActivitiesDialog: TActivitiesDialog;
  MessageDialog: TMessageDialog;
  ALangDialog : TLangDialog;
  PriveSlot : Array[0..MAXGIRLSPRIVE-1] of TPoint3d;
implementation

{$R *.fmx}


{ TForm1 }

procedure TForm1.StartApplication;
begin
  DirSaves := GetEnvironmentVariable('LOCALAPPDATA') + '\LapDance Prive\';
  ForceDirectories(DirSaves);
  TMenuItem(MainMenu1.Items[0]).Text := L(STR_LICENSE);

  InputLicense := TInputDialog.Create(Self, Self);
  MessageDialog := TMessageDialog.Create(Self, Self);

  CheckLicense;   // 👈 QUI PARTE IL FLUSSO
end;
procedure TForm1.CheckLicense;
var
  Serial    : string;
  FirstRun : TDateTime;
begin
  Serial := ReadSerialFromRegistry;

  if IsValidSerial(Serial) then
  begin
    IsDemo := False;
    Caption := 'LapDance Prive v.' + GetFileVersion(ParamStr(0));
    ContinueApplication;
    Exit;
  end;

  FirstRun := GetOrCreateFirstRunDate;

  if (FirstRun > 0) and (Now - FirstRun <= 60) then
  begin
    IsDemo := True;
    Caption := 'LapDance Prive DEMO v.' + GetFileVersion(ParamStr(0)) + ' ('+
      Format(L(STR_TRIAL_DAYS_LEFT), [60 - DaysBetween(Now, FirstRun)]) + ')';
    ContinueApplication;
    Exit;
  end;

  // ⛔ DEMO SCADUTA → chiedi licenza
  AskForLicense;
end;
procedure TForm1.AskForLicense;
begin
  InputLicense.Show(
    L(STR_TRIAL_EXPIRED) + ' .' + L(STR_TRIAL_INPUT_LICENSE),

    // OK
    procedure
    begin
      if IsValidSerial(Trim(InputLicense.FEdit.Text)) then
      begin
        WriteSerialToRegistry(Trim(InputLicense.FEdit.Text));
        IsDemo := False;
        Caption := 'LapDance Prive v.' + GetFileVersion(ParamStr(0));
        ContinueApplication;
      end
      else
      begin
        MessageDialog.Show(
          L(STR_INVALID_LICENSE),
          procedure
          begin
            CheckLicense; // 🔁 RIPROVA, NON TERMINA
          end
        );
      end;
    end,

    // NO → L’UTENTE RINUNCIA
    procedure
    begin
      Application.Terminate; // ❗ SOLO QUI
    end
  );


end;

procedure TForm1.ContinueApplication;
var
  S: TPrivStorage;
  D: TPrivData;
  I: integer;
  APrive: TPlane;
  Serial: string;
  FirstRun: TDateTime;
begin
  //serial := GenerateSerial;
 // WriteSerialToRegistry (SERIAL);

  SelectedPrive := -1;

  FormReady := False;
  Confirm := TConfirmDialog.Create(Self, Self);
  InputGirl := TInputDialog.Create(Self, Self);
  AActivitiesDialog := TActivitiesDialog.Create(Self,Self);
  //MessageDialog:= TMessageDialog.Create(self,self);

  Viewport3D1.Align := TAlignLayout.Client;
  Viewport3D1.Visible := True;

  PriveSlot[0].X := 0;
  PriveSlot[0].Y := 0;
  PriveSlot[1].X := 0;
  PriveSlot[1].Y := -0.5;
  PriveSlot[2].X := 0;
  PriveSlot[2].Y := -1;
  PriveSlot[3].X := 0;
  PriveSlot[3].Y := -1.5;

  // Crea grid privè 6x4
  PrivGrid := TPrivGrid.Create(Viewport3D1,  5, 3, 3,4,0.05,0.05);
  PrivGrid.SetBasePosition(-8.5,-4);
  PrivGrid.OnTileMouseDown := TileMouseDown;
  PrivGrid.OnSwitchMouseDown := SwitchMouseDown;
  PrivGrid.OnAddMouseDown := PriveAddMouseDown;
  PrivGrid.OnStateChanged := OnStateChanged;
  //    ShowMessage('ok');

  GirlGrid := TGirlGrid.Create ( ViewPort3d1, 2, 0.42,  0.02,0.02, PrivGrid );
  GirlGrid.LoadfromFiles;
  GirlGrid.OnGirlGridMouseDown := GirlGridMouseDown;
  GirlGrid.OnGirlGridImgDeleteMouseDown := GirlGridDeleteMouseDown;
  GirlGrid.OnGirlGridImgInfoMouseDown := GirlGridInfoMouseDown;
  GirlGrid.SetBasePosition(9,-2.5);


  TmpPriveGirls:=  TObjectList<TGirl>.Create(false);

  S:= TPrivStorage.Create(DirSaves + 'prive.j');
  for I := 0 to MAXPRIVE-1 do begin
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
  MatMenuText2.Color := TAlphaColorRec.Red;

  MatMenu := TColorMaterialSource.Create(Viewport3D1);
  MatMenu.Color := TAlphaColorRec.Black;

//  TxtSelGirl := CreateBlinkingText3D(Viewport3D1, 'Seleziona una ragazza', Vector3D(8,-3.5,0), 12);
  TxtSelGirl := CreateBlinkingText3D(Viewport3D1, L(STR_SELECT_GIRL) );

  PlaneClearAllActivities := TPlane.Create(Viewport3D1);
  PlaneClearAllActivities.Parent := Viewport3D1;
  PlaneClearAllActivities.Width := 2.2;
  PlaneClearAllActivities.Height := 0.5;
  PlaneClearAllActivities.MaterialSource := MatMenu;
  PlaneClearAllActivities.Position.X := 6.5;
  PlaneClearAllActivities.Position.Y := -5;
  PlaneClearAllActivities.HitTest := True;
  PlaneClearAllActivities.OnMouseDown := ClearAllActivitiesMouseDown;
  PlaneClearAllActivities.Cursor := CrHandPoint;

  // Testo identificativo della cella
  TxtClearAllActivities := TText3D.Create(PlaneClearAllActivities);
  TxtClearAllActivities.Parent := PlaneClearAllActivities;
  TxtClearAllActivities.Font.Size := 10;
  TxtClearAllActivities.WordWrap := False;
  TxtClearAllActivities.MaterialSource := MatMenuText;
  TxtClearAllActivities.Text := L(STR_CLEAR_ACTIVITIES);
  TxtClearAllActivities.HorzTextAlign := TTextAlign.Center;
  TxtClearAllActivities.VertTextAlign := TTextAlign.Center;
// Posizione al centro del plane
  TxtClearAllActivities.Position.X := 0;
  TxtClearAllActivities.Position.Y := 0;
  TxtClearAllActivities.Depth := 0.00;
  TxtClearAllActivities.Scale.X := 0.70;
  TxtClearAllActivities.Scale.Y := 0.15;
  //TxtClearAllActivities.Stretch := false;
  TxtClearAllActivities.Position.Z := 0.05;
  TxtClearAllActivities.RotationAngle.X := -180;
  TxtClearAllActivities.HitTest := false;

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
  TxtAddGirl.Text := L(STR_ADD_GIRL);
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


  PlanePrintAll := TPlane.Create(Viewport3D1);
  PlanePrintAll.Parent := Viewport3D1;
  PlanePrintAll.Width := 2.2;
  PlanePrintAll.Height := 0.5;
  PlanePrintAll.MaterialSource := MatMenu;
  PlanePrintAll.Position.X := 6.5;
  PlanePrintAll.Position.Y := -5.65;
  PlanePrintAll.HitTest := True;
  PlanePrintAll.OnMouseDown := PrintAllMouseDown;
  PlanePrintAll.Cursor := CrHandPoint;

  // Testo identificativo della cella
  TxtPrintAll := TText3D.Create(PlaneAddGirl);
  TxtPrintAll.Parent := PlanePrintAll;
  TxtPrintAll.Font.Size := 10;
  TxtPrintAll.WordWrap := False;
  TxtPrintAll.MaterialSource := MatMenuText;
  TxtPrintAll.Text := L(STR_PRINT_ACTIVITIES);
  TxtPrintAll.HorzTextAlign := TTextAlign.Center;
  TxtPrintAll.VertTextAlign := TTextAlign.Center;
// Posizione al centro del plane
  TxtPrintAll.Position.X := 0;
  TxtPrintAll.Position.Y := 0;
  TxtPrintAll.Depth := 0.00;
  TxtPrintAll.Scale.X := 0.70;
  TxtPrintAll.Scale.Y := 0.15;
  //TxtAddGirl.Stretch := false;
  TxtPrintAll.Position.Z := 0.05;
  TxtPrintAll.RotationAngle.X := -180;
  TxtPrintAll.HitTest := false;


  PlaneExit := TPlane.Create(Viewport3D1);
  PlaneExit.Parent := Viewport3D1;
  PlaneExit.Width := 2.2;
  PlaneExit.Height := 0.5;
  PlaneExit.MaterialSource := MatMenu;
  PlaneExit.Position.X := 9;
  PlaneExit.Position.Y := -5.65;
  PlaneExit.HitTest := True;
  PlaneExit.OnMouseDown := ExitMouseDown;
  PlaneExit.Cursor := CrHandPoint;

  // Testo identificativo della cella
  TxtExit := TText3D.Create(PlaneExit);
  TxtExit.Parent := PlaneExit;
  TxtExit.Font.Size := 10;
  TxtExit.WordWrap := False;
  TxtExit.MaterialSource := MatMenuText2;
  TxtExit.Text :=  L(STR_EXIT);
  TxtExit.HorzTextAlign := TTextAlign.Center;
  TxtExit.VertTextAlign := TTextAlign.Center;
// Posizione al centro del plane
  TxtExit.Position.X := 0;
  TxtExit.Position.Y := 0;
  TxtExit.Depth := 0.00;
  TxtExit.Scale.X := 0.70;
  TxtExit.Scale.Y := 0.15;
  //TxtExit.Stretch := false;
  TxtExit.Position.Z := 0.05;
  TxtExit.RotationAngle.X := -180;
  TxtExit.HitTest := false;

  SetupCameraTopView;
  TimerPrive.Enabled := true;

end;


procedure TForm1.FormCreate(Sender: TObject);
begin
ALangDialog := TLangDialog.Create(
    Self,
    Self,
    StartApplication   // ← QUI riparte tutto
  );

  ALangDialog.Show;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  TmpPriveGirls.Free;
  Confirm.Free;
  InputLicense.Free;
  InputGirl.Free;
  MessageDialog.Free;
  PrivGrid.Free;
  ALangDialog.Free;
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
  SelectedPrive := TileTag;

  if TPrivStatus((Tplane(Sender)).TagObject).State = tsOff  then begin
    if GetGirlsCountByPrive ( SelectedPrive ) >= MAXGIRLSPRIVE then
    begin
      MessageDialog.Show(Format(L(STR_MAX_GIRLS_PRIVE), [MAXGIRLSPRIVE]));
      SelectedPrive := -1;
      Exit;
    end;
    SetTxtSelGirlVisible ( True, TPlane(Sender) );
  end
  else if TPrivStatus((Tplane(Sender)).TagObject).State <> tsOff then   { non puoi aggiungere ragazze ad un privè in corso , tsOn, tsAlaram }
  begin
    MessageDialog.Show(L(STR_PRIVE_ACTIVE_NO_ADD));
    SelectedPrive := -1;
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
              AGirlStorage.SetStatus(GirlGrid.FGirls[I].Name , PriveTag, GirlGrid.FGirls[I].Slot , Now);  // SCRIVE SUBITO SUL FILE
              AGirlStorage.Free;
            end;
          end;

      end;
      tsOff: begin
         {  se il privè è durato troppo poco chiedo }
        if (Now - Data.StartTime) < (5 / 1440) then   // meno di 5 minuti
        begin
        Confirm.Show(L(STR_PRIVE_SHORT_CONFIRM) + sLineBreak,
          procedure
          var
          I: Integer;
          begin
         {  per tutte le girl in quel prive' LogActivity }
            for I := 0 to GirlGrid.FGirls.Count -1 do
              begin
                if GirlGrid.FGirls[I].Prive = PriveTag then begin
                  AGirlStorage:= TGirlStorage.Create;
                  AGirlStorage.LogActivity(GirlGrid.FGirls[I].Name);   // CHIUDE L’ULTIMA ATTIVITÀ
                  AGirlStorage.Free;
                end;
              end;
          end,
          procedure
          begin
            CancelSelectedPrive;
            Exit;
          end
        );
        end
        else begin
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
      Confirm.Show(Format(L(STR_DELETE_GIRL_CONFIRM), [UpperCase(Tag)]),
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
        MessageDialog.Show(L(STR_CANNOT_REMOVE_ACTIVE));
      end;
      tsOff: begin
        AGirl.Prive := -1; // la rimette enlla GirlGrid
        AGirl.Slot := -1; // la rimette enlla GirlGrid
        AGirl.Start := 0; // la rimette enlla GirlGrid
        AGirlStorage:= TGirlStorage.Create;
        AGirlStorage.SetStatus( AGirl.Name, -1, -1, 0 );
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
          AGirl.Slot := GetPriveFreeSlot (SelectedPrive);  // la chiamo prima per escludere dalla lista QUESTA girl
          AGirl.Prive := SelectedPrive;
          AGirl.Start := 0; // lo start lo setta lo Switch
        end
        else MessageDialog.Show(Format(L(STR_MAX_GIRLS_PRIVE), [MAXGIRLSPRIVE]));
      end;
    end;

    CancelSelectedPrive;
  end;

end;
procedure TForm1.MenuItem1Click(Sender: TObject);
var
  Serial    : string;
begin
  Serial := ReadSerialFromRegistry;
  if IsValidSerial(Serial) then
    MessageDialog.Show(Serial)
  else begin
  InputLicense.Show(
    L(STR_TRIAL_INPUT_LICENSE),

    // OK
    procedure
    begin
      if IsValidSerial(Trim(InputLicense.FEdit.Text)) then
      begin
        WriteSerialToRegistry(Trim(InputLicense.FEdit.Text));
        IsDemo := False;
        Caption := 'LapDance Prive';
      end
      else
      begin
        MessageDialog.Show(
          L(STR_INVALID_LICENSE),
          procedure
          begin
            CheckLicense; // 🔁 RIPROVA, NON TERMINA
          end
        );
      end;
    end,

    // NO → L’UTENTE RINUNCIA
    procedure
    begin

    end
  );


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
      L(STR_ADD_GIRL_TITLE),
      procedure
      begin
        // YES
        Name := Trim(InputGirl.FEdit.Text);
        if Length(Name) <= 0 then
        begin
          ShowMessage(L(STR_ENTER_NAME));
          Exit;
        end;
        if not System.IOUtils.TPath.HasValidFileNameChars(Name, False) then
        begin
          ShowMessage(L(STR_INVALID_NAME));
          Exit;
        end;
        if not FileExists(DirSaves + Name + '.json') then
        begin
          Data.Prive := -1;
          Data.Slot := -1;
          Data.Start := 0;
          SetLength(Data.Activities, 0);
          GirlStorage.SaveGirl(Name, Data);
          TThread.Queue(nil,
          procedure
          begin
        // ora è sicuro modificare FGirls o ricreare le tile
            GirlGrid.AddGirl(Name);
          end);

        end
        else
        begin
          ShowMessage(Format(L(STR_GIRL_ALREADY_EXISTS), [Name]));
        end;
      end,
      procedure
      begin
        // NO
      end
    ); // <- chiude la chiamata a InputGirl.Show

  end
  else
    ShowMessage(Format(L(STR_MAX_GIRLS_TOTAL), [MAXGIRLS]));
end;
procedure TForm1.ClearAllActivitiesMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
begin
  Confirm.Show(L(STR_CLEAR_ALL_CONFIRM),
    procedure
    var
      GirlStorage: TGirlStorage;
      Files: TStringDynArray;
      FileName, GirlName: string;
      S: TPrivStorage;
      I: Integer;
      D: TPrivdata;
      APrive: TPlane;

    begin
      Files := TDirectory.GetFiles(DirSaves, '*.json');

      // Azzera i file Json delle Girls
      for FileName in Files do
      begin
        GirlStorage := TGirlStorage.Create;
        GirlName := UpperCase( system.IOUtils.TPath.GetFileNameWithoutExtension(FileName));
        GirlStorage.ClearActivities (GirlName);
        GirlStorage.Free;
      end;

      // Chiude tutti i Prive
      S:= TPrivStorage.Create(DirSaves + 'prive.j');
      for I := 0 to MAXPRIVE-1 do begin
        D:= S.LoadOne( I );
        D.State := tsOff;
        D.StartTime := 0;
        D.EndTime := 0;
        S.SaveOne(I, D );
        APrive := PrivGrid.GetPriveByTag(I);
        TPrivStatus(APrive.TagObject).Number := I;
        TPrivStatus(APrive.TagObject).State := D.State;
        TPrivStatus(APrive.TagObject).StartTime := D.StartTime;
        TPrivStatus(APrive.TagObject).EndTime := D.EndTime;
        PrivGrid.SetTileState ( I, D.State );
      end;
      S.Free;

      MessageDialog.Show(L(STR_ACTIVITIES_RESET));

    end,
    procedure
    begin
      CancelSelectedPrive;
      Exit;
    end
  );



end;
procedure TForm1.CancelSelectedPrive;
var
  APrive: TPlane;
begin
  APrive := PrivGrid.GetPriveByTag(SelectedPrive);
  SelectedPrive := -1;
  SetTxtSelGirlVisible ( False, APrive );
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
function TForm1.GetPriveFreeSlot ( PriveTag: Integer ): Integer;
var
  i: integer;
  Slot: Array[0..MAXGIRLSPRIVE-1] of Boolean;
begin
  Result:= 0;
  Slot[0]:= False;
  Slot[1]:= False;
  Slot[2]:= False;
  Slot[3]:= False;
  for I := 0 to GirlGrid.FGirls.Count -1 do
  begin
    if GirlGrid.FGirls[I].Prive = PriveTag then begin
      Slot [GirlGrid.FGirls[I].Slot] := True;
    end;
  end;

  for I := low(Slot) to High(Slot) do
  begin
    if Slot[i] = false then begin
      Result := I;
      Exit;
    end;
  end;


end;

function CreateBlinkingText3D(const AOwner: TFmxObject;const TextStr: string): TText3D;
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
  //Txt.Position.Point := Pos;
  Txt.Width := 50;
  Txt.Height := 10;
  Txt.Font.Size := 8;
  Txt.HorzTextAlign := TTextAlign.Center;
  Txt.VertTextAlign := TTextAlign.Center;
  Txt.MaterialSource := MatMenuText;
  Txt.Stretch := True;
  Txt.Depth := 0.0;
  Txt.Scale.X := 0.04;
  Txt.Scale.Y := 0.04;
  Txt.Position.X := 1;
  Txt.Position.Y := 0.85;
  Txt.Position.Z := 0.03;
  Txt.RotationAngle.X := 0;
  Txt.RotationAngle.Y := 0;
  Txt.RotationAngle.Z := 0;
  Txt.HitTest := False;
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
procedure SetTxtSelGirlVisible(AVisible: Boolean; APrive:TPlane);
var
  Anim: TFloatAnimation;
begin
  // imposta la visibilità
  TxtSelGirl.Visible := AVisible;
  TxtSelGirl.Parent := APrive;
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
procedure TForm1.PrintAllMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
begin
  CancelSelectedPrive;
  AActivitiesDialog.PrintAllActivities;

end;
procedure TForm1.ExitMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
begin
  Application.Terminate;
end;

end.

