program ResolutionChecks;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Math, System.Types, System.UITypes,
  FMX.Forms, FMX.Types, FMX.Controls, FMX.Controls3D, FMX.Viewport3D,
  FMX.Objects, FMX.Layouts, FMX.Objects3D,
  Unit1 in '../Unit1.pas',
  u_ResponsiveLayout in '../u_ResponsiveLayout.pas',
  u_PrivGrid, u_GirlGrid;

procedure Check(Condition: Boolean; const Msg: string);
begin
  if not Condition then
    raise Exception.Create(Msg);
end;

procedure CheckResolution(W, H: Integer);
var
  F: TForm1;
  Root: TResponsiveDialogRoot;
  Panel: TRectangle;
  VisibleHalfHeight, VisibleHalfWidth: Single;
  I: Integer;
const
  PanelWidths: array[0..3] of Integer = (800, 900, 800, 700);
  PanelHeights: array[0..3] of Integer = (400, 300, 800, 700);
begin
  F := TForm1.CreateNew(nil);
  try
    F.Viewport3D1 := TViewport3D.Create(F);
    F.Viewport3D1.Parent := F;
    F.Viewport3D1.SetBounds(0, 0, W, H);
    F.Camera1 := TCamera.Create(F.Viewport3D1);
    F.Viewport3D1.Camera := F.Camera1;
    F.FormResize(F);
    VisibleHalfHeight := (F.Camera1.Position.Z - 0.5) *
      Tan(DegToRad(F.Camera1.AngleOfView / 2));
    VisibleHalfWidth := VisibleHalfHeight * W / H;
    Check(VisibleHalfHeight >= 6.375 - 0.001, 'Dashboard vertically clipped');
    Check(VisibleHalfWidth >= 10.5 - 0.001, 'Dashboard horizontally clipped');

    Root := TResponsiveDialogRoot.Create(F);
    Root.Parent := F;
    Root.SetBounds(0, 0, W, H);
    Panel := TRectangle.Create(Root);
    Panel.Parent := Root;
    for I := 0 to High(PanelWidths) do
    begin
      Panel.SetBounds(0, 0, PanelWidths[I], PanelHeights[I]);
      Root.FitPanel(Panel);
      Check(Panel.Position.X >= 0, 'Dialog left clipped');
      Check(Panel.Position.Y >= 0, 'Dialog top clipped');
      Check(Panel.Position.X + Panel.Width * Panel.Scale.X <= W + 0.01,
        'Dialog right clipped');
      Check(Panel.Position.Y + Panel.Height * Panel.Scale.Y <= H + 0.01,
        'Dialog bottom clipped');
      Check(Abs(Panel.Scale.X - Panel.Scale.Y) < 0.0001, 'Distorted dialog');
      // Resize the existing parent, then restore it: no cumulative scaling.
      Root.SetBounds(0, 0, W / 2, H / 2);
      Root.SetBounds(0, 0, W, H);
      Check(Abs(Panel.Position.X - (W - Panel.Width * Panel.Scale.X) / 2)
        < 0.01, 'Dialog not centered after resize');
    end;
    Writeln(Format('PASS %dx%d: camera and dialogs fit', [W, H]));
  finally
    F.Free;
  end;
end;

procedure CheckGirlCoordinates;
var
  F: TForm;
  V: TViewport3D;
  Priv: TPrivGrid;
  Girls: TGirlGrid;
  Girl: TGirl;
  Plane: TPlane;
  I: Integer;
begin
  F := TForm.CreateNew(nil);
  try
    V := TViewport3D.Create(F);
    V.Parent := F;
    Priv := TPrivGrid.Create(V, 5, 3, 3, 4, 0.05, 0.05);
    Girls := TGirlGrid.Create(V, 2, 0.42, 0.02, 0.02, Priv);
    try
      for I := 0 to 20 do
        Girls.AddGirl(Format('TEST%.2d', [I]));
      Girl := Girls.FGirls[20];
      Girl.Prive := 0;
      Girl.Slot := 0;
      PriveSlot[0].X := 0;
      PriveSlot[0].Y := 0;
      Girls.UpdateGrid;
      Plane := nil;
      for I := 0 to V.ComponentCount - 1 do
        if (V.Components[I] is TPlane) and
           (TPlane(V.Components[I]).TagString = UpperCase(Girl.Name)) and
           (TPlane(V.Components[I]).Parent = Priv.GetPriveByTag(0)) then
          Plane := TPlane(V.Components[I]);
      Check(Assigned(Plane), 'Assigned girl tile missing');
      Check(Abs(Plane.Position.X) < 0.0001, 'Stale girl X inside prive');
      Check(Abs(Plane.Position.Z - 0.3) < 0.0001, 'Wrong prive depth');
      Girl.Prive := -1;
      Girls.UpdateGrid;
      Check(Abs(Plane.Position.Z) < 0.0001, 'Stale girl Z outside prive');
      Check(Abs(Plane.Position.X + 2.02) < 0.0001, 'Wrong girl column');
      Writeln('PASS girl reassignment: X and Z reset');
    finally
      Girls.Free;
      Priv.Free;
    end;
  finally
    F.Free;
  end;
end;

begin
  try
    Application.Initialize;
    CheckResolution(640, 480);
    CheckResolution(800, 600);
    CheckResolution(1024, 768);
    CheckResolution(1280, 1024);
    CheckResolution(1366, 768);
    CheckResolution(1920, 1080);
    CheckResolution(2560, 1440);
    CheckResolution(3440, 1440);
    CheckResolution(3840, 2160);
    CheckResolution(1080, 1920);
    CheckGirlCoordinates;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
