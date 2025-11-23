unit u_GirlGrid;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, Math,
  System.Math.Vectors, System.Generics.Collections, FMX.Graphics, FMX.Controls, FMX.Objects,
  FMX.Types3D, FMX.Types, FMX.Controls3D, FMX.Objects3D, FMX.MaterialSources, FMX.Viewport3D;

type

  TGirlGridMouseDownEvent = procedure(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; TagString: string) of object;

  TGirlGrid = class
  private
    FCols, FRows: Integer;
    FTileWidth, FTileHeight: Single;
    FPadX, FPadY: Single;
    FViewport: TViewport3D;
    FRoot: TDummy;
    FTiles: array of array of TPlane;

    Mat: TTextureMaterialSource;
    Tex: TBitmap;
    MatText: TColorMaterialSource;


    procedure CreateRoundedBitmap(ABitmap: TBitmap; AColor: TAlphaColor);
    procedure InternalMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
    procedure InternalImgDeleteMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);

    function GetTileByText(Text: String): TPlane;
    procedure RebuildGrid;

  public
    FNames: TStringList;
    OnGirlGridMouseDown: TGirlGridMouseDownEvent;
    OnGirlGridImgDeleteMouseDown: TGirlGridMouseDownEvent;

    constructor Create(AParent: TViewport3D;
      TileW, TileH, PadX, PadY: Single; LstGirls: TstringList);
    destructor Destroy; override;
    procedure SetBasePosition(BaseX, BaseY: Single);

    procedure AddGirl(const GirlName: string);
    procedure DeleteGirl(const GirlName: string);
  end;

procedure MakeRoundedBitmap(ABitmap: TBitmap; AColor: TAlphaColor; const Text: string = '');

implementation

{ TGirlGrid }

constructor TGirlGrid.Create(AParent: TViewport3D;
  TileW, TileH, PadX, PadY: Single; LstGirls: TstringList);
begin

  inherited Create;
  FViewport := AParent;

  // Griglia fissa
  FCols := 2;
  FRows := 24;
  FTileWidth := TileW;
  FTileHeight := TileH;
  FPadX := PadX;
  FPadY := PadY;

  FRoot := TDummy.Create(FViewport);
  FRoot.Parent := FViewport;

  Tex := TBitmap.Create;
  CreateRoundedBitmap(Tex, TAlphaColors.Gray);

  Mat := TTextureMaterialSource.Create(FViewport);
  Mat.Texture.Assign(Tex);

  MatText := TColorMaterialSource.Create(FViewport);
  MatText.Color := TAlphaColorRec.White;

  FNames := TStringList.Create;
  FNames.CaseSensitive := False;
  FNames.Sorted := True;
  FNames.Duplicates := dupIgnore;
  if Assigned(LstGirls) then
    FNames.Assign(LstGirls);

  SetLength(FTiles, FCols, FRows);
  FillChar(FTiles[0,0], SizeOf(TPlane)*FCols*FRows, 0);

  RebuildGrid;
end;

destructor TGirlGrid.Destroy;
var
  X, Y: Integer;
begin
  for X := 0 to High(FTiles) do
    for Y := 0 to FRows - 1 do
      if Assigned(FTiles[X, Y]) then
      begin
        FTiles[X, Y].DisposeOf;
        FTiles[X, Y] := nil;
      end;

  FNames.Free;

  Tex.Free;
  Mat.Free;
  MatText.Free;
  FRoot.DisposeOf;
  inherited;
end;

procedure TGirlGrid.RebuildGrid;
var
  col, row, i: Integer;
  Plane: TPlane;
  Txt: TText3D;
  ImgBitmap: TBitmap;
  ImgMat: TTextureMaterialSource;
  BaseBitmap: TBitmap;
  ImgPlane: TPlane;
