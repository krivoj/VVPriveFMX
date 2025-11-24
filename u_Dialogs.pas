unit u_Dialogs;

interface

uses
  System.SysUtils, System.Classes, FMX.Types, FMX.Controls, FMX.Objects, FMX.Layouts, System.Types, System.UITypes,
  FMX.StdCtrls, FMX.Graphics, FMX.Edit;

type
  TConfirmDialog = class
  private
    FOwner: TComponent;
    FRoot: TLayout;
    FTitle: TLabel;
    FOnYes: TProc;
    FOnNo: TProc;
    procedure ClickYes(Sender: TObject);
    procedure ClickNo(Sender: TObject);
    procedure PaintCancel(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure PaintOk(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
  public
    constructor Create(AOwner: TComponent; AParent: TFmxObject);
    procedure Show(const Msg: string; OnYes, OnNo: TProc);
    procedure Hide;
  end;

  TInputDialog = class
  private
    FOwner: TComponent;
    FRoot: TLayout;
    FTitle: TLabel;
    FOnConfirm: TProc;
    FOnCancel: TProc;
    procedure ClickConfirm(Sender: TObject);
    procedure ClickCancel(Sender: TObject);
    procedure PaintCancel(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure PaintOk(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
  public
    FEdit: TEdit;
    constructor Create(AOwner: TComponent; AParent: TFmxObject);
    procedure Show(const Title: string; OnConfirm: TProc; OnCancel: TProc);
    procedure Hide;
  end;

implementation

{ TConfirmDialog }

constructor TConfirmDialog.Create(AOwner: TComponent; AParent: TFmxObject);
var
  bg, box: TRectangle;
  footer: TLayout;
  ok, cancel: TButton;
begin
  FOwner := AOwner;

  FRoot := TLayout.Create(AOwner);
  FRoot.Parent := AParent;
  FRoot.Align := TAlignLayout.Contents;
  FRoot.Visible := False;
  FRoot.HitTest := True;
  FRoot.Opacity := 0.0;

  bg := TRectangle.Create(FRoot);
  bg.Parent := FRoot;
  bg.Align := TAlignLayout.Contents;
  bg.Fill.Color := $88000000;
  bg.Stroke.Kind := TBrushKind.None;

  box := TRectangle.Create(FRoot);
  box.Parent := FRoot;
  box.Align := TAlignLayout.Center;
  box.Width := 800;
  box.Height := 300;
  box.XRadius := 20;
  box.YRadius := 20;
  box.Fill.Color := $FFFFFFFF;

  FTitle := TLabel.Create(box);
  FTitle.Parent := box;
  FTitle.Align := TAlignLayout.Top;
  FTitle.Margins.Top := 20;
  FTitle.Font.Size := 14;
  FTitle.TextSettings.HorzAlign := TTextAlign.Center;
  FTitle.TextSettings.VertAlign := TTextAlign.Center;
  FTitle.Scale.X := 4;
  FTitle.Scale.Y := 2;
  FTitle.WordWrap := true;

  footer := TLayout.Create(box);
  footer.Parent := box;
  footer.Align := TAlignLayout.Bottom;
  footer.Height := 80;
  footer.Padding.Left := 20;
  footer.Padding.Right := 20;

  cancel := TButton.Create(footer);
  cancel.Parent := footer;
  cancel.Align := TAlignLayout.Left;
  cancel.Width := 380;
  cancel.Text := 'NO';
  cancel.Margins.Right := 40;
  cancel.OnClick := ClickNo;
  cancel.StyledSettings := [];
  cancel.OnPaint := PaintCancel;

  ok := TButton.Create(footer);
  ok.Parent := footer;
  ok.Align := TAlignLayout.Right;
  ok.Width := 380;
  ok.Text := 'SI';
  ok.Margins.Left := 40;
  ok.OnClick := ClickYes;
  ok.StyledSettings := [];
  ok.OnPaint := PaintOk;
end;

procedure TConfirmDialog.Show(const Msg: string; OnYes, OnNo: TProc);
begin
  FTitle.Text := Msg;
  FOnYes := OnYes;
  FOnNo := OnNo;
  FRoot.Visible := True;
  FRoot.Opacity := 1;
end;

procedure TConfirmDialog.Hide;
begin
  FRoot.Visible := False;
end;

procedure TConfirmDialog.ClickYes(Sender: TObject);
begin
  if Assigned(FOnYes) then FOnYes();
  Hide;
end;

procedure TConfirmDialog.ClickNo(Sender: TObject);
begin
  if Assigned(FOnNo) then FOnNo();
  Hide;
end;

procedure TConfirmDialog.PaintCancel(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  Btn: TButton;
  TextRect: TRectF;
begin
  Btn := Sender as TButton;
  Canvas.Fill.Color := $FFFFCCCC;
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.FillRect(ARect, 8, 8, AllCorners, 1);
  Canvas.Fill.Color := $FF000000;
  Canvas.Font.Size := 24;
  Canvas.Font.Family := Btn.TextSettings.Font.Family;
  Canvas.Font.Style := [TFontStyle.fsBold];
  TextRect := ARect;
  Canvas.FillText(TextRect, Btn.Text, False, 1, [], TTextAlign.Center, TTextAlign.Center);
end;

procedure TConfirmDialog.PaintOk(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  Btn: TButton;
  TextRect: TRectF;
begin
  Btn := Sender as TButton;
  Canvas.Fill.Color := $FFCCFFCC;
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.FillRect(ARect, 8, 8, AllCorners, 1);
  Canvas.Fill.Color := $FF000000;
  Canvas.Font.Size := 24;
  Canvas.Font.Family := Btn.TextSettings.Font.Family;
  Canvas.Font.Style := [TFontStyle.fsBold];
  TextRect := ARect;
  Canvas.FillText(TextRect, Btn.Text, False, 1, [], TTextAlign.Center, TTextAlign.Center);
end;

{ TInputDialog }

constructor TInputDialog.Create(AOwner: TComponent; AParent: TFmxObject);
var
  bg, box: TRectangle;
  footer: TLayout;
  ok, cancel: TButton;
begin
  FOwner := AOwner;

  FRoot := TLayout.Create(AOwner);
  FRoot.Parent := AParent;
  FRoot.Align := TAlignLayout.Contents;
  FRoot.Visible := False;
  FRoot.HitTest := True;
  FRoot.Opacity := 0.0;

  bg := TRectangle.Create(FRoot);
  bg.Parent := FRoot;
  bg.Align := TAlignLayout.Contents;
  bg.Fill.Color := $88000000;
  bg.Stroke.Kind := TBrushKind.None;

  box := TRectangle.Create(FRoot);
  box.Parent := FRoot;
  box.Align := TAlignLayout.Center;
  box.Width := 800;
  box.Height := 300;
  box.XRadius := 20;
  box.YRadius := 20;
  box.Fill.Color := $FFFFFFFF;

  FTitle := TLabel.Create(box);
  FTitle.Parent := box;
  FTitle.Align := TAlignLayout.Top;
  FTitle.Margins.Top := 20;
  FTitle.Font.Size := 14;
  FTitle.Font.Style := [TFontStyle.fsBold];
  FTitle.TextSettings.HorzAlign := TTextAlign.Center;
  FTitle.TextSettings.VertAlign := TTextAlign.Center;
  FTitle.Scale.X := 4;
  FTitle.Scale.Y := 2;
  FTitle.WordWrap := True;

  FEdit := TEdit.Create(box);
  FEdit.Parent := box;
  FEdit.Align := TAlignLayout.Client;
  FEdit.Font.Size := 22;
  FEdit.Scale.X := 10;
  FEdit.Scale.Y := 7;

  footer := TLayout.Create(box);
  footer.Parent := box;
  footer.Align := TAlignLayout.Bottom;
  footer.Height := 80;
  footer.Padding.Left := 20;
  footer.Padding.Right := 20;

  cancel := TButton.Create(footer);
  cancel.Parent := footer;
  cancel.Align := TAlignLayout.Left;
  cancel.Width := 380;
  cancel.Text := 'Annulla';
  cancel.Margins.Right := 40;
  cancel.OnClick := ClickCancel;
  cancel.StyledSettings := [];
  cancel.OnPaint := PaintCancel;

  ok := TButton.Create(footer);
  ok.Parent := footer;
  ok.Align := TAlignLayout.Right;
  ok.Width := 380;
  ok.Text := 'Aggiungi';
  ok.Margins.Left := 40;
  ok.OnClick := ClickConfirm;
  ok.StyledSettings := [];
  ok.OnPaint := PaintOk;
end;

procedure TInputDialog.Show(const Title: string; OnConfirm: TProc; OnCancel: TProc);
begin
  FTitle.Text := Title;
  FOnConfirm := OnConfirm;
  FOnCancel := OnCancel;
  FEdit.Text := '';
  FRoot.Visible := True;
  FRoot.Opacity := 1;
end;

procedure TInputDialog.Hide;
begin
  FRoot.Visible := False;
end;

procedure TInputDialog.ClickConfirm(Sender: TObject);
begin
  if Assigned(FOnConfirm) then FOnConfirm;
  Hide;
end;

procedure TInputDialog.ClickCancel(Sender: TObject);
begin
  if Assigned(FOnCancel) then FOnCancel();
  Hide;
end;

procedure TInputDialog.PaintCancel(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  Btn: TButton;
  TextRect: TRectF;
begin
  Btn := Sender as TButton;
  Canvas.Fill.Color := $FFFFCCCC;
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.FillRect(ARect, 8, 8, AllCorners, 1);
  Canvas.Fill.Color := $FF000000;
  Canvas.Font.Size := 24;
  Canvas.Font.Family := Btn.TextSettings.Font.Family;
  Canvas.Font.Style := [TFontStyle.fsBold];
  TextRect := ARect;
  Canvas.FillText(TextRect, Btn.Text, False, 1, [], TTextAlign.Center, TTextAlign.Center);
end;

procedure TInputDialog.PaintOk(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  Btn: TButton;
  TextRect: TRectF;
begin
  Btn := Sender as TButton;
  Canvas.Fill.Color := $FFCCFFCC;
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.FillRect(ARect, 8, 8, AllCorners, 1);
  Canvas.Fill.Color := $FF000000;
  Canvas.Font.Size := 24;
  Canvas.Font.Family := Btn.TextSettings.Font.Family;
  Canvas.Font.Style := [TFontStyle.fsBold];
  TextRect := ARect;
  Canvas.FillText(TextRect, Btn.Text, False, 1, [], TTextAlign.Center, TTextAlign.Center);
end;

end.
