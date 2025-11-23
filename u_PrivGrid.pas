unit u_PrivGrid;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Math.Vectors, System.Generics.Collections, FMX.Graphics, FMX.Controls, FMX.Objects,
  FMX.Types3D, FMX.Types, FMX.Controls3D, FMX.Objects3D, FMX.MaterialSources, FMX.Viewport3D;

type
  TTileState = (tsOff, tsOn, tsAlarm);
  TPrivStatus = class
    State: TTileState;
    Girls: Array of string;
  end;

  TStateChangedEvent = procedure(Sender: TObject; TileTag: Integer; Data: TPrivStatus) of object;
  TTileMouseDownEvent = procedure(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; TileTag: Integer) of object;


  TPrivGrid = class
  private
    FCols, FRows: Integer;
    FTileWidth, FTileHeight: Single;
    FPadX, FPadY: Single;
    FViewport: TViewport3D;
    FRoot: TDummy;
    FTiles: array of array of TPlane;

    MatOff, MatOn, MatAlarm: TTextureMaterialSource;
    TexOff, TexOn, TexAlarm: TBitmap;
    MatText: TColorMaterialSource;

    procedure CreateRoundedBitmap(ABitmap: TBitmap; AColor: TAlphaColor);
    procedure InternalMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
    procedure InternalImgMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
    procedure InternalImgAddMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);

    procedure SetTileStateInternal(ATile: TPlane; AState: TTileState);
    function GetTileByTag(Tag: Integer): TPlane;

  public
    OnTileMouseDown: TTileMouseDownEvent;
    OnImgMouseDown: TTileMouseDownEvent;
    OnImgAddMouseDown: TTileMouseDownEvent;
    OnStateChanged: TStateChangedEvent;
    constructor Create(AParent: TViewport3D; Cols, Rows: Integer;
      TileW, TileH, PadX, PadY: Single);
    destructor Destroy; override;

    procedure SetTileState(Col, Row: Integer; State: TTileState);
    procedure SetBasePosition(BaseX, BaseY: Single);
    procedure ToggleTileState(ImgPlane: TPlane);
  end;

procedure MakeRoundedBitmap(ABitmap: TBitmap; AColor: TAlphaColor; const Text: string = '');

implementation

{ TPrivGrid }

constructor TPrivGrid.Create(AParent: TViewport3D; Cols, Rows: Integer;
  TileW, TileH, PadX, PadY: Single);
var
  X, Y, TotCells: Integer;
  Plane, ImgSwitch, ImgAdd: TPlane;
  Txt: TText3D;
  Data: TPrivStatus;
  ImgBitmap: TBitmap;
  ImgMat, ImgMatAdd: TTextureMaterialSource;
  BaseBitmap: TBitmap;
  RS : TResourceStream;