begin
  BaseBitmap := TBitmap.Create(64,64);
  MakeRoundedBitmap(BaseBitmap, TAlphaColorRec.Crimson, '-');
  // Crea bitmap e materiale indipendente per l'icona -
  ImgBitmap := TBitmap.Create(64,64);
  ImgBitmap.Assign(BaseBitmap); // copia la bitmap di base rossa OFF
  ImgMat := TTextureMaterialSource.Create(FViewport);
  ImgMat.Texture.Assign(ImgBitmap);
  ImgBitmap.Free; // <--- evitare memory leak

  // Dispose tiles esistenti
  for col := 0 to FCols - 1 do
    for row := 0 to FRows - 1 do
      if Assigned(FTiles[col,row]) then
      begin
        FTiles[col,row].DisposeOf;
        FTiles[col,row] := nil;
      end;

  i := 0;
  for col := FCols - 1 downto 0 do       // destra -> sinistra
    for row := 0 to FRows - 1 do        // dall’alto verso il basso
    begin
      if i >= FNames.Count then Exit;

      Plane := TPlane.Create(FViewport);
      Plane.Parent := FRoot;
      Plane.Width := FTileWidth;
      Plane.Height := FTileHeight;
      Plane.MaterialSource := Mat;

      Plane.Position.X := -((FCols - 1) - col) * (FTileWidth + FPadX);
      Plane.Position.Y := (FRows - 1 - row) * (FTileHeight + FPadY);  // alto -> basso

      Plane.HitTest := True;
      Plane.OnMouseDown := InternalMouseDown;

      Plane.Tag := i;
      Plane.TagString := Uppercase(FNames[i]);
      FTiles[col,row] := Plane;

      Txt := TText3D.Create(Plane);
      Txt.Parent := Plane;
      Txt.Font.Size := 8;
      Txt.WordWrap := False;
      Txt.MaterialSource := MatText;
      Txt.Text := Plane.TagString;
      Txt.TagString := Plane.TagString;
      Txt.HorzTextAlign := TTextAlign.Center;
      Txt.VertTextAlign := TTextAlign.Center;
      Txt.Position.X := 0;
      Txt.Position.Y := 0;
      Txt.Depth := 0;
      Txt.Scale.X := 0.35;
      Txt.Scale.Y := 0.15;
      Txt.Stretch := False;
      Txt.Position.Z := 0.05;
      Txt.RotationAngle.X := -180;
      Txt.HitTest := False;


      ImgPlane := TPlane.Create(FViewport);
      ImgPlane.Parent := Plane;
      ImgPlane.Width := FTileWidth * 0.10;
      ImgPlane.Height := FTileHeight * 0.50;
      ImgPlane.Position.X := (Plane.Width / 2) - 0.2;
      ImgPlane.Position.Y := (Plane.Height / 2) - 0.2 ;
      ImgPlane.Position.Z := 0.05;
      ImgPlane.MaterialSource := ImgMat;
      ImgPlane.TagString := Uppercase(FNames[i]);
      ImgPlane.Tag := Plane.Tag;
      ImgPlane.OnMouseDown := InternalImgDeleteMouseDown;
      ImgPlane.HitTest := True;
      ImgPlane.RotationAngle.X := 180;
      ImgPlane.Cursor := crHandPoint;



      Inc(i);
    end;
end;

procedure TGirlGrid.CreateRoundedBitmap(ABitmap: TBitmap; AColor: TAlphaColor);
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

procedure TGirlGrid.InternalMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
begin
  if (Sender is TPlane) and Assigned(OnGirlGridMouseDown) then
    OnGirlGridMouseDown(Sender, Button, Shift, TPlane(Sender).TagString);
end;

procedure TGirlGrid.InternalImgDeleteMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
begin
  if (Sender is TPlane) and Assigned(OnGirlGridImgDeleteMouseDown) then
    OnGirlGridImgDeleteMouseDown(Sender, Button, Shift, TPlane(Sender).TagString);
end;


procedure TGirlGrid.SetBasePosition(BaseX, BaseY: Single);
begin
  FRoot.Position.X := BaseX;
  FRoot.Position.Y := BaseY;
end;

procedure TGirlGrid.AddGirl(const GirlName: string);
begin
  if GirlName.Trim = '' then Exit;

  FNames.Add(GirlName);
  FNAmes.Sort;
  RebuildGrid;
end;
procedure TGirlGrid.DeleteGirl(const GirlName: string);
var
  idx: Integer;
begin
  if GirlName.Trim = '' then Exit;

  idx := FNames.IndexOf(GirlName);
  if idx < 0 then
    Exit; // non trovata

  FNames.Delete(idx);
  FNames.Sort;

  RebuildGrid;
end;
function TGirlGrid.GetTileByText(Text: String): TPlane;
var
  X, Y: Integer;
begin
  Result := nil;
  for Y := 0 to FRows - 1 do
    for X := 0 to FCols - 1 do
      if Assigned(FTiles[X,Y]) and (FTiles[X,Y].TagString = Text) then
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
    ABitmap.Canvas.Fill.Kind := TBrushKind.Solid;
    ABitmap.Canvas.Fill.Color := AColor;
    ABitmap.Canvas.FillRect(R, Radius, Radius, AllCorners, 1);

    ABitmap.Canvas.Stroke.Kind := TBrushKind.Solid;
    ABitmap.Canvas.Stroke.Thickness := 2;
    ABitmap.Canvas.Stroke.Color := TAlphaColorRec.Black;
    ABitmap.Canvas.DrawRect(R, Radius, Radius, AllCorners, 1);

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

end.

