unit u_Serial;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,System.Win.Registry,
  Winapi.Windows;

function GenerateSerial: string;
function IsValidSerial(const S: string): Boolean;
procedure GenerateSerialList(const FileName: string; Count: Integer);
function ReadSerialFromRegistry: string;
function GetOrCreateFirstRunDate: TDateTime;

implementation

const
  WEIGHTS: array[0..10] of Integer =
    (3, 7, 1, 9, 3, 7, 1, 9, 3, 7, 1);

function CalcChecksum(const Digits: TArray<Integer>): Integer;
var
  I, Sum: Integer;
begin
  Sum := 0;
  for I := 0 to High(WEIGHTS) do
    Sum := Sum + Digits[I] * WEIGHTS[I];

  Result := Sum mod 10;
end;

function RandomDigit: Integer;
begin
  Result := Random(10);
end;

function GenerateSerial: string;
var
  Digits: TArray<Integer>;
  I, Check: Integer;
begin
  SetLength(Digits, 11);

  for I := 0 to 10 do
    Digits[I] := RandomDigit;

  Check := CalcChecksum(Digits);

  Result := Format('%d%d%d-%d%d%d%d-%d%d%d%d-%d',
    [ Digits[0], Digits[1], Digits[2],
      Digits[3], Digits[4], Digits[5], Digits[6],
      Digits[7], Digits[8], Digits[9], Digits[10],
      Check ]);
end;

function IsValidSerial(const S: string): Boolean;
var
  Clean: string;
  Digits: TArray<Integer>;
  I, Check, Expected: Integer;
begin
  Result := False;

  Clean := StringReplace(S, '-', '', [rfReplaceAll]);
  if Length(Clean) <> 12 then Exit;

  SetLength(Digits, 11);

  for I := 1 to 11 do
  begin
    if not CharInSet(Clean[I], ['0'..'9']) then Exit;
    Digits[I-1] := Ord(Clean[I]) - Ord('0');
  end;

  Check := Ord(Clean[12]) - Ord('0');
  Expected := CalcChecksum(Digits);

  Result := Check = Expected;
end;

procedure GenerateSerialList(const FileName: string; Count: Integer);
var
  SL: TStringList;
  I: Integer;
begin
  SL := TStringList.Create;
  try
    for I := 1 to Count do
      SL.Add(GenerateSerial);

    SL.SaveToFile(FileName);
  finally
    SL.Free;
  end;
end;
function ReadSerialFromRegistry: string;
var
  Reg: TRegistry;
begin
  Result := '';
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey('\Software\VVPrive', False) then
    begin
      if Reg.ValueExists('Serial') then
        Result := Reg.ReadString('Serial');
    end;
  finally
    Reg.Free;
  end;
end;
function GetOrCreateFirstRunDate: TDateTime;
var
  Reg: TRegistry;
  S: string;
begin
  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    Reg.RootKey := HKEY_CURRENT_USER;

    if Reg.OpenKey('\Software\VVPrive', True) then
    begin
      if Reg.ValueExists('FirstRun') then
      begin
        S := Reg.ReadString('FirstRun');
        Result := StrToDateTimeDef(S, 0);
      end
      else
      begin
        Result := Now;
        Reg.WriteString('FirstRun', DateTimeToStr(Result));
      end;
    end
    else
      Result := 0;
  finally
    Reg.Free;
  end;
end;

initialization
  Randomize;

end.