begin
  inherited Create;
  FViewport := AParent;
  FCols := Cols;
  FRows := Rows;
  FTileWidth := TileW;
  FTileHeight := TileH;
  FPadX := PadX;
  FPadY := PadY;

  FRoot := TDummy.Create(FViewport);
  FRoot.Parent := FViewport;

  RS := TResourceStream.Create(HInstance, 'PNGADD', RT_RCDATA);
  ImgMatAdd := TTextureMaterialSource.Create(FViewport);
  ImgMatAdd.Texture.LoadFromStream(RS);
  RS.Free;


  // Creazione texture arrotondate principali
  TexOff := TBitmap.Create;
  TexOn := TBitmap.Create;
  TexAlarm := TBitmap.Create;
  CreateRoundedBitmap(TexOff, TAlphaColors.Gray);
  CreateRoundedBitmap(TexOn, TAlphaColors.Limegreen);
  CreateRoundedBitmap(TexAlarm, TAlphaColors.Crimson);

  MatOff := TTextureMaterialSource.Create(FViewport);
  MatOff.Texture.Assign(TexOff);
  MatOn := TTextureMaterialSource.Create(FViewport);
  MatOn.Texture.Assign(TexOn);
  MatAlarm := TTextureMaterialSource.Create(FViewport);
  MatAlarm.Texture.Assign(TexAlarm);

  MatText := TColorMaterialSource.Create(FViewport);
  MatText.Color := TAlphaColorRec.White;

  // Bitmap di base rosso "OFF" da clonare
  BaseBitmap := TBitmap.Create(128,128);
  MakeRoundedBitmap(BaseBitmap, TAlphaColorRec.Crimson, 'OFF');

  // Crea celle
  TotCells := 0;
  SetLength(FTiles, FCols, FRows);

  for Y := 0 to FRows - 1 do
    for X := 0 to FCols - 1 do
    begin
      Data := TPrivStatus.Create;
      Data.State := tsOff;

      Plane := TPlane.Create(FViewport);
      Plane.TagObject := Data;
      Plane.Parent := FRoot;
      Plane.Width := FTileWidth;
      Plane.Height := FTileHeight;
      Plane.MaterialSource := MatOff;
      Plane.Position.X := X * (FTileWidth + FPadX);
      Plane.Position.Y := (FRows - 1 - Y) * (FTileHeight + FPadY);
      Plane.Tag := TotCells;
      Inc(TotCells);
      Plane.HitTest := True;
      Plane.OnMouseDown := InternalMouseDown;

      // Testo identificativo della cella
      Txt := TText3D.Create(Plane);
      Txt.Parent := Plane;
      Txt.Font.Size := 8;
      Txt.WordWrap := False;
      Txt.MaterialSource := MatText;
      Txt.Text := IntToStr(Plane.Tag+1);
      Txt.Depth := 0.01;
      Txt.Scale.X := 0.18;
      Txt.Scale.Y := 0.18;
      Txt.Position.X := -FTileWidth / 3.3;
      Txt.Position.Y := FTileHeight / 3;
      Txt.Position.Z := 0.05;
      Txt.RotationAngle.X := -180;
      Txt.HitTest := False;


      // Crea bitmap e materiale indipendente per l'icona ON/OFF
      ImgBitmap := TBitmap.Create(128,128);
      ImgBitmap.Assign(BaseBitmap); // copia la bitmap di base rossa OFF
      ImgMat := TTextureMaterialSource.Create(FViewport);
      ImgMat.Texture.Assign(ImgBitmap);
      ImgBitmap.Free; // <--- evitare memory leak

      ImgSwitch := TPlane.Create(FViewport);
      ImgSwitch.Parent := Plane;
      ImgSwitch.Width := FTileWidth * 0.16;
      ImgSwitch.Height := FTileHeight * 0.16;
      ImgSwitch.Position.X := (Plane.Width / 2) - (ImgSwitch.Width / 1);
      ImgSwitch.Position.Y := (Plane.Height / 2) - (ImgSwitch.Height / 1);
      ImgSwitch.Position.Z := 0.05;
      ImgSwitch.MaterialSource := ImgMat;
      ImgSwitch.TagObject := Data;
      ImgSwitch.Tag := Plane.Tag;
      ImgSwitch.OnMouseDown := InternalImgMouseDown;
      ImgSwitch.HitTest := True;
      ImgSwitch.RotationAngle.X := 180;
      ImgSwitch.Cursor := crHandPoint;


      ImgAdd := TPlane.Create(FViewport);
      ImgAdd.Parent := Plane;
      ImgAdd.Width := FTileWidth * 0.16;
      ImgAdd.Height := FTileHeight * 0.16;
      ImgAdd.Position.X := (Plane.Width / 2 )  - 1.25;
      ImgAdd.Position.Y := (Plane.Height / 2) - (ImgAdd.Height / 1);
      ImgAdd.Position.Z := 0.05;
      ImgAdd.MaterialSource := ImgMatAdd;
      ImgAdd.TagObject := Data;
      ImgAdd.Tag := Plane.Tag;
      ImgAdd.OnMouseDown := InternalImgAddMouseDown;
      ImgAdd.HitTest := True;
      ImgAdd.RotationAngle.X := 180;
      ImgAdd.Cursor := crHandPoint;


      FTiles[X, Y] := Plane;
    end;

  BaseBitmap.Free;
end;

destructor TPrivGrid.Destroy;
var
  X, Y: Integer;
begin
  for Y := 0 to FRows - 1 do
    for X := 0 to FCols - 1 do
      FTiles[X, Y].DisposeOf;

  TexOff.Free;
  TexOn.Free;
  TexAlarm.Free;
  MatOff.Free;
  MatOn.Free;
  MatAlarm.Free;
  MatText.Free;
  FRoot.DisposeOf;
  inherited;
end;

procedure TPrivGrid.CreateRoundedBitmap(ABitmap: TBitmap; AColor: TAlphaColor);
var
  R: TRectF;
begin
  ABitmap.SetSize(128,128);
  ABitmap.Clear(0);
  R := RectF(4,4,124,124);

  ABitmap.Canvas.BeginScene;
  try
    ABitmap.Canvas.Fill.Kind := TBrushKind.Solid;
    ABitmap.Canvas.Fill.Color := AColor;
    ABitmap.Canvas.FillRect(R,20,20,AllCorners,1.0);
  finally
    ABitmap.Canvas.EndScene;
  end;
end;

procedure TPrivGrid.InternalMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
begin
  if (Sender is TPlane) and Assigned(OnTileMouseDown) then
    OnTileMouseDown(Sender, Button, Shift, TPlane(Sender).Tag);
