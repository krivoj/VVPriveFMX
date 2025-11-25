unit u_GirlGrid;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, Math, Generics.defaults,
  System.Math.Vectors, System.Generics.Collections, FMX.Graphics, FMX.Controls, FMX.Objects, u_Privgrid,
  FMX.Types3D, FMX.Types, FMX.Controls3D, FMX.Objects3D, FMX.MaterialSources, FMX.Viewport3D;

type

  TGirlGridMouseDownEvent = procedure(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; TagString: string) of object;

  TGirl = record
    Name: string;
    Prive: integer;
  end;
type
  PGirl = ^TGirl;

  TGirlGrid = class
  private
    FCols, FRows: Integer;
    FTileWidth, FTileHeight: Single;
    FPadX, FPadY: Single;
    FViewport: TViewport3D;
    FRoot: TDummy;
    FPrivGrid: TPrivGrid;
    FTiles: array of array of TPlane;
    FGirls: Tlist<TGirl>;

    MatText: TColorMaterialSource;


    procedure CreateRoundedBitmap(ABitmap: TBitmap; AColor: TAlphaColor);
    procedure InternalMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
    procedure InternalImgDeleteMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
    procedure InternalImgInfoMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);

    function GetTileByText(Text: String): TPlane;
    procedure RebuildGrid;

  public
    Mat, MatHighLight: TTextureMaterialSource;

    OnGirlGridMouseDown: TGirlGridMouseDownEvent;
    OnGirlGridImgDeleteMouseDown: TGirlGridMouseDownEvent;
    OnGirlGridImgInfoMouseDown: TGirlGridMouseDownEvent;

    constructor Create(AParent: TViewport3D;
      TileW, TileH, PadX, PadY: Single; const PrivGrid:TPrivGrid;  const LstGirls: Tlist<TGirl>);
    destructor Destroy; override;
    procedure SetBasePosition(BaseX, BaseY: Single);

    procedure AddGirl(const GirlName: string);
    procedure DeleteGirl(const GirlName: string);
    function IndexOfGirl(const AGirlName: string): Integer;
    function GetGirl(const AGirlName: string): TGirl;
  end;


implementation

{ TGirlGrid }

constructor TGirlGrid.Create(AParent: TViewport3D;
  TileW, TileH, PadX, PadY: Single; const PrivGrid:TPrivGrid; const LstGirls: Tlist<TGirl>);
var
  RS : TResourceStream;
begin

  inherited Create;
  FViewport := AParent;
  FGirls :=  LstGirls;
  FPrivGrid := PrivGrid;
  // Griglia fissa
  FCols := 2;
  FRows := 24;
  FTileWidth := TileW;
  FTileHeight := TileH;
  FPadX := PadX;
  FPadY := PadY;

  FRoot := TDummy.Create(FViewport);
  FRoot.Parent := FViewport;

  RS := TResourceStream.Create(HInstance, 'PNGBUTTONGIRL', RT_RCDATA);
  Mat := TTextureMaterialSource.Create(FViewport);
  Mat.Texture.LoadFromStream(RS);
  RS.Free;

  RS := TResourceStream.Create(HInstance, 'PNGBUTTONGIRL', RT_RCDATA);
  MatHighLight := TTextureMaterialSource.Create(FViewport);
  MatHighLight.Texture.LoadFromStream(RS);
  RS.Free;


  MatText := TColorMaterialSource.Create(FViewport);
  MatText.Color := TAlphaColorRec.White;

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


  Mat.Free;
  MatHighLight.Free;
  MatText.Free;
  FRoot.DisposeOf;
  inherited;
end;

procedure TGirlGrid.RebuildGrid;
var
  col, row, i: Integer;
  Plane: TPlane;
  Txt: TText3D;
  ImgMatDelete,ImgMatInfo: TTextureMaterialSource;
  ImgPlaneDelete, ImgPlaneInfo: TPlane;
  RS: TResourceStream;
  APrivPlane: TPlane;
