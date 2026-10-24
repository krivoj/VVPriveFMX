unit u_ActivitiesDialog;

interface

uses
  System.SysUtils, System.Classes, System.Types,
  System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Layouts, FMX.ListBox, FMX.StdCtrls, System.UITypes, FMX.Memo, u_lang,
  FMX.Objects, FMX.Graphics,
  FMX.Printer, FMX.Dialogs,                // << aggiunte per la stampa
  u_GirlStorage, System.IOUtils, System.DateUtils, u_ResponsiveLayout;

type
  TPrintPreviewDialog = class
  private
    FOwner: TComponent;
    FRoot: TLayout;
    FPanel: TRectangle;
    FMemo: TMemo;
    FBtnPrint: TButton;
    FBtnClose: TButton;
    FContent: string;
    procedure BtnCloseClick(Sender: TObject);
    procedure BtnPrintClick(Sender: TObject);
    procedure StampaTesto(const AText: string);  // << aggiunto
  public
    constructor Create(AOwner: TComponent; AParent: TFmxObject);
    procedure ShowPreview(const AText: string);
  end;

type
  TActivityView = record
    GirlName : string;
    Prive    : Integer;
    StartDT  : TDateTime;
    EndDT    : TDateTime;
    Duration : TDateTime;
  end;

  TActivitiesDialog = class
  private
    FOwner: TComponent;
    FRoot : TLayout;
    FPanel: TRectangle;
    FList: TListBox;
    FBtnClose: TButton;
    FBtnPrint: TButton;
    FCurrentGirl: string;
    FItems: TList<TActivityView>;
    FStorage: TGirlStorage;

    procedure LoadGirl(const GirlName: string);
    procedure PopulateList;
    procedure PaintClose(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure PaintPrint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);

    procedure BtnCloseClick(Sender: TObject);
    procedure BtnPrintClick(Sender: TObject);

    procedure StampaTesto(const AText: string);   // << aggiunto
  public
    constructor Create(AOwner: TComponent; AParent: TFmxObject);
    destructor Destroy; override;

    procedure ShowCentered(GirlName: String);
    procedure PrintAllActivities;
  end;

implementation

uses
  Unit1;

{ ===================================================================== }
{  FUNZIONE DI STAMPA REALE (TPrinter)                                  }
{ ===================================================================== }

procedure StampaReal(const Text: string);
var
  P: TPrinter;
  Lines: TArray<string>;
  LineHeight: Single;
  MaxLinesPerPage: Integer;
  X, Y: Single;
  I, Total: Integer;
begin
  P := Printer;

  Lines := Text.Split([sLineBreak]);
  LineHeight := 50; // pixel verticali per riga
  MaxLinesPerPage := Trunc((P.PageHeight - 100) / LineHeight);

  P.BeginDoc;
  try
    I := 0;
    Total := Length(Lines);

    while I < Total do
    begin
      X := 50;
      Y := 50;

      while (I < Total) and (MaxLinesPerPage > 0) do
      begin
        P.Canvas.Fill.Color := TAlphaColors.Black;
        P.Canvas.FillText(
          RectF(X, Y, P.PageWidth - 50, Y + LineHeight),
          Lines[I],
          False,
          1.0,
          [],
          TTextAlign.Leading,
          TTextAlign.Leading
        );

        Inc(I);
        Dec(MaxLinesPerPage);
        Y := Y + LineHeight;
      end;

      if I < Total then
      begin
        P.NewPage;  // <<< pagina successiva
        MaxLinesPerPage := Trunc((P.PageHeight - 100) / LineHeight);
      end;
    end;

  finally
    P.EndDoc;
  end;
end;

{ ===================================================================== }
{ TActivitiesDialog                                                     }
{ ===================================================================== }

constructor TActivitiesDialog.Create(AOwner: TComponent; AParent: TFmxObject);
var
  DarkBG: TRectangle;
  BtnBar : TLayout;
