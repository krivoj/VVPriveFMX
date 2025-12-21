unit u_GirlGrid;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, Math, Generics.defaults,System.IOUtils, FMX.Dialogs,
  System.Math.Vectors, System.Generics.Collections, FMX.Graphics, FMX.Controls, FMX.Objects, u_Privgrid,u_GirlStorage, u_lang,
  FMX.Types3D, FMX.Types, FMX.Controls3D, FMX.Objects3D, FMX.MaterialSources, FMX.Viewport3D, FMX.Ani;

type

  TGirlGridMouseDownEvent = procedure(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; TagString: string) of object;

type
  TGirl = class
  public
    Name: string;
    Prive: Integer;
    Slot: Integer;
    Start: TDateTime;
  end;

  TGirlGrid = class
  private
    FCols, FRows: Integer;
    FTileWidth, FTileHeight: Single;
    FPadX, FPadY: Single;
    FViewport: TViewport3D;
    FPrivGrid: TPrivGrid;
    FTiles: array of array of TPlane;
    MatText: TColorMaterialSource;

    procedure CreateRoundedBitmap(ABitmap: TBitmap; AColor: TAlphaColor);
    procedure InternalMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
    procedure InternalImgDeleteMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);
    procedure InternalImgInfoMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single; RayPos, RayDir: TVector3D);

    function GetTileByGirlName(Text: String): TPlane;
  public
    FRoot: TDummy;
    Mat, MatHighLight, MatDelete, MatDelete2, MatInfo: TTextureMaterialSource;
    FGirls: TObjectlist<TGirl>;

    OnGirlGridMouseDown: TGirlGridMouseDownEvent;
    OnGirlGridImgDeleteMouseDown: TGirlGridMouseDownEvent;
    OnGirlGridImgInfoMouseDown: TGirlGridMouseDownEvent;

    constructor Create(AParent: TViewport3D;
      TileW, TileH, PadX, PadY: Single; const PrivGrid:TPrivGrid);
    destructor Destroy; override;
    procedure SetBasePosition(BaseX, BaseY: Single);

    procedure AddGirl(const GirlName: string);
    procedure DeleteGirl(const GirlName: string);
    function IndexOfGirl(const AGirlName: string): Integer;
    function GetGirl(const AGirlName: string): TGirl;
    procedure LoadfromFiles;
    procedure RebuildGrid;
    procedure UpdateGrid;
  end;


implementation
Uses unit1;
{ TGirlGrid }

constructor TGirlGrid.Create(AParent: TViewport3D;
  TileW, TileH, PadX, PadY: Single; const PrivGrid:TPrivGrid);
var
  RS : TResourceStream;
begin

  inherited Create;
  FViewport := AParent;
  FGirls := TObjectlist<TGirl>.Create(true);
//  FGirls :=  LstGirls;
  FPrivGrid := PrivGrid;
  // Griglia fissa
  FCols := 2;
  FRows := 20;
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

  RS := TResourceStream.Create(HInstance, 'PNGBUTTONGIRLHIGHLIGHT', RT_RCDATA);
  MatHighLight := TTextureMaterialSource.Create(FViewport);
  MatHighLight.Texture.LoadFromStream(RS);
  RS.Free;

  RS := TResourceStream.Create(HInstance, 'PNGDELETE', RT_RCDATA);
  MatDelete := TTextureMaterialSource.Create(FViewport);
  MatDelete.Texture.LoadFromStream(RS);
  RS.Free;

  RS := TResourceStream.Create(HInstance, 'PNGDELETE2', RT_RCDATA);
  MatDelete2 := TTextureMaterialSource.Create(FViewport);
  MatDelete2.Texture.LoadFromStream(RS);
  RS.Free;

  RS := TResourceStream.Create(HInstance, 'PNGINFO', RT_RCDATA);
  MatInfo := TTextureMaterialSource.Create(FViewport);
  MatInfo.Texture.LoadFromStream(RS);
  RS.Free;

  MatText := TColorMaterialSource.Create(FViewport);
  MatText.Color := TAlphaColorRec.White;

  SetLength(FTiles, FCols, FRows);


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
  Matdelete.Free;
  Matdelete2.Free;
  MatInfo.Free;
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
  PlaneDelete, PlaneInfo: TPlane;
  RS: TResourceStream;
  APrivPlane: TPlane;