begin
  RS := TResourceStream.Create(HInstance, 'PNGDELETE', RT_RCDATA);
  ImgMatDelete := TTextureMaterialSource.Create(FViewport);
  ImgMatDelete.Texture.LoadFromStream(RS);
  RS.Free;
  RS := TResourceStream.Create(HInstance, 'PNGINFO', RT_RCDATA);
  ImgMatInfo := TTextureMaterialSource.Create(FViewport);
  ImgMatInfo.Texture.LoadFromStream(RS);
  RS.Free;

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
      if i >= FGirls.Count then Exit;

      Plane := TPlane.Create(FViewport);
      Plane.Width := FTileWidth;
      Plane.Height := FTileHeight;
      Plane.MaterialSource := Mat;

      if FGirls[i].Prive < 0 then
      begin
        Plane.Parent := FRoot;
        Plane.Position.X := -((FCols - 1) - col) * (FTileWidth + FPadX);
        Plane.Position.Y := (FRows - 1 - row) * (FTileHeight + FPadY);  // alto -> basso
      end
      else begin
        // LA RAGAZZA E' IN PRIVE
        APrivPlane := FPrivGrid.GetTileByTag(FGirls[i].Prive);
        Plane.Parent := APrivPlane;
        Plane.Position.X := 0;
        Plane.Position.Y := 0;
      end;

      Plane.HitTest := True;
      Plane.OnMouseDown := InternalMouseDown;

      Plane.Tag := i;
      Plane.TagString := Uppercase(FGirls[i].Name);
      Plane.Cursor := crHandPoint;

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


      ImgPlaneDelete := TPlane.Create(FViewport);
      ImgPlaneDelete.Parent := Plane;
      ImgPlaneDelete.Width := FTileWidth * 0.15;
      ImgPlaneDelete.Height := FTileHeight * 0.60;
      ImgPlaneDelete.Position.X := (Plane.Width / 2) - 0.25;
      ImgPlaneDelete.Position.Y := (Plane.Height / 2) - 0.2 ;
      ImgPlaneDelete.Position.Z := 0.05;
      ImgPlaneDelete.MaterialSource := ImgMatdelete;
      ImgPlaneDelete.TagString := Uppercase(FGirls[i].Name);
      ImgPlaneDelete.Tag := Plane.Tag;
      ImgPlaneDelete.OnMouseDown := InternalImgDeleteMouseDown;
      ImgPlaneDelete.HitTest := True;
      ImgPlaneDelete.RotationAngle.X := 180;
      ImgPlaneDelete.Cursor := crHandPoint;

      ImgPlaneInfo := TPlane.Create(FViewport);
      ImgPlaneInfo.Parent := Plane;
      ImgPlaneInfo.Width := FTileWidth * 0.15;
      ImgPlaneInfo.Height := FTileHeight * 0.60;
      ImgPlaneInfo.Position.X := -(Plane.Width / 2) + 0.2;
      ImgPlaneInfo.Position.Y := (Plane.Height / 2) - 0.2 ;
      ImgPlaneInfo.Position.Z := 0.05;
      ImgPlaneInfo.MaterialSource := ImgMatInfo;
      ImgPlaneInfo.TagString := Uppercase(FGirls[i].Name);
      ImgPlaneInfo.Tag := Plane.Tag;
      ImgPlaneInfo.OnMouseDown := InternalImgInfoMouseDown;
      ImgPlaneInfo.HitTest := True;
      ImgPlaneInfo.RotationAngle.X := 180;
      ImgPlaneInfo.Cursor := crHandPoint;


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
procedure TGirlGrid.InternalImgInfoMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
begin
  if (Sender is TPlane) and Assigned(OnGirlGridImgInfoMouseDown) then
    OnGirlGridImgInfoMouseDown(Sender, Button, Shift, TPlane(Sender).TagString);
end;


procedure TGirlGrid.SetBasePosition(BaseX, BaseY: Single);
begin
  FRoot.Position.X := BaseX;
  FRoot.Position.Y := BaseY;
end;

procedure TGirlGrid.AddGirl(const GirlName: string);
var
  AGirl: TGirl;
begin
  if GirlName.Trim = '' then Exit;
  AGirl.Name := GirlName;
  AGirl.Prive := -1;
  FGirls.Add(AGirl);
  FGirls.Sort(TComparer<TGirl>.Construct(
    function(const A, B: TGirl): Integer
    begin
      Result := CompareText(A.Name, B.Name);  // ordina per Name
    end));
    RebuildGrid;
  end;
procedure TGirlGrid.DeleteGirl(const GirlName: string);
var
  idx: Integer;
begin
  if GirlName.Trim = '' then Exit;

  idx := IndexOfGirl(GirlName);
  if idx < 0 then
    Exit; // non trovata

  FGirls.Delete(idx);
  FGirls.Sort(TComparer<TGirl>.Construct(
    function(const A, B: TGirl): Integer
    begin
      Result := CompareText(A.Name, B.Name);  // ordina per Name
    end));
  RebuildGrid;
end;
function TGirlGrid.IndexOfGirl(const AGirlName: string): Integer;
var
  i: Integer;
begin
  for i := 0 to FGirls.Count - 1 do
    if SameText(FGirls[i].Name, AGirlName) then
      Exit(i);

  Result := -1; // non trovata
end;
function TGirlGrid.GetGirl(const AGirlName: string): TGirl;
var
  i: Integer;
begin
  for i := 0 to FGirls.Count - 1 do
    if SameText(FGirls[i].Name, AGirlName) then
      Exit(FGirls[i]);

  Result := Default(TGirl);
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


end.