begin
  FOwner := AOwner;

  FItems := TList<TActivityView>.Create;
  FStorage := TGirlStorage.Create;

  FRoot := TResponsiveDialogRoot.Create(AOwner);
  FRoot.Parent := AParent;
  FRoot.Align := TAlignLayout.Contents;
  FRoot.HitTest := True;

  DarkBG := TRectangle.Create(FRoot);
  DarkBG.Parent := FRoot;
  DarkBG.Align := TAlignLayout.Contents;
  DarkBG.Fill.Color := $88000000;
  DarkBG.Stroke.Kind := TBrushKind.None;

  FPanel := TRectangle.Create(FRoot);
  FPanel.Parent := FRoot;
  FPanel.Align := TAlignLayout.Center;
  FPanel.Width := 800;
  FPanel.Height := 800;
  TResponsiveDialogRoot(FRoot).FitPanel(FPanel);
  FPanel.Fill.Color := $FF202020;
  FPanel.XRadius := 18;
  FPanel.YRadius := 18;
  FPanel.Stroke.Kind := TBrushKind.None;
  FPanel.Padding.Rect := TRectF.Create(20,20,20,20);

  FList := TListBox.Create(FPanel);
  FList.Parent := FPanel;
  FList.Align := TAlignLayout.Client;
  FList.ItemHeight := 25;

  BtnBar := TLayout.Create(FPanel);
  BtnBar.Parent := FPanel;
  BtnBar.Align := TAlignLayout.Bottom;
  BtnBar.Height := 100;

  FBtnPrint := TButton.Create(BtnBar);
  FBtnPrint.Parent := BtnBar;
  FBtnPrint.Align := TAlignLayout.Left;
  FBtnPrint.Width := 250;
  FBtnPrint.Text := L(STR_PRINT);
  FBtnPrint.OnClick := BtnPrintClick;
  FBtnPrint.Cursor := CrHandPoint;
  FBtnPrint.OnPaint := PaintPrint;

  FBtnClose := TButton.Create(BtnBar);
  FBtnClose.Parent := BtnBar;
  FBtnClose.Align := TAlignLayout.Right;
  FBtnClose.Width := 250;
  FBtnClose.Text :=  L(STR_CLOSE);
  FBtnClose.OnClick := BtnCloseClick;
  FBtnClose.Cursor := CrHandPoint;
  FBtnClose.OnPaint := PaintClose;

  FRoot.Visible := False;
end;

destructor TActivitiesDialog.Destroy;
begin
  FItems.Free;
  FStorage.Free;
  inherited;
end;

procedure TActivitiesDialog.ShowCentered(GirlName: String);
begin
  FCurrentGirl := GirlName;

  FItems.Clear;
  FList.Clear;

  LoadGirl(GirlName);
  PopulateList;

  FRoot.Visible := True;
end;

procedure TActivitiesDialog.BtnCloseClick(Sender: TObject);
begin
  FRoot.Visible := False;
end;
function Fix(const S: string; Len: Integer): string;
begin
  Result := Copy(S + StringOfChar(' ', Len), 1, Len);
end;

procedure TActivitiesDialog.BtnPrintClick(Sender: TObject);
var
  A: TActivityView;
  Output: TStringList;
begin
  Output := TStringList.Create;
  try
    Output.Add(Format(L(STR_ACTIVITY_LOG_TITLE), [FCurrentGirl]));
    Output.Add(StringOfChar('-', 70));
    Output.Add('');
    Output.Add(
      //Fix('Ragazza',12)+' '+
      Fix(L(STR_PRIVE),14)+' '+
      Fix(L(STR_START),25)+' '+
      Fix(L(STR_END),25)+' '+
      Fix(L(STR_DURATION),8)
    );
    Output.Add(
      //StringOfChar('-',12)+' '+
      StringOfChar('-',14)+' '+
      StringOfChar('-',25)+' '+
      StringOfChar('-',25)+' '+
      StringOfChar('-',8)
    );

    for A in FItems do
      Output.Add(
       // Fix(A.GirlName,12)+' '+
        Fix(A.Prive.ToString,5)+' '+
        Fix(FormatDateTime('yyyy-mm-dd hh:nn', A.StartDT),19)+' '+
        Fix(FormatDateTime('yyyy-mm-dd hh:nn', A.EndDT),19)+' '+
        Fix(FormatDateTime('hh:nn:ss', A.Duration),8)
      );

    StampaReal(Output.Text);
  finally
    Output.Free;
  end;
