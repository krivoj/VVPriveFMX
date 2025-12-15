unit u_Dialogs;

interface

uses
  System.SysUtils, System.Classes, FMX.Types, FMX.Controls, FMX.Objects, FMX.Layouts, System.Types, System.UITypes, FMX.Text, FMX.Types3D, System.Math.Vectors,u_lang,
  FMX.StdCtrls, FMX.Graphics, FMX.Edit, FMX.Objects3D,FMX.MaterialSources;

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

type
  TSpinBoxDialog = class
  private
    FOwner: TComponent;
    FRoot: TLayout;
    FTitle: TLabel;
    FMinutes: TLabel;
    FValue: Integer;
    FOnConfirm: TProc<Integer>;
    FOnCancel: TProc;
    MatAdd, MatSub : TTextureMaterialSource;
    procedure ClickConfirm(Sender: TObject);
    procedure ClickCancel(Sender: TObject);
    procedure ClickAdd(Sender: TObject);
    procedure ClickSub(Sender: TObject);
    procedure PaintCancel(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure PaintOk(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
  public
    constructor Create(AOwner: TComponent; AParent: TFmxObject);
    procedure Show(const Title: string; OnConfirm: TProc<Integer>; OnCancel: TProc);
    procedure Hide;
  end;

type
  TMessageDialog = class
    private
      FOwner: TComponent;
      FRoot: TLayout;
      FTitle: TLabel;
      FOnOk: TProc;
      procedure ClickOk(Sender: TObject);
      procedure PaintOk(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    public
      constructor Create(AOwner: TComponent; AParent: TFmxObject);
      procedure Show(const Msg: string; OnOk: TProc = nil);
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
  FTitle.StyledSettings:=[];
  FTitle.Align := TAlignLayout.Top;
  FTitle.Margins.Top := 20;
  FTitle.AutoSize := False;
  FTitle.Height := 150;
  FTitle.TextSettings.Font.Size := 28;  // **questa modifica il font visibile**
  FTitle.TextSettings.Font.Style := [TFontStyle.fsBold];
  FTitle.TextSettings.HorzAlign := TTextAlign.Center;
  FTitle.TextSettings.VertAlign := TTextAlign.Center;
  FTitle.WordWrap := True;
  FTitle.TextSettings.WordWrap := True;

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
  cancel.Text :=  L(STR_NO);
  cancel.Margins.Right := 40;
  cancel.OnClick := ClickNo;
  cancel.StyledSettings := [];
  cancel.OnPaint := PaintCancel;
  cancel.Cursor := CrHandPoint;

  ok := TButton.Create(footer);
  ok.Parent := footer;
  ok.Align := TAlignLayout.Right;
  ok.Width := 380;
  ok.Text :=  L(STR_YES);
  ok.Margins.Left := 40;
  ok.OnClick := ClickYes;
  ok.StyledSettings := [];
  ok.OnPaint := PaintOk;
  ok.Cursor := CrHandPoint;
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
  FTitle.StyledSettings:=[];
  FTitle.Align := TAlignLayout.Top;
  FTitle.Margins.Top := 20;
  //FTitle.AutoSize := False;
  FTitle.Height := 50;
  FTitle.TextSettings.Font.Size := 28;  // **questa modifica il font visibile**
  FTitle.TextSettings.Font.Style := [TFontStyle.fsBold];
  FTitle.TextSettings.HorzAlign := TTextAlign.Center;
  FTitle.TextSettings.VertAlign := TTextAlign.Center;
  FTitle.WordWrap := True;
  FTitle.TextSettings.WordWrap := True;

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
  cancel.Text := L(STR_CANCEL);
  cancel.Margins.Right := 40;
  cancel.OnClick := ClickCancel;
  cancel.StyledSettings := [];
  cancel.OnPaint := PaintCancel;
  cancel.Cursor := CrHandPoint;

  ok := TButton.Create(footer);
  ok.Parent := footer;
  ok.Align := TAlignLayout.Right;
  ok.Width := 380;
  ok.Text := L(STR_OK_ADD);
  ok.Margins.Left := 40;
  ok.OnClick := ClickConfirm;
  ok.StyledSettings := [];
  ok.OnPaint := PaintOk;
  ok.Cursor := CrHandPoint;
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
{ TSpinBoxDialog }

constructor TSpinBoxDialog.Create(AOwner: TComponent; AParent: TFmxObject);
var
  bg, box: TRectangle;
  footer: TLayout;
  ok, cancel: TButton;
  BtnSub, BtnAdd: TPlane;
  RS : TResourceStream;
  ImgSub, ImgAdd: TImage;
begin

  FOwner := AOwner;

  FRoot := TLayout.Create(AOwner);
  FRoot.Parent := AParent;
  FRoot.Align := TAlignLayout.Contents;
  FRoot.Visible := False;
  FRoot.HitTest := True;
  FRoot.Opacity := 0.0;

  RS := TResourceStream.Create(HInstance, 'PNGADD2', RT_RCDATA);
  MatAdd := TTextureMaterialSource.Create(FRoot);
  MatAdd.Texture.LoadFromStream(RS);
  RS.Free;

  RS := TResourceStream.Create(HInstance, 'PNGSUB', RT_RCDATA);
  MatSub := TTextureMaterialSource.Create(FRoot);
  MatSub.Texture.LoadFromStream(RS);
  RS.Free;

  bg := TRectangle.Create(FRoot);
  bg.Parent := FRoot;
  bg.Align := TAlignLayout.Contents;
  bg.Fill.Color := $88000000;
  bg.Stroke.Kind := TBrushKind.None;

  box := TRectangle.Create(FRoot);
  box.Parent := FRoot;
  box.Align := TAlignLayout.Center;
  box.Width := 800;
  box.Height := 400;
  box.XRadius := 20;
  box.YRadius := 20;
  box.Fill.Color := $FFFFFFFF;

  FTitle := TLabel.Create(box);
  FTitle.Parent := box;
  FTitle.StyledSettings:=[];
  FTitle.Align := TAlignLayout.Top;
  FTitle.Margins.Top := 20;
  //FTitle.AutoSize := False;
  FTitle.Height := 50;
  FTitle.TextSettings.Font.Size := 28;  // **questa modifica il font visibile**
  FTitle.TextSettings.Font.Style := [TFontStyle.fsBold];
  FTitle.TextSettings.HorzAlign := TTextAlign.Center;
  FTitle.TextSettings.VertAlign := TTextAlign.Center;
  FTitle.WordWrap := True;
  FTitle.TextSettings.WordWrap := True;


  FMinutes := TLabel.Create(box);
  FMinutes.Parent := box;
  FMinutes.Align := TAlignLayout.Client;
  FMinutes.StyledSettings := [];
  FMinutes.TextSettings.Font.Size := 22;
  FMinutes.TextSettings.Font.Style := [TFontStyle.fsBold];
  FMinutes.TextSettings.HorzAlign := TTextAlign.Center;
  FMinutes.TextSettings.VertAlign := TTextAlign.Center;
  FMinutes.Scale.X := 10;
  FMinutes.Scale.Y := 7;


  ImgSub := TImage.Create(box);
  ImgSub.Parent := box;
  ImgSub.Align := TAlignLayout.Left;
  ImgSub.Width := 200;
  ImgSub.Cursor := crHandPoint;
  ImgSub.HitTest := True;
  RS := TResourceStream.Create(HInstance, 'PNGSUB', RT_RCDATA);
  ImgSub.Bitmap.LoadFromStream(RS);
  RS.Free;
  ImgSub.OnClick := ClickSub;

  ImgAdd := TImage.Create(box);
  ImgAdd.Parent := box;
  ImgAdd.Align := TAlignLayout.Right;
  ImgAdd.Width := 200;
  ImgAdd.Cursor := crHandPoint;
  ImgAdd.HitTest := True;
  RS := TResourceStream.Create(HInstance, 'PNGADD2', RT_RCDATA);
  ImgAdd.Bitmap.LoadFromStream(RS);
  RS.Free;
  ImgAdd.OnClick := ClickAdd;

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
  cancel.Text := L(STR_CANCEL);
  cancel.Margins.Right := 40;
  cancel.OnClick := ClickCancel;
  cancel.StyledSettings := [];
  cancel.OnPaint := PaintCancel;
  cancel.Cursor := CrHandPoint;

  ok := TButton.Create(footer);
  ok.Parent := footer;
  ok.Align := TAlignLayout.Right;
  ok.Width := 380;
  ok.Text := L(STR_OK_CONFIRM);
  ok.Margins.Left := 40;
  ok.OnClick := ClickConfirm;
  ok.StyledSettings := [];
  ok.OnPaint := PaintOk;
  ok.Cursor := CrHandPoint;

  FValue := 10;
  FMinutes.Text := FValue.ToString ;
end;

procedure TSpinBoxDialog.Show(const Title: string; OnConfirm: TProc<Integer>; OnCancel: TProc);
begin
  FTitle.Text := Title;
  FOnConfirm := OnConfirm;
  FOnCancel := OnCancel;

  FValue := 10;
  FMinutes.Text := FValue.ToString ;

  FRoot.Visible := True;
  FRoot.Opacity := 1;
end;

procedure TSpinBoxDialog.Hide;
begin
  FRoot.Visible := False;
end;

procedure TSpinBoxDialog.ClickConfirm(Sender: TObject);
begin
  if Assigned(FOnConfirm) then
    FOnConfirm(FValue);
  Hide;
end;

procedure TSpinBoxDialog.ClickCancel(Sender: TObject);
begin
  if Assigned(FOnCancel) then
    FOnCancel();

  Hide;
end;

procedure TSpinBoxDialog.PaintCancel(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
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

procedure TSpinBoxDialog.PaintOk(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  Btn: TButton;
  TextRect: TRectF;
begin
  Btn := Sender as TButton;
  Canvas.Fill.Color := $FF00FF00;// $FFCCFFCC;
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.FillRect(ARect, 8, 8, AllCorners, 1);
  Canvas.Fill.Color := $FF000000;
  Canvas.Font.Size := 24;
  Canvas.Font.Family := Btn.TextSettings.Font.Family;
  Canvas.Font.Style := [TFontStyle.fsBold];
  TextRect := ARect;
  Canvas.FillText(TextRect, Btn.Text, False, 1, [], TTextAlign.Center, TTextAlign.Center);
end;
procedure TSpinBoxDialog.ClickAdd(Sender: TObject);
begin
  if FValue < 180 then
  begin
    FValue := FValue + 5;
    if FValue > 180 then FValue := 180;
    FMinutes.Text := FValue.ToString;
  end;
end;

procedure TSpinBoxDialog.ClickSub(Sender: TObject);
begin
  FMinutes.Text := FValue.ToString;

  if FValue > 5 then
  begin
    FValue := FValue - 5;
    if FValue < 5 then FValue := 5;
    FMinutes.Text := FValue.ToString;
  end;
end;
{ ================================
  TMessageDialog
  ================================ }

constructor TMessageDialog.Create(AOwner: TComponent; AParent: TFmxObject);
var
  bg, box: TRectangle;
  footer: TLayout;
  ok: TButton;
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
  box.Height := 260;
  box.XRadius := 20;
  box.YRadius := 20;
  box.Fill.Color := $FFFFFFFF;

  FTitle := TLabel.Create(box);
  FTitle.Parent := box;
  FTitle.StyledSettings:=[];
  FTitle.Align := TAlignLayout.Client;
  FTitle.Margins.Top := 20;
  FTitle.Margins.Bottom := 20;
  FTitle.TextSettings.Font.Size := 28;
  FTitle.TextSettings.Font.Style := [TFontStyle.fsBold];
  FTitle.TextSettings.HorzAlign := TTextAlign.Center;
  FTitle.TextSettings.VertAlign := TTextAlign.Center;
  FTitle.WordWrap := True;
  FTitle.TextSettings.WordWrap := True;

  footer := TLayout.Create(box);
  footer.Parent := box;
  footer.Align := TAlignLayout.Bottom;
  footer.Height := 80;
  footer.Padding.Left := 20;
  footer.Padding.Right := 20;

  // --- UNICO BOTTONE OK, CENTRATO E LARGEZZA FULL ---
  ok := TButton.Create(footer);
  ok.Parent := footer;
  ok.Align := TAlignLayout.Contents;
  ok.Margins.Left := 10;
  ok.Margins.Right := 10;
  ok.Margins.Bottom := 10;
  ok.Text := L(STR_CLOSE);
  ok.StyledSettings := [];
  ok.OnClick := ClickOk;
  ok.OnPaint := PaintOk;
  ok.Cursor := CrHandPoint;
end;

procedure TMessageDialog.Show(const Msg: string; OnOk: TProc);
begin
  FTitle.Text := Msg;
  FOnOk := OnOk;
  FRoot.Visible := True;
  FRoot.Opacity := 1;
end;

procedure TMessageDialog.Hide;
begin
  FRoot.Visible := False;
end;

procedure TMessageDialog.ClickOk(Sender: TObject);
begin
  if Assigned(FOnOk) then FOnOk();
  Hide;
end;

procedure TMessageDialog.PaintOk(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var Btn: TButton; TextRect: TRectF;
begin
  Btn := Sender as TButton;
  Canvas.Fill.Color := $FFCCFFCC; // verde chiaro come "SI"
  Canvas.FillRect(ARect, 8, 8, AllCorners, 1);
  Canvas.Fill.Color := $FF000000;
  Canvas.Font.Size := 24;
  Canvas.Font.Style := [TFontStyle.fsBold];
  TextRect := ARect;
  Canvas.FillText(TextRect, Btn.Text, False, 1, [], TTextAlign.Center, TTextAlign.Center);
end;
end.
