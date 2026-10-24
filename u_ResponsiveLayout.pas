unit u_ResponsiveLayout;

interface

uses
  System.Classes, System.Math, FMX.Types, FMX.Controls, FMX.Layouts;

type
  // The background fills the window; only the dialog panel is scaled.
  TResponsiveDialogRoot = class(TLayout)
  private
    FPanel: TControl;
  protected
    procedure Resize; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    procedure FitPanel(APanel: TControl);
  end;

implementation

type
  TDialogControlAccess = class(TControl);

procedure TResponsiveDialogRoot.FitPanel(APanel: TControl);
begin
  FPanel := APanel;
  FPanel.FreeNotification(Self);
  FPanel.Align := TAlignLayout.None;
  Resize;
end;

procedure TResponsiveDialogRoot.Resize;
var
  S: Single;
begin
  inherited;
  if (FPanel = nil) or (Width <= 0) or (Height <= 0) or
     (FPanel.Width <= 0) or (FPanel.Height <= 0) then
    Exit;
  // Never enlarge bitmap assets. Recalculate from the original panel size,
  // avoiding cumulative rounding and double DPI scaling (FMX uses logical units).
  S := Min(1.0, Min(Width * 0.94 / FPanel.Width,
                    Height * 0.94 / FPanel.Height));
  TDialogControlAccess(FPanel).Scale.X := S;
  TDialogControlAccess(FPanel).Scale.Y := S;
  FPanel.Position.X := (Width - FPanel.Width * S) / 2;
  FPanel.Position.Y := (Height - FPanel.Height * S) / 2;
end;

procedure TResponsiveDialogRoot.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FPanel) then
    FPanel := nil;
end;

end.