end;

procedure TActivitiesDialog.StampaTesto(const AText: string);
begin
  StampaReal(AText);
end;

procedure TActivitiesDialog.LoadGirl(const GirlName: string);
var
  Data: TGirlData;
  A: TActivity;
  Item: TActivityView;
begin
  Data := FStorage.LoadGirl(GirlName);

  for A in Data.Activities do
  begin
    Item.GirlName := GirlName;
    Item.Prive    := A.Prive;
    Item.StartDT  := A.Start;
    Item.EndDT    := A.End_;
    Item.Duration := A.End_ - A.Start;

    FItems.Add(Item);
  end;
end;

procedure TActivitiesDialog.PopulateList;
var
  I: TActivityView;
  LI: TListBoxItem;
  S_Priv, S_Start, S_End, S_Dur: string;
begin
  FList.Clear;

  for I in FItems do
  begin
    LI := TListBoxItem.Create(FList);
    LI.Parent := FList;

    // colonne esattamente come la stampa
    S_Priv  := Fix(I.Prive.ToString, 5);
    S_Start := Fix(FormatDateTime('yyyy-mm-dd hh:nn', I.StartDT), 19);
    S_End   := Fix(FormatDateTime('yyyy-mm-dd hh:nn', I.EndDT), 19);
    S_Dur   := Fix(FormatDateTime('hh:nn:ss', I.Duration), 8);

    // monospazio e perfetta allineazione
    LI.Text :=
      S_Priv + '   ' +
      S_Start + '   ' +
      S_End   + '   ' +
      S_Dur;

    LI.StyledSettings := [];
    LI.TextSettings.Font.Family := 'Consolas';   // <--- MONOSPAZIO
    LI.TextSettings.Font.Size := 20;
    LI.TextSettings.FontColor := TAlphaColors.Black;
    LI.TextSettings.HorzAlign := TTextAlign.Leading;

    LI.Height := 28;
  end;
end;

procedure TActivitiesDialog.PrintAllActivities;
var
  Files: TStringDynArray;
  FileName, GirlName: string;
  Data: TGirlData;
  A: TActivity;
  Output: TStringList;
begin
  Output := TStringList.Create;
  try
    Output.Add(L(STR_ACTIVITY_LOG_COMPLETE_TITLE));
    Output.Add(StringOfChar('=', 70));
    Output.Add('');

    Files := TDirectory.GetFiles(DirSaves, '*.json');

    for FileName in Files do
    begin
      GirlName := TPath.GetFileNameWithoutExtension(FileName);
      Data := FStorage.LoadGirl(GirlName);

      Output.Add('--- '+GirlName+' ---');
      Output.Add(
        Fix(L(STR_GIRL), 10)+' '+
        Fix(L(STR_PRIVE), 10)+' '+  // se vuoi tradurre "Prive" come titolo colonna
        Fix(L(STR_START), 30)+' '+
        Fix(L(STR_END), 20)+' '+
        Fix(L(STR_DURATION), 20)      );
      Output.Add(
        StringOfChar('-',10)+' '+
        StringOfChar('-',10)+' '+
        StringOfChar('-',30)+' '+
        StringOfChar('-',20)+' '+
        StringOfChar('-',20)
      );

      for A in Data.Activities do
      begin
        Output.Add(
          Fix(GirlName,12)+' '+
          Fix(A.Prive.ToString,5)+' '+
          Fix(FormatDateTime('yyyy-mm-dd hh:nn', A.Start),19)+' '+
          Fix(FormatDateTime('yyyy-mm-dd hh:nn', A.End_),19)+' '+
          Fix(FormatDateTime('hh:nn:ss', A.End_ - A.Start),8)
        );
      end;

      Output.Add('');
    end;

    StampaReal(Output.Text);
  finally
    Output.Free;
  end;
