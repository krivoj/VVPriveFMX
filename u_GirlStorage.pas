unit u_GirlStorage;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.IOUtils;

// -----------------------------------------------------------------------------
// Strutture dati
// -----------------------------------------------------------------------------

type
  TActivity = record
    Prive: Integer;
    Slot: integer;
    Start: TDateTime;
    End_: TDateTime;
  end;

  TGirlData = record
    Prive: Integer;         // stato attuale
    Slot: Integer;
    Start: TDateTime;       // orario inizio stato
    Activities: TArray<TActivity>;
  end;

// -----------------------------------------------------------------------------
// Classe TGirlStorage
// Gestisce caricamento/salvataggio JSON per ogni ragazza
// -----------------------------------------------------------------------------

type
  TGirlStorage = class
  private
  public
    constructor Create();
    function LoadGirl(const GirlName: string): TGirlData;
    procedure SaveGirl(const GirlName: string; const Data: TGirlData);
    procedure AddActivity(const GirlName: string; const A: TActivity);
    procedure SetStatus(const GirlName: string; NewPrive, Slot: Integer; StartTime: TDateTime);
    procedure LogActivity(const GirlName: string);
    procedure ClearActivities(const GirlName: string);
  end;

implementation

uses
  System.DateUtils, unit1;

// -----------------------------------------------------------------------------
constructor TGirlStorage.Create();
begin
end;

// -----------------------------------------------------------------------------
function TGirlStorage.LoadGirl(const GirlName: string): TGirlData;
var
  FileName: string;
  JSON: TJSONObject;
  Status: TJSONObject;
  Arr: TJSONArray;
  Item: TJSONValue;
  A: TActivity;
  O: TJSONObject;
  i: Integer;
begin
  FileName := DirSaves + GirlName + '.json';

  // se il file non esiste restituiamo record vuoto
  if not FileExists(FileName) then
  begin
    Result.Prive := -1;
    Result.Slot := -1;
    Result.Start := 0;
    SetLength(Result.Activities, 0);
    Exit;
  end;

  JSON := TJSONObject.ParseJSONValue(TFile.ReadAllText(FileName)) as TJSONObject;
  try
    // STATUS
    Status := JSON.GetValue<TJSONObject>('status');
    Result.Prive := Status.GetValue<Integer>('prive');
    Result.Slot := Status.GetValue<Integer>('slot');
    Result.Start := ISO8601ToDate(Status.GetValue<string>('start'));

    // ACTIVITIES
    Arr := JSON.GetValue<TJSONArray>('activities');
    SetLength(Result.Activities, Arr.Count);

    i := 0;
    for Item in Arr do
    begin
      O := Item as TJSONObject;
      A.Prive := O.GetValue<Integer>('prive');
      A.Slot := O.GetValue<Integer>('slot');
      A.Start := ISO8601ToDate(O.GetValue<string>('start'));
      A.End_  := ISO8601ToDate(O.GetValue<string>('end'));
      Result.Activities[i] := A;
      Inc(i);
    end;

  finally
    JSON.Free;
  end;
end;

// -----------------------------------------------------------------------------
procedure TGirlStorage.SaveGirl(const GirlName: string; const Data: TGirlData);
var
  FileName: string;
  JSON, Status, O: TJSONObject;
  Arr: TJSONArray;
  A: TActivity;
begin
  FileName := DirSaves + GirlName + '.json';

  JSON := TJSONObject.Create;
  try
    // STATUS
    Status := TJSONObject.Create;
    Status.AddPair('prive', TJSONNumber.Create(Data.Prive));
    Status.AddPair('slot', TJSONNumber.Create(Data.Slot));
    Status.AddPair('start', DateToISO8601(Data.Start));
    JSON.AddPair('status', Status);

    // ACTIVITIES
    Arr := TJSONArray.Create;
    for A in Data.Activities do
    begin
      O := TJSONObject.Create;
      O.AddPair('prive', TJSONNumber.Create(A.Prive));
      O.AddPair('slot', TJSONNumber.Create(A.Slot));
      O.AddPair('start', DateToISO8601(A.Start));
      O.AddPair('end',   DateToISO8601(A.End_));
      Arr.AddElement(O);
    end;
    JSON.AddPair('activities', Arr);

    // salva
    TFile.WriteAllText(FileName, JSON.ToJSON);

  finally
    JSON.Free;
  end;
end;
procedure TGirlStorage.AddActivity(const GirlName: string; const A: TActivity);
var
  Data: TGirlData;
  Len: Integer;
begin
  Data := LoadGirl(GirlName);
  Len := Length(Data.Activities);
  SetLength(Data.Activities, Len + 1);
  Data.Activities[Len] := A;
  SaveGirl(GirlName, Data);
end;
procedure TGirlStorage.SetStatus(const GirlName: string; NewPrive, Slot: Integer; StartTime: TDateTime);
var
  Data: TGirlData;
begin
  Data := LoadGirl(GirlName);
  Data.Prive := NewPrive;
  Data.Slot := Slot;
  Data.Start := StartTime; // può essere Now o 0
  SaveGirl(GirlName, Data);
end;
procedure TGirlStorage.LogActivity(const GirlName: string);
var
  Data: TGirlData;
  A: TActivity;
begin
  // Carico i dati della ragazza
  Data := LoadGirl(GirlName);

  // Se non è in un privè, non facciamo nulla
  if Data.Prive = -1 then
    Exit;

  // Preparo nuova attività
  A.Prive := Data.Prive;
  A.Slot := Data.Slot;
  A.Start := Data.Start;
  A.End_  := Now;   // momento della registrazione

  // Aggiungo l'attività al JSON
  AddActivity(GirlName, A);

end;
procedure TGirlStorage.ClearActivities(const GirlName: string);
var
  Data: TGirlData;
begin
  Data := LoadGirl(GirlName);

  // cancella tutte le attività
  SetLength(Data.Activities, 0);

  // opzionale: resetta anche lo stato attuale
   Data.Prive := -1;
   Data.Slot := -1;
   Data.Start := 0;

  SaveGirl(GirlName, Data);
end;
end.

