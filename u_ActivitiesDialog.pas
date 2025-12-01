unit u_ActivitiesDialog;

interface

uses
  System.SysUtils, System.Classes, System.Types,
  System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Layouts, FMX.ListBox, FMX.StdCtrls, System.UITypes,
  FMX.Objects, FMX.Graphics,
  u_GirlStorage, System.IOUtils, System.DateUtils;

type
  TActivityView = record
    GirlName : string;
    Prive    : Integer;
    StartDT  : TDateTime;
    EndDT    : TDateTime;
    Duration : TDateTime;
  end;

  TActivitiesDialog = class(TLayout)
  private
    FRoot : TLayout;
    FPanel: TRectangle;
    FList: TListBox;
    FBtnClose: TButton;
    FBtnPrint: TButton;

    FItems: TList<TActivityView>;
    FStorage: TGirlStorage;

    procedure LoadGirl(const GirlName: string);
    procedure PopulateList;

    procedure BtnCloseClick(Sender: TObject);
    procedure BtnPrintClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure ShowCentered(GirlName: String);
  end;

implementation

uses
  Unit1;

{ TActivitiesDialog }

constructor TActivitiesDialog.Create(AOwner: TComponent);
var
  DarkBG: TRectangle;
  BtnBar : TLayout;
begin
  inherited;

  HitTest := True;
  Align   := TAlignLayout.Contents;
  Visible := False;

  FItems := TList<TActivityView>.Create;
  FStorage := TGirlStorage.Create;

  // ---------------------------------------------------------
  // ROOT OVERLAY (come TConfirmDialog)
  // ---------------------------------------------------------
  FRoot := TLayout.Create(Self);
  FRoot.Parent := Self;
  FRoot.Align := TAlignLayout.Contents;
  FRoot.HitTest := True;

  // sfondo scuro trasparente
  DarkBG := TRectangle.Create(FRoot);
  DarkBG.Parent := FRoot;
  DarkBG.Align := TAlignLayout.Contents;
  DarkBG.Fill.Color := $88000000;
  DarkBG.Stroke.Kind := TBrushKind.None;

  // ---------------------------------------------------------
  // PANNELLO CENTRALE
  // ---------------------------------------------------------
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

  // ---------------------------------------------------------
  // LISTA DELLE ATTIVITÀ
  // ---------------------------------------------------------
  FList := TListBox.Create(FPanel);
  FList.Parent := FPanel;
  FList.Align := TAlignLayout.Client;
  FList.ItemHeight := 50;

  // ---------------------------------------------------------
  // BARRA BOTTONI IN BASSO
  // ---------------------------------------------------------
  BtnBar := TLayout.Create(FPanel);
  BtnBar.Parent := FPanel;
  BtnBar.Align := TAlignLayout.Bottom;
  BtnBar.Height := 100;

  // Pulsante stampa
  FBtnPrint := TButton.Create(BtnBar);
  FBtnPrint.Parent := BtnBar;
  FBtnPrint.Align := TAlignLayout.Left;
  FBtnPrint.Width := 250;
  FBtnPrint.Text := 'Stampa';
  FBtnPrint.OnClick := BtnPrintClick;
  FBtnPrint.Cursor := CrHandPoint;

  // Pulsante chiudi
  FBtnClose := TButton.Create(BtnBar);
  FBtnClose.Parent := BtnBar;
  FBtnClose.Align := TAlignLayout.Right;
  FBtnClose.Width := 250;
  FBtnClose.Text := 'Chiudi';
  FBtnClose.OnClick := BtnCloseClick;
  FBtnClose.Cursor := CrHandPoint;
end;

destructor TActivitiesDialog.Destroy;
begin
  FItems.Free;
  FStorage.Free;
  inherited;
end;

procedure TActivitiesDialog.ShowCentered(GirlName: String);
begin
  // Reset lista attività
  FItems.Clear;
  FList.Clear;

  // Carica attività della ragazza
  LoadGirl(GirlName);

  // Popola lista
  PopulateList;

  // Mostra overlay
  Visible := True;
  BringToFront;
end;

procedure TActivitiesDialog.BtnCloseClick(Sender: TObject);
begin
  Visible := False;
end;

procedure TActivitiesDialog.BtnPrintClick(Sender: TObject);
var
  SL: TStringList;
  A: TActivityView;
  OutFile: string;
begin
  SL := TStringList.Create;
  try
    SL.Add('Registro attività privè');
    SL.Add('----------------------------------------');

    for A in FItems do
      SL.Add(Format('%s | Prive %d | %s -> %s | %s',
        [
          A.GirlName,
          A.Prive,
          DateTimeToStr(A.StartDT),
          DateTimeToStr(A.EndDT),
          FormatDateTime('hh:nn:ss', A.Duration)
        ]));

    OutFile := TPath.Combine(TPath.GetDocumentsPath, 'AttivitaPrive.txt');
    SL.SaveToFile(OutFile);

  finally
    SL.Free;
  end;
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
      Format('%s | p%d | %s → %s | %s',
      [
        I.GirlName,
        I.Prive,
        FormatDateTime('dd/mm HH:nn', I.StartDT),
        FormatDateTime('HH:nn',        I.EndDT),
        FormatDateTime('hh:nn:ss',     I.Duration)
      ]);

    LI.Height := 50;
    LI.TextSettings.FontColor := TAlphaColors.White;
  end;
end;

end.

