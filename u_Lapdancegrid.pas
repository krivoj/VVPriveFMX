unit u_LapDanceGrid;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Controls3D, FMX.Objects3D, FMX.MaterialSources, FMX.Graphics,
  FMX.Viewport3D, System.Math.Vectors ;

type
  TTileState = (tsOff, tsOn, tsAlarm);

  TModelTile = class
  public
    FPlane: TPlane;
    FMaterial: TTextureMaterialSource;
    GridIndex, CellX, CellY: Integer;
    procedure SetPosition(X, Y, Z: Single);
    procedure SetTexture(AOwner: TComponent; Bitmap: TBitmap);
    procedure Free;
  end;

  TLapDanceGrid = class
  private
    FViewport: TViewport3D;
    FDummyRoot: TDummy;
    FTileWidth, FTileHeight, FTileDepth: Single;

    TexOff, TexOn, TexAlarm: TBitmap;

    procedure LocalMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single; RayPos, RayDir: TVector3D);
    procedure CreateTextures;
  public
    FCols, FRows: Integer;
    FPaddingX, FPaddingY: Single;
    FTiles: array of array of TModelTile;
    constructor Create(AOwner: TComponent; AViewport: TViewport3D;
      Cols, Rows: Integer; TileWidth, TileHeight, PaddingX, PaddingY: Single);
    destructor Destroy; override;
    procedure DrawGrid;
    procedure SetTileState(Col, Row: Integer; AState: TTileState);
    procedure SetBasePosition(BaseX, BaseY: Single);
  end;

implementation
uses unit1;
{ TModelTile }

procedure TModelTile.SetPosition(X, Y, Z: Single);
begin
  FPlane.Position.X := X;
  FPlane.Position.Y := Y;
  FPlane.Position.Z := Z;
end;

procedure TModelTile.SetTexture(AOwner: TComponent; Bitmap: TBitmap);
begin
  if FMaterial = nil then
    FMaterial := TTextureMaterialSource.Create(AOwner);
  FMaterial.Texture.Assign(Bitmap);
  FPlane.MaterialSource := FMaterial;
end;

procedure TModelTile.Free;
begin
  if FPlane <> nil then FPlane.DisposeOf;
  if FMaterial <> nil then FMaterial.DisposeOf;
end;

{ TLapDanceGrid }

constructor TLapDanceGrid.Create(AOwner: TComponent; AViewport: TViewport3D;
  Cols, Rows: Integer; TileWidth, TileHeight, PaddingX, PaddingY: Single);
var
  X, Y: Integer;
  PosX, PosY: Single;
begin
  FViewport := AViewport;
  FCols := Cols;
  FRows := Rows;
  FTileWidth := TileWidth;
  FTileHeight := TileHeight;
  FTileDepth := 0.1;
  FPaddingX := PaddingX;
  FPaddingY := PaddingY;

  FDummyRoot := TDummy.Create(FViewport);
  FDummyRoot.Parent := FViewport;
  FDummyRoot.Position.Point := Point3D(0, 0, 0);

  CreateTextures;

  SetLength(FTiles, FCols, FRows);
  for Y := 0 to FRows - 1 do
    for X := 0 to FCols - 1 do
    begin
      FTiles[X, Y] := TModelTile.Create;
      FTiles[X, Y].FPlane := TPlane.Create(FDummyRoot);
      FTiles[X, Y].FPlane.Parent := FDummyRoot;
      FTiles[X, Y].FPlane.Width := FTileWidth;
      FTiles[X, Y].FPlane.Height := FTileHeight;
      FTiles[X, Y].FPlane.HitTest := True;
      FTiles[X, Y].FPlane.Tag := X*FRows + Y;
      FTiles[X, Y].FPlane.OnMouseDown := LocalMouseDown;
      FTiles[X, Y].GridIndex := X*FRows+Y;
      FTiles[X, Y].CellX := X;
      FTiles[X, Y].CellY := Y;
      PosX := X * (FTileWidth + FPaddingX) + FTileWidth/2;
      PosY := (FRows - 1 - Y) * (FTileHeight + FPaddingY) + FTileHeight/2;
      FTiles[X, Y].SetPosition(PosX, PosY, FTileDepth/2);
      FTiles[X, Y].SetTexture(AOwner, TexOff);
    end;
end;

destructor TLapDanceGrid.Destroy;
var
  X,Y: Integer;
begin
  for Y := 0 to FRows-1 do
    for X := 0 to FCols-1 do
      FTiles[X,Y].Free;
  TexOff.Free;
  TexOn.Free;
  TexAlarm.Free;
  FDummyRoot.DisposeOf;
  inherited;
end;

procedure TLapDanceGrid.CreateTextures;

  procedure FillBitmap(ABitmap: TBitmap; AColor: TAlphaColor);
  var x,y: Integer; bmpData: TBitmapData;
  begin
    ABitmap.SetSize(Round(FTileWidth), Round(FTileHeight));
    if ABitmap.Map(TMapAccess.Write, bmpData) then
    begin
      for y := 0 to bmpData.Height-1 do
        for x := 0 to bmpData.Width-1 do
          bmpData.SetPixel(x, y, AColor);
      ABitmap.Unmap(bmpData);
    end;
  end;

begin
  TexOff := TBitmap.Create;
  TexOn := TBitmap.Create;
  TexAlarm := TBitmap.Create;

  FillBitmap(TexOff, TAlphaColors.Silver);
  FillBitmap(TexOn, TAlphaColors.Limegreen);
  FillBitmap(TexAlarm, TAlphaColors.Crimson);
end;

procedure TLapDanceGrid.DrawGrid;
var X,Y: Integer; PosX, PosY: Single;
begin
  for Y := 0 to FRows-1 do
    for X := 0 to FCols-1 do
    begin
      PosX := X * (FTileWidth + FPaddingX) + FTileWidth/2;
      PosY := (FRows - 1 - Y) * (FTileHeight + FPaddingY) + FTileHeight/2;
      FTiles[X,Y].SetPosition(PosX, PosY, FTileDepth/2);
    end;
end;

procedure TLapDanceGrid.SetTileState(Col, Row: Integer; AState: TTileState);
begin
  if (Col<0) or (Col>=FCols) or (Row<0) or (Row>=FRows) then Exit;
  case AState of
    tsOff: FTiles[Col,Row].SetTexture(FViewport.Owner, TexOff);
    tsOn: FTiles[Col,Row].SetTexture(FViewport.Owner, TexOn);
    tsAlarm: FTiles[Col,Row].SetTexture(FViewport.Owner, TexAlarm);
  end;
end;

procedure TLapDanceGrid.LocalMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Single; RayPos, RayDir: TVector3D);
begin
  if Assigned(Form1) then
    Form1.TileMouseDown(Sender, Button, TPlane(Sender).Tag);
end;
procedure TLapDanceGrid.SetBasePosition(BaseX, BaseY: Single);
var
  X, Y: Integer;
  PosX, PosY: Single;
begin
  for Y := 0 to FRows-1 do
    for X := 0 to FCols-1 do
    begin
      PosX := BaseX + X * (FTileWidth + FPaddingX) + FTileWidth/2;
      PosY := BaseY + (FRows - 1 - Y) * (FTileHeight + FPaddingY) + FTileHeight/2;
      FTiles[X,Y].SetPosition(PosX, PosY, FTileDepth/2);
    end;
end;
end.

