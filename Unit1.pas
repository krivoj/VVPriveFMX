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
    procedure PaintCancel(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure PaintOk(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
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
    procedure CreateAddGirlOverlay;
    procedure ShowAddGirlOverlay;
    procedure HideAddGirlOverlay;
    procedure AddGirlConfirm(Sender: TObject);
    procedure AddGirlCancel(Sender: TObject);



  end;


var
  Form1: TForm1;
  FormReady: Boolean;
  DirSaves: string;
  Girls: TList<TGirl>;

  MatMenu : TColorMaterialSource;
  PlaneAddGirl: TPlane;
  TxtAddGirl : TText3D;
  MatMenuText, MatMenuText2 : TColorMaterialSource;

  MBorder: TPlane;
  BorderMat: TColorMaterialSource;

  FAddGirlOverlay : TLayout;
  FAddGirlEdit : TEdit;

  FYesNoOverlay : TLayout;
  FYesNoTitle : TLabel;
  Confirm: TConfirmDialog;

implementation

{$R *.fmx}


{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  DirSaves := GetEnvironmentVariable('LOCALAPPDATA') + '\VVprive\';
  ForceDirectories(DirSaves);


  FormReady := False;
  Confirm := TConfirmDialog.Create(Self, Self);
  CreateAddGirlOverlay;

  Viewport3D1.Align := TAlignLayout.Client;
  Viewport3D1.Visible := True;

  // Crea grid privè 6x4
  PrivGrid := TPrivGrid.Create(Viewport3D1,  6, 4, 2.5,3,0.05,0.05);
  PrivGrid.SetBasePosition(-9,-4.5);
  PrivGrid.OnTileMouseDown := TileMouseDown;
  PrivGrid.OnImgMouseDown := ImgMouseDown;
  PrivGrid.OnImgAddMouseDown := ImgAddMouseDown;
  PrivGrid.OnStateChanged := OnStateChanged;

  Girls:= TList<TGirl>.Create;
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
  i: integer;
begin

    for FileName in TDirectory.GetFiles(DirSaves, '*.json') do
      begin
        AGirl.Name := System.IOUtils.TPath.GetFileNameWithoutExtension(FileName);
        AGirl.Prive := -1;
        Girls.Add(AGirl);
      end;
  Girls.Sort(TComparer<TGirl>.Construct(
    function(const A, B: TGirl): Integer
    begin
      Result := CompareText(A.Name, B.Name);  // ordina per Name
    end));

  GirlGrid := TGirlGrid.Create ( ViewPort3d1, 2, 0.4,  0.02,0.02, Girls );

  GirlGrid.OnGirlGridMouseDown := GirlGridMouseDown;
  GirlGrid.OnGirlGridImgDeleteMouseDown := GirlGridImgDeleteMouseDown;
  GirlGrid.OnGirlGridImgInfoMouseDown := GirlGridImgInfoMouseDown;
  GirlGrid.SetBasePosition(9,-4);

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
  Caption := 'add premuto sul prive' + TPlane(Sender).Tag.ToString;
  //Girlgrid.Mat := GirlGrid.MatHighlight;
end;
procedure TForm1.OnStateChanged(Sender: TObject; TileTag: Integer; Data: TPrivStatus);
begin
  // puoi aggiungere logica click 3D se serve
  Caption:= IntTostr(TileTag);
end;
procedure TForm1.GirlGridMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; Tag: string);
begin
  // puoi aggiungere logica click 3D se serve
  Caption:= Tag;
end;
procedure TForm1.GirlGridImgDeleteMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; Tag: string);
begin
  if FileExists (dirSaves + Tag + '.json' ) then
  Confirm.Show(
    'Vuoi davvero cancellare questa ragazza?' + sLineBreak + Uppercase(Tag),
    procedure
    begin
      // YES
      ShowMessage('Hai premuto SÌ');
    end,
    procedure
    begin
      // NO
      ShowMessage('Hai premuto NO');
    end
  );
end;
procedure TForm1.GirlGridImgInfoMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; Tag: string);
begin
  if FileExists (dirSaves + Tag + '.json' ) then
  //  ShowyesNoOverlay ( 'Mostro info ' + Uppercase(Tag) + '?');
  Confirm.Show(
  'Vuoi davvero cancellare questa ragazza?',
  procedure
  begin
    // YES
    ShowMessage('Hai premuto SÌ');
  end,
  procedure
  begin
    // NO
    ShowMessage('Hai premuto NO');
  end
);
end;

procedure TForm1.AddGirlMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
begin
  if Girls.count < 48 then
    ShowAddGirlOverlay
    else begin
      ShowMessage ('Puoi gestire al massimo 48 ragazze');
    end;
end;
procedure TForm1.ShowAddGirlOverlay;
begin
  FAddGirlOverlay.Visible := True;
  FAddGirlOverlay.Opacity := 1.0;
  FAddGirlEdit.Text := '';
  FAddGirlEdit.SetFocus;
end;
procedure TForm1.HideAddGirlOverlay;
begin
  FAddGirlOverlay.Visible := False;
end;
procedure TForm1.AddGirlConfirm(Sender: TObject);
var
  GirlStorage: TGirlStorage;
  Data: TGirlData;
begin
  name := Trim(FAddGirlEdit.Text);
  if (Length(name) <= 0) then begin
    ShowMessage ( 'Inserisci un nome.' );
    exit;
  end;
  if not System.IOUtils.Tpath.HasValidFileNameChars( name , false ) then begin
    ShowMessage ( 'Inserisci un nome senza caratteri speciali.' );
    exit;
  end;

  if not FileExists( DirSaves + name + '.json') then begin
    Data.Prive := -1;
    Data.Start := 0;
    SetLength(Data.Activities, 0);
    GirlStorage.SaveGirl(name, Data);
    Girlgrid.AddGirl(name);
    FAddGirlEdit.Text := '';
  end
  else begin
    ShowMessage ( name + ' è già presente' );
  end;

  HideAddGirlOverlay;
