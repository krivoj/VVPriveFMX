unit Unit1;
{$R Images.res}
interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, Generics.defaults,
  System.IOUtils, FMX.ListBox, u_PrivGrid, u_GirlGrid, u_girlStorage,u_Dialogs,
  FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.edit, FMX.ani,
  FMX.Viewport3D, System.Math.Vectors, FMX.Controls3D , FMX.Objects3D, FMX.SpinBox,
  FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, FMX.MaterialSources,
  FMX.Types, System.Generics.Collections, Math, FMX.Effects;

type
  TForm1 = class(TForm)
    TimerMain: TTimer;
    Viewport3D1: TViewport3D;
    Camera1: TCamera;
    procedure FormCreate(Sender: TObject);
    procedure TimerMainTimer(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    GirlGrid: TGirlGrid;
    PrivGrid: TPrivGrid;
    procedure LoadGirlsList;
    procedure SetupCameraTopView;
  public
    procedure TileMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; TileTag: Integer);
    procedure ImgMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; TileTag: Integer);
    procedure ImgAddMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; TileTag: Integer);
    procedure OnStateChanged(Sender: TObject; TileTag: Integer; Data: TPrivStatus);
    procedure GirlGridMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; Tag: string);
    procedure GirlGridImgDeleteMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; Tag: string);
    procedure GirlGridImgInfoMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; Tag: string);

    // Menu click
    procedure AddGirlMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);



  end;

const MAXGIRLS = 40;
var
  Form1: TForm1;
  FormReady: Boolean;
  DirSaves: string;
  Girls: TObjectList<TGirl>;
  SelectionPrive: Integer;

  MatMenu : TColorMaterialSource;
  PlaneAddGirl: TPlane;
  TxtAddGirl : TText3D;
  MatMenuText, MatMenuText2 : TColorMaterialSource;

  MBorder: TPlane;
  BorderMat: TColorMaterialSource;

  Confirm: TConfirmDialog;
  InputGirl: TInputDialog;
implementation

{$R *.fmx}


{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  DirSaves := GetEnvironmentVariable('LOCALAPPDATA') + '\VVprive\';
  ForceDirectories(DirSaves);
  SelectionPrive := -1;

  FormReady := False;
  Confirm := TConfirmDialog.Create(Self, Self);
  InputGirl := TInputDialog.Create(Self, Self);

  Viewport3D1.Align := TAlignLayout.Client;
  Viewport3D1.Visible := True;

  // Crea grid privè 6x4
  PrivGrid := TPrivGrid.Create(Viewport3D1,  5, 3, 3,4,0.05,0.05);
  PrivGrid.SetBasePosition(-8.5,-4);
  PrivGrid.OnTileMouseDown := TileMouseDown;
  PrivGrid.OnImgMouseDown := ImgMouseDown;
  PrivGrid.OnImgAddMouseDown := ImgAddMouseDown;
  PrivGrid.OnStateChanged := OnStateChanged;

  Girls:= TObjectList<TGirl>.Create(true);
  LoadGirlsList; // GirlGrid

  MatMenuText := TColorMaterialSource.Create(Viewport3D1);
  MatMenuText.Color := TAlphaColorRec.Yellow;
  MatMenuText2 := TColorMaterialSource.Create(Viewport3D1);
  MatMenuText2.Color := TAlphaColorRec.oRANGE;

  MatMenu := TColorMaterialSource.Create(Viewport3D1);
  MatMenu.Color := TAlphaColorRec.Black;

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


  TimerMain := TTimer.Create(Self);
  TimerMain.Interval := 1000;
  TimerMain.Enabled := True;
  TimerMain.OnTimer := TimerMainTimer;

  SetupCameraTopView;
end;

procedure TForm1.LoadGirlsList;
var
  FileName : string;
  AGirl : TGirl;
begin
  Girls.Clear;
    for FileName in TDirectory.GetFiles(DirSaves, '*.json') do
      begin
        AGirl := TGirl.Create;
        AGirl.Name := System.IOUtils.TPath.GetFileNameWithoutExtension(FileName);
        AGirl.Prive := -1;
        Girls.Add(AGirl);
      end;
  Girls.Sort(TComparer<TGirl>.Construct(
    function(const A, B: TGirl): Integer
    begin
      Result := CompareText(A.Name, B.Name);  // ordina per Name
    end));

  GirlGrid := TGirlGrid.Create ( ViewPort3d1, 2, 0.4,  0.02,0.02, PrivGrid, Girls );

  GirlGrid.OnGirlGridMouseDown := GirlGridMouseDown;
  GirlGrid.OnGirlGridImgDeleteMouseDown := GirlGridImgDeleteMouseDown;
  GirlGrid.OnGirlGridImgInfoMouseDown := GirlGridImgInfoMouseDown;
  GirlGrid.SetBasePosition(9,-2.5);

end;


procedure TForm1.TimerMainTimer(Sender: TObject);
var
  i: integer;
begin
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
  // puoi aggiungere logica click 3D se serve
  Caption:= IntTostr(TileTag);
end;
procedure TForm1.ImgMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; TileTag: Integer);
begin
  // puoi aggiungere logica click 3D se serve
  Caption:= IntTostr(TileTag);
end;
procedure TForm1.ImgAddMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; TileTag: Integer);
begin
  SelectionPrive := TileTag;
  { TODO : highlight }
  //Girlgrid.Mat := GirlGrid.MatHighlight;
end;
procedure TForm1.OnStateChanged(Sender: TObject; TileTag: Integer; Data: TPrivStatus);
begin
  // puoi aggiungere logica click 3D se serve
  Caption:= IntTostr(TileTag);
end;
procedure TForm1.GirlGridMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; Tag: string);
var
  AGirl: TGirl;
  APrivTile :TPlane;
begin
  If SelectionPrive > -1 then
  begin
    AGirl := GirlGrid.GetGirl(Tag);
    AGirl.Prive := SelectionPrive;
    APrivTile := PrivGrid.GetTileByTag(SelectionPrive);
    SelectionPrive := -1;
    GirlGrid.RebuildGrid;
  end;
end;
procedure TForm1.GirlGridImgDeleteMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; Tag: string);
var
  AGirl : TGirl;
begin
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
  else begin
    // LA RAGAZZA E' IN PRIVE'
    //RecordActivity;
    AGirl.Prive := -1;
    SelectionPrive := -1;
    GirlGrid.RebuildGrid;
  end;
end;
procedure TForm1.GirlGridImgInfoMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; Tag: string);
var
  AGirl: TGirlData;
  GirlStorage: TGirlStorage;
begin
  if FileExists (dirSaves + Tag + '.json' ) then
  begin
    GirlStorage:= TGirlStorage.Create;
    AGirl:= GirlStorage.LoadGirl(Tag);
    GirlStorage.Free;
  end;

end;

procedure TForm1.AddGirlMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
var
  GirlStorage: TGirlStorage;
  Data: TGirlData;
  Name: string;
begin
  if Girls.Count < MAXGIRLS then
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
          GirlGrid.AddGirl(Name);
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
    ShowMessage('Puoi gestire al massimo 48 ragazze');
end;

end.

