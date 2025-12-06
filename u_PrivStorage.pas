unit u_PrivStorage;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.IOUtils;

type
  TPrivState = (tsOff, tsOn, tsAlarm);

  TPrivData = record
    State: TPrivState;
    StartTime: TDateTime;
    EndTime: TDateTime;
  end;

  TPrivStorage = class
  private
    FFileName: string;
    function StateToStr(S: TPrivState): string;
    function StrToState(const S: string): TPrivState;
  public
    constructor Create(const FileName: string);

    function LoadAll: TArray<TPrivData>;
    procedure SaveAll(const List: TArray<TPrivData>);

    function LoadOne(Index: Integer): TPrivData;
    procedure SaveOne(Index: Integer; const Data: TPrivData);
    procedure SetStatus(Index: Integer; State: TPrivState; StartTime, EndTime: TDateTime);

  end;

implementation

uses
  System.DateUtils;

{ --------------------------------------------------------------------------
  COSTRUTTORE
  -------------------------------------------------------------------------- }
constructor TPrivStorage.Create(const FileName: string);
begin
  FFileName := FileName;
end;

{ --------------------------------------------------------------------------
  CONVERSIONI STATO <-> STRINGA
  -------------------------------------------------------------------------- }
function TPrivStorage.StateToStr(S: TPrivState): string;
begin
  case S of
    tsOff:   Result := 'off';
    tsOn:    Result := 'on';
    tsAlarm: Result := 'alarm';
  end;
end;

function TPrivStorage.StrToState(const S: string): TPrivState;
begin
  if SameText(S, 'on') then Exit(tsOn);
  if SameText(S, 'alarm') then Exit(tsAlarm);
  Result := tsOff;
end;

{ --------------------------------------------------------------------------
  CARICA TUTTO IL FILE prive.json
  -------------------------------------------------------------------------- }
function TPrivStorage.LoadAll: TArray<TPrivData>;
var
  JSON: TJSONObject;
  Arr: TJSONArray;
  O: TJSONObject;
  Item: TJSONValue;
  P: TPrivData;
  i: Integer;
begin
  // Se non esiste → restituisci array vuoto
  if not FileExists(FFileName) then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  JSON := TJSONObject.ParseJSONValue(TFile.ReadAllText(FFileName)) as TJSONObject;
  try
    Arr := JSON.GetValue<TJSONArray>('prives');

    SetLength(Result, Arr.Count);
    i := 0;

    for Item in Arr do
    begin
      O := Item as TJSONObject;
      P.State := StrToState(O.GetValue<string>('state'));
      P.StartTime := ISO8601ToDate(O.GetValue<string>('start'));
      P.EndTime := ISO8601ToDate(O.GetValue<string>('end'));
      Result[i] := P;
      Inc(i);
    end;

  finally
    JSON.Free;
  end;
end;

{ --------------------------------------------------------------------------
  SALVA TUTTI I PRIVE
  -------------------------------------------------------------------------- }
procedure TPrivStorage.SaveAll(const List: TArray<TPrivData>);
var
  JSON: TJSONObject;
  Arr: TJSONArray;
  O: TJSONObject;
  P: TPrivData;
begin
  JSON := TJSONObject.Create;
  try
    Arr := TJSONArray.Create;

    for P in List do
    begin
      O := TJSONObject.Create;
      O.AddPair('state', StateToStr(P.State));
      O.AddPair('start', DateToISO8601(P.StartTime));
      O.AddPair('end', DateToISO8601(P.endTime));
      Arr.AddElement(O);
    end;

    JSON.AddPair('prives', Arr);
    TFile.WriteAllText(FFileName, JSON.ToJSON);

  finally
    JSON.Free;
  end;
end;

{ --------------------------------------------------------------------------
  CARICA 1 PRIVÈ
  -------------------------------------------------------------------------- }
function TPrivStorage.LoadOne(Index: Integer): TPrivData;
var
  List: TArray<TPrivData>;
begin
  List := LoadAll;

  // Se non esiste, restituisci dati vuoti (tsOff, 0)
  if (Index < 0) or (Index >= Length(List)) then
  begin
    Result.State := tsOff;
    Result.StartTime := 0;
    Result.EndTime := 0;
  end
  else
    Result := List[Index];
end;

{ --------------------------------------------------------------------------
  SALVA 1 PRIVÈ
  -------------------------------------------------------------------------- }
procedure TPrivStorage.SaveOne(Index: Integer; const Data: TPrivData);
var
  List: TArray<TPrivData>;
  OldLen: Integer;
begin
  List := LoadAll;
  OldLen := Length(List);

  // Se l'indice è oltre la dimensione → estende l'array
  if Index >= OldLen then
  begin
    SetLength(List, Index + 1);
    while OldLen < Index do
    begin
      List[OldLen].State := tsOff;
      List[OldLen].StartTime := 0;
      List[OldLen].EndTime := 0;
      Inc(OldLen);
    end;
  end;

  // Sovrascrivi
  List[Index] := Data;

  SaveAll(List);
end;
procedure TPrivStorage.SetStatus(Index: Integer; State: TPrivState; StartTime, EndTime: TDateTime);
var
  P: TPrivData;
begin
  // Carico lo stato attuale del singolo privè
  P := LoadOne(Index);

  // Aggiorno i valori
  P.State := State;
  P.StartTIme := StartTime;
  P.EndTIme := EndTime;

  // Salvo solo questo privè
  SaveOne(Index, P);
end;
end.

