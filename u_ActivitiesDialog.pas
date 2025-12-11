unit u_ActivitiesDialog;

interface

uses
  System.SysUtils, System.Classes, System.Types,
  System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Layouts, FMX.ListBox, FMX.StdCtrls, System.UITypes, FMX.Memo,
  FMX.Objects, FMX.Graphics,
  FMX.Printer, FMX.Dialogs,                // << aggiunte per la stampa
  u_GirlStorage, System.IOUtils, System.DateUtils;

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
begin

    P := Printer;
    P.BeginDoc;
    try
      P.Canvas.Fill.Color := TAlphaColors.Black;
      P.Canvas.FillText(
        RectF(50, 50, P.PageWidth - 50, P.PageHeight - 50),
        Text,
        False,
        1.0,
        [],
        TTextAlign.Leading,
        TTextAlign.Leading
      );
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

  FRoot := TLayout.Create(AOwner);
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
  FPanel.Width := 600;
  FPanel.Height := 600;
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
  FBtnPrint.Text := 'Stampa';
  FBtnPrint.OnClick := BtnPrintClick;
  FBtnPrint.Cursor := CrHandPoint;

  FBtnClose := TButton.Create(BtnBar);
  FBtnClose.Parent := BtnBar;
  FBtnClose.Align := TAlignLayout.Right;
  FBtnClose.Width := 250;
  FBtnClose.Text := 'Chiudi';
  FBtnClose.OnClick := BtnCloseClick;
  FBtnClose.Cursor := CrHandPoint;

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

procedure TActivitiesDialog.BtnPrintClick(Sender: TObject);
var
  A: TActivityView;
  Output: TStringList;
begin
  Output := TStringList.Create;
  try
    Output.Add('Registro attività privè - ' + FCurrentGirl);
    Output.Add('----------------------------------------');

    for A in FItems do
      Output.Add(Format('%s | Prive %d      | %s -> %s      | %s',
        [
          A.GirlName,
          A.Prive,
          DateTimeToStr(A.StartDT),
          DateTimeToStr(A.EndDT),
          FormatDateTime('hh:nn:ss', A.Duration)
        ]));

    StampaReal(Output.Text);   // << STAMPA VERA
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
begin
  FList.Clear;

  for I in FItems do
  begin
    LI := TListBoxItem.Create(FList);
    LI.Parent := FList;

    LI.Text :=
      Format('p%d      | %s → %s     | %s',
      [
        I.Prive,
        FormatDateTime('dd/mm HH:nn', I.StartDT),
        FormatDateTime('HH:nn',        I.EndDT),
        FormatDateTime('hh:nn:ss',     I.Duration)
      ]);

    LI.Height := 25;
    LI.TextSettings.FontColor := TAlphaColors.White;
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
    Output.Add('Registro completo attività privè');
    Output.Add('----------------------------------------');
    Output.Add('');

    Files := TDirectory.GetFiles(DirSaves, '*.json');

    for FileName in Files do
    begin
      GirlName := TPath.GetFileNameWithoutExtension(FileName);
      Data := FStorage.LoadGirl(GirlName);

      Output.Add('--- ' + GirlName + ' ---');
      Output.Add('');

      for A in Data.Activities do
      begin
        Output.Add(
          Format('%s | Prive %d      | %s -> %s       | %s',
          [
            GirlName,
            A.Prive,
            DateTimeToStr(A.Start),
            DateTimeToStr(A.End_),
            FormatDateTime('hh:nn:ss', A.End_ - A.Start)
          ]));
      end;

      Output.Add('');
    end;

    StampaReal(Output.Text);   // << STAMPA VERA
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

  FRoot := TLayout.Create(AOwner);
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
  FBtnPrint.Text := 'Stampa';
  FBtnPrint.Cursor := CrHandPoint;
  FBtnPrint.OnClick := BtnPrintClick;

  FBtnClose := TButton.Create(BtnBar);
  FBtnClose.Parent := BtnBar;
  FBtnClose.Align := TAlignLayout.Right;
  FBtnClose.Width := 300;
  FBtnClose.Text := 'Chiudi';
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

end.