end;

{ ===================================================================== }
{ TPrintPreviewDialog                                                   }
{ ===================================================================== }

constructor TPrintPreviewDialog.Create(AOwner: TComponent; AParent: TFmxObject);
var
  DarkBG: TRectangle;
  BtnBar: TLayout;
begin
  FOwner := AOwner;

  FRoot := TResponsiveDialogRoot.Create(AOwner);
  FRoot.Parent := AParent;
  FRoot.Align := TAlignLayout.Contents;
  FRoot.Visible := False;

  DarkBG := TRectangle.Create(FRoot);
  DarkBG.Parent := FRoot;
  DarkBG.Align := TAlignLayout.Contents;
  DarkBG.Fill.Color := $88000000;
  DarkBG.Stroke.Kind := TBrushKind.None;

  FPanel := TRectangle.Create(FRoot);
  FPanel.Parent := FRoot;
  FPanel.Align := TAlignLayout.Center;
  FPanel.Width := 700;
  FPanel.Height := 700;
  TResponsiveDialogRoot(FRoot).FitPanel(FPanel);
  FPanel.XRadius := 16;
  FPanel.YRadius := 16;
  FPanel.Fill.Color := $FF202020;
  FPanel.Stroke.Kind := TBrushKind.None;
  FPanel.Padding.Rect := TRectF.Create(20,20,20,20);

  FMemo := TMemo.Create(FPanel);
  FMemo.Parent := FPanel;
  FMemo.Align := TAlignLayout.Client;
  FMemo.ReadOnly := True;
  FMemo.TextSettings.FontColor := TAlphaColors.White;
  FMemo.Lines.Clear;

  BtnBar := TLayout.Create(FPanel);
  BtnBar.Parent := FPanel;
  BtnBar.Align := TAlignLayout.Bottom;
  BtnBar.Height := 80;

  FBtnPrint := TButton.Create(BtnBar);
  FBtnPrint.Parent := BtnBar;
  FBtnPrint.Align := TAlignLayout.Left;
  FBtnPrint.Width := 300;
  FBtnPrint.Text := L(STR_PRINT);
  FBtnPrint.Cursor := CrHandPoint;
  FBtnPrint.OnClick := BtnPrintClick;

  FBtnClose := TButton.Create(BtnBar);
  FBtnClose.Parent := BtnBar;
  FBtnClose.Align := TAlignLayout.Right;
  FBtnClose.Width := 300;
  FBtnClose.Text := L(STR_CLOSE);
  FBtnClose.Cursor := CrHandPoint;
  FBtnClose.OnClick := BtnCloseClick;
end;

procedure TPrintPreviewDialog.ShowPreview(const AText: string);
begin
  FContent := AText;
  FMemo.Lines.Text := AText;
  FRoot.Visible := True;
end;

procedure TPrintPreviewDialog.BtnCloseClick(Sender: TObject);
begin
  FRoot.Visible := False;
end;

procedure TPrintPreviewDialog.StampaTesto(const AText: string);
begin
  StampaReal(AText);
end;

procedure TPrintPreviewDialog.BtnPrintClick(Sender: TObject);
begin
  StampaReal(FContent);   // << STAMPA VERA
  FRoot.Visible := False;
end;
procedure TActivitiesDialog.PaintClose(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
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

procedure TActivitiesDialog.PaintPrint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
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