begin

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
      Plane.Depth := 0.03;
      if FGirls[i].Prive < 0 then
      begin
        Plane.Parent := FRoot;
        Plane.Position.X := -((FCols - 1) - col) * (FTileWidth + FPadX);
        Plane.Position.Y := (FRows - 1 - row) * (FTileHeight + FPadY);  // alto -> basso
        Plane.Position.Z := 0;
      end
      else begin
        // LA RAGAZZA E' IN PRIVE
        APrivPlane := FPrivGrid.GetPriveByTag(FGirls[i].Prive);
        Plane.Parent := APrivPlane;
        //Plane.Position.X := PriveSlot[FGirls[i].Slot].X ;
        Plane.Position.Y := PriveSlot[FGirls[i].Slot].Y ;
        Plane.Position.Z := 0.3;
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
      Txt.Position.Z := 0.05;
      Txt.HitTest := False;


      PlaneDelete := TPlane.Create(FViewport);
      PlaneDelete.Parent := Plane;
      PlaneDelete.TagFloat := 2;
      PlaneDelete.Width := FTileWidth * 0.15;
      PlaneDelete.Height := FTileHeight * 0.60;
      PlaneDelete.Position.X := (Plane.Width / 2) - 0.25;
      PlaneDelete.Position.Y := (Plane.Height / 2) - 0.2 ;
      PlaneDelete.Position.Z := 0.05;
      PlaneDelete.MaterialSource := Matdelete;
      PlaneDelete.TagString := Uppercase(FGirls[i].Name);
      PlaneDelete.Tag := Plane.Tag;
      PlaneDelete.OnMouseDown := InternalImgDeleteMouseDown;
      PlaneDelete.HitTest := True;
      PlaneDelete.RotationAngle.X := 180;
      PlaneDelete.Cursor := crHandPoint;

      PlaneInfo := TPlane.Create(FViewport);
      PlaneInfo.Parent := Plane;
      PlaneInfo.TagFloat := 1;
      PlaneInfo.Width := FTileWidth * 0.15;
      PlaneInfo.Height := FTileHeight * 0.60;
      PlaneInfo.Position.X := -(Plane.Width / 2) + 0.2;
      PlaneInfo.Position.Y := (Plane.Height / 2) - 0.2 ;
      PlaneInfo.Position.Z := 0.05;
      PlaneInfo.MaterialSource := MatInfo;
      PlaneInfo.TagString := Uppercase(FGirls[i].Name);
      PlaneInfo.Tag := Plane.Tag;
      PlaneInfo.OnMouseDown := InternalImgInfoMouseDown;
      PlaneInfo.HitTest := True;
      PlaneInfo.RotationAngle.X := 180;
      PlaneInfo.Cursor := crHandPoint;


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
  AGirl := TGirl.Create;
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
function TGirlGrid.GetTileByGirlName(Text: String): TPlane;
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

procedure TGirlGrid.UpdateGrid;
var
  col, row, i: Integer;
  Plane: TPlane;
  Child: TFmxObject;
  PlaneInfo, PlaneDelete: TPlane;
  APrivPlane: TPlane;
begin
  i := 0;
  for col := FCols - 1 downto 0 do
    for row := 0 to FRows - 1 do
    begin
      if i >= FGirls.Count then
        Exit;

      Plane := FTiles[col, row];
      if not Assigned(Plane) then Continue;

      // ------ Posizionamento base ------
      if FGirls[i].Prive < 0 then
      begin
        Plane.Parent := FRoot;
        Plane.Position.X := -((FCols - 1) - col) * (FTileWidth + FPadX);
        Plane.Position.Y := (FRows - 1 - row) * (FTileHeight + FPadY);
      end
      else
      begin
        APrivPlane := FPrivGrid.GetPriveByTag(FGirls[i].Prive);
        if Assigned(APrivPlane) then
        begin
          Plane.Parent := APrivPlane;
          //Plane.Position.X := PriveSlot[FGirls[i].Slot].X ;
          Plane.Position.Y := PriveSlot[FGirls[i].Slot].Y ;
          Plane.Position.Z := 0.3 ;
        end;
      end;

      // ------ Trovo Info/Delete grazie a TagFloat ------
      PlaneInfo := nil;
      PlaneDelete := nil;

      for Child in Plane.Children do
      begin
        if Child is TPlane then
        begin
          if TPlane(Child).TagFloat = 1 then
            PlaneInfo := TPlane(Child)
          else if TPlane(Child).TagFloat = 2 then
            PlaneDelete := TPlane(Child);
        end;
      end;

      // ------ Cambio materiali ------
      if Assigned(PlaneDelete) then
      begin
        if FGirls[i].Prive < 0 then
          PlaneDelete.MaterialSource := MatDelete     // PNGDELETE
        else
          PlaneDelete.MaterialSource := MatDelete2;   // PNGDELETE2
      end;

      Inc(i);
    end;
end;
procedure TGirlGrid.LoadFromFiles;
var
  FileName : string;
  AGirl : TGirl;
  AGirlStorage: TGirlStorage;
  GirlData: TGirlData;
begin
    FGirls.Clear;
    for FileName in TDirectory.GetFiles(DirSaves, '*.json') do
      begin
        AGirl := TGirl.Create;
        AGirl.Name := Uppercase(System.IOUtils.TPath.GetFileNameWithoutExtension(FileName));
        // TgirlStorage per sapere dove mettere le girl e se aprire o no i prive
        AGirlStorage:= TGirlStorage.Create;
        GirlData := AGirlStorage.LoadGirl( AGirl.Name );
        AGirl.Prive := GirlData.Prive;
        AGirl.Slot :=  GirlData.Slot;
        AGirl.Start := GirlData.Start;
        FGirls.Add(AGirl);
      end;
  FGirls.Sort(TComparer<TGirl>.Construct(
    function(const A, B: TGirl): Integer
    begin
      Result := CompareText(A.Name, B.Name);  // ordina per Name
    end));

  ReBuildGrid;
end;
end.