end;

procedure TForm1.PaintCancel(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  Btn: TButton;
  TextRect: TRectF;
begin
  Btn := Sender as TButton;

  // sfondo
  Canvas.Fill.Color := $FFFFCCCC;
  Canvas.Fill.Kind  := TBrushKind.Solid;
  Canvas.FillRect(ARect, 8, 8, AllCorners, 1);

  // testo
  Canvas.Fill.Color := $FF000000; // nero
  Canvas.Font.Size := 24;//Btn.TextSettings.Font.Size;
  Canvas.Font.Family := Btn.TextSettings.Font.Family;
  Canvas.Font.Style :=   [TFontStyle.fsBold]; //Btn.TextSettings.Font.Style;

  TextRect := ARect;
  Canvas.FillText(TextRect, Btn.Text, False, 1, [], TTextAlign.Center, TTextAlign.Center);
end;
procedure TForm1.PaintOk(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  Btn: TButton;
  TextRect: TRectF;
begin
  Btn := Sender as TButton;

  // sfondo
  Canvas.Fill.Color := $FFCCFFCC;
  Canvas.Fill.Kind  := TBrushKind.Solid;
  Canvas.FillRect(ARect, 8, 8, AllCorners, 1);

  // testo
  Canvas.Fill.Color := $FF000000; // nero
  Canvas.Font.Size := 24;//Btn.TextSettings.Font.Size;
  Canvas.Font.Family := Btn.TextSettings.Font.Family;
  Canvas.Font.Style :=  [TFontStyle.fsBold]; //Btn.TextSettings.Font.Style;Btn.TextSettings.Font.Style;

  TextRect := ARect;
  Canvas.FillText(TextRect, Btn.Text, False, 1, [], TTextAlign.Center, TTextAlign.Center);
end;

procedure TForm1.AddGirlCancel(Sender: TObject);
begin
  HideAddGirlOverlay;
end;
procedure TForm1.CreateAddGirlOverlay;
var
  bg, box : TRectangle;
  title : TLabel;
  ok, cancel : TButton;
// footer con pulsanti affiancati
  footer: TLayout;
begin
  FAddGirlOverlay := TLayout.Create(Self);
  FAddGirlOverlay.Parent := Self;
  FAddGirlOverlay.Align := TAlignLayout.Contents;
  FAddGirlOverlay.Visible := False;
  FAddGirlOverlay.HitTest := True;
  FAddGirlOverlay.Opacity := 0.0;

  // sfondo scuro semi trasparente
  bg := TRectangle.Create(FAddGirlOverlay);
  bg.Parent := FAddGirlOverlay;
  bg.Align := TAlignLayout.Contents;
  bg.Fill.Color := $88000000;
  bg.Stroke.Kind := TBrushKind.None;

  // box centrale
  box := TRectangle.Create(FAddGirlOverlay);
  box.Parent := FAddGirlOverlay;
  box.Align := TAlignLayout.Center;
  box.Width := 800;
  box.Height := 300;
  box.XRadius := 20;
  box.YRadius := 20;
  box.Fill.Color := $FFFFFFFF;

  title := TLabel.Create(box);
  title.Parent := box;
  title.Align := TAlignLayout.Top;
  title.Text := 'Nuova ragazza';
  title.Margins.Top := 20;
  title.Font.Size := 14;
  title.Font.Style := [TFontStyle.fsBold];
  title.TextSettings.HorzAlign := TTextAlign.Center;
  title.TextSettings.VertAlign := TTextAlign.Center;
  title.Scale.X := 4;
  title.Scale.Y := 2;

  FAddGirlEdit := TEdit.Create(box);
  FAddGirlEdit.Parent := box;
  FAddGirlEdit.Align := TAlignLayout.Client;
  FAddGirlEdit.Font.Size := 22;
  FAddGirlEdit.Scale.X := 10;
  FAddGirlEdit.Scale.Y := 7;

  // FOOTER
  footer := TLayout.Create(box);
  footer.Parent := box;
  footer.Align := TAlignLayout.Bottom;
  footer.Height := 80;
  footer.Padding.Left := 20;
  footer.Padding.Right := 20;

  // Pulsante ANNULLA (sinistra)
  cancel := TButton.Create(footer);
  cancel.Parent := footer;
  cancel.Align := TAlignLayout.Left;
  cancel.Width := 380;
  cancel.Text := 'Annulla';
  cancel.Margins.Right := 40;
  cancel.OnClick := AddGirlCancel;

  // abilita colore custom
  cancel.StyledSettings := [];
  cancel.OnPaint := PaintCancel;
  cancel.TextSettings.FontColor := $FF000000; // testo nero
  cancel.TextSettings.HorzAlign := TTextAlign.Center;
  // rosso chiaro (background)

  // Pulsante AGGIUNGI (destra)
  ok := TButton.Create(footer);
  ok.Parent := footer;
  ok.Align := TAlignLayout.Right;
  ok.Width := 380;
  ok.Text := 'Aggiungi';
  ok.Margins.Left := 40;
  ok.OnClick := AddGirlConfirm;

  // abilita colore custom
  ok.StyledSettings := [];
  ok.OnPaint := PaintOk;
  ok.TextSettings.FontColor := $FF000000; // testo nero
  ok.TextSettings.HorzAlign := TTextAlign.Center;


end;


end.