end;

procedure TPrivGrid.InternalImgMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
begin
  if Sender is TPlane then
  begin
    ToggleTileState(TPlane(Sender));

    if Assigned(OnImgMouseDown) then
      OnImgMouseDown(Sender, Button, Shift, TPlane(Sender).Tag);
  end;
end;
procedure TPrivGrid.InternalImgAddMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
begin
    if Assigned(OnImgAddMouseDown) then
      OnImgAddMouseDown(Sender, Button, Shift, TPlane(Sender).Tag);

end;
procedure TPrivGrid.SetTileStateInternal(ATile: TPlane; AState: TTileState);
begin
  case AState of
    tsOff: ATile.MaterialSource := MatOff;
    tsOn: ATile.MaterialSource := MatOn;
    tsAlarm: ATile.MaterialSource := MatAlarm;
  end;
end;

procedure TPrivGrid.SetTileState(Col, Row: Integer; State: TTileState);
begin
  if (Col >= 0) and (Col < FCols) and (Row >= 0) and (Row < FRows) then
    SetTileStateInternal(FTiles[Col, Row], State);
end;

procedure TPrivGrid.SetBasePosition(BaseX, BaseY: Single);
begin
  FRoot.Position.X := BaseX;
  FRoot.Position.Y := BaseY;
end;

function TPrivGrid.GetTileByTag(Tag: Integer): TPlane;
var
  X, Y: Integer;
begin
  Result := nil;
  for Y := 0 to FRows - 1 do
    for X := 0 to FCols - 1 do
      if Assigned(FTiles[X,Y]) and (FTiles[X,Y].Tag = Tag) then
      begin
        Result := FTiles[X,Y];
        Exit;
      end;
end;

procedure MakeRoundedBitmap(ABitmap: TBitmap; AColor: TAlphaColor; const Text: string = '');
var
  R: TRectF;
  Radius: Single;
begin
  ABitmap.SetSize(128,128);
  ABitmap.Clear(0);
  Radius := ABitmap.Height * 0.4;
  R := RectF(0,0,ABitmap.Width,ABitmap.Height);

  ABitmap.Canvas.BeginScene;
  try
    // Fill
    ABitmap.Canvas.Fill.Kind := TBrushKind.Solid;
    ABitmap.Canvas.Fill.Color := AColor;
    ABitmap.Canvas.FillRect(R, Radius, Radius, AllCorners, 1);

    // Border
    ABitmap.Canvas.Stroke.Kind := TBrushKind.Solid;
    ABitmap.Canvas.Stroke.Thickness := 2;
    ABitmap.Canvas.Stroke.Color := TAlphaColorRec.Black;
    ABitmap.Canvas.DrawRect(R, Radius, Radius, AllCorners, 1);

    // Disegna testo se fornito
    if Text <> '' then
    begin
      ABitmap.Canvas.Fill.Color := TAlphaColorRec.White;
      ABitmap.Canvas.Font.Size := 40;
      ABitmap.Canvas.Font.Style := [TFontStyle.fsBold];
      ABitmap.Canvas.FillText(R, Text, False, 1.0, [], TTextAlign.Center, TTextAlign.Center);
    end;
  finally
    ABitmap.Canvas.EndScene;
  end;
end;
procedure TPrivGrid.ToggleTileState(ImgPlane: TPlane);
var
  Data: TPrivStatus;
  ImgMat: TTextureMaterialSource;
  NewColor: TAlphaColor;
  MainTile: TPlane;
  StatusText: string;
  OldState: TTileState;
begin
  Data := TPrivStatus(ImgPlane.TagObject);
  ImgMat := ImgPlane.MaterialSource as TTextureMaterialSource;

  OldState := Data.State;  // ← memorizzi lo stato precedente

  case Data.State of
    tsOff: begin
      Data.State := tsOn;
      NewColor := TAlphaColorRec.Limegreen;
      StatusText := 'ON';
    end;
    tsOn: begin
      Data.State := tsOff;
      NewColor := TAlphaColorRec.Crimson;
      StatusText := 'OFF';
    end;
    else Exit;
  end;

  // Se niente è cambiato esci
  if OldState = Data.State then
    Exit;

  // Redraw bitmap
  ImgMat.Texture.SetSize(128,128);
  MakeRoundedBitmap(ImgMat.Texture, NewColor, StatusText);

  // Aggiorna il tile principale
  MainTile := GetTileByTag(ImgPlane.Tag);
  if Assigned(MainTile) then
    SetTileStateInternal(MainTile, Data.State);

  // 🔥 EVENTO STATE-CHANGED
  if Assigned(OnStateChanged) then
    OnStateChanged(Self, MainTile.Tag, Data);
end;
end.

