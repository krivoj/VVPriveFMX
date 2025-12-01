unit u_ActivitiesDialog;

interface

uses
  System.SysUtils, System.Classes, System.Types,
  System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Layouts, FMX.ListBox, FMX.StdCtrls,
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
    FPanel: TLayout;
    FList: TListBox;
    FBtnClose: TButton;
    FBtnPrint: TButton;

    FItems: TList<TActivityView>;
    FStorage: TGirlStorage;

    procedure LoadAllActivitiesFromFiles;
    procedure LoadGirl(const FilePath: string);
    procedure PopulateList;

    procedure BtnCloseClick(Sender: TObject);
    procedure BtnPrintClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure ShowCentered;
  end;

implementation

uses
  unit1; // per DirSaves

{ TActivitiesDialog }

constructor TActivitiesDialog.Create(AOwner: TComponent);
var
  BG : TRectangle;
begin
  inherited;

  Align := TAlignLayout.Contents;
  HitTest := True;
  Opacity := 0.0;
  Visible := True;

  FItems := TList<TActivityView>.Create;
  FStorage := TGirlStorage.Create;

  // Pannello centrale stile tConfirmDialog
  FPanel := TLayout.Create(Self);
  FPanel.Parent := Self;
  FPanel.Width := 600;
  FPanel.Height := 600;
  FPanel.Position.Point :=
    PointF(
      (Owner as TControl).Width / 2 - FPanel.Width / 2,
      (Owner as TControl).Height / 2 - FPanel.Height / 2
    );
  FPanel.Padding.Rect := TRectF.Create(20, 20, 20, 20);
  FPanel.ClipChildren := True;

  // Sfondo scuro arrotondato
  BG := TRectangle.Create(FPanel);
  BG.Parent := FPanel;
  BG.Align := TAlignLayout.Contents;
  BG.Fill.Color := $FF202020;
  BG.Stroke.Kind := TBrushKind.None;
  BG.XRadius := 16;
  BG.YRadius := 16;

  // Lista attività
  FList := TListBox.Create(FPanel);
  FList.Parent := FPanel;
  FList.Align := TAlignLayout.Client;
  FList.ItemHeight := 50;
  FList.TextSettings.Font.Size := 15;
  FList.TextSettings.FontColor := TAlphaColors.White;

  // Pulsante stampa
  FBtnPrint := TButton.Create(FPanel);
  FBtnPrint.Parent := FPanel;
  FBtnPrint.Align := TAlignLayout.Bottom;
  FBtnPrint.Height := 50;
  FBtnPrint.Text := 'Stampa';
  FBtnPrint.OnClick := BtnPrintClick;

  // Pulsante chiudi
  FBtnClose := TButton.Create(FPanel);
  FBtnClose.Parent := FPanel;
  FBtnClose.Align := TAlignLayout.Bottom;
  FBtnClose.Height := 50;
  FBtnClose.Text := 'Chiudi';
  FBtnClose.OnClick := BtnCloseClick;

  // Caricamento dati
  LoadAllActivitiesFromFiles;
  PopulateList;
end;

destructor TActivitiesDialog.Destroy;
begin
  FItems.Free;
  FStorage.Free;
  inherited;
end;

procedure TActivitiesDialog.ShowCentered;
begin
  BringToFront;
  AnimateFloat('Opacity', 1, 0.3);
end;

procedure TActivitiesDialog.BtnCloseClick(Sender: TObject);
begin
  AnimateFloat('Opacity', 0, 0.25,
    procedure
    begin
      Free;
    end);
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
    begin
      SL.Add(
        Format(
          '%s | Prive %d | %s -> %s | Durata: %s',
          [
            A.GirlName,
            A.Prive,
            DateTimeToStr(A.StartDT),
            DateTimeToStr(A.EndDT),
            FormatDateTime('hh:nn:ss', A.Duration.TotalSeconds / 86400)
          ]
        )
      );
    end;

    OutFile := TPath.Combine(TPath.GetDocumentsPath, 'AttivitaPrive.txt');
    SL.SaveToFile(OutFile);

    ShowMessage('Stampato: ' + OutFile);
  finally
    SL.Free;
  end;
end;

procedure TActivitiesDialog.LoadAllActivitiesFromFiles;
var
  FileName: string;
begin
  for FileName in TDirectory.GetFiles(DirSaves, '*.json') do
    LoadGirl(FileName);
end;

procedure TActivitiesDialog.LoadGirl(const FilePath: string);
var
  GirlName: string;
  Data: TGirlData;
  A: TActivity;
  Item: TActivityView;
begin
  GirlName := TPath.GetFileNameWithoutExtension(FilePath);

  Data := FStorage.LoadGirl(GirlName);

  for A in Data.Activities do
  begin
    Item.GirlName := GirlName;
    Item.Prive := A.Prive;
    Item.StartDT := A.Start;
    Item.EndDT   := A.End_;
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
      Format(
        '%s | p%d | %s → %s | %s',
        [
          I.GirlName,
          I.Prive,
          FormatDateTime('dd/mm HH:nn', I.StartDT),
          FormatDateTime('HH:nn', I.EndDT),
          FormatDateTime('hh:nn:ss', I.Duration)   // ← durata come TDateTime
        ]
      );

    LI.Height := 50;
    LI.TextSettings.FontColor := TAlphaColors.White;
  end;
end;

end.

